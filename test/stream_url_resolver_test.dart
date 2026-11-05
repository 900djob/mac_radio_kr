import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mac_radio_kr/radio_channel.dart';
import 'package:mac_radio_kr/stream_url_resolver.dart';

void main() {
  test('KBS parses the current channel_item response', () async {
    final resolver = StreamUrlResolver(
      client: MockClient((request) async {
        expect(request.url.path, endsWith('/25'));
        return http.Response(
          '{"channel_item":[{"service_url":"https://example.com/live.m3u8"}]}',
          200,
        );
      }),
    );
    addTearDown(resolver.close);
    expect(
      await resolver.resolve(RadioChannel.byId('kbs_cool')),
      Uri.parse('https://example.com/live.m3u8'),
    );
  });

  test('text URLs are trimmed and refreshed for every play', () async {
    var calls = 0;
    final resolver = StreamUrlResolver(
      client: MockClient((_) async {
        calls++;
        return http.Response(
          '  https://example.com/live.m3u8?token=$calls\r\n',
          200,
        );
      }),
    );
    addTearDown(resolver.close);
    final channel = RadioChannel.byId('mbc_fm4u');
    expect((await resolver.resolve(channel)).query, 'token=1');
    expect((await resolver.resolve(channel)).query, 'token=2');
  });

  test('EBS extracts the onair URL and uses the official fallback', () async {
    var found = true;
    final resolver = StreamUrlResolver(
      client: MockClient(
        (_) async => http.Response(
          found
              ? "src: 'https://liveotu.ebs.co.kr/radio/live.m3u8?a=1&amp;b=2'"
              : '<html></html>',
          200,
        ),
      ),
    );
    addTearDown(resolver.close);
    final channel = RadioChannel.byId('ebs_fm');
    expect((await resolver.resolve(channel)).query, 'a=1&b=2');
    found = false;
    expect(
      (await resolver.resolve(channel)).toString(),
      StreamUrlResolver.ebsFallback,
    );
  });

  test(
    'invalid responses and HTTP errors fail without passing HTML to the player',
    () async {
      final resolver = StreamUrlResolver(
        client: MockClient(
          (_) async => http.Response('<html>unavailable</html>', 200),
        ),
      );
      addTearDown(resolver.close);
      await expectLater(
        resolver.resolve(RadioChannel.byId('mbc_fm4u')),
        throwsFormatException,
      );
      final unavailable = StreamUrlResolver(
        client: MockClient((_) async => http.Response('', 503)),
      );
      addTearDown(unavailable.close);
      await expectLater(
        unavailable.resolve(RadioChannel.byId('sbs_power')),
        throwsA(isA<http.ClientException>()),
      );
    },
  );

  testWidgets('URL lookup times out after ten seconds', (tester) async {
    final resolver = StreamUrlResolver(
      client: MockClient((_) => Completer<http.Response>().future),
    );
    addTearDown(resolver.close);
    final future = resolver.resolve(RadioChannel.byId('mbc_fm4u'));
    final expectation = expectLater(future, throwsA(isA<TimeoutException>()));
    await tester.pump(const Duration(seconds: 11));
    await expectation;
  });
}
