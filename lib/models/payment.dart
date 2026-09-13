class Payment {
  final int id;
  final int stationId;
  final double amountKes;
  final String status;
  final String method;
  final String? providerReference;

  Payment({
    required this.id,
    required this.stationId,
    required this.amountKes,
    required this.status,
    required this.method,
    this.providerReference,
  });

  bool get isCompleted => status == 'completed';

  // Laravel returns decimal fields as strings (e.g. "185.00"), so amount_kes
  // is parsed explicitly rather than assumed to already be a number.
  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      stationId: json['station_id'],
      amountKes: double.parse(json['amount_kes'].toString()),
      status: json['status'],
      method: json['method'],
      providerReference: json['provider_reference'],
    );
  }
}
