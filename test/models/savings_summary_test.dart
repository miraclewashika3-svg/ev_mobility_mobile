import 'package:flutter_test/flutter_test.dart';
import 'package:ev_mobility_mobile/models/savings_summary.dart';

void main() {
  test('SavingsSummary.fromJson parses whole-number sums', () {
    final summary = SavingsSummary.fromJson({
      'total_petrol_equivalent_kes': 3547,
      'total_actual_cost_kes': 1115,
      'total_savings_kes': 2432,
    });

    expect(summary.totalPetrolEquivalentKes, 3547.0);
    expect(summary.totalActualCostKes, 1115.0);
    expect(summary.totalSavingsKes, 2432.0);
  });

  test('SavingsSummary.fromJson parses fractional sums', () {
    final summary = SavingsSummary.fromJson({
      'total_petrol_equivalent_kes': 444.5,
      'total_actual_cost_kes': 185.25,
      'total_savings_kes': 259.25,
    });

    expect(summary.totalPetrolEquivalentKes, 444.5);
    expect(summary.totalActualCostKes, 185.25);
    expect(summary.totalSavingsKes, 259.25);
  });
}
