import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What this phone keeps of its own choices (redix-app #91), each one key in the phone's key-value storage, which is read once at start. Every later choice is one more key here, and a switch is 1 or 0.
/// It tells its listeners when the mode changes, so the whole app redraws at once (redix-app #87).
class LocalConfig extends ChangeNotifier {
  static const _expanded = 1;
  static const _collapsed = 0;
  static const _homeDetailsKey = 'summary_projectSetting_state';

  static const _light = 0;
  static const _dark = 1;
  static const _darkModeKey = 'darkMode_state';

  var _homeDetails = _expanded;
  var _darkMode = _light;

  /// Reads what was kept before the first frame, so the home never flashes open and the app never flashes light. A key not found yet is set to its default and kept.
  Future<void> restore() async {
    final preferences = await SharedPreferences.getInstance();
    _homeDetails = await preferences.restoreOrDefault(_homeDetailsKey, _expanded);
    _darkMode = await preferences.restoreOrDefault(_darkModeKey, _light);
  }

  /// True while the home shows the conclusion and the project's buttons.
  bool get showsHomeDetails => _homeDetails == _expanded;

  /// Collapses the home, or expands it, and keeps that for the next start.
  Future<void> toggleHomeDetails() async {
    _homeDetails = showsHomeDetails ? _collapsed : _expanded;
    await (await SharedPreferences.getInstance()).setInt(_homeDetailsKey, _homeDetails);
  }

  /// True while the app is in its dark mode.
  bool get isDark => _darkMode == _dark;

  /// Turns the dark mode on, or off, at once on every screen, and keeps that for the next start.
  Future<void> toggleDarkMode() async {
    _darkMode = isDark ? _light : _dark;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setInt(_darkModeKey, _darkMode);
  }
}

extension on SharedPreferences {
  /// The number kept under [key], or [fallback] when none is, as .NET's GetValueOrDefault answers.
  int getOrDefault(String key, int fallback) => getInt(key) ?? fallback;

  /// The number kept under [key]; when none is, [fallback], kept there from now on.
  Future<int> restoreOrDefault(String key, int fallback) async {
    final value = getOrDefault(key, fallback);
    if (!containsKey(key)) {
      await setInt(key, value);
    }
    return value;
  }
}
