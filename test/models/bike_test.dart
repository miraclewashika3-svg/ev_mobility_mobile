import 'package:flutter_test/flutter_test.dart';
import 'package:ev_mobility_mobile/models/bike.dart';

void main() {
  test('Bike.fromJson parses a Laravel bike record', () {
    final bike = Bike.fromJson({
      'id': 1,
      'model': 'Roam Air',
      'registration_number': 'KMEV001A',
      'home_network': 'Roam',
    });

    expect(bike.id, 1);
    expect(bike.model, 'Roam Air');
    expect(bike.registrationNumber, 'KMEV001A');
    expect(bike.homeNetwork, 'Roam');
  });
}
