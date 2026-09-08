class SavingsSummary {
  final double totalPetrolEquivalentKes;
  final double totalActualCostKes;
  final double totalSavingsKes;

  SavingsSummary({
    required this.totalPetrolEquivalentKes,
    required this.totalActualCostKes,
    required this.totalSavingsKes,
  });

  factory SavingsSummary.fromJson(Map<String, dynamic> json) {
    // The API returns these as plain numbers (int or double depending on
    // whether the sum happens to be a whole number) — parsing via
    // num.parse(...toString()) handles either case safely, rather than
    // assuming one specific type and crashing on the other.
    return SavingsSummary(
      totalPetrolEquivalentKes: double.parse(
        json['total_petrol_equivalent_kes'].toString(),
      ),
      totalActualCostKes: double.parse(
        json['total_actual_cost_kes'].toString(),
      ),
      totalSavingsKes: double.parse(json['total_savings_kes'].toString()),
    );
  }
}
