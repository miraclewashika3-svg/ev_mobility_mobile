import 'package:local_auth/local_auth.dart';

// Wraps local_auth as a single, testable place for what "biometric unlock"
// actually means in this app: a local gate in front of the session token
// ApiService already stores in the platform keystore -- never a new
// server-side auth method. A fingerprint never reaches the backend and
// can't be verified by it; see docs/FUTURE_CONSIDERATIONS.md §5 on the
// backend repo for the full design note this implements.
class BiometricAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  // Whether this device can even prompt for biometrics right now -- no
  // enrolled fingerprint/face, or hardware that doesn't support it, both
  // land here. Checked before ever showing the Settings toggle, so a rider
  // on a device without biometrics never sees an option that would only
  // ever fail.
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
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
