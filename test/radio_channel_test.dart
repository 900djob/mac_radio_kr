import 'package:flutter_test/flutter_test.dart';
import 'package:mac_radio_kr/radio_channel.dart';

void main() {
  test('catalogue has stable unique IDs and retains the original channels', () {
    final ids = RadioChannel.channels.map((channel) => channel.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(RadioChannel.channels.length, greaterThan(180));
    for (final id in [
      'kbs_1',
      'kbs_2',
      'kbs_3',
      'kbs_classic',
      'kbs_cool',
      'kbs_hanminjok',
      'mbc_standard',
      'mbc_fm4u',
      'sbs_love',
      'sbs_power',
      'cbs_standard',
      'cbs_music',
      'ebs_fm',
    ]) {
      expect(RadioChannel.byId(id).id, id);
    }
    expect(RadioChannel.byId('missing').id, RadioChannel.defaultId);
  });

  test('regional sources are grouped by region and broadcaster', () {
    final busan = RadioChannel.channels
        .where((channel) => channel.region == RadioRegion.busan)
        .toList();
    expect(busan, isNotEmpty);
    expect(
      busan.map((channel) => channel.group),
      containsAll(['KBS', 'MBC', 'KNN', 'CBS', 'TBN', '공동체 라디오']),
    );
    expect(
      RadioChannel.channels
          .where((channel) => channel.id == 'ebs_fm')
          .single
          .region,
      RadioRegion.national,
    );
    expect(
      RadioChannel.channels
          .where((channel) => channel.id == 'community_gwanak')
          .single
          .region,
      RadioRegion.capital,
    );
    for (final unavailableId in [
      'kbs_ulsan_2',
      'kbs_ulsan_music',
      'kbs_jinju_2',
      'kbs_wonju_2',
    ]) {
      expect(
        RadioChannel.channels.any((channel) => channel.id == unavailableId),
        isFalse,
      );
    }
  });
}
