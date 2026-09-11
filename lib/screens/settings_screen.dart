import 'package:flutter/material.dart';
import '../models/rider.dart';
import '../services/api_service.dart';
import 'help_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final ApiService apiService;

  const SettingsScreen({super.key, required this.apiService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<Rider> _riderFuture;
  bool _persistSession = true;

  @override
  void initState() {
    super.initState();
    _riderFuture = widget.apiService.getMe();
    widget.apiService.getPersistSessionPreference().then((value) {
      if (mounted) setState(() => _persistSession = value);
    });
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  Future<void> _togglePersistSession(bool value) async {
    setState(() => _persistSession = value);
    await widget.apiService.setPersistSessionPreference(value);
  }

  void _openHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HelpScreen()),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('About'),
        content: const Text(
          'EV Mobility Platform, v1.0.0\n\n'
          'Find a swap station across every network in one app, log your '
          'swaps, and track real savings against petrol.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You\'ll need to sign in again to use the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign out',
              style: TextStyle(color: Color(0xFFB4392C)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await widget.apiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(apiService: widget.apiService),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAF7),
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF1A2620),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        children: [
          FutureBuilder<Rider>(
            future: _riderFuture,
            builder: (context, snapshot) {
              final rider = snapshot.data;
              return Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 23,
                      backgroundColor: const Color(0xFFE1F3EA),
                      child: Text(
                        rider != null ? _initials(rider.name) : '…',
                        style: const TextStyle(
                          color: Color(0xFF1B8A4A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rider?.name ?? 'Loading…',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF14251A),
                            ),
                          ),
                          Text(
                            rider?.email ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5B6660),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const _SectionLabel('Preferences'),
          SwitchListTile(
            value: _persistSession,
            onChanged: _togglePersistSession,
            activeThumbColor: const Color(0xFF1B8A4A),
            title: const Text(
              'Stay signed in',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
            ),
            subtitle: const Text(
              'Skip sign-in the next time you open the app',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF8A9490)),
            ),
          ),
          const _SectionLabel('Support'),
          ListTile(
            leading: const Icon(
              Icons.help_outline,
              color: Color(0xFF1B8A4A),
            ),
            title: const Text(
              'Help & support',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFFB7C0BA)),
            onTap: _openHelp,
          ),
          ListTile(
            leading: const Icon(
              Icons.info_outline,
              color: Color(0xFF1B8A4A),
            ),
            title: const Text(
              'About',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
            ),
            subtitle: const Text(
              'v1.0.0',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF8A9490)),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFFB7C0BA)),
            onTap: _showAbout,
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE2E8E4)),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFB4392C)),
            title: const Text(
              'Sign out',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFFB4392C),
              ),
            ),
            onTap: _confirmSignOut,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: Color(0xFF8A9490),
        ),
      ),
    );
  }
}
