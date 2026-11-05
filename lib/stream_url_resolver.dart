import 'dart:convert';

import 'package:http/http.dart' as http;

import 'radio_channel.dart';

class StreamUrlResolver {
  StreamUrlResolver({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const ebsFallback =
      'https://ebsonair.ebs.co.kr/fmradiofamilypc/familypc1m/playlist.m3u8';

  Future<Uri> resolve(RadioChannel channel) =>
      _resolve(channel).timeout(const Duration(seconds: 10));

  Future<Uri> _resolve(RadioChannel channel) async {
    switch (channel.source) {
      case StreamSource.kbs:
        final body = await _get(
          'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/${channel.endpoint}',
        );
        final data = jsonDecode(body) as Map<String, dynamic>;
        final items = data['channel_item'] as List<dynamic>?;
        if (items == null || items.isEmpty) {
          throw const FormatException('KBS stream is missing');
        }
        return _streamUri(items.first['service_url'] as String? ?? '');
      case StreamSource.text:
        return _streamUri(await _get(channel.endpoint));
      case StreamSource.direct:
        return _streamUri(channel.endpoint);
      case StreamSource.mbcDateCode:
        final nowInKorea = DateTime.now().toUtc().add(const Duration(hours: 9));
        final digits =
            '${nowInKorea.year.toString().substring(2)}'
            '${nowInKorea.month.toString().padLeft(2, '0')}'
            '${nowInKorea.day.toString().padLeft(2, '0')}';
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
        final code = digits.split('').map((digit) => dateCode[digit]!).join();
        return _streamUri('${channel.endpoint}$code/playlist.m3u8');
      case StreamSource.mbcBora:
        final body = await _get(channel.endpoint);
        final match = RegExp(r'''"BoraURL"\s*:\s*"([^"]+)"''').firstMatch(body);
        if (match == null) {
          throw const FormatException('MBC Bora stream is missing');
        }
        return _streamUri(match.group(1)!.replaceAll('&amp;', '&'));
      case StreamSource.afn:
        final response = await _get(
          'https://playerservices.streamtheworld.com/api/livestream?station=${channel.endpoint}&transports=http%2Chls&version=1.10',
        );
        final addresses = RegExp(
          r'<ip>(.*?)</ip>',
        ).allMatches(response).map((match) => match.group(1)!).toList();
        if (addresses.isEmpty) {
          throw const FormatException('AFN stream server is missing');
        }
        final server = addresses.last;
        return _streamUri('https://$server/${channel.endpoint}AAC.aac');
      case StreamSource.ebs:
        // EBS 온에어 페이지에서 당일 재생 주소를 가져온다.
        try {
          final html = await _get(channel.endpoint);
          final match = RegExp(
            r'''src:\s*['"](https://liveotu\.ebs\.co\.kr/[^'"]+)['"]''',
          ).firstMatch(html);
          if (match != null) {
            return _streamUri(match.group(1)!.replaceAll('&amp;', '&'));
          }
        } on http.ClientException {
          // 온에어 페이지를 읽을 수 없으면 기존 공식 HLS 주소를 시도한다.
        }
        return _streamUri(ebsFallback);
    }
  }

  Future<String> _get(String url) async {
    final response = await _client.get(
      Uri.parse(url),
      headers: {'User-Agent': 'mac_radio_kr/1.0'},
    );
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', Uri.parse(url));
    }
    return response.body;
  }

  Uri _streamUri(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !const {'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException('Invalid HTTP stream URL');
    }
    return uri;
  }

  void close() => _client.close();
}
