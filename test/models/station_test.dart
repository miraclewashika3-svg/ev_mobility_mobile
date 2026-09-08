import 'package:flutter_test/flutter_test.dart';
import 'package:ev_mobility_mobile/models/station.dart';

void main() {
  test('Station.fromJson parses Laravel decimal fields sent as strings', () {
    final station = Station.fromJson({
      'id': 1,
      'station_name': 'Westlands Swap Point',
      'provider_name': 'ARC Ride',
      'latitude': '-1.2634000',
      'longitude': '36.8047000',
      'swap_price_kes': '185.00',
    });

    expect(station.stationName, 'Westlands Swap Point');
    expect(station.latitude, -1.2634);
    expect(station.longitude, 36.8047);
    expect(station.swapPriceKes, 185.0);
  });

  test('Station.fromJson also handles plain numeric fields', () {
    final station = Station.fromJson({
      'id': 2,
      'station_name': 'CBD Fuel Point',
      'provider_name': 'Roam',
      'latitude': -1.2864,
      'longitude': 36.8172,
      'swap_price_kes': 0,
    });

    expect(station.latitude, -1.2864);
    expect(station.swapPriceKes, 0.0);
  });
}
