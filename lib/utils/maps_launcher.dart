import 'package:url_launcher/url_launcher.dart';

// Opens the real Google Maps app (or maps.google.com in a browser if the
// app isn't installed) with turn-by-turn directions to a station already
// loaded — no Google Maps API key or billing account needed, since this is
// just a deep link into Maps, not a call to the Maps/Directions API.
Future<bool> openDirectionsTo({
  required double latitude,
  required double longitude,
}) async {
  final uri = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '$latitude,$longitude',
    'travelmode': 'driving',
  });

  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
