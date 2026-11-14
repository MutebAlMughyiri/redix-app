import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quick_actions/quick_actions.dart';

import '../api.dart';
import '../entries/entry_card.dart';
import '../entries/entry_row.dart';
import '../entries/entry_share.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../words/words.dart';

/// REDIX outside the app (redix-app #86): «إضافة قيد» on the icon's menu, through Flutter's `quick_actions` (D4), and on the home-screen widget, through `home_widget`
/// (D5), with the latest entries under the widget's button (D8). The one owner of what the launcher shows: its words are the app's (R5), and every tap opens [path], which
/// the router lands as the session allows (R7). A phone with no widget yet, the iPhone until D7, says why in the log and the app goes on.
class LauncherAddEntry {
  /// What reaches the icon's menu and the home-screen widget.
  const LauncherAddEntry();

  /// The one link «إضافة قيد» outside the app opens, for the icon, the widget and any later link (redix-app #86, the rule, R7).
  static const path = '/add-entry';

  /// What the widget's button says, saved for `AddEntryWidget.kt` to read (D5).
  static const widgetLabel = 'addEntryLabel';

  /// The link the widget's button opens, on the host of the environment the app was built for (D5).
  static const widgetLink = 'addEntryLink';

  /// The rows under the widget's button, as JSON: each entry's title, details and amount as its card says them, and its link (D8, D9).
  static const widgetEntries = 'addEntryEntries';

  /// When the rows were read (D8).
  static const widgetReadAt = 'addEntryReadAt';

  static const _shortcut = 'addEntry';
  static const _shortcutIcon = 'ic_add_entry';
  static const _widgetProvider = 'sa.redix.AddEntryWidget';

  /// Opens [path] through [open] when the icon's «إضافة قيد» is tapped, the tap that started the app included (R1, AC-86.1).
  Future<void> listen(ValueChanged<String> open) => _reach('The icon\'s menu', () => const QuickActions().initialize((_) => open(path)));

  /// Writes «إضافة قيد» in [words], the app's language, on the icon's menu and the widget's button, each time the words load (R5, AC-86.4). Nothing while the phone has no
  /// words yet.
  Future<void> showWords(Words words) async {
    if (words.isEmpty) {
      return;
    }
    await _reach('The icon\'s menu', () => const QuickActions().setShortcutItems([ShortcutItem(type: _shortcut, localizedTitle: words.entriesNew, icon: _shortcutIcon)]));
    await _save({widgetLabel: words.entriesNew, widgetLink: 'https://$linkHost$path'});
  }

  /// Lists [entries], the newest the home of the project [projectId] read, under the widget's button with when they were read: each row as its entry card says it in
  /// [words], and opening its entry's own link (R9, D8, D9, AC-86.7).
  Future<void> showEntries(String projectId, List<EntryRow> entries, Words words) {
    final readAt = DateTime.now();
    return _save({
      widgetEntries: jsonEncode([
        for (final entry in entries) {'title': entry.title, 'details': EntryCard.detailsOf(entry, words), 'amount': formatMoney(entry.amount), 'link': EntryShare.linkOf(projectId, entry)},
      ]),
      widgetReadAt: '${formatDate(readAt)} ${formatTime(readAt)}',
    });
  }

  /// Empties the widget's rows once the session ends, so the home screen, which anyone holding the phone sees, shows the button alone (R10, D10, AC-86.8).
  Future<void> forgetEntries() => _save({widgetEntries: '[]', widgetReadAt: ''});

  Future<void> _save(Map<String, String> data) => _reach('The home-screen widget', () async {
    for (final MapEntry(:key, :value) in data.entries) {
      await HomeWidget.saveWidgetData(key, value);
    }
    await HomeWidget.updateWidget(qualifiedAndroidName: _widgetProvider);
  });

  /// Runs [change] on the launcher's side, naming [what] in the log when the phone cannot take it.
  static Future<void> _reach(String what, Future<void> Function() change) async {
    try {
      await change();
    } on Exception catch (error) {
      debugPrint('$what not reached: $error');
    }
  }
}
