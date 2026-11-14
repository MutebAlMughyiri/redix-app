/// REDIX outside the app (redix-app #86): «إضافة قيد» on the icon's menu and on the home-screen widget. Every tap opens [path], which the router lands as the session
/// allows (R7).
class LauncherAddEntry {
  /// What reaches the icon's menu and the home-screen widget.
  const LauncherAddEntry();

  /// The one link «إضافة قيد» outside the app opens, for the icon, the widget and any later link (redix-app #86, the rule, R7).
  static const path = '/add-entry';
}
