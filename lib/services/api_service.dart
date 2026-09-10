import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/station.dart';
import '../models/bike.dart';
import '../models/savings_summary.dart';
import '../models/swap_log.dart';

class ApiService {
  // Defaults to the live production API so a plain `flutter run` / `flutter
  // build apk` with no flags works out of the box on a real device — the
  // common case now that this is meant to be handed to an actual rider, not
  // just run against a laptop. Override at compile time for local backend
  // development instead:
  //   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api   (Android emulator)
  //   flutter run --dart-define=API_BASE_URL=http://localhost:8000/api  (everything else)
  //   flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000/api (physical device, laptop's LAN IP)
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  static const String _liveApiBaseUrl =
      'https://backend-production-10b9.up.railway.app/api';

  static String get baseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }
    return _liveApiBaseUrl;
  }

  String? _token;

  void setToken(String token) {
    _token = token;
  }

  bool get isLoggedIn => _token != null;

  // Revokes the current token server-side, then clears it locally either
  // way — if the token is already invalid/expired, the server call fails,
  // but the rider still needs to be logged out of the app itself.
  Future<void> logout() async {
    try {
      await http.post(Uri.parse('$baseUrl/logout'), headers: _headers);
    } finally {
      _token = null;
    }
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
      throw Exception(_errorMessage(response, fallback: 'Login failed'));
    }
  }

  // Registers a new rider and, like login, comes back with a token already
  // set — so a brand-new rider lands straight in the app, no separate
  // login step required.
  Future<String> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String;
      setToken(token);
      return token;
    } else {
      throw Exception(_errorMessage(response, fallback: 'Registration failed'));
    }
  }

  // Requests a 6-digit reset code by email. The response is identical
  // whether or not the email is registered — the server deliberately
  // doesn't reveal that, so there's nothing rider-specific to return here.
  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response, fallback: 'Could not request a reset code'),
      );
    }
  }

  // Verifies the code from forgotPassword() and sets a new password. On
  // success, the server also revokes every existing token for this rider,
  // so the caller still needs to log in again afterward.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'code': code,
        'password': password,
        'password_confirmation': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _errorMessage(response, fallback: 'Could not reset password'),
      );
    }
  }

  // Pulls the first validation error Laravel reports (e.g. "This email is
  // already taken") rather than just its generic top-level message, so the
  // rider sees the actual reason their input was rejected.
  String _errorMessage(http.Response response, {required String fallback}) {
    try {
      final data = jsonDecode(response.body);
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
      }
      return data['message']?.toString() ?? fallback;
    } catch (_) {
      return fallback;
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

  // A bike's full swap history — the "rider-owned usage record" your
  // pitch specifically differentiates on, shown newest-first since that's
  // what a rider actually wants to see first.
  Future<List<SwapLog>> getSwapLogsForBike(int bikeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/bikes/$bikeId/swap-logs'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => SwapLog.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load swap history');
    }
  }

  // Registers a rider's first (or an additional) bike. rider_id is never
  // sent — the server always derives it from the auth token, so there's
  // nothing here for a client to get wrong.
  Future<Bike> createBike({
    required String model,
    required String registrationNumber,
    required String homeNetwork,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bikes'),
      headers: _headers,
      body: jsonEncode({
        'model': model,
        'registration_number': registrationNumber,
        'home_network': homeNetwork,
      }),
    );

    if (response.statusCode == 201) {
      return Bike.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_errorMessage(response, fallback: 'Failed to add bike'));
    }
  }

  // Records one swap event for a bike. Kept separate from createCostEntry
  // because a swap log (what happened, where, when) and a cost entry (the
  // savings-comparison figures) are two distinct models server-side.
  Future<SwapLog> createSwapLog({
    required int bikeId,
    required int stationId,
    required DateTime swappedAt,
    required double costKes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/swap-logs'),
      headers: _headers,
      body: jsonEncode({
        'bike_id': bikeId,
        'station_id': stationId,
        // .toUtc() first: a local DateTime's toIso8601String() has no "Z"
        // suffix, so Laravel parses it as if it were already UTC — in any
        // timezone ahead of UTC that reads as a future timestamp and fails
        // the "before_or_equal:now" validation even for the actual current
        // moment.
        'swapped_at': swappedAt.toUtc().toIso8601String(),
        'cost_kes': costKes,
      }),
    );

    if (response.statusCode == 201) {
      return SwapLog.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_errorMessage(response, fallback: 'Failed to log swap'));
    }
  }

  // Records the savings comparison for a swap — what it actually cost versus
  // what the same trip would have cost on petrol. Called right after
  // createSwapLog so every logged swap immediately counts toward Savings.
  Future<void> createCostEntry({
    required int bikeId,
    required double petrolEquivalentKes,
    required double actualCostKes,
    required DateTime entryDate,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cost-entries'),
      headers: _headers,
      body: jsonEncode({
        'bike_id': bikeId,
        'petrol_equivalent_kes': petrolEquivalentKes,
        'actual_cost_kes': actualCostKes,
        'entry_date':
            '${entryDate.year.toString().padLeft(4, '0')}-${entryDate.month.toString().padLeft(2, '0')}-${entryDate.day.toString().padLeft(2, '0')}',
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
        _errorMessage(response, fallback: 'Failed to log cost entry'),
      );
    }
  }
}
