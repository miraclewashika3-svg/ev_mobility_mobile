import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// A first-run empty screen should read as onboarding, not as "nothing
// here" -- an icon, a real headline, and one clear action, instead of a
// single line of grey text. Shared so every empty state in the app looks
// and behaves the same way rather than each screen inventing its own.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: context.colors.accentSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 42, color: context.colors.accent),
              ),
              Positioned(
                right: 6,
                bottom: 10,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: context.colors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt, size: 15, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.colors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: context.colors.inkMuted,
              height: 1.5,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
