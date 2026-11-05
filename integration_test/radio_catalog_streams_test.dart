import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:mac_radio_kr/radio_channel.dart';
import 'package:mac_radio_kr/stream_url_resolver.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'all registered stream URLs respond with media data',
    (tester) async {
      final client = http.Client();
      final resolver = StreamUrlResolver(client: client);
      addTearDown(resolver.close);
      var next = 0;
      final failures = <String>[];

      Future<void> checkNext() async {
        while (true) {
          final index = next++;
          if (index >= RadioChannel.channels.length) return;
          final channel = RadioChannel.channels[index];
          var lastError = 'no response';
          for (var attempt = 0; attempt < 2; attempt++) {
            final abort = Completer<void>();
            var phase = 'resolve';
            try {
              final uri = await resolver.resolve(channel);
              phase = 'connect';
              final response = await client
                  .send(
                    http.AbortableRequest(
                      'GET',
                      uri,
                      abortTrigger: abort.future,
                    ),
                  )
                  .timeout(
                    const Duration(seconds: 15),
                    onTimeout: () {
                      abort.complete();
                      throw TimeoutException('Stream connection timed out');
                    },
                  );
              if (response.statusCode < 200 || response.statusCode >= 300) {
                throw http.ClientException('HTTP ${response.statusCode}', uri);
              }
              final firstData = Completer<void>();
              final subscription = response.stream.listen((chunk) {
                if (chunk.isNotEmpty && !firstData.isCompleted) {
                  firstData.complete();
                }
              });
              try {
                phase = 'data';
                await firstData.future.timeout(const Duration(seconds: 8));
              } finally {
                await subscription.cancel();
              }
              debugPrint('STREAM_CHECK ${channel.id}: ${response.statusCode}');
              break;
            } catch (error) {
              if (!abort.isCompleted) abort.complete();
              final detail = error is http.ClientException
                  ? error.message
                  : error.runtimeType.toString();
              lastError = '$phase $detail';
              if (attempt == 1) failures.add('${channel.id}: $lastError');
            }
          }
        }
      }

      await Future.wait(List.generate(4, (_) => checkNext()));
      expect(failures, isEmpty, reason: failures.take(20).join('\n'));
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
