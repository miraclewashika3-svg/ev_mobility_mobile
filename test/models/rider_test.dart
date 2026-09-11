import 'package:flutter_test/flutter_test.dart';
import 'package:ev_mobility_mobile/models/rider.dart';

void main() {
  test('Rider.fromJson parses the /me response', () {
    final rider = Rider.fromJson({
      'id': 1,
      'name': 'Brian Otieno',
      'email': 'brian.otieno@example.com',
      'phone': '0722100001',
      'created_at': '2026-09-09T14:58:06.000000Z',
      'updated_at': '2026-09-09T14:58:06.000000Z',
    });

    expect(rider.id, 1);
    expect(rider.name, 'Brian Otieno');
    expect(rider.email, 'brian.otieno@example.com');
    expect(rider.phone, '0722100001');
  });
}
