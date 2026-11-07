import 'package:flutter/material.dart';

import '../format/date_format.dart';
import '../format/number_format.dart';
import '../ui/part_keys.dart';
import '../words/words.dart';
import 'entries_screen.dart';
import 'entry_row.dart';

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
    return Card.outlined(
      key: EntriesScreen.rowKey(entry.id).card,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        key: EntriesScreen.rowKey(entry.id),
        onTap: onTap,
        title: Text(entry.itemName, key: EntriesScreen.rowKey(entry.id).title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text([if (entry.supplierName.isNotEmpty) entry.supplierName, formatDate(entry.date), if (!entry.isMine) words.entriesEnteredBy.replaceFirst('{0}', entry.authorName)].join(' · '), key: EntriesScreen.detailsKey(entry.id)),
            if (entry.showsStatus) Text(words.text(entry.statusWordKey), key: EntriesScreen.statusKey(entry.id), style: TextStyle(color: entry.isRejected ? theme.colorScheme.error : null)),
            if (entry.isRejected) Text('${words.entriesReason}: ${entry.rejectionReason}', key: EntriesScreen.reasonKey(entry.id), style: TextStyle(color: theme.colorScheme.error)),
          ],
        ),
        trailing: Text(formatMoney(entry.amount), key: EntriesScreen.rowKey(entry.id).trailing, style: theme.textTheme.titleSmall),
      ),
    );
  }
}
