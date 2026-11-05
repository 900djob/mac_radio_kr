enum StreamSource { kbs, text, direct, ebs, mbcDateCode, mbcBora, afn }

enum RadioRegion {
  national('전국'),
  capital('수도권'),
  gyeonggi('경기'),
  busan('부산'),
  ulsan('울산'),
  gyeongnam('경남'),
  daegu('대구'),
  gyeongbuk('경북'),
  gwangju('광주'),
  jeonnam('전남'),
  jeonbuk('전북'),
  daejeon('대전'),
  sejong('세종'),
  chungnam('충남'),
  chungbuk('충북'),
  gangwon('강원'),
  jeju('제주');

  const RadioRegion(this.label);
  final String label;
}

class RadioChannel {
  const RadioChannel({
    required this.id,
    required this.name,
    required this.station,
    String? group,
    required this.region,
    required this.source,
    required this.endpoint,
  }) : group = group ?? station;

  final String id;
  final String name;
  final String station;
  final String group;
  final RadioRegion region;
  final StreamSource source;
  final String endpoint;

  static const defaultId = 'mbc_fm4u';

  static final channels = List<RadioChannel>.unmodifiable([
    for (final region in RadioRegion.values)
      ..._allChannels.where((channel) => channel.region == region),
  ]);

  static final _allChannels = <RadioChannel>[
    // 전국 채널과 기존 수도권 기본 채널
    const RadioChannel(
      id: 'kbs_1',
      name: 'KBS 1라디오',
      station: 'KBS',
      region: RadioRegion.national,
      source: StreamSource.kbs,
      endpoint: '21',
    ),
    const RadioChannel(
      id: 'kbs_2',
      name: 'KBS 2라디오',
      station: 'KBS',
      region: RadioRegion.national,
      source: StreamSource.kbs,
      endpoint: '22',
    ),
    const RadioChannel(
      id: 'kbs_3',
      name: 'KBS 3라디오',
      station: 'KBS',
      region: RadioRegion.national,
      source: StreamSource.kbs,
      endpoint: '23',
    ),
    const RadioChannel(
      id: 'kbs_classic',
      name: 'KBS Classic FM',
      station: 'KBS',
      region: RadioRegion.national,
      source: StreamSource.kbs,
      endpoint: '24',
    ),
    const RadioChannel(
      id: 'kbs_cool',
      name: 'KBS Cool FM',
      station: 'KBS',
      region: RadioRegion.national,
      source: StreamSource.kbs,
      endpoint: '25',
    ),
    const RadioChannel(
      id: 'kbs_hanminjok',
      name: 'KBS 한민족방송',
      station: 'KBS',
      region: RadioRegion.national,
      source: StreamSource.kbs,
      endpoint: '26',
    ),
    const RadioChannel(
      id: 'mbc_standard',
      name: 'MBC 표준FM',
      station: 'MBC',
      region: RadioRegion.national,
      source: StreamSource.text,
      endpoint:
          'https://sminiplay.imbc.com/aacplay.ashx?agent=webapp&channel=sfm',
    ),
    const RadioChannel(
      id: 'mbc_fm4u',
      name: 'MBC FM4U',
      station: 'MBC',
      region: RadioRegion.national,
      source: StreamSource.text,
      endpoint:
          'https://sminiplay.imbc.com/aacplay.ashx?agent=webapp&channel=mfm',
    ),
    const RadioChannel(
      id: 'sbs_love',
      name: 'SBS 러브FM',
      station: 'SBS',
      region: RadioRegion.national,
      source: StreamSource.text,
      endpoint:
          'https://apis.sbs.co.kr/play-api/1.0/livestream/lovepc/lovefm?protocol=hls&ssl=Y',
    ),
    const RadioChannel(
      id: 'sbs_power',
      name: 'SBS 파워FM',
      station: 'SBS',
      region: RadioRegion.national,
      source: StreamSource.text,
      endpoint:
          'https://apis.sbs.co.kr/play-api/1.0/livestream/powerpc/powerfm?protocol=hls&ssl=Y',
    ),
    const RadioChannel(
      id: 'cbs_standard',
      name: 'CBS 표준FM',
      station: 'CBS',
      region: RadioRegion.national,
      source: StreamSource.direct,
      endpoint:
          'https://m-aac.cbs.co.kr/mweb_cbs981/_definst_/cbs981.stream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'cbs_music',
      name: 'CBS 음악FM',
      station: 'CBS',
      region: RadioRegion.national,
      source: StreamSource.direct,
      endpoint:
          'https://m-aac.cbs.co.kr/mweb_cbs939/_definst_/cbs939.stream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'ebs_fm',
      name: 'EBS FM',
      station: 'EBS',
      region: RadioRegion.national,
      source: StreamSource.ebs,
      endpoint: 'https://www.ebs.co.kr/onair?channelCodeString=radio',
    ),
    const RadioChannel(
      id: 'mbc_all_that_music',
      name: 'MBC mini 올댓뮤직',
      station: 'MBC',
      region: RadioRegion.national,
      source: StreamSource.text,
      endpoint:
          'https://sminiplay.imbc.com/aacplay.ashx?agent=webapp&channel=chm',
    ),
    const RadioChannel(
      id: 'sbs_gorilla',
      name: 'SBS 고릴라디오M',
      station: 'SBS',
      region: RadioRegion.national,
      source: StreamSource.text,
      endpoint:
          'https://apis.sbs.co.kr/play-api/1.0/livestream/sbsdmbpc/sbsdmb?protocol=hls&ssl=Y',
    ),
    const RadioChannel(
      id: 'ebs_bandi',
      name: 'EBS 반디 외국어 전문',
      station: 'EBS',
      region: RadioRegion.national,
      source: StreamSource.direct,
      endpoint: 'https://ebsonair.ebs.co.kr/cloud1/iradio/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'cbs_joy4u',
      name: 'CBS JOY4U',
      station: 'CBS',
      region: RadioRegion.national,
      source: StreamSource.direct,
      endpoint:
          'https://m-aac.cbs.co.kr/mweb_cbscmc/_definst_/cbscmc.stream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'tbs_fm',
      name: 'TBS FM',
      station: 'TBS',
      region: RadioRegion.capital,
      source: StreamSource.direct,
      endpoint:
          'https://cdnfm.tbs.seoul.kr/tbs/_definst_/tbs_fm_web_360.smil/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'tbs_efm',
      name: 'TBS eFM',
      station: 'TBS',
      region: RadioRegion.capital,
      source: StreamSource.direct,
      endpoint:
          'https://cdnefm.tbs.seoul.kr/tbs/_definst_/tbs_efm_web_360.smil/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'obs_radio',
      name: 'OBS 라디오',
      station: 'OBS',
      region: RadioRegion.capital,
      source: StreamSource.direct,
      endpoint:
          'https://vod3.obs.co.kr:444/live/obsstream1/radio.stream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'ifm_radio',
      name: 'iFM 경인방송',
      station: 'iFM',
      region: RadioRegion.capital,
      source: StreamSource.direct,
      endpoint: 'https://stream.ifm.kr/live/aod1/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'ytn_radio',
      name: 'YTN 라디오',
      station: 'YTN',
      region: RadioRegion.national,
      source: StreamSource.direct,
      endpoint:
          'https://radiolive.ytn.co.kr/radio/_definst_/20211118_fmlive/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'bbs_seoul',
      name: 'BBS 서울불교방송',
      station: 'BBS',
      region: RadioRegion.capital,
      source: StreamSource.direct,
      endpoint:
          'https://bbslive.clouducs.com/bbsradio-mlive/radio.stream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'febc_seoul',
      name: 'FEBC 서울극동방송',
      station: 'FEBC',
      region: RadioRegion.capital,
      source: StreamSource.direct,
      endpoint: 'http://mlive2.febc.net:1935/live/seoulfm/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'cpbc_seoul',
      name: 'CPBC 서울가톨릭평화방송',
      station: 'CPBC',
      region: RadioRegion.capital,
      source: StreamSource.direct,
      endpoint:
          'http://onair1.cpbc.co.kr:1935/live/_definst_/Instreamer.stream_aac/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'wbs_seoul',
      name: 'WBS 서울원음방송',
      station: 'WBS',
      region: RadioRegion.capital,
      source: StreamSource.direct,
      endpoint: 'https://wbsradio.kr/wbs-seoul',
    ),
    const RadioChannel(
      id: 'tbn_capital',
      name: 'TBN 경인교통방송',
      station: 'TBN',
      region: RadioRegion.capital,
      source: StreamSource.direct,
      endpoint: 'https://www.tbn.it.kr/gyeongin/myStream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'kugak_seoul',
      name: '국악방송',
      station: '국악',
      region: RadioRegion.national,
      source: StreamSource.direct,
      endpoint:
          'https://mgugaklive.nowcdn.co.kr/gugakradio/gugakradio.stream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'national_defense',
      name: '국방FM',
      station: '국방',
      region: RadioRegion.national,
      source: StreamSource.direct,
      endpoint:
          'https://mediaworks.dema.mil.kr/live_edge/audio.sdp/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'arirang_radio',
      name: 'Arirang Radio',
      station: 'Arirang',
      region: RadioRegion.national,
      source: StreamSource.direct,
      endpoint:
          'https://amdlive-ch03-ctnd-com.akamaized.net/arirang_3ch/smil:arirang_3ch.smil/playlist.m3u8',
    ),

    // KBS 지역국: 1라디오, 2라디오, 음악FM을 지역 API 코드로 조회한다.
    ..._regionalKbs(),

    // MBC 지역 표준FM 및 FM4U
    ..._regionalMbc(),

    // SBS 지역 민영방송
    const RadioChannel(
      id: 'sbs_knn_love',
      name: 'KNN 러브FM',
      station: 'KNN',
      region: RadioRegion.busan,
      source: StreamSource.direct,
      endpoint:
          'https://stream1.knn.co.kr/hls/b3y26uu6471k8tes9w7h_lfm/index.m3u8',
    ),
    const RadioChannel(
      id: 'sbs_knn_power',
      name: 'KNN 파워FM',
      station: 'KNN',
      region: RadioRegion.busan,
      source: StreamSource.direct,
      endpoint:
          'https://stream1.knn.co.kr/hls/lb9ezl87d37uu0vy65bb_pfm/index.m3u8',
    ),
    const RadioChannel(
      id: 'sbs_ubc_green',
      name: 'UBC 그린FM',
      station: 'UBC',
      region: RadioRegion.ulsan,
      source: StreamSource.direct,
      endpoint: 'https://stream.ubc.co.kr/hls/ubcfmstream/index.m3u8',
    ),
    const RadioChannel(
      id: 'sbs_tbc_dream',
      name: 'TBC 드림FM',
      station: 'TBC',
      region: RadioRegion.daegu,
      source: StreamSource.direct,
      endpoint: 'http://203.251.91.122:1935/on-air-Backup/fm/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'sbs_kbc_myfm',
      name: 'KBC 마이FM',
      station: 'KBC',
      region: RadioRegion.gwangju,
      source: StreamSource.direct,
      endpoint: 'https://vod.ikbc.co.kr/KBCFM/kbcra_aac/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'sbs_jtv_magic',
      name: 'JTV 매직FM',
      station: 'JTV',
      region: RadioRegion.jeonbuk,
      source: StreamSource.direct,
      endpoint: 'http://61.85.197.53:1935/jtv_radio/myStream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'sbs_tjb_power',
      name: 'TJB 파워FM',
      station: 'TJB',
      region: RadioRegion.daejeon,
      source: StreamSource.direct,
      endpoint:
          'https://vod.tjb.co.kr/radiolive/_definst_/radio_64k/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'sbs_g1_fresh',
      name: 'G1 프레쉬FM',
      station: 'G1',
      region: RadioRegion.gangwon,
      source: StreamSource.direct,
      endpoint: 'http://61.82.49.4:1935/fm/_definst_/myStream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'sbs_jibs_new_power',
      name: 'JIBS 뉴파워FM',
      station: 'JIBS',
      region: RadioRegion.jeju,
      source: StreamSource.direct,
      endpoint: 'http://123.140.197.22/stream/2/play.m3u8',
    ),

    // CBS 지역 표준FM 및 음악FM
    ..._regionalCbs(),

    // 교통·종교·공영 지역 방송
    ..._regionalStations(),

    // 공동체 라디오
    ..._communityStations(),
  ];

  static const _kbsRegions =
      <({RadioRegion region, String slug, String name, String prefix})>[
        (
          region: RadioRegion.busan,
          slug: 'busan',
          name: 'KBS부산',
          prefix: '10_',
        ),
        (
          region: RadioRegion.ulsan,
          slug: 'ulsan',
          name: 'KBS울산',
          prefix: '11_',
        ),
        (
          region: RadioRegion.gyeongnam,
          slug: 'changwon',
          name: 'KBS창원',
          prefix: '20_',
        ),
        (
          region: RadioRegion.gyeongnam,
          slug: 'jinju',
          name: 'KBS진주',
          prefix: '21_',
        ),
        (
          region: RadioRegion.daegu,
          slug: 'daegu',
          name: 'KBS대구',
          prefix: '30_',
        ),
        (
          region: RadioRegion.gyeongbuk,
          slug: 'andong',
          name: 'KBS안동',
          prefix: '31_',
        ),
        (
          region: RadioRegion.gyeongbuk,
          slug: 'pohang',
          name: 'KBS포항',
          prefix: '32_',
        ),
        (
          region: RadioRegion.gwangju,
          slug: 'gwangju',
          name: 'KBS광주',
          prefix: '40_',
        ),
        (
          region: RadioRegion.jeonnam,
          slug: 'mokpo',
          name: 'KBS목포',
          prefix: '41_',
        ),
        (
          region: RadioRegion.jeonnam,
          slug: 'suncheon',
          name: 'KBS순천',
          prefix: '43_',
        ),
        (
          region: RadioRegion.jeonbuk,
          slug: 'jeonju',
          name: 'KBS전주',
          prefix: '50_',
        ),
        (
          region: RadioRegion.daejeon,
          slug: 'daejeon',
          name: 'KBS대전',
          prefix: '60_',
        ),
        (
          region: RadioRegion.chungbuk,
          slug: 'cheongju',
          name: 'KBS청주',
          prefix: '70_',
        ),
        (
          region: RadioRegion.chungbuk,
          slug: 'chungju',
          name: 'KBS충주',
          prefix: '71_',
        ),
        (
          region: RadioRegion.gangwon,
          slug: 'chuncheon',
          name: 'KBS춘천',
          prefix: '80_',
        ),
        (
          region: RadioRegion.gangwon,
          slug: 'gangneung',
          name: 'KBS강릉',
          prefix: '81_',
        ),
        (
          region: RadioRegion.gangwon,
          slug: 'wonju',
          name: 'KBS원주',
          prefix: '82_',
        ),
        (region: RadioRegion.jeju, slug: 'jeju', name: 'KBS제주', prefix: '90_'),
      ];

  static const _kbsServices = <({String id, String name, String code})>[
    (id: '1', name: '1라디오', code: '21'),
    (id: '2', name: '2라디오', code: '22'),
    (id: 'music', name: '음악FM', code: '24'),
  ];

  // KBS 지역 API에서 실제 스트림이 제공되는 조합만 등록한다.
  static const _kbsAvailableServices = <String, Set<String>>{
    'busan': {'1', '2', 'music'},
    'ulsan': {'1'},
    'changwon': {'1', '2', 'music'},
    'jinju': {'1'},
    'daegu': {'1', '2', 'music'},
    'andong': {'1'},
    'pohang': {'1'},
    'gwangju': {'1', '2', 'music'},
    'mokpo': {'1', 'music'},
    'suncheon': {'1'},
    'jeonju': {'1', '2', 'music'},
    'daejeon': {'1', '2', 'music'},
    'cheongju': {'1', '2', 'music'},
    'chungju': {'1', 'music'},
    'chuncheon': {'1', '2', 'music'},
    'gangneung': {'1', 'music'},
    'wonju': {'1', 'music'},
    'jeju': {'1', '2', 'music'},
  };

  static List<RadioChannel> _regionalKbs() => [
    for (final city in _kbsRegions)
      for (final service in _kbsServices.where(
        (service) => _kbsAvailableServices[city.slug]!.contains(service.id),
      ))
        RadioChannel(
          id: 'kbs_${city.slug}_${service.id}',
          name: '${city.name} ${service.name}',
          station: 'KBS',
          region: city.region,
          source: StreamSource.kbs,
          endpoint: '${city.prefix}${service.code}',
        ),
  ];

  static const _mbcRegions =
      <
        ({
          RadioRegion region,
          String slug,
          String city,
          String standard,
          String fm4u,
        })
      >[
        (
          region: RadioRegion.busan,
          slug: 'busan',
          city: '부산',
          standard: 'https://brook.bsmbc.com/live/BusanMBC_AM_onairstream.',
          fm4u: 'https://brook.bsmbc.com/live/BusanMBC_FM_onairstream.',
        ),
        (
          region: RadioRegion.ulsan,
          slug: 'ulsan',
          city: '울산',
          standard:
              'https://5ddfd163bd00d.streamlock.net/STDFM/STDFM/playlist.m3u8',
          fm4u: 'https://5ddfd163bd00d.streamlock.net/FM4U/FM4U/playlist.m3u8',
        ),
        (
          region: RadioRegion.gyeongnam,
          slug: 'changwon',
          city: '경남',
          standard: 'https://wowza.mbcgn.kr/MBCFM/TV2.stream/playlist.m3u8',
          fm4u: 'https://wowza.mbcgn.kr/MBCFM4U/TV3.stream/playlist.m3u8',
        ),
        (
          region: RadioRegion.daegu,
          slug: 'daegu',
          city: '대구',
          standard:
              'https://5ee1ec6f32118.streamlock.net/amradio/am/playlist.m3u8',
          fm4u: 'https://5ee1ec6f32118.streamlock.net/fmradio/fm/playlist.m3u8',
        ),
        (
          region: RadioRegion.gyeongbuk,
          slug: 'andong',
          city: '안동',
          standard: 'https://live.andongmbc.co.kr/live/amlive/playlist.m3u8',
          fm4u: 'https://live.andongmbc.co.kr/live/fmlive/playlist.m3u8',
        ),
        (
          region: RadioRegion.gyeongbuk,
          slug: 'pohang',
          city: '포항',
          standard:
              'http://stream.yubinet.com:1935/live/_definst_/Radio_Am/playlist.m3u8',
          fm4u:
              'http://stream.yubinet.com:1935/live/_definst_/Radio_Fm/playlist.m3u8',
        ),
        (
          region: RadioRegion.gwangju,
          slug: 'gwangju',
          city: '광주',
          standard:
              'https://media.kjmbc.co.kr/hls/amlive/GWANGJU-MBC-AM/playlist.m3u8',
          fm4u:
              'https://media.kjmbc.co.kr/hls/fmlive/GWANGJU-MBC-FM/playlist.m3u8',
        ),
        (
          region: RadioRegion.jeonnam,
          slug: 'mokpo',
          city: '목포',
          standard: 'https://vod.mpmbc.co.kr/live/encoder-am/playlist.m3u8',
          fm4u: 'https://vod.mpmbc.co.kr/live/encoder-fm/playlist.m3u8',
        ),
        (
          region: RadioRegion.jeonnam,
          slug: 'yeosu',
          city: '여수',
          standard:
              'https://5c3639aa99149.streamlock.net/표준FM/표준FM/playlist.m3u8',
          fm4u: 'https://5c3639aa99149.streamlock.net/FM4U/FM4U/playlist.m3u8',
        ),
        (
          region: RadioRegion.jeonbuk,
          slug: 'jeonju',
          city: '전주',
          standard: 'https://live.jmbc.co.kr/live/am_live.m3u8',
          fm4u: 'https://live.jmbc.co.kr/live/fm_live.m3u8',
        ),
        (
          region: RadioRegion.daejeon,
          slug: 'daejeon',
          city: '대전',
          standard:
              'https://ns1.tjmbc.co.kr/live_am/live_am.stream/playlist.m3u8',
          fm4u: 'https://ns1.tjmbc.co.kr/live_fm/live_fm.stream/playlist.m3u8',
        ),
        (
          region: RadioRegion.chungbuk,
          slug: 'cheongju',
          city: '충북',
          standard:
              'https://mbccbp.coreit.co.kr/radio_stfm/myStream.sdp/playlist.m3u8',
          fm4u:
              'https://mbccbp.coreit.co.kr/radio_fm/myStream.sdp/playlist.m3u8',
        ),
        (
          region: RadioRegion.gangwon,
          slug: 'chuncheon',
          city: '춘천',
          standard: 'https://stream.chmbc.co.kr/radio1/fm1_aac/playlist.m3u8',
          fm4u: 'https://stream.chmbc.co.kr/live_radio2/fm1/playlist.m3u8',
        ),
        (
          region: RadioRegion.gangwon,
          slug: 'wonju',
          city: '원주',
          standard: 'http://live.wjmbc.co.kr:1935/fm2/fm2/playlist.m3u8',
          fm4u: 'http://live.wjmbc.co.kr:1935/fm989/fm989/playlist.m3u8',
        ),
        (
          region: RadioRegion.gangwon,
          slug: 'gangwon_yeongdong',
          city: '강원영동',
          standard: 'http://123.254.72.24:1935/amlive/livestream/playlist.m3u8',
          fm4u: 'http://123.254.72.24:1935/fmlive/livestream/playlist.m3u8',
        ),
        (
          region: RadioRegion.jeju,
          slug: 'jeju',
          city: '제주',
          standard: 'https://onairfm.jejumbc.com/hls/onairfmjejumbc/index.m3u8',
          fm4u:
              'https://onairsfm.jejumbc.com/hls/onairsfmjejumbc/1_2/index.m3u8',
        ),
      ];

  static List<RadioChannel> _regionalMbc() => [
    for (final city in _mbcRegions)
      for (final service
          in <({String id, String name, String endpoint, StreamSource source})>[
            (
              id: 'sfm',
              name: '표준FM',
              endpoint: city.standard,
              source: city.slug == 'busan'
                  ? StreamSource.mbcDateCode
                  : StreamSource.direct,
            ),
            (
              id: 'fm4u',
              name: 'FM4U',
              endpoint: city.fm4u,
              source: city.slug == 'busan'
                  ? StreamSource.mbcDateCode
                  : StreamSource.direct,
            ),
          ].where((service) => !(city.slug == 'wonju' && service.id == 'sfm')))
        RadioChannel(
          id: 'mbc_${city.slug}_${service.id}',
          name: '${city.city}MBC ${service.name}',
          station: 'MBC',
          region: city.region,
          source: service.source,
          endpoint: service.endpoint,
        ),
  ];

  static List<RadioChannel> _regionalCbs() => [
    const RadioChannel(
      id: 'cbs_busan_sfm',
      name: '부산CBS 표준FM',
      station: 'CBS',
      region: RadioRegion.busan,
      source: StreamSource.direct,
      endpoint:
          'https://m-aac.cbs.co.kr/busan939/_definst_/busan939.stream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'cbs_ulsan_sfm',
      name: '울산CBS 표준FM',
      station: 'CBS',
      region: RadioRegion.ulsan,
      source: StreamSource.direct,
      endpoint:
          'https://m-aac.cbs.co.kr/ulsan/_definst_/ulsan.stream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'cbs_gyeongnam_sfm',
      name: '경남CBS 표준FM',
      station: 'CBS',
      region: RadioRegion.gyeongnam,
      source: StreamSource.direct,
      endpoint:
          'https://m-aac.cbs.co.kr/gyeongnam/_definst_/gyeongnam.stream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'cbs_daegu_sfm',
      name: '대구CBS 표준FM',
      station: 'CBS',
      region: RadioRegion.daegu,
      source: StreamSource.direct,
      endpoint:
          'https://m-aac.cbs.co.kr/daegu/_definst_/daegu.stream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'cbs_pohang_sfm',
      name: '포항CBS 표준FM',
      station: 'CBS',
      region: RadioRegion.gyeongbuk,
      source: StreamSource.direct,
      endpoint:
          'https://m-aac.cbs.co.kr/pohang/_definst_/pohang.stream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'cbs_gwangju_sfm',
      name: '광주CBS 표준FM',
      station: 'CBS',
      region: RadioRegion.gwangju,
      source: StreamSource.direct,
      endpoint:
          'https://m-aac.cbs.co.kr/gwangju/_definst_/gwangju.stream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'cbs_jeonnam_sfm',
      name: '전남CBS 표준FM',
      station: 'CBS',
      region: RadioRegion.jeonnam,
      source: StreamSource.direct,
      endpoint:
          'https://m-aac.cbs.co.kr/jeonnam/_definst_/jeonnam.stream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'cbs_jeonbuk_sfm',
      name: '전북CBS 표준FM',
      station: 'CBS',
      region: RadioRegion.jeonbuk,
      source: StreamSource.direct,
      endpoint:
          'https://m-aac.cbs.co.kr/jeonbuk/_definst_/jeonbuk.stream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'cbs_daejeon_sfm',
      name: '대전CBS 표준FM',
      station: 'CBS',
      region: RadioRegion.daejeon,
      source: StreamSource.direct,
      endpoint:
          'https://m-aac.cbs.co.kr/daejeon/_definst_/daejeon.stream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'cbs_chungbuk_sfm',
      name: '청주CBS 표준FM',
      station: 'CBS',
      region: RadioRegion.chungbuk,
      source: StreamSource.direct,
      endpoint:
          'https://m-aac.cbs.co.kr/cheongju/_definst_/cheongju.stream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'cbs_gangwon_sfm',
      name: '춘천CBS 표준FM',
      station: 'CBS',
      region: RadioRegion.gangwon,
      source: StreamSource.direct,
      endpoint:
          'https://m-aac.cbs.co.kr/chuncheon/_definst_/chuncheon.stream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'cbs_gangwon_yeongdong_sfm',
      name: '강원영동CBS 표준FM',
      station: 'CBS',
      region: RadioRegion.gangwon,
      source: StreamSource.direct,
      endpoint:
          'https://m-aac.cbs.co.kr/youngdong/_definst_/youngdong.stream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'cbs_jeju_sfm',
      name: '제주CBS 표준FM',
      station: 'CBS',
      region: RadioRegion.jeju,
      source: StreamSource.direct,
      endpoint:
          'https://m-aac.cbs.co.kr/jeju/_definst_/jeju.stream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'cbs_busan_mfm',
      name: '부산CBS 음악FM',
      station: 'CBS',
      region: RadioRegion.busan,
      source: StreamSource.direct,
      endpoint:
          'https://m-aac.cbs.co.kr/busan981/_definst_/busan981.stream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'cbs_daegu_mfm',
      name: '대구CBS 음악FM',
      station: 'CBS',
      region: RadioRegion.daegu,
      source: StreamSource.direct,
      endpoint:
          'https://m-aac.cbs.co.kr/daegu939/_definst_/daegu939.stream/playlist.m3u8',
    ),
    const RadioChannel(
      id: 'cbs_gwangju_mfm',
      name: '광주CBS 음악FM',
      station: 'CBS',
      region: RadioRegion.gwangju,
      source: StreamSource.direct,
      endpoint:
          'https://m-aac.cbs.co.kr/gwangju939/_definst_/gwangju939.stream/playlist.m3u8',
    ),
  ];

  static List<RadioChannel> _regionalStations() => const [
    RadioChannel(
      id: 'tbn_busan',
      name: 'TBN 부산교통방송',
      station: 'TBN',
      region: RadioRegion.busan,
      source: StreamSource.direct,
      endpoint: 'https://www.tbn.it.kr/busan/myStream/playlist.m3u8',
    ),
    RadioChannel(
      id: 'tbn_ulsan',
      name: 'TBN 울산교통방송',
      station: 'TBN',
      region: RadioRegion.ulsan,
      source: StreamSource.direct,
      endpoint: 'https://www.tbn.it.kr/ulsan/myStream/playlist.m3u8',
    ),
    RadioChannel(
      id: 'tbn_gyeongnam',
      name: 'TBN 경남교통방송',
      station: 'TBN',
      region: RadioRegion.gyeongnam,
      source: StreamSource.direct,
      endpoint: 'https://www.tbn.it.kr/gyeongnam/myStream/playlist.m3u8',
    ),
    RadioChannel(
      id: 'tbn_daegu',
      name: 'TBN 대구교통방송',
      station: 'TBN',
      region: RadioRegion.daegu,
      source: StreamSource.direct,
      endpoint: 'https://www.tbn.it.kr/daegu/myStream/playlist.m3u8',
    ),
    RadioChannel(
      id: 'tbn_gyeongbuk',
      name: 'TBN 경북교통방송',
      station: 'TBN',
      region: RadioRegion.gyeongbuk,
      source: StreamSource.direct,
      endpoint: 'https://www.tbn.it.kr/kyungbuk/myStream/playlist.m3u8',
    ),
    RadioChannel(
      id: 'tbn_gwangju',
      name: 'TBN 광주교통방송',
      station: 'TBN',
      region: RadioRegion.gwangju,
      source: StreamSource.direct,
      endpoint: 'https://www.tbn.it.kr/gwangju/myStream/playlist.m3u8',
    ),
    RadioChannel(
      id: 'tbn_jeonbuk',
      name: 'TBN 전북교통방송',
      station: 'TBN',
      region: RadioRegion.jeonbuk,
      source: StreamSource.direct,
      endpoint: 'https://www.tbn.it.kr/jeonbuk/myStream/playlist.m3u8',
    ),
    RadioChannel(
      id: 'tbn_daejeon',
      name: 'TBN 대전교통방송',
      station: 'TBN',
      region: RadioRegion.daejeon,
      source: StreamSource.direct,
      endpoint: 'https://www.tbn.it.kr/daejeon/myStream/playlist.m3u8',
    ),
    RadioChannel(
      id: 'tbn_chungbuk',
      name: 'TBN 충북교통방송',
      station: 'TBN',
      region: RadioRegion.chungbuk,
      source: StreamSource.direct,
      endpoint: 'https://www.tbn.it.kr/chungbuk/myStream/playlist.m3u8',
    ),
    RadioChannel(
      id: 'tbn_chungnam',
      name: 'TBN 충남교통방송',
      station: 'TBN',
      region: RadioRegion.chungnam,
      source: StreamSource.direct,
      endpoint: 'https://www.tbn.it.kr/chungnam/myStream/playlist.m3u8',
    ),
    RadioChannel(
      id: 'tbn_gangwon',
      name: 'TBN 강원교통방송',
      station: 'TBN',
      region: RadioRegion.gangwon,
      source: StreamSource.direct,
      endpoint: 'https://www.tbn.it.kr/gangwon/myStream/playlist.m3u8',
    ),
    RadioChannel(
      id: 'tbn_jeju',
      name: 'TBN 제주교통방송',
      station: 'TBN',
      region: RadioRegion.jeju,
      source: StreamSource.direct,
      endpoint: 'https://www.tbn.it.kr/jeju/myStream/playlist.m3u8',
    ),
    RadioChannel(
      id: 'febc_busan',
      name: 'FEBC 부산극동방송',
      station: 'FEBC',
      region: RadioRegion.busan,
      source: StreamSource.direct,
      endpoint: 'http://mlive2.febc.net:1935/live/bsfebc/playlist.m3u8',
    ),
    RadioChannel(
      id: 'febc_ulsan',
      name: 'FEBC 울산극동방송',
      station: 'FEBC',
      region: RadioRegion.ulsan,
      source: StreamSource.direct,
      endpoint: 'http://mlive2.febc.net:1935/live/uslive/playlist.m3u8',
    ),
    RadioChannel(
      id: 'febc_changwon',
      name: 'FEBC 창원극동방송',
      station: 'FEBC',
      region: RadioRegion.gyeongnam,
      source: StreamSource.direct,
      endpoint: 'http://mlive2.febc.net:1935/live/cwlive/playlist.m3u8',
    ),
    RadioChannel(
      id: 'febc_daegu',
      name: 'FEBC 대구극동방송',
      station: 'FEBC',
      region: RadioRegion.daegu,
      source: StreamSource.direct,
      endpoint: 'https://mlive3.febc.net/live5/daegulive/playlist.m3u8',
    ),
    RadioChannel(
      id: 'febc_pohang',
      name: 'FEBC 포항극동방송',
      station: 'FEBC',
      region: RadioRegion.gyeongbuk,
      source: StreamSource.direct,
      endpoint: 'http://mlive2.febc.net:1935/live/phlive/playlist.m3u8',
    ),
    RadioChannel(
      id: 'febc_gwangju',
      name: 'FEBC 광주극동방송',
      station: 'FEBC',
      region: RadioRegion.gwangju,
      source: StreamSource.direct,
      endpoint: 'http://mlive2.febc.net:1935/live/gjlive/playlist.m3u8',
    ),
    RadioChannel(
      id: 'febc_mokpo',
      name: 'FEBC 목포극동방송',
      station: 'FEBC',
      region: RadioRegion.jeonnam,
      source: StreamSource.direct,
      endpoint: 'https://mlive3.febc.net/live5/mplive/playlist.m3u8',
    ),
    RadioChannel(
      id: 'febc_jeonnam',
      name: 'FEBC 전남동부극동방송',
      station: 'FEBC',
      region: RadioRegion.jeonnam,
      source: StreamSource.direct,
      endpoint: 'http://mlive2.febc.net:1935/live/jndblive/playlist.m3u8',
    ),
    RadioChannel(
      id: 'febc_jeonbuk',
      name: 'FEBC 전북극동방송',
      station: 'FEBC',
      region: RadioRegion.jeonbuk,
      source: StreamSource.direct,
      endpoint: 'http://mlive2.febc.net:1935/live/jblive/playlist.m3u8',
    ),
    RadioChannel(
      id: 'febc_daejeon',
      name: 'FEBC 대전극동방송',
      station: 'FEBC',
      region: RadioRegion.daejeon,
      source: StreamSource.direct,
      endpoint: 'http://mlive2.febc.net:1935/live/djlive/playlist.m3u8',
    ),
    RadioChannel(
      id: 'febc_gangwon',
      name: 'FEBC 강원극동방송',
      station: 'FEBC',
      region: RadioRegion.gangwon,
      source: StreamSource.direct,
      endpoint: 'https://mlive3.febc.net/live5/ydlive/playlist.m3u8',
    ),
    RadioChannel(
      id: 'febc_jeju',
      name: 'FEBC 제주극동방송',
      station: 'FEBC',
      region: RadioRegion.jeju,
      source: StreamSource.direct,
      endpoint: 'http://mlive2.febc.net:1935/live/jejufm/playlist.m3u8',
    ),
    RadioChannel(
      id: 'cpbc_busan',
      name: 'CPBC 부산가톨릭평화방송',
      station: 'CPBC',
      region: RadioRegion.busan,
      source: StreamSource.direct,
      endpoint:
          'http://pbcradio.dynamicsmart.com:1935/radio/bscpbc-radio/index.m3u8',
    ),
    RadioChannel(
      id: 'cpbc_daegu',
      name: 'CPBC 대구가톨릭평화방송',
      station: 'CPBC',
      region: RadioRegion.daegu,
      source: StreamSource.direct,
      endpoint: 'http://live.dgcpbc.co.kr/dgcpbclive/livestream/playlist.m3u8',
    ),
    RadioChannel(
      id: 'cpbc_gwangju',
      name: 'CPBC 광주가톨릭평화방송',
      station: 'CPBC',
      region: RadioRegion.gwangju,
      source: StreamSource.direct,
      endpoint: 'http://pbcradio.dynamicsmart.com:1935/radio/kjpbc2/index.m3u8',
    ),
    RadioChannel(
      id: 'bbs_jeju',
      name: 'BBS 제주불교방송',
      station: 'BBS',
      region: RadioRegion.jeju,
      source: StreamSource.direct,
      endpoint:
          'http://kdbmobile.clouducs.com:1935/jeju/jeju.stream_aac/playlist.m3u8',
    ),
    RadioChannel(
      id: 'wbs_busan',
      name: 'WBS 부산원음방송',
      station: 'WBS',
      region: RadioRegion.busan,
      source: StreamSource.direct,
      endpoint: 'https://wbsradio2.kr/wbs-b',
    ),
    RadioChannel(
      id: 'wbs_daegu',
      name: 'WBS 대구원음방송',
      station: 'WBS',
      region: RadioRegion.daegu,
      source: StreamSource.direct,
      endpoint: 'https://wbsradio2.kr/wbs-d',
    ),
    RadioChannel(
      id: 'wbs_gwangju',
      name: 'WBS 광주원음방송',
      station: 'WBS',
      region: RadioRegion.gwangju,
      source: StreamSource.direct,
      endpoint: 'https://wbsradio2.kr/wbs-g',
    ),
    RadioChannel(
      id: 'wbs_jeonbuk',
      name: 'WBS 전북원음방송',
      station: 'WBS',
      region: RadioRegion.jeonbuk,
      source: StreamSource.direct,
      endpoint: 'https://wbsradio2.kr/wbs-j',
    ),
    RadioChannel(
      id: 'kugak_gwangju',
      name: '광주국악방송',
      station: '국악',
      region: RadioRegion.gwangju,
      source: StreamSource.direct,
      endpoint:
          'https://mgugaklive.nowcdn.co.kr/gugakgwangju/Glive.stream/playlist.m3u8',
    ),
    RadioChannel(
      id: 'kugak_daejeon',
      name: '대전국악방송',
      station: '국악',
      region: RadioRegion.daejeon,
      source: StreamSource.direct,
      endpoint:
          'https://mgugaklive.nowcdn.co.kr/gugakdaejeon/Daejeonradio.stream/playlist.m3u8',
    ),
    RadioChannel(
      id: 'ggn_gwangju',
      name: '글로벌광주방송',
      station: 'GGN',
      region: RadioRegion.gwangju,
      source: StreamSource.direct,
      endpoint: 'http://media.ggn.or.kr:8080/live',
    ),
    RadioChannel(
      id: 'afn_humphreys',
      name: 'AFN FM Humphreys',
      station: 'AFN',
      region: RadioRegion.gyeonggi,
      source: StreamSource.afn,
      endpoint: 'AFNP_OSN',
    ),
    RadioChannel(
      id: 'afn_daegu',
      name: 'AFN FM Daegu',
      station: 'AFN',
      region: RadioRegion.daegu,
      source: StreamSource.afn,
      endpoint: 'AFNP_DGU',
    ),
    RadioChannel(
      id: 'afn_kunsan',
      name: 'AFN FM Kunsan',
      station: 'AFN',
      region: RadioRegion.jeonbuk,
      source: StreamSource.afn,
      endpoint: 'AFNP_KSN',
    ),
  ];

  static List<RadioChannel> _communityStations() => const [
    RadioChannel(
      id: 'community_yeongju',
      name: '영주FM',
      station: 'FM',
      group: '공동체 라디오',
      region: RadioRegion.gyeongbuk,
      source: StreamSource.direct,
      endpoint: 'http://icecast.radios.kr:8000/yeongjufm',
    ),
    RadioChannel(
      id: 'community_gwanak',
      name: '관악FM',
      station: 'FM',
      group: '공동체 라디오',
      region: RadioRegion.capital,
      source: StreamSource.direct,
      endpoint: 'http://icecast.radios.kr:8000/gwanakfm',
    ),
    RadioChannel(
      id: 'community_gwangju',
      name: '광주FM',
      station: 'FM',
      group: '공동체 라디오',
      region: RadioRegion.gwangju,
      source: StreamSource.direct,
      endpoint: 'http://radiostream.communityradio.kr/live',
    ),
    RadioChannel(
      id: 'community_mapo_local',
      name: '마포FM',
      station: 'FM',
      group: '공동체 라디오',
      region: RadioRegion.capital,
      source: StreamSource.direct,
      endpoint: 'http://onair.mapofm.net/mapofm',
    ),
    RadioChannel(
      id: 'community_seongnam',
      name: '성남FM',
      station: 'FM',
      group: '공동체 라디오',
      region: RadioRegion.capital,
      source: StreamSource.direct,
      endpoint: 'http://onair.mapofm.net/seongnamfm',
    ),
    RadioChannel(
      id: 'community_seongseo',
      name: '성서공동체FM',
      station: 'FM',
      group: '공동체 라디오',
      region: RadioRegion.daegu,
      source: StreamSource.direct,
      endpoint: 'http://onair.mapofm.net/scnfm',
    ),
    RadioChannel(
      id: 'community_okcheon',
      name: '옥천FM',
      station: 'FM',
      group: '공동체 라디오',
      region: RadioRegion.chungbuk,
      source: StreamSource.direct,
      endpoint: 'http://icecast.radios.kr:8000/obn',
    ),
    RadioChannel(
      id: 'community_sejong',
      name: '세종FM',
      station: 'FM',
      group: '공동체 라디오',
      region: RadioRegion.sejong,
      source: StreamSource.direct,
      endpoint: 'http://icecast.radios.kr:8000/sejongfm',
    ),
    RadioChannel(
      id: 'community_gbs',
      name: 'GBS고려방송',
      station: 'FM',
      group: '공동체 라디오',
      region: RadioRegion.jeonnam,
      source: StreamSource.direct,
      endpoint: 'http://icecast.radios.kr:8000/crfm',
    ),
    RadioChannel(
      id: 'community_hanbat',
      name: '한밭FM',
      station: 'FM',
      group: '공동체 라디오',
      region: RadioRegion.daejeon,
      source: StreamSource.direct,
      endpoint: 'http://115.68.194.186:8000/hanbatfm',
    ),
    RadioChannel(
      id: 'community_seongju',
      name: '성주FM',
      station: 'FM',
      group: '공동체 라디오',
      region: RadioRegion.gyeongbuk,
      source: StreamSource.direct,
      endpoint: 'http://icecast.radios.kr:8000/sjfm',
    ),
    RadioChannel(
      id: 'community_namhae',
      name: '남해FM',
      station: 'FM',
      group: '공동체 라디오',
      region: RadioRegion.gyeongnam,
      source: StreamSource.direct,
      endpoint: 'http://icecast.radios.kr:8000/namhaefm',
    ),
    RadioChannel(
      id: 'community_sangju',
      name: '상주FM',
      station: 'FM',
      group: '공동체 라디오',
      region: RadioRegion.gyeongbuk,
      source: StreamSource.direct,
      endpoint: 'http://icecast.radios.kr:8000/sangjufm',
    ),
    RadioChannel(
      id: 'community_seodaemun_local',
      name: '서대문FM',
      station: 'FM',
      group: '공동체 라디오',
      region: RadioRegion.capital,
      source: StreamSource.direct,
      endpoint: 'http://icecast.radios.kr:8000/sdmfm',
    ),
    RadioChannel(
      id: 'community_suwon',
      name: '수원FM',
      station: 'FM',
      group: '공동체 라디오',
      region: RadioRegion.capital,
      source: StreamSource.direct,
      endpoint: 'http://onair.mapofm.net/sonefm',
    ),
    RadioChannel(
      id: 'community_yeonje',
      name: '우리FM',
      station: 'FM',
      group: '공동체 라디오',
      region: RadioRegion.busan,
      source: StreamSource.direct,
      endpoint: 'http://icecast.radios.kr:8000/yeonjefm',
    ),
    RadioChannel(
      id: 'community_suncheon',
      name: '순천미디어네트워크',
      station: 'FM',
      group: '공동체 라디오',
      region: RadioRegion.jeonnam,
      source: StreamSource.direct,
      endpoint: 'http://icecast.radios.kr:8000/suncheonfm',
    ),
    RadioChannel(
      id: 'community_guri',
      name: '구리FM',
      station: 'FM',
      group: '공동체 라디오',
      region: RadioRegion.capital,
      source: StreamSource.direct,
      endpoint: 'http://icecast.radios.kr:8000/gurifm',
    ),
    RadioChannel(
      id: 'community_daegu_donggu',
      name: '대구동구FM',
      station: 'FM',
      group: '공동체 라디오',
      region: RadioRegion.daegu,
      source: StreamSource.direct,
      endpoint: 'http://icecast.radios.kr:8000/daegufm',
    ),
    RadioChannel(
      id: 'community_jeonju',
      name: '전주FM',
      station: 'FM',
      group: '공동체 라디오',
      region: RadioRegion.jeonbuk,
      source: StreamSource.direct,
      endpoint: 'http://radiostream.communityradio.kr/jcfm1',
    ),
    RadioChannel(
      id: 'community_danwon',
      name: '단원FM',
      station: 'FM',
      group: '공동체 라디오',
      region: RadioRegion.capital,
      source: StreamSource.direct,
      endpoint: 'http://radiostream.communityradio.kr/dwfm1',
    ),
  ];

  static RadioChannel byId(String? id) => channels.firstWhere(
    (channel) => channel.id == id,
    orElse: () => channels.firstWhere((channel) => channel.id == defaultId),
  );
}
