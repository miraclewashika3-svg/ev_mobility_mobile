class Station {
  final int id;
  final String stationName;
  final String providerName;
  final double latitude;
  final double longitude;
  final double swapPriceKes;

  Station({
    required this.id,
    required this.stationName,
    required this.providerName,
    required this.latitude,
    required this.longitude,
    required this.swapPriceKes,
  });

  // Factory constructor: converts raw, untyped JSON (strings/numbers from
  // the API) into a real, type-safe Station object. Laravel returns decimal
  // fields as strings (e.g. "185.00"), so they're parsed explicitly here
  // rather than assumed to already be numbers.
  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'],
      stationName: json['station_name'],
      providerName: json['provider_name'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      swapPriceKes: double.parse(json['swap_price_kes'].toString()),
    );
  }
}
