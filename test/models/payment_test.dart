import 'package:flutter_test/flutter_test.dart';
import 'package:ev_mobility_mobile/models/payment.dart';

void main() {
  test('Payment.fromJson parses a pending payment', () {
    final payment = Payment.fromJson({
      'id': 7,
      'station_id': 2,
      'amount_kes': '185.00',
      'status': 'pending',
      'method': 'simulated',
      'provider_reference': null,
    });

    expect(payment.id, 7);
    expect(payment.stationId, 2);
    expect(payment.amountKes, 185.0);
    expect(payment.status, 'pending');
    expect(payment.isCompleted, false);
    expect(payment.providerReference, null);
  });

  test('Payment.fromJson parses a completed payment', () {
    final payment = Payment.fromJson({
      'id': 7,
      'station_id': 2,
      'amount_kes': '185.00',
      'status': 'completed',
      'method': 'simulated',
      'provider_reference': 'SIM-4F8A21C9',
    });

    expect(payment.isCompleted, true);
    expect(payment.providerReference, 'SIM-4F8A21C9');
  });
}
