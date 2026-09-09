import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const EvMobilityApp());
}

// A single ScaffoldMessenger that outlives any individual screen. Needed
// because ResetPasswordScreen shows its "password reset" confirmation right
// after navigating away from itself (back to Login) — a context-based
// ScaffoldMessenger.of(context) call there would be tied to the screen
// that's being removed from the tree, and the snackbar would vanish with it.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class EvMobilityApp extends StatelessWidget {
  const EvMobilityApp({super.key});

  @override
  Widget build(BuildContext context) {
    // One shared ApiService instance for the whole app's lifetime, so the
    // auth token set at login is still there when StationFinderScreen
    // makes its own request — not a fresh, token-less instance per screen.
    final apiService = ApiService();

    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'EV Mobility Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1B8A4A),
        scaffoldBackgroundColor: const Color(0xFFF7FAF7),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFE2E8E4)),
          ),
        ),
      ),
      home: LoginScreen(apiService: apiService),
    );
  }
}
