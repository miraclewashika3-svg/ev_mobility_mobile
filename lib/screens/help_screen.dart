import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    (
      'How is my savings figure calculated?',
      'Petrol-equivalent cost minus what you actually paid, added up across '
          'every swap you\'ve logged. It\'s the same formula the fleet '
          'console shows to network operators, so the numbers always agree.',
    ),
    (
      'Can I swap at a station from a different network?',
      'Yes. Stations from every participating network show up in the same '
          'list and map — you\'re not limited to your bike\'s home network.',
    ),
    (
      'What if a station shows no charged batteries?',
      'Try the next nearest station on the list or map. Stock isn\'t tracked '
          'live yet, so it\'s worth checking a second option if the first is '
          'out.',
    ),
    (
      'I forgot to log a swap — can I add it after the fact?',
      'Yes, from the Log a Swap screen you can pick any past date and time, '
          'so a swap you forgot to log at the time still counts toward your '
          'savings.',
    ),
    (
      'How do I stop the app from signing me out?',
      'Settings → Stay signed in. When it\'s on, the app skips the sign-in '
          'screen on future launches; turning it off signs you out '
          'immediately and every time after.',
    ),
  ];

  Future<void> _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@evmobility.app',
      query: 'subject=EV Mobility app — help needed',
    );
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAF7),
        elevation: 0,
        title: const Text(
          'Help & support',
          style: TextStyle(
            color: Color(0xFF1A2620),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          ..._faqs.asMap().entries.map((entry) {
            final (question, answer) = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8E4)),
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: entry.key == 0,
                  iconColor: const Color(0xFF1B8A4A),
                  collapsedIconColor: const Color(0xFF1B8A4A),
                  title: Text(
                    question,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF14251A),
                    ),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      answer,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5B6660),
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          InkWell(
            onTap: _contactSupport,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1B8A4A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mail_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Still stuck? Message support',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Replies within one business day',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
