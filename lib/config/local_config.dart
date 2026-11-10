import 'package:shared_preferences/shared_preferences.dart';

/// What this phone keeps of its own choices (redix-app #91), each one key in the phone's key-value storage, which is read once at start. Every later choice is one more key here, and a switch is 1 or 0.
class LocalConfig {
  static const _expanded = 1;
  static const _collapsed = 0;
  static const _homeDetailsKey = 'summary_projectSetting_state';

  var _homeDetails = _expanded;

  /// Reads what was kept before the first frame, so the home never flashes open. A key not found yet is set to its default and kept.
  Future<void> restore() async {
    final preferences = await SharedPreferences.getInstance();
    _homeDetails = preferences.getOrDefault(_homeDetailsKey, _expanded);
    if (!preferences.containsKey(_homeDetailsKey)) {
      await preferences.setInt(_homeDetailsKey, _homeDetails);
    }
  }

  /// True while the home shows the conclusion and the project's buttons.
  bool get showsHomeDetails => _homeDetails == _expanded;

  /// Collapses the home, or expands it, and keeps that for the next start.
  Future<void> toggleHomeDetails() async {
    _homeDetails = showsHomeDetails ? _collapsed : _expanded;
    await (await SharedPreferences.getInstance()).setInt(_homeDetailsKey, _homeDetails);
  }
}

extension on SharedPreferences {
  /// The number kept under [key], or [fallback] when none is, as .NET's GetValueOrDefault answers.
  int getOrDefault(String key, int fallback) => getInt(key) ?? fallback;
}
