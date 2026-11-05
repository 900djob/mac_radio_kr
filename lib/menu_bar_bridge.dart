import 'package:flutter/services.dart';

import 'radio_channel.dart';

class SystemVolumeState {
  const SystemVolumeState({
    required this.volume,
    required this.muted,
    required this.available,
  });

  factory SystemVolumeState.fromMap(Map<dynamic, dynamic> data) =>
      SystemVolumeState(
        volume: ((data['volume'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
        muted: data['muted'] == true,
        available: data['available'] == true,
      );

  final double volume;
  final bool muted;
  final bool available;
}

class MenuBarBridge {
  static const _channel = MethodChannel('mac_radio_kr/menu_bar');
  static const _volumeEvents = EventChannel('mac_radio_kr/system_volume');

  Stream<SystemVolumeState> get systemVolumeChanges => _volumeEvents
      .receiveBroadcastStream()
      .map((event) => SystemVolumeState.fromMap(event as Map));

  Future<SystemVolumeState> getSystemVolume() async =>
      SystemVolumeState.fromMap(
        await _channel.invokeMapMethod<String, dynamic>('getSystemVolume') ??
            {},
      );

  Future<SystemVolumeState> setSystemVolume(double value) async =>
      SystemVolumeState.fromMap(
        await _channel.invokeMapMethod<String, dynamic>(
              'setSystemVolume',
              value,
            ) ??
            {},
      );

  Future<String?> showChannels(String selectedId) =>
      _channel.invokeMethod<String>('showChannelMenu', {
        'selectedId': selectedId,
        'channels': [
          for (final channel in RadioChannel.channels)
            {
              'id': channel.id,
              'name': channel.name,
              'station': channel.group,
              'region': channel.region.label,
            },
        ],
      });

  Future<String?> showActions() =>
      _channel.invokeMethod<String>('showActionsMenu');

  Future<void> updateStatus(String value) =>
      _channel.invokeMethod<void>('updateStatus', value);

  Future<void> updateNowPlaying(String title, {required bool isPlaying}) =>
      _channel.invokeMethod<void>('updateNowPlaying', {
        'title': title,
        'isPlaying': isPlaying,
      });

  void setMediaCommandHandler(Future<void> Function(String) handler) {
    _channel.setMethodCallHandler((call) {
      final command = switch (call.method) {
        'mediaPlay' => 'play',
        'mediaPause' => 'pause',
        'mediaStop' => 'stop',
        'mediaTogglePlayPause' => 'togglePlayPause',
        _ => null,
      };
      if (command == null) throw MissingPluginException(call.method);
      return handler(command);
    });
  }

  void clearMediaCommandHandler() => _channel.setMethodCallHandler(null);

  Future<void> quit() => _channel.invokeMethod<void>('quit');
}
