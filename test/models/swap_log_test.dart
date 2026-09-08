import 'package:flutter_test/flutter_test.dart';
import 'package:ev_mobility_mobile/models/swap_log.dart';

void main() {
  test('SwapLog.fromJson parses the swap timestamp and decimal cost', () {
    final log = SwapLog.fromJson({
      'id': 3,
      'swapped_at': '2026-09-05T08:30:00.000000Z',
      'cost_kes': '185.00',
    });

    expect(log.id, 3);
    expect(log.swappedAt, DateTime.parse('2026-09-05T08:30:00.000000Z'));
    expect(log.costKes, 185.0);
  });
}
