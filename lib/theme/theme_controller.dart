import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// A plain top-level singleton, not threaded through every screen's
// constructor -- mirrors how `rootScaffoldMessengerKey` in main.dart is
// already a global rather than a parameter every screen has to carry.
// ValueNotifier so the root MaterialApp can listen for a toggle and
// rebuild with the new ThemeMode without any other package (this app
// doesn't use provider/riverpod elsewhere, so adding one just for this
// would be a bigger change than the feature itself).
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.light) {
    _restore();
  }

  static const _storage = FlutterSecureStorage();
  static const _key = 'dark_mode_enabled';

  // _restore() runs unawaited from the constructor, so it's still in
  // flight for a moment after app launch. Without this flag, a rider who
  // toggles Settings in that window would have their explicit choice
  // silently overwritten the instant the slower _restore() call finally
  // resolves. Once a real toggle happens, the stored value has already
  // done its one job (picking the launch-time default) and should never
  // overwrite anything again.
  bool _userHasChosen = false;

  bool get isDark => value == ThemeMode.dark;

  // Same defensive shape as ApiService.tryRestoreSession(): a missing
  // platform channel (tests) or a slow keystore (a real device right after
  // boot) should never stop the app from rendering -- it just falls back
  // to light mode instead of hanging or crashing.
  Future<void> _restore() async {
    try {
      final stored =
          await _storage.read(key: _key).timeout(const Duration(seconds: 3));
      if (_userHasChosen) return;
      value = stored == 'true' ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      if (_userHasChosen) return;
      value = ThemeMode.light;
    }
  }

  Future<void> setDark(bool enabled) async {
    _userHasChosen = true;
    value = enabled ? ThemeMode.dark : ThemeMode.light;
    try {
      await _storage
          .write(key: _key, value: enabled.toString())
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // The toggle still works for the rest of this session even if it
      // can't be persisted -- same trade-off tryRestoreSession() makes.
    }
  }
}

final themeController = ThemeController();
