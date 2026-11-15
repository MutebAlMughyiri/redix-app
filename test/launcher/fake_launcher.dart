import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/launcher/launcher_add_entry.dart';

/// The phone's launcher as the app's tests see it, through the channels `quick_actions` and `home_widget` speak on (redix-app #86): what the app wrote on the icon's
/// menu, what it saved for the home-screen widget, and the shortcut a start was asked from.
class FakeLauncher {
  /// A launcher whose start, when [startedFrom] is a shortcut's type, came from that shortcut; forgotten when the test ends.
  FakeLauncher({this.startedFrom = ''}) {
    _messenger.setMockMethodCallHandler(_shortcuts, (call) async {
      if (call.method == 'setShortcutItems') {
        shortcuts = [for (final item in call.arguments as List<Object?>) Map<String, Object?>.from(item! as Map)];
      }
      return call.method == 'getLaunchAction' && startedFrom.isNotEmpty ? startedFrom : null;
    });
    _messenger.setMockMethodCallHandler(_widget, (call) async {
      final arguments = Map<String, Object?>.from(call.arguments as Map);
      switch (call.method) {
        case 'saveWidgetData':
          saved[arguments['id']! as String] = arguments['data'];
        case 'updateWidget':
          updated.add(arguments['qualifiedAndroidName']! as String);
      }
      return true;
    });
    addTearDown(() {
      _messenger.setMockMethodCallHandler(_shortcuts, null);
      _messenger.setMockMethodCallHandler(_widget, null);
    });
  }

  static const _shortcuts = MethodChannel('plugins.flutter.io/quick_actions');
  static const _widget = MethodChannel('home_widget');
  static TestDefaultBinaryMessenger get _messenger => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// The shortcut type the app was started from; empty for a start from the icon itself.
  final String startedFrom;

  /// The icon's menu as the app last wrote it: each item's type, title and icon.
  var shortcuts = <Map<String, Object?>>[];

  /// What the app saved for the widget, by name.
  final saved = <String, Object?>{};

  /// The widget providers the app asked to draw again, in order.
  final updated = <String>[];

  /// The rows the widget lists under its button, as the app last saved them.
  List<Map<String, Object?>> get entries => [for (final row in jsonDecode(saved[LauncherAddEntry.widgetEntries] as String? ?? '[]') as List<Object?>) Map<String, Object?>.from(row! as Map)];

  /// Taps the icon's menu item of [type], with the app already running.
  Future<void> tapShortcut(String type) => _messenger.handlePlatformMessage(_shortcuts.name, _shortcuts.codec.encodeMethodCall(MethodCall('launch', type)), (_) {});
}
