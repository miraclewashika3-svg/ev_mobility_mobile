import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ev_mobility_mobile/theme/app_colors.dart';
import 'package:ev_mobility_mobile/theme/app_theme.dart';
import 'package:ev_mobility_mobile/theme/theme_controller.dart';

// Deliberately doesn't pump the full EvMobilityApp: that would go through
// tryRestoreSession()'s secure-storage read, which this codebase already
// has a known flakiness note about ("session-restore read() hangs on
// emulator, unresolved" -- see git history). Testing the theme pieces in
// isolation gets the same confidence without that risk.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppTheme.light and AppTheme.dark carry distinct, matching AppColors', () {
    final lightColors = AppTheme.light.extension<AppColors>();
    final darkColors = AppTheme.dark.extension<AppColors>();

    expect(lightColors, isNotNull);
    expect(darkColors, isNotNull);
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(lightColors!.background, AppColors.light.background);
    expect(darkColors!.background, AppColors.dark.background);
    expect(lightColors.background, isNot(darkColors.background));
  });

  test('ThemeController.setDark flips value and persists the choice', () async {
    final controller = ThemeController();

    await controller.setDark(true);
    expect(controller.value, ThemeMode.dark);
    expect(controller.isDark, isTrue);

    await controller.setDark(false);
    expect(controller.value, ThemeMode.light);
    expect(controller.isDark, isFalse);
  });
}
