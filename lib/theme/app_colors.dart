import 'package:flutter/material.dart';

// Every screen used to reach for a literal `Color(0xFF...)` directly --
// fine while there was only ever one theme, but it meant "dark mode" had
// nowhere to hook in: nothing was asking "which theme is this?" before
// picking a color. This file is that hook, as a ThemeExtension so every
// screen keeps reading colors off Theme.of(context) exactly the way it
// already reads TextStyles and InputDecorationTheme -- just through
// `context.colors.ink` instead of a hardcoded hex.
//
// A handful of near-identical shades that only ever differed by which
// screen's author picked them (e.g. three different muted-text grays)
// were folded into one token here -- that was inconsistency, not intent.
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface;
  final Color ink;
  final Color inkMuted;
  final Color border;
  final Color iconMuted;
  final Color accent;
  final Color accentDark;
  final Color accentMuted;
  final Color accentSurface;
  final Color warning;
  final Color warningDark;
  final Color warningSurface;
  final Color danger;

  const AppColors({
    required this.background,
    required this.surface,
    required this.ink,
    required this.inkMuted,
    required this.border,
    required this.iconMuted,
    required this.accent,
    required this.accentDark,
    required this.accentMuted,
    required this.accentSurface,
    required this.warning,
    required this.warningDark,
    required this.warningSurface,
    required this.danger,
  });

  static const light = AppColors(
    background: Color(0xFFF7FAF7),
    surface: Colors.white,
    ink: Color(0xFF1A2620),
    inkMuted: Color(0xFF6B786F),
    border: Color(0xFFE2E8E4),
    iconMuted: Color(0xFFB7C0BA),
    accent: Color(0xFF1B8A4A),
    accentDark: Color(0xFF0F5C30),
    accentMuted: Color(0xFF4C7A56),
    accentSurface: Color(0xFFE1F3EA),
    warning: Color(0xFFB45309),
    warningDark: Color(0xFF8A5A00),
    warningSurface: Color(0xFFFCEED3),
    danger: Color(0xFFB4392C),
  );

  // Not a literal invert of `light` -- e.g. the brand green shifts lighter
  // here (0xFF1B8A4A -> 0xFF4CBF7D) because the darker one fails contrast
  // against a near-black background.
  static const dark = AppColors(
    background: Color(0xFF0F1512),
    surface: Color(0xFF182019),
    ink: Color(0xFFE7EFE9),
    inkMuted: Color(0xFF93A79A),
    border: Color(0xFF2A362E),
    iconMuted: Color(0xFF6B7A70),
    accent: Color(0xFF4CBF7D),
    accentDark: Color(0xFF8FE0AE),
    accentMuted: Color(0xFF6FA080),
    accentSurface: Color(0xFF16301F),
    warning: Color(0xFFE0A857),
    warningDark: Color(0xFFF0C98A),
    warningSurface: Color(0xFF3A2A12),
    danger: Color(0xFFE0897B),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? ink,
    Color? inkMuted,
    Color? border,
    Color? iconMuted,
    Color? accent,
    Color? accentDark,
    Color? accentMuted,
    Color? accentSurface,
    Color? warning,
    Color? warningDark,
    Color? warningSurface,
    Color? danger,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      border: border ?? this.border,
      iconMuted: iconMuted ?? this.iconMuted,
      accent: accent ?? this.accent,
      accentDark: accentDark ?? this.accentDark,
      accentMuted: accentMuted ?? this.accentMuted,
      accentSurface: accentSurface ?? this.accentSurface,
      warning: warning ?? this.warning,
      warningDark: warningDark ?? this.warningDark,
      warningSurface: warningSurface ?? this.warningSurface,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      iconMuted: Color.lerp(iconMuted, other.iconMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentDark: Color.lerp(accentDark, other.accentDark, t)!,
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t)!,
      accentSurface: Color.lerp(accentSurface, other.accentSurface, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningDark: Color.lerp(warningDark, other.warningDark, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
