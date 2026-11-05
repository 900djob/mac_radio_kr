import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mac_radio_kr/radio_channel.dart';
import 'package:mac_radio_kr/radio_controller.dart';
import 'package:mac_radio_kr/stream_url_resolver.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockResolver extends Mock implements StreamUrlResolver {}

void main() {
  late MockAudioPlayer player;
  late MockResolver resolver;
  late RadioController controller;
  late StreamController<PlayerState> states;
  late StreamController<PlayerException> errors;
  late SharedPreferences preferences;

  setUpAll(() => registerFallbackValue(RadioChannel.channels.first));
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    states = StreamController<PlayerState>.broadcast(sync: true);
    errors = StreamController<PlayerException>.broadcast(sync: true);
    player = MockAudioPlayer();
    resolver = MockResolver();
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
    );
  });
  tearDown(() async {
    await controller.shutdown();
    await states.close();
    await errors.close();
  });

  test('starts stopped at FM4U and restores only channel and volume', () async {
    await controller.initialize();
    expect(controller.channel.id, 'mbc_fm4u');
    expect(controller.status, RadioStatus.stopped);
    verifyNever(() => player.play());
    await controller.setVolume(0.3);
    await controller.select(RadioChannel.byId('sbs_power'));
    expect(preferences.getString('channel'), 'sbs_power');
    expect(preferences.getDouble('volume'), 0.3);
    final restored = RadioController(
      preferences: preferences,
      player: player,
      resolver: resolver,
    );
    expect(restored.channel.id, 'sbs_power');
    expect(restored.volume, 0.3);
    expect(restored.status, RadioStatus.stopped);
    await restored.shutdown();
  });

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

  test('previous and next wrap around the catalog', () async {
    await controller.select(RadioChannel.channels.first);
    await controller.step(-1);
    expect(controller.channel.id, RadioChannel.channels.last.id);
    await controller.step(1);
    expect(controller.channel.id, RadioChannel.channels.first.id);
  });
}
