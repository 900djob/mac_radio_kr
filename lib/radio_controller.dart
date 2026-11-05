import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'radio_channel.dart';
import 'stream_url_resolver.dart';

enum RadioStatus {
  stopped('정지'),
  connecting('연결 중'),
  playing('재생 중'),
  failed('연결 실패');

  const RadioStatus(this.label);
  final String label;
}

class RadioController extends ChangeNotifier {
  RadioController({
    required SharedPreferences preferences,
    AudioPlayer? player,
    StreamUrlResolver? resolver,
  }) : _preferences = preferences,
       _player = player ?? AudioPlayer(),
       _resolver = resolver ?? StreamUrlResolver() {
    channel = RadioChannel.byId(preferences.getString('channel'));
    volume = (preferences.getDouble('volume') ?? 0.5).clamp(0.0, 1.0);
    _stateSubscription = _player.playerStateStream.listen(_onPlayerState);
    _errorSubscription = _player.errorStream.listen((_) => _fail());
  }

  final SharedPreferences _preferences;
  final AudioPlayer _player;
  final StreamUrlResolver _resolver;
  late final StreamSubscription<PlayerState> _stateSubscription;
  late final StreamSubscription<PlayerException> _errorSubscription;

  late RadioChannel channel;
  late double volume;
  RadioStatus status = RadioStatus.stopped;
  int _request = 0;
  bool _wantsPlayback = false;
  bool _closed = false;
  Future<void>? _shutdown;

  Future<void> initialize() => _player.setVolume(volume);

  Future<void> select(RadioChannel selected) async {
    if (_closed) return;
    final request = ++_request;
    channel = selected;
    _wantsPlayback = true;
    status = RadioStatus.connecting;
    notifyListeners();
    unawaited(_preferences.setString('channel', selected.id));

    try {
      // 새 선택은 기존 재생과 로딩을 중단하고, 늦게 도착한 응답은 버린다.
      await _player.stop();
      if (!_isCurrent(request)) return;
      final uri = await _resolver.resolve(selected);
      if (!_isCurrent(request)) return;
      await _player.setUrl(uri.toString()).timeout(const Duration(seconds: 15));
      if (!_isCurrent(request)) return;
      unawaited(
        _player.play().catchError((Object error) {
          if (_isCurrent(request)) _fail();
        }),
      );
    } on PlayerInterruptedException {
      if (_isCurrent(request)) _fail();
    } catch (_) {
      if (_isCurrent(request)) _fail();
    }
  }

  Future<void> togglePlayback() => _wantsPlayback ? stop() : select(channel);

  Future<void> stop() async {
    if (_closed) return;
    ++_request;
    _wantsPlayback = false;
    status = RadioStatus.stopped;
    notifyListeners();
    await _player.stop();
  }

  Future<void> step(int offset) {
    final index = RadioChannel.channels.indexOf(channel);
    return select(
      RadioChannel.channels[(index + offset) % RadioChannel.channels.length],
    );
  }

  Future<void> setVolume(double value) async {
    if (_closed) return;
    volume = value.clamp(0.0, 1.0);
    notifyListeners();
    await _player.setVolume(volume);
    await _preferences.setDouble('volume', volume);
  }

  bool _isCurrent(int request) => !_closed && request == _request;

  void _onPlayerState(PlayerState state) {
    if (_closed || !_wantsPlayback || status == RadioStatus.failed) return;
    final next = switch (state.processingState) {
      ProcessingState.ready =>
        state.playing ? RadioStatus.playing : RadioStatus.connecting,
      ProcessingState.completed => RadioStatus.failed,
      _ => RadioStatus.connecting,
    };
    if (next == RadioStatus.failed) {
      _fail();
    } else if (status != next) {
      status = next;
      notifyListeners();
    }
  }

  void _fail() {
    if (_closed || !_wantsPlayback) return;
    ++_request;
    _wantsPlayback = false;
    status = RadioStatus.failed;
    unawaited(_player.stop());
    notifyListeners();
  }

  Future<void> shutdown() {
    dispose();
    return _shutdown!;
  }

  Future<void> _close() async {
    await _stateSubscription.cancel();
    await _errorSubscription.cancel();
    await _player.dispose();
    _resolver.close();
  }

  @override
  void dispose() {
    if (_closed) return;
    _closed = true;
    ++_request;
    _shutdown = _close();
    super.dispose();
  }
}
