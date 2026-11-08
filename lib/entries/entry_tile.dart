import 'package:flutter/material.dart';

import '../format/date_format.dart';
import '../format/number_format.dart';
import '../auth/permission.dart';
import '../projects/project.dart';
import '../ui/part_keys.dart';
import '../ui/swipe_to_remove.dart';
import '../words/words.dart';
import 'entries_screen.dart';
import 'entry_row.dart';
import 'project_entries.dart';
import '../attachments/invoice_capture.dart';

/// An entry on a list of [project]'s [entries]: tapping it opens its actions, and swiping it removes it where the user may delete it (redix-api #102).
class EntryListTile extends StatelessWidget {
  /// The tile of [entry], one of [project]'s [entries], shared through [capture].
  const EntryListTile({super.key, required this.project, required this.entries, required this.entry, required this.capture});

  /// The phone's share sheet.
  final InvoiceCapture capture;

  /// The project.
  final Project project;

  /// Its entries.
  final ProjectEntries entries;

  /// The entry.
  final EntryRow entry;

  @override
  Widget build(BuildContext context) => SwipeToRemove(
    rowKey: EntriesScreen.rowKey(entry.id),
    mayRemove: entry.allows(project, Permission.deleteEntries),
    onRemove: () => entries.delete(entry),
    child: EntryTile(entry: entry, onTap: () => EntriesScreen.openActions(context, project, entries, entry, capture)),
  );
}

/// An entry on a list: what it was for, how much, who entered it when someone else did, and where it stands unless approved, with why it was rejected.
class EntryTile extends StatelessWidget {
  /// The tile of [entry], calling [onTap].
  const EntryTile({super.key, required this.entry, required this.onTap});

  /// The entry.
  final EntryRow entry;

  /// Called when it is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    return ListTile(
      key: EntriesScreen.rowKey(entry.id),
      onTap: onTap,
      title: Text(entry.title, key: EntriesScreen.rowKey(entry.id).title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text([if (!entry.isExpense) words.text(entry.kind.wordKey), if (entry.supplierName.isNotEmpty) entry.supplierName, formatDate(entry.date), if (!entry.isMine) words.entriesEnteredBy.replaceFirst('{0}', entry.authorName)].join(' · '), key: EntriesScreen.detailsKey(entry.id)),
          if (entry.showsStatus) Text(words.text(entry.statusWordKey), key: EntriesScreen.statusKey(entry.id), style: TextStyle(color: entry.isRejected ? theme.colorScheme.error : null)),
          if (entry.isRejected) Text('${words.entriesReason}: ${entry.rejectionReason}', key: EntriesScreen.reasonKey(entry.id), style: TextStyle(color: theme.colorScheme.error)),
        ],
      ),
      trailing: Text(formatMoney(entry.amount), key: EntriesScreen.rowKey(entry.id).trailing, style: theme.textTheme.titleSmall),
    );
  }
}
