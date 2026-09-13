import 'package:flutter/material.dart';
import '../main.dart' show appHasEnteredHome;
import '../services/api_service.dart';
import '../services/biometric_auth_service.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  final ApiService apiService;

  const LoginScreen({super.key, required this.apiService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _biometricAuth = BiometricAuthService();
  bool _isSubmitting = false;
  String? _errorMessage;
  // Only ever true when there's an actual session to unlock -- a restored
  // token already sitting in apiService from tryRestoreSession() at launch
  // (see main.dart), with the rider's own "require fingerprint" preference
  // on. A rider who has never logged in, or who signed out, has no token
  // to unlock, so this stays false and the button never appears -- a
  // fingerprint can confirm an existing session, never substitute for the
  // first real sign-in.
  bool _showBiometricOption = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricOption();
  }

  Future<void> _checkBiometricOption() async {
    if (!widget.apiService.isLoggedIn) return;
    final enabled = await widget.apiService.getBiometricUnlockPreference();
    if (!enabled) return;
    // hasEnrolledBiometrics, not just isSupported -- the preference can
    // only ever have been switched on from Settings after a successful
    // authenticate() there, which itself required something enrolled. If a
    // rider later removes every fingerprint from their phone's own
    // Settings, this button should quietly stop appearing rather than
    // offering something that would only ever fail.
    final ready = await _biometricAuth.hasEnrolledBiometrics();
    if (mounted) setState(() => _showBiometricOption = ready);
  }

  Future<void> _handleBiometricLogin() async {
    final success = await _biometricAuth.authenticate();
    if (!success || !mounted) return;
    appHasEnteredHome = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(apiService: widget.apiService),
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.apiService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;
      appHasEnteredHome = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(apiService: widget.apiService),
        ),
      );
    } catch (error) {
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: context.colors.accent),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'EV',
                    style: TextStyle(
                      color: context.colors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Welcome back',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: context.colors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to find your nearest swap station.',
                  style: TextStyle(fontSize: 14, color: context.colors.inkMuted),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ForgotPasswordScreen(
                                apiService: widget.apiService,
                              ),
                            ),
                          ),
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(color: context.colors.accent, fontSize: 13),
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: context.colors.warning,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(_isSubmitting ? 'Signing in…' : 'Sign in'),
                  ),
                ),
                if (_showBiometricOption) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Divider(color: context.colors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.inkMuted,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: context.colors.border)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _handleBiometricLogin,
                      icon: Icon(Icons.fingerprint, color: context.colors.accent),
                      label: Text(
                        'Sign in with fingerprint',
                        style: TextStyle(color: context.colors.accent),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.colors.accent),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RegisterScreen(apiService: widget.apiService),
                            ),
                          ),
                    child: Text(
                      "Don't have an account? Create one",
                      style: TextStyle(color: context.colors.accent, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
