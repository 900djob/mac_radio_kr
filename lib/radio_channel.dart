enum StreamSource { kbs, text, direct, ebs }

class RadioChannel {
  const RadioChannel(
    this.id,
    this.name,
    this.station,
    this.source,
    this.endpoint,
  );

  final String id;
  final String name;
  final String station;
  final StreamSource source;
  final String endpoint;

  static const defaultId = 'mbc_fm4u';

  static const channels = [
    RadioChannel('kbs_1', 'KBS 1라디오', 'KBS', StreamSource.kbs, '21'),
    RadioChannel('kbs_2', 'KBS 2라디오', 'KBS', StreamSource.kbs, '22'),
    RadioChannel('kbs_3', 'KBS 3라디오', 'KBS', StreamSource.kbs, '23'),
    RadioChannel(
      'kbs_classic',
      'KBS Classic FM',
      'KBS',
      StreamSource.kbs,
      '24',
    ),
    RadioChannel('kbs_cool', 'KBS Cool FM', 'KBS', StreamSource.kbs, '25'),
    RadioChannel('kbs_hanminjok', 'KBS 한민족방송', 'KBS', StreamSource.kbs, '26'),
    RadioChannel(
      'mbc_standard',
      'MBC 표준FM',
      'MBC',
      StreamSource.text,
      'https://sminiplay.imbc.com/aacplay.ashx?agent=webapp&channel=sfm',
    ),
    RadioChannel(
      'mbc_fm4u',
      'MBC FM4U',
      'MBC',
      StreamSource.text,
      'https://sminiplay.imbc.com/aacplay.ashx?agent=webapp&channel=mfm',
    ),
    RadioChannel(
      'sbs_love',
      'SBS 러브FM',
      'SBS',
      StreamSource.text,
      'https://apis.sbs.co.kr/play-api/1.0/livestream/lovepc/lovefm?protocol=hls&ssl=Y',
    ),
    RadioChannel(
      'sbs_power',
      'SBS 파워FM',
      'SBS',
      StreamSource.text,
      'https://apis.sbs.co.kr/play-api/1.0/livestream/powerpc/powerfm?protocol=hls&ssl=Y',
    ),
    RadioChannel(
      'cbs_standard',
      'CBS 표준FM',
      'CBS',
      StreamSource.direct,
      'https://m-aac.cbs.co.kr/mweb_cbs981/_definst_/cbs981.stream/playlist.m3u8',
    ),
    RadioChannel(
      'cbs_music',
      'CBS 음악FM',
      'CBS',
      StreamSource.direct,
      'https://m-aac.cbs.co.kr/mweb_cbs939/_definst_/cbs939.stream/playlist.m3u8',
    ),
    RadioChannel(
      'ebs_fm',
      'EBS FM',
      'EBS',
      StreamSource.ebs,
      'https://www.ebs.co.kr/onair?channelCodeString=radio',
    ),
  ];

  static RadioChannel byId(String? id) => channels.firstWhere(
    (channel) => channel.id == id,
    orElse: () => channels.firstWhere((channel) => channel.id == defaultId),
  );
}
