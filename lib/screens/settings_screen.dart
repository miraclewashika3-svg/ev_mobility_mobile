import 'package:flutter/material.dart';
import '../models/rider.dart';
import '../services/api_service.dart';
import 'help_screen.dart';
import 'login_screen.dart';
import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';

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
            child: Text(
              'Sign out',
              style: TextStyle(color: context.colors.danger),
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
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: context.colors.ink,
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
                      backgroundColor: context.colors.accentSurface,
                      child: Text(
                        rider != null ? _initials(rider.name) : '…',
                        style: TextStyle(
                          color: context.colors.accent,
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
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: context.colors.ink,
                            ),
                          ),
                          Text(
                            rider?.email ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.inkMuted,
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
            activeThumbColor: context.colors.accent,
            title: const Text(
              'Stay signed in',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'Skip sign-in the next time you open the app',
              style: TextStyle(fontSize: 11.5, color: context.colors.inkMuted),
            ),
          ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeController,
            builder: (context, mode, _) {
              return SwitchListTile(
                value: mode == ThemeMode.dark,
                onChanged: themeController.setDark,
                activeThumbColor: context.colors.accent,
                title: const Text(
                  'Dark mode',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Easier on the eyes for swaps after dark',
                  style: TextStyle(fontSize: 11.5, color: context.colors.inkMuted),
                ),
              );
            },
          ),
          const _SectionLabel('Support'),
          ListTile(
            leading: Icon(
              Icons.help_outline,
              color: context.colors.accent,
            ),
            title: const Text(
              'Help & support',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
            ),
            trailing: Icon(Icons.chevron_right, color: context.colors.iconMuted),
            onTap: _openHelp,
          ),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: context.colors.accent,
            ),
            title: const Text(
              'About',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'v1.0.0',
              style: TextStyle(fontSize: 11.5, color: context.colors.inkMuted),
            ),
            trailing: Icon(Icons.chevron_right, color: context.colors.iconMuted),
            onTap: _showAbout,
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: context.colors.border),
          ListTile(
            leading: Icon(Icons.logout, color: context.colors.danger),
            title: Text(
              'Sign out',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: context.colors.danger,
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
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: context.colors.inkMuted,
        ),
      ),
    );
  }
}
