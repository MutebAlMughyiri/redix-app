import 'package:flutter/material.dart';

import '../format/date_format.dart';
import '../format/number_format.dart';
import '../format/parts_line.dart';
import '../ui/act_once.dart';
import '../ui/app_color.dart';
import '../ui/bottom_button.dart';
import '../ui/part_keys.dart';
import '../ui/screen_title.dart';
import '../ui/swipe_to_remove.dart';
import '../words/words.dart';
import 'outbox.dart';
import 'pending_entry.dart';

/// What waits on this phone for the project (UC-029): an entry the network has not taken yet, or one the API refused, which waits for its author. Each row reads like the entry it
/// will become, across the screen: its table, amount, supplier, date and whether its bill waits too (redix-app #103); only a refused one says more, and why.
class WaitingScreen extends StatelessWidget {
  /// The entries of the project [projectId] in [outbox].
  const WaitingScreen({super.key, required this.projectId, required this.outbox});

  /// The address of the screen.
  static const path = '/projects/:projectId/waiting';

  /// The address of the screen for the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/waiting';

  /// The line saying nothing waits.
  static const emptyKey = Key('waiting.empty');

  /// The line saying they go by themselves when the network is back.
  static const autoSendKey = Key('waiting.autoSend');

  /// The button sending every waiting entry now.
  static const sendNowKey = Key('waiting.sendNow');

  /// The row of the entry [id].
  static Key rowKey(String id) => Key('waiting.row.$id');

  /// What the entry [id] is: its table, or its amount when nothing more was kept.
  static Key titleKey(String id) => Key('waiting.title.$id');

  /// The amount of the entry [id], beside its table.
  static Key amountKey(String id) => Key('waiting.amount.$id');

  /// The supplier, date and bill of the entry [id].
  static Key detailsKey(String id) => Key('waiting.details.$id');

  /// The line saying why the entry [id] was refused.
  static Key stateKey(String id) => Key('waiting.state.$id');

  /// The button sending the refused entry [id] again.
  static Key sendAgainKey(String id) => Key('waiting.sendAgain.$id');

  /// The project whose entries show.
  final String projectId;

  /// Where they wait.
  final Outbox outbox;

  Widget _row(BuildContext context, PendingEntry entry, Words words) {
    final amount = formatMoney(entry.amount.toDouble());
    final date = DateTime.tryParse(entry.date);
    return SwipeToRemove(
      rowKey: rowKey(entry.id),
      mayRemove: true,
      onRemove: () async {
        await outbox.discard(entry);
        return '';
      },
      child: ListTile(
        key: rowKey(entry.id),
        title: Text(entry.title.isEmpty ? amount : entry.title, key: titleKey(entry.id)),
        trailing: entry.title.isEmpty ? null : Text(amount, key: amountKey(entry.id), style: Theme.of(context).textTheme.titleSmall),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(partsLine([entry.details, if (date != null) formatDate(date), if (entry.hasFile) words.offlineWithFile]), key: detailsKey(entry.id)),
            if (entry.isRefused) ...[
              Text(words.text(entry.refusal), key: stateKey(entry.id), style: TextStyle(color: AppColor.refusal.of(context))),
              ActOnce(builder: (once) => TextButton(key: sendAgainKey(entry.id), onPressed: once(() => outbox.sendAgain(entry)), child: Text(words.offlineSendAgain, key: sendAgainKey(entry.id).label))),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ListenableBuilder(
      listenable: outbox,
      builder: (context, _) {
        final entries = outbox.of(projectId);
        return Scaffold(
          appBar: AppBar(title: Text(words.offlineTitle, key: ScreenTitle.titleKey)),
          bottomNavigationBar: BottomButton(buttonKey: sendNowKey, label: words.offlineSendNow, icon: Icons.sync, onPressed: entries.isEmpty ? null : outbox.send),
          body: entries.isEmpty
              ? Center(child: Text(words.offlineEmpty, key: emptyKey))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(words.offlineAutoSend, key: autoSendKey, style: Theme.of(context).textTheme.bodySmall),
                    ),
                    for (final entry in entries) _row(context, entry, words),
                  ],
                ),
        );
      },
    );
  }
}
