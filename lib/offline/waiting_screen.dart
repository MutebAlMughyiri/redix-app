import 'package:flutter/material.dart';

import '../format/date_format.dart';
import '../format/number_format.dart';
import '../ui/confirm_dialog.dart';
import '../words/words.dart';
import 'outbox.dart';
import 'pending_entry.dart';

/// What waits on this phone for the project (UC-029): an entry the network has not taken yet, or one the API refused, which waits for its author.
class WaitingScreen extends StatelessWidget {
  /// The entries of the project [projectId] in [outbox].
  const WaitingScreen({super.key, required this.projectId, required this.outbox});

  /// The address of the screen.
  static const path = '/projects/:projectId/waiting';

  /// The address of the screen for the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/waiting';

  /// The line saying nothing waits.
  static const emptyKey = Key('waiting.empty');

  /// The row of the entry [id].
  static Key rowKey(String id) => Key('waiting.row.$id');

  /// The line saying where the entry [id] stands.
  static Key stateKey(String id) => Key('waiting.state.$id');

  /// The button sending the refused entry [id] again.
  static Key sendAgainKey(String id) => Key('waiting.sendAgain.$id');

  /// The button sending the entry [id] though it repeats an invoice.
  static Key sendAnywayKey(String id) => Key('waiting.sendAnyway.$id');

  /// The button deleting the entry [id].
  static Key discardKey(String id) => Key('waiting.discard.$id');

  /// The project whose entries show.
  final String projectId;

  /// Where they wait.
  final Outbox outbox;

  void _askToDiscard(BuildContext context, PendingEntry entry) {
    final words = Words.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: words.offlineDiscardQuestion,
        subject: _titleOf(entry),
        explanation: words.offlineDiscardExplain,
        confirmLabel: words.offlineDiscard,
        onConfirm: () => outbox.discard(entry),
      ),
    );
  }

  String _titleOf(PendingEntry entry) {
    final date = DateTime.tryParse(entry.date);
    return [if (date != null) formatDate(date), formatMoney(entry.amount.toDouble())].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(words.offlineTitle)),
      body: ListenableBuilder(
        listenable: outbox,
        builder: (context, _) {
          final entries = outbox.of(projectId);
          if (entries.isEmpty) {
            return Center(child: Text(words.offlineEmpty, key: emptyKey));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final entry in entries)
                Card.outlined(
                  key: rowKey(entry.id),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_titleOf(entry), style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          entry.isRefused ? words.text(entry.refusal) : words.offlineWaiting,
                          key: stateKey(entry.id),
                          style: TextStyle(color: entry.isRefused ? Theme.of(context).colorScheme.error : null),
                        ),
                        Wrap(
                          alignment: WrapAlignment.end,
                          children: [
                            if (entry.refusal == 'expenses.duplicateInvoice')
                              TextButton(key: sendAnywayKey(entry.id), onPressed: () => outbox.sendAgain(entry, confirmDuplicate: true), child: Text(words.offlineSendAnyway))
                            else if (entry.isRefused)
                              TextButton(key: sendAgainKey(entry.id), onPressed: () => outbox.sendAgain(entry), child: Text(words.offlineSendAgain)),
                            TextButton(key: discardKey(entry.id), onPressed: () => _askToDiscard(context, entry), child: Text(words.offlineDiscard)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
