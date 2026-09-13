import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

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

    // Created exactly once per app launch, outside the ValueListenableBuilder
    // below -- if this lived inside that builder, toggling dark mode would
    // re-trigger the whole session-restore check (and briefly show the
    // splash screen again) every single time, since the builder reruns on
    // every theme change.
    final sessionFuture = apiService.tryRestoreSession();

    // themeController is a top-level singleton (see theme_controller.dart),
    // so this ValueListenableBuilder is the one place in the app that reacts
    // to the Settings toggle -- it rebuilds just the MaterialApp, not
    // apiService or sessionFuture above, when dark mode is switched on or
    // off.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, mode, _) {
        return MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          title: 'EV Mobility Platform',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          // A rider who signed in previously shouldn't have to do it again
          // just because the app was closed or Android killed it in the
          // background — tryRestoreSession() checks the platform keystore
          // for a token from a prior session before deciding which screen
          // to open on.
          home: FutureBuilder<bool>(
            future: sessionFuture,
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
      },
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
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: colors.accent),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'EV',
                style: TextStyle(
                  color: colors.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: colors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
