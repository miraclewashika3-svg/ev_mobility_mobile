import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

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
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        title: Text(
          'Help & support',
          style: TextStyle(
            color: context.colors.ink,
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
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.colors.border),
              ),
              // ExpansionTile's internal ListTile paints its background and
              // tap ripple on the nearest Material ancestor -- painting the
              // surface color directly on this Container's DecoratedBox
              // (rather than on a Material below it) sat between the tile
              // and that ancestor, which is exactly what Flutter's own
              // "ListTile background color or ink splashes may be
              // invisible" assertion warns about. clipBehavior keeps the
              // Material's corners (and its ripple) clipped to match this
              // container's rounded border instead of square corners
              // peeking out or spilling past it.
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: context.colors.surface,
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: entry.key == 0,
                    iconColor: context.colors.accent,
                    collapsedIconColor: context.colors.accent,
                    title: Text(
                      question,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.colors.ink,
                      ),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        answer,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.inkMuted,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
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
                color: context.colors.accent,
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
