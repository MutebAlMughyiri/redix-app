import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What this phone keeps of its own choices (redix-app #91), each one key in the phone's key-value storage, which is read once at start. Every later choice is one more key here, and a switch is 1 or 0.
/// It tells its listeners when the appearance changes, so the whole app redraws at once (redix-app #87, #97).
class LocalConfig extends ChangeNotifier {
  static const _expanded = 1;
  static const _collapsed = 0;
  static const _homeDetailsKey = 'summary_projectSetting_state';

  /// The appearances in the order of the numbers kept: 0 light, 1 dark and 2 the phone's (redix-app #97).
  static const _themeModes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];
  static const _themeModeKey = 'themeMode_state';

  /// How many entries the home may show at a time (redix-app #105): any number from 5 to 20, the first until one is chosen.
  static const entriesShownChoices = [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];
  static const _entriesShownKey = 'entriesShown_count';

  var _homeDetails = _expanded;
  var _themeMode = ThemeMode.system;
  var _entriesShown = entriesShownChoices.first;

  /// Reads what was kept before the first frame, so the home never flashes open and the app never flashes light. A key not found yet is set to its default and kept.
  /// A number no build kept reads as the phone's appearance, or as the fewest entries shown.
  Future<void> restore() async {
    final preferences = await SharedPreferences.getInstance();
    _homeDetails = await preferences.restoreOrDefault(_homeDetailsKey, _expanded);
    final kept = await preferences.restoreOrDefault(_themeModeKey, _themeModes.indexOf(ThemeMode.system));
    _themeMode = _themeModes.asMap()[kept] ?? ThemeMode.system;
    final shown = await preferences.restoreOrDefault(_entriesShownKey, entriesShownChoices.first);
    _entriesShown = entriesShownChoices.contains(shown) ? shown : entriesShownChoices.first;
  }

  /// True while the home shows the conclusion and the project's buttons.
  bool get showsHomeDetails => _homeDetails == _expanded;

  /// Collapses the home, or expands it, and keeps that for the next start.
  Future<void> toggleHomeDetails() async {
    _homeDetails = showsHomeDetails ? _collapsed : _expanded;
    await (await SharedPreferences.getInstance()).setInt(_homeDetailsKey, _homeDetails);
  }

  /// The appearance the app is drawn in: light, dark, or the phone's, which Flutter follows by itself.
  ThemeMode get themeMode => _themeMode;

  /// Draws every screen in [mode] at once, and keeps it for the next start.
  Future<void> chooseThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setInt(_themeModeKey, _themeModes.indexOf(mode));
  }

  /// How many entries the home shows at first, and how many each Show more adds (redix-app #105).
  int get entriesShown => _entriesShown;

  /// Shows [count] entries at a time, one of [entriesShownChoices], and keeps it for the next start.
  Future<void> chooseEntriesShown(int count) async {
    _entriesShown = count;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setInt(_entriesShownKey, count);
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
