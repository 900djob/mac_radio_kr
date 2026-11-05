import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mac_radio_kr/menu_bar_bridge.dart';
import 'package:mac_radio_kr/radio_channel.dart';
import 'package:mac_radio_kr/radio_controller.dart';
import 'package:mac_radio_kr/stream_url_resolver.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockResolver extends Mock implements StreamUrlResolver {}

class MockVolumeBridge extends Mock implements MenuBarBridge {}

void main() {
  late MockAudioPlayer player;
  late MockResolver resolver;
  late RadioController controller;
  late StreamController<PlayerState> states;
  late StreamController<PlayerException> errors;
  late SharedPreferences preferences;
  late MockVolumeBridge volumeBridge;
  late StreamController<SystemVolumeState> volumeChanges;

  setUpAll(() => registerFallbackValue(RadioChannel.channels.first));
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    states = StreamController<PlayerState>.broadcast(sync: true);
    errors = StreamController<PlayerException>.broadcast(sync: true);
    player = MockAudioPlayer();
    resolver = MockResolver();
    volumeBridge = MockVolumeBridge();
    volumeChanges = StreamController<SystemVolumeState>.broadcast(sync: true);
    when(
      () => volumeBridge.systemVolumeChanges,
    ).thenAnswer((_) => volumeChanges.stream);
    when(() => volumeBridge.getSystemVolume()).thenAnswer(
      (_) async =>
          const SystemVolumeState(volume: 0.5, muted: false, available: true),
    );
    when(() => volumeBridge.setSystemVolume(any())).thenAnswer(
      (call) async => SystemVolumeState(
        volume: call.positionalArguments.first as double,
        muted: false,
        available: true,
      ),
    );
    when(() => player.playerStateStream).thenAnswer((_) => states.stream);
    when(() => player.errorStream).thenAnswer((_) => errors.stream);
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.setVolume(any())).thenAnswer((_) async {});
    when(() => player.setUrl(any())).thenAnswer((_) async => null);
    when(() => player.play()).thenAnswer((_) async {
      states.add(PlayerState(true, ProcessingState.ready));
    });
    when(() => player.dispose()).thenAnswer((_) async {});
    when(
      () => resolver.resolve(any()),
    ).thenAnswer((_) async => Uri.parse('https://example.com/live.m3u8'));
    controller = RadioController(
      preferences: preferences,
      player: player,
      resolver: resolver,
      volumeBridge: volumeBridge,
    );
  });
  tearDown(() async {
    await controller.shutdown();
    await states.close();
    await errors.close();
    await volumeChanges.close();
  });

  test(
    'restores the channel but reads system volume without overwriting it',
    () async {
      await preferences.setDouble('volume', 0.1);
      await controller.initialize();
      expect(controller.channel.id, 'mbc_fm4u');
      expect(controller.status, RadioStatus.stopped);
      verifyNever(() => player.play());
      expect(controller.volume, 0.5);
      verify(() => player.setVolume(1)).called(1);
      verifyNever(() => volumeBridge.setSystemVolume(any()));
      await controller.select(RadioChannel.byId('sbs_power'));
      expect(preferences.getString('channel'), 'sbs_power');
      expect(preferences.getDouble('volume'), isNull);
      final restored = RadioController(
        preferences: preferences,
        player: player,
        resolver: resolver,
        volumeBridge: volumeBridge,
      );
      await restored.initialize();
      expect(restored.channel.id, 'sbs_power');
      expect(restored.volume, 0.5);
      expect(restored.status, RadioStatus.stopped);
      await restored.shutdown();
    },
  );

  test('late URL responses cannot replace the latest channel', () async {
    final first = Completer<Uri>();
    when(
      () => resolver.resolve(RadioChannel.byId('kbs_cool')),
    ).thenAnswer((_) => first.future);
    final oldSelection = controller.select(RadioChannel.byId('kbs_cool'));
    await Future<void>.delayed(Duration.zero);
    await controller.select(RadioChannel.byId('sbs_power'));
    first.complete(Uri.parse('https://example.com/old.m3u8'));
    await oldSelection;
    expect(controller.channel.id, 'sbs_power');
    expect(controller.status, RadioStatus.playing);
    verifyNever(() => player.setUrl('https://example.com/old.m3u8'));
    verify(() => player.play()).called(1);
  });

  test('stopping during lookup prevents late playback', () async {
    final pending = Completer<Uri>();
    when(() => resolver.resolve(any())).thenAnswer((_) => pending.future);
    final selection = controller.select(controller.channel);
    await Future<void>.delayed(Duration.zero);
    await controller.stop();
    pending.complete(Uri.parse('https://example.com/live.m3u8'));
    await selection;
    expect(controller.status, RadioStatus.stopped);
    verifyNever(() => player.play());
  });

  test('an error can be retried with a fresh URL', () async {
    when(
      () => resolver.resolve(any()),
    ).thenThrow(const FormatException('unavailable'));
    await controller.togglePlayback();
    expect(controller.status, RadioStatus.failed);
    when(
      () => resolver.resolve(any()),
    ).thenAnswer((_) async => Uri.parse('https://example.com/new.m3u8'));
    await controller.togglePlayback();
    expect(controller.status, RadioStatus.playing);
    verify(() => resolver.resolve(any())).called(2);
  });

  test(
    'system changes and mute update the slider without writing back',
    () async {
      await controller.initialize();
      volumeChanges.add(
        const SystemVolumeState(volume: 0.7, muted: false, available: true),
      );
      expect(controller.volume, 0.7);
      volumeChanges.add(
        const SystemVolumeState(volume: 0.7, muted: true, available: true),
      );
      expect(controller.volume, 0);
      verifyNever(() => volumeBridge.setSystemVolume(any()));
      verifyNever(() => player.setVolume(0.7));
    },
  );

  test(
    'slider changes system volume and does not attenuate the player',
    () async {
      await controller.initialize();
      await controller.setVolume(0.3);
      expect(controller.volume, 0.3);
      verify(() => volumeBridge.setSystemVolume(0.3)).called(1);
      verifyNever(() => player.setVolume(0.3));
      expect(preferences.getDouble('volume'), isNull);
    },
  );

  test(
    'a delayed slider response cannot replace a newer system event',
    () async {
      await controller.initialize();
      final pending = Completer<SystemVolumeState>();
      when(
        () => volumeBridge.setSystemVolume(0.2),
      ).thenAnswer((_) => pending.future);
      final setting = controller.setVolume(0.2);
      volumeChanges.add(
        const SystemVolumeState(volume: 0.8, muted: false, available: true),
      );
      pending.complete(
        const SystemVolumeState(volume: 0.2, muted: false, available: true),
      );
      await setting;
      expect(controller.volume, 0.8);
    },
  );

  test('unsupported output devices disable volume writes', () async {
    await controller.initialize();
    volumeChanges.add(
      const SystemVolumeState(volume: 0, muted: false, available: false),
    );
    expect(controller.canControlVolume, isFalse);
    await controller.setVolume(0.3);
    verifyNever(() => volumeBridge.setSystemVolume(any()));
  });
}
