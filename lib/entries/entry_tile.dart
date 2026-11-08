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

/// An entry on a list of [project]'s [entries], framed in its status's color: tapping it opens it read only (redix-app #90), and swiping it removes it where the user may delete it (redix-api #102).
class EntryListTile extends StatelessWidget {
  /// The tile of [entry], one of [project]'s [entries].
  const EntryListTile({super.key, required this.project, required this.entries, required this.entry});

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
    side: entry.status.sideIn(context),
    child: EntryTile(entry: entry, onTap: () => EntriesScreen.openEntry(context, project, entry)),
  );
}

/// An entry on a list: what it was for, how much, and who entered it when someone else did. Where it stands is its frame's color alone; its page says the rest, a rejection's reason included (Muteb, 9 Nov 2026).
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
      subtitle: Text(
        [if (!entry.isExpense) words.text(entry.kind.wordKey), if (entry.supplierName.isNotEmpty) entry.supplierName, formatDate(entry.date), if (!entry.isMine) words.entriesEnteredBy.replaceFirst('{0}', entry.authorName)].join(' · '),
        key: EntriesScreen.detailsKey(entry.id),
      ),
      trailing: Text(formatMoney(entry.amount), key: EntriesScreen.rowKey(entry.id).trailing, style: theme.textTheme.titleSmall),
    );
  }
}
