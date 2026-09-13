import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/biometric_auth_service.dart';
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

// Set true the moment a rider reaches Home, from *any* entry path --
// automatic session restore at cold launch, a plain password login, or
// the Login screen's own fingerprint button. Plain top-level mutable
// state, same pattern as themeController -- not a ValueNotifier, since
// nothing needs to rebuild in response to it, only read it at the exact
// moment the app is backgrounded. Originally this only ever got set
// inside _resolveStartupSession below, which meant a rider who signed in
// manually with their password (a completely different code path that
// never touches that future) was invisibly exempt from ever being
// re-locked on resume -- the bug behind "it worked once via adb, never
// through the real app."
bool appHasEnteredHome = false;

// A stored session only skips straight to Home if biometric unlock is
// off -- when it's on, this deliberately does NOT auto-prompt. Landing on
// Login instead (with the token already restored into apiService) lets
// the rider choose: tap "Sign in with fingerprint" there when they're
// ready, or type their password -- never a system dialog popping up
// before they've asked for it.
Future<bool> _resolveStartupSession(ApiService apiService) async {
  final hasSession = await apiService.tryRestoreSession();
  if (!hasSession) return false;

  return !(await apiService.getBiometricUnlockPreference());
}

class EvMobilityApp extends StatefulWidget {
  const EvMobilityApp({super.key});

  @override
  State<EvMobilityApp> createState() => _EvMobilityAppState();
}

// WidgetsBindingObserver, not just the FutureBuilder in build() below --
// that alone only ever gates a genuinely fresh process, which turned out
// to be an unreliable thing to depend on: OEM skins (MIUI confirmed here)
// routinely keep an app's process alive across what looks, to the rider,
// like fully closing it (swiping it away in Recents), so main() never
// re-runs and the one-time startup check never re-fires. Real high-level
// apps (banking, messaging) don't rely on process death either -- they
// re-lock on every background/foreground transition instead, which is
// what this observer does.
class _EvMobilityAppState extends State<EvMobilityApp>
    with WidgetsBindingObserver {
  late final ApiService _apiService;
  late final Future<bool> _sessionFuture;
  final _biometricAuth = BiometricAuthService();

  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _apiService = ApiService();
    _sessionFuture = _resolveStartupSession(_apiService).then((entered) {
      if (entered) appHasEnteredHome = true;
      return entered;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!appHasEnteredHome) return;

    if (state == AppLifecycleState.paused) {
      // Reads the preference fresh rather than caching it -- a rider could
      // have just turned the toggle off in Settings, and backgrounding
      // right after should respect that immediately, not lock them out
      // with yesterday's setting.
      _apiService.getBiometricUnlockPreference().then((required) {
        if (required && mounted) setState(() => _isLocked = true);
      });
    } else if (state == AppLifecycleState.resumed && _isLocked) {
      _attemptUnlock();
    }
  }

  Future<void> _attemptUnlock() async {
    final success = await _biometricAuth.authenticate();
    if (mounted && success) setState(() => _isLocked = false);
    // A failed or cancelled prompt just leaves _isLocked true -- the lock
    // screen's own retry button (or backgrounding and resuming again)
    // gives another chance, rather than forcing a full sign-out.
  }

  @override
  Widget build(BuildContext context) {
    // themeController is a top-level singleton (see theme_controller.dart),
    // so this ValueListenableBuilder is the one place in the app that reacts
    // to the Settings toggle -- it rebuilds just the MaterialApp, not
    // _apiService or _sessionFuture above, when dark mode is switched on or
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
            future: _sessionFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const _SessionCheckScreen();
              }
              if (snapshot.data != true) {
                return LoginScreen(apiService: _apiService);
              }
              return _isLocked
                  ? _LockScreen(onRetry: _attemptUnlock)
                  : HomeScreen(apiService: _apiService);
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

// Covers the app's content the moment it's resumed from background with
// biometric unlock on -- shown instead of Home until the rider taps
// Unlock and authenticate() succeeds, so a rider's swap history and
// savings are never on screen for the split second after switching back
// to the app. Deliberately doesn't auto-prompt on appearing -- the
// system fingerprint dialog only ever shows after this screen's own
// button is tapped, never on its own.
class _LockScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const _LockScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.accentSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fingerprint,
                  size: 40,
                  color: colors.accent,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'EV Mobility is locked',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Confirm it\'s you to continue',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colors.inkMuted),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.fingerprint, color: colors.accent),
                label: Text('Unlock', style: TextStyle(color: colors.accent)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.accent),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
