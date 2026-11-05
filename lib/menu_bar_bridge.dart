import 'package:flutter/services.dart';

import 'radio_channel.dart';

class MenuBarBridge {
  static const _channel = MethodChannel('mac_radio_kr/menu_bar');

  Future<String?> showChannels(String selectedId) =>
      _channel.invokeMethod<String>('showChannelMenu', {
        'selectedId': selectedId,
        'channels': [
          for (final channel in RadioChannel.channels)
            {
              'id': channel.id,
              'name': channel.name,
              'station': channel.station,
            },
        ],
      });

  Future<String?> showActions() =>
      _channel.invokeMethod<String>('showActionsMenu');

  Future<void> updateStatus(String value) =>
      _channel.invokeMethod<void>('updateStatus', value);

  Future<void> quit() => _channel.invokeMethod<void>('quit');
}
