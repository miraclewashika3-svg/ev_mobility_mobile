import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/station.dart';
import '../models/bike.dart';
import '../models/savings_summary.dart';

class ApiService {
  // 10.0.2.2 is the Android emulator's special alias for the host machine's
  // localhost — NOT a typo for 127.0.0.1. If testing on a real physical
  // phone instead of the emulator, replace this with your laptop's actual
  // local network IP (e.g. 192.168.x.x) so the phone can reach it over WiFi.
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  String? _token;

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String;
      setToken(token);
      return token;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Login failed');
    }
  }

  Future<List<Station>> getStations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/stations'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Station.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load stations');
    }
  }

  // Returns only the logged-in rider's own bikes — enforced server-side by
  // BikeController, not something this method decides on its own.
  Future<List<Bike>> getBikes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/bikes'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Bike.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load bikes');
    }
  }

  // The actual savings calculation — same endpoint the Vue dashboard uses,
  // so both frontends show identical, consistent figures for the same bike.
  Future<SavingsSummary> getSavingsSummary(int bikeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/bikes/$bikeId/savings-summary'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return SavingsSummary.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load savings summary');
    }
  }
}
