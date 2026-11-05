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

  test('KBS regional code is resolved through the official API', () async {
    final resolver = StreamUrlResolver(
      client: MockClient((request) async {
        expect(request.url.path, endsWith('/10_21'));
        return http.Response(
          '{"channel_item":[{"service_url":"https://example.com/busan.m3u8"}]}',
          200,
        );
      }),
    );
    addTearDown(resolver.close);
    expect(
      await resolver.resolve(RadioChannel.byId('kbs_busan_1')),
      Uri.parse('https://example.com/busan.m3u8'),
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

  test('MBC date-coded regional stream uses Korea local date', () async {
    final resolver = StreamUrlResolver();
    addTearDown(resolver.close);
    final localDate = DateTime.now().toUtc().add(const Duration(hours: 9));
    final digits =
        '${localDate.year.toString().substring(2)}'
        '${localDate.month.toString().padLeft(2, '0')}'
        '${localDate.day.toString().padLeft(2, '0')}';
    const dateCode = {
      '0': 'q',
      '1': 'h',
      '2': 's',
      '3': 'a',
      '4': 'g',
      '5': 'b',
      '6': 'j',
      '7': 'c',
      '8': 'p',
      '9': 'd',
    };
    final expected = digits.split('').map((digit) => dateCode[digit]!).join();
    expect(
      (await resolver.resolve(RadioChannel.byId('mbc_busan_sfm'))).path,
      endsWith('$expected/playlist.m3u8'),
    );
  });

  test('MBC Bora and AFN extract their dynamic stream addresses', () async {
    final resolver = StreamUrlResolver(
      client: MockClient((request) async {
        if (request.url.path.endsWith('boraplay.ashx')) {
          return http.Response(
            '__boraplay({"BoraURL":"https://example.com/bora.m3u8"});',
            200,
          );
        }
        return http.Response(
          '<servers><ip>14613.live.streamtheworld.com</ip></servers>',
          200,
        );
      }),
    );
    addTearDown(resolver.close);
    const boraChannel = RadioChannel(
      id: 'mbc_bora_test',
      name: 'MBC 보이는 라디오',
      station: 'MBC',
      region: RadioRegion.national,
      source: StreamSource.mbcBora,
      endpoint:
          'https://sminiplay.imbc.com/boraplay.ashx?agent=webapp&callback=__boraplay',
    );
    expect(
      await resolver.resolve(boraChannel),
      Uri.parse('https://example.com/bora.m3u8'),
    );
    expect(
      await resolver.resolve(RadioChannel.byId('afn_humphreys')),
      Uri.parse('https://14613.live.streamtheworld.com/AFNP_OSNAAC.aac'),
    );
  });

  test('HTTP streams are accepted only with a valid network host', () async {
    final resolver = StreamUrlResolver();
    addTearDown(resolver.close);
    expect(
      await resolver.resolve(RadioChannel.byId('community_gwanak')),
      Uri.parse('http://icecast.radios.kr:8000/gwanakfm'),
    );
    await expectLater(
      resolver.resolve(
        const RadioChannel(
          id: 'bad',
          name: 'bad',
          station: 'bad',
          region: RadioRegion.national,
          source: StreamSource.direct,
          endpoint: 'file:///tmp/bad.m3u8',
        ),
      ),
      throwsFormatException,
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
