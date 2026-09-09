import 'package:flutter/material.dart';
import '../main.dart' show rootScaffoldMessengerKey;
import '../services/api_service.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final ApiService apiService;
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.apiService,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _handleReset() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.apiService.resetPassword(
        email: widget.email,
        code: _codeController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      // The server revoked every token on reset, so this always lands back
      // at Login — there is no valid session to carry forward.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(apiService: widget.apiService),
        ),
        (route) => false,
      );
      // Uses the app-wide messenger key, not context — this screen is being
      // removed from the tree by the navigation above, so a context-bound
      // ScaffoldMessenger would be tied to a Scaffold that's already gone.
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Password reset. Sign in with your new password.'),
        ),
      );
    } catch (error) {
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your code',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2620),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'We sent a 6-digit code to ${widget.email}.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B786F),
                  ),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: 'Reset code'),
                ),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'New password',
                    helperText: 'At least 8 characters',
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFB45309),
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B8A4A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      _isSubmitting ? 'Resetting…' : 'Reset password',
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
