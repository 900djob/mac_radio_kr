import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mac_radio_kr/menu_bar_bridge.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'system volume writes emit CoreAudio events and restore the original level',
    (tester) async {
      final bridge = MenuBarBridge();
      final initial = Completer<SystemVolumeState>();
      final events = <SystemVolumeState>[];
      final subscription = bridge.systemVolumeChanges.listen((state) {
        events.add(state);
        if (!initial.isCompleted) initial.complete(state);
      });
      addTearDown(subscription.cancel);
      await initial.future.timeout(const Duration(seconds: 5));
      final original = await bridge.getSystemVolume();
      if (!original.available || original.muted || original.volume < 0.05) {
        markTestSkipped(
          'Output is unavailable, muted or too quiet for a reversible volume check.',
        );
        return;
      }

      Future<void> waitForEvent(
        bool Function(SystemVolumeState) matches,
      ) async {
        final deadline = DateTime.now().add(const Duration(seconds: 5));
        while (!events.any(matches) && DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        expect(
          events.any(matches),
          isTrue,
          reason: 'CoreAudio change notification',
        );
      }

      try {
        events.clear();
        final lowered = await bridge.setSystemVolume(original.volume - 0.04);
        expect(lowered.volume, lessThan(original.volume));
        await waitForEvent(
          (state) =>
              !state.muted && (state.volume - lowered.volume).abs() < 0.001,
        );
        final read = await bridge.getSystemVolume();
        expect(read.volume, closeTo(lowered.volume, 0.001));

        events.clear();
        final muted = await bridge.setSystemVolume(0);
        expect(muted.volume, closeTo(0, 0.001));
        await waitForEvent((state) => state.volume == 0);
        debugPrint(
          'SYSTEM_VOLUME_CHECK: read/write and CoreAudio event stream passed',
        );
      } finally {
        await bridge.setSystemVolume(original.volume);
        final restored = await bridge.getSystemVolume();
        expect(restored.volume, closeTo(original.volume, 0.001));
        expect(restored.muted, original.muted);
      }
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
