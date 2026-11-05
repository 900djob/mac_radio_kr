import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mac_radio_kr/radio_channel.dart';
import 'package:mac_radio_kr/radio_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'all 13 stations play through the native macOS player',
    (tester) async {
      // 자동 검증은 무음으로 수행하며 실제 사용자 설정을 변경하지 않는다.
      SharedPreferences.setMockInitialValues({'volume': 0.0});
      final player = AudioPlayer();
      final controller = RadioController(
        preferences: await SharedPreferences.getInstance(),
        player: player,
      );
      addTearDown(controller.shutdown);
      await controller.initialize();

      for (final channel in RadioChannel.channels) {
        await controller.select(channel);
        final deadline = DateTime.now().add(const Duration(seconds: 20));
        while (DateTime.now().isBefore(deadline) &&
            controller.status != RadioStatus.failed &&
            (controller.status != RadioStatus.playing ||
                player.bufferedPosition <= Duration.zero)) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
        expect(controller.status, RadioStatus.playing, reason: channel.name);
        expect(
          player.bufferedPosition.inMilliseconds,
          greaterThan(0),
          reason: channel.name,
        );
        debugPrint(
          'AUDIO_CHECK ${channel.id}: playing, buffered=${player.bufferedPosition.inMilliseconds}ms',
        );
      }

      await controller.stop();
      expect(controller.status, RadioStatus.stopped);
      expect(player.playing, isFalse);
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
