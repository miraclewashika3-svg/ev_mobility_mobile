import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/home_screen.dart';
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
      // A rider who signed in previously shouldn't have to do it again just
      // because the app was closed or Android killed it in the background —
      // tryRestoreSession() checks the platform keystore for a token from a
      // prior session before deciding which screen to open on.
      home: FutureBuilder<bool>(
        future: apiService.tryRestoreSession(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _SessionCheckScreen();
          }
          return snapshot.data == true
              ? HomeScreen(apiService: apiService)
              : LoginScreen(apiService: apiService);
        },
      ),
    );
  }
}

// Shown for the brief moment it takes to check the platform keystore for a
// saved session, on every single app launch — worth matching the rest of
// the app's identity (the same "EV" mark every other screen opens with)
// rather than a bare default spinner with no branding at all.
class _SessionCheckScreen extends StatelessWidget {
  const _SessionCheckScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF1B8A4A)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'EV',
                style: TextStyle(
                  color: Color(0xFF1B8A4A),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Color(0xFF1B8A4A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
