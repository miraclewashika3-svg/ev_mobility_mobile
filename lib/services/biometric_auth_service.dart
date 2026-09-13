import 'package:local_auth/local_auth.dart';

// Wraps local_auth as a single, testable place for what "biometric unlock"
// actually means in this app: a local gate in front of the session token
// ApiService already stores in the platform keystore -- never a new
// server-side auth method. A fingerprint never reaches the backend and
// can't be verified by it; see docs/FUTURE_CONSIDERATIONS.md §5 on the
// backend repo for the full design note this implements.
class BiometricAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  // Whether this hardware supports biometrics *at all* -- true regardless
  // of whether a fingerprint/face is actually enrolled yet, the same way
  // high-level apps (banking apps, Google) show the option on capable
  // hardware and explain what's missing rather than hiding it outright.
  // Only a device with no biometric sensor at all never sees the toggle.
  Future<bool> isSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  // True only once something is actually enrolled at the OS level -- no
  // app, this one included, can ever capture or save a fingerprint itself;
  // enrollment only ever happens in the phone's own Settings. This is what
  // separates "the toggle exists but needs setup first" from "it's ready."
  Future<bool> hasEnrolledBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  // Not biometricOnly: true -- a device credential (PIN/pattern) fallback
  // is what stops a fingerprint sensor having a bad day from locking a
  // rider out of their own account, with normal email/password login as
  // the ultimate fallback regardless (see main.dart's session-restore
  // gating: a failed or cancelled prompt here just lands on the login
  // screen, never a dead end).
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock EV Mobility to continue',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
