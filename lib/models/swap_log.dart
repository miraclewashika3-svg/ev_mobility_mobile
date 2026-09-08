class SwapLog {
  final int id;
  final DateTime swappedAt;
  final double costKes;

  SwapLog({required this.id, required this.swappedAt, required this.costKes});

  factory SwapLog.fromJson(Map<String, dynamic> json) {
    return SwapLog(
      id: json['id'],
      swappedAt: DateTime.parse(json['swapped_at']),
      costKes: double.parse(json['cost_kes'].toString()),
    );
  }
}
