class Bike {
  final int id;
  final String model;
  final String registrationNumber;
  final String homeNetwork;

  Bike({
    required this.id,
    required this.model,
    required this.registrationNumber,
    required this.homeNetwork,
  });

  factory Bike.fromJson(Map<String, dynamic> json) {
    return Bike(
      id: json['id'],
      model: json['model'],
      registrationNumber: json['registration_number'],
      homeNetwork: json['home_network'],
    );
  }
}
