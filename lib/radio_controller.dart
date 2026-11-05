import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'menu_bar_bridge.dart';
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
    MenuBarBridge? volumeBridge,
  }) : _preferences = preferences,
       _player = player ?? AudioPlayer(),
       _resolver = resolver ?? StreamUrlResolver(),
       _volumeBridge = volumeBridge ?? MenuBarBridge() {
    channel = RadioChannel.byId(preferences.getString('channel'));
    _stateSubscription = _player.playerStateStream.listen(_onPlayerState);
    _errorSubscription = _player.errorStream.listen((_) => _fail());
  }

  final SharedPreferences _preferences;
  final AudioPlayer _player;
  final StreamUrlResolver _resolver;
  final MenuBarBridge _volumeBridge;
  StreamSubscription<SystemVolumeState>? _volumeSubscription;
  late final StreamSubscription<PlayerState> _stateSubscription;
  late final StreamSubscription<PlayerException> _errorSubscription;

  late RadioChannel channel;
  double volume = 0;
  bool canControlVolume = false;
  RadioStatus status = RadioStatus.stopped;
  int _request = 0;
  bool _wantsPlayback = false;
  bool _closed = false;
  Future<void>? _shutdown;
  int _volumeRevision = 0;

  Future<void> initialize() async {
    // 시스템 볼륨 연동은 유지하고 라디오 출력만 낮춰 작은 음량을 확보한다.
    await _player.setVolume(0.3);
    await _preferences.remove('volume');
    if (_closed) return;
    _volumeSubscription = _volumeBridge.systemVolumeChanges.listen(
      _applySystemVolume,
      onError: (Object _) => _disableVolumeControl(),
    );
    final revision = _volumeRevision;
    try {
      final state = await _volumeBridge.getSystemVolume();
      if (revision == _volumeRevision) _applySystemVolume(state);
    } catch (_) {
      if (revision == _volumeRevision) _disableVolumeControl();
    }
  }

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

  Future<void> play() async {
    if (_closed || _wantsPlayback) return;
    await select(channel);
  }

  Future<void> togglePlayback() => _wantsPlayback ? stop() : play();

  Future<void> stop() async {
    if (_closed) return;
    ++_request;
    _wantsPlayback = false;
    status = RadioStatus.stopped;
    notifyListeners();
    await _player.stop();
  }

  Future<void> setVolume(double value) async {
    if (_closed || !canControlVolume) return;
    final revision = ++_volumeRevision;
    volume = value.clamp(0.0, 1.0);
    notifyListeners();
    try {
      final state = await _volumeBridge.setSystemVolume(volume);
      if (revision == _volumeRevision) _applySystemVolume(state);
    } catch (_) {
      if (_closed || revision != _volumeRevision) return;
      try {
        final state = await _volumeBridge.getSystemVolume();
        if (revision == _volumeRevision) _applySystemVolume(state);
      } catch (_) {
        _disableVolumeControl();
      }
    }
  }

  void _applySystemVolume(SystemVolumeState state) {
    if (_closed) return;
    ++_volumeRevision;
    volume = state.muted ? 0 : state.volume;
    canControlVolume = state.available;
    notifyListeners();
  }

  void _disableVolumeControl() {
    if (_closed) return;
    ++_volumeRevision;
    canControlVolume = false;
    notifyListeners();
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
    await _volumeSubscription?.cancel();
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
