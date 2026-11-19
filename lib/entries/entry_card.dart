// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../format/date_format.dart';
import '../format/number_format.dart';
import '../format/parts_line.dart';
import '../projects/project.dart';
import '../ui/part_keys.dart';
import '../ui/swipe_to_remove.dart';
import '../words/word_fill.dart';
import '../words/words.dart';
import 'entries_screen.dart';
import 'entry_row.dart';
import 'project_entries.dart';

/// An entry on a list of [project]'s [entries], framed in its status's color: tapping it opens it read only (redix-app #90), and swiping it removes it where the user may delete it (redix-api #102).
class SwipeableEntryCard extends StatelessWidget {
  /// The tile of [entry], one of [project]'s [entries], calling [onOpen] with the route that opens it and [onRemoved] once a swipe has removed it.
  const SwipeableEntryCard({super.key, required this.project, required this.entries, required this.entry, required this.onOpen, this.onRemoved = _nothing});

  /// The project.
  final Project project;

  /// Its entries.
  final ProjectEntries entries;

  /// The entry.
  final EntryRow entry;

  /// Opens a route of the project, so the screen it is on reads again what the entry changed once it comes back.
  final ValueChanged<String> onOpen;

  /// Called once a swipe has removed it; nothing unless the screen shows figures a removal changes.
  final VoidCallback onRemoved;

  static void _nothing() {}

  /// Waits for [change], a removal or its undo, and tells [onRemoved] once it is made, so a screen showing figures reads them again.
  Future<String> _changed(Future<String> change) async {
    final refusal = await change;
    if (refusal.isEmpty) {
      onRemoved();
    }
    return refusal;
  }

  @override
  Widget build(BuildContext context) => SwipeToRemove(
    rowKey: EntriesScreen.rowKey(entry.id),
    mayRemove: entry.mayRemoveIn(project),
    onRemove: () => _changed(entries.delete(entry)),
    onUndo: entry.isApproved ? () => _changed(entries.restore(entry)) : SwipeToRemove.noUndo,
    side: entry.status.sideIn(context),
    child: EntryCard(entry: entry, onTap: () => onOpen(EntriesScreen.entryPathOf(project.id, entry))),
  );
}

/// An entry on a list: what it was for, how much, and who entered it when someone else did, its details line led by its «رقم القيد» (redix-api #128, D5). Where it stands is its
/// frame's color alone; its page says the rest, a rejection's reason included (the owner, 9 Nov 2026).
class EntryCard extends StatelessWidget {
  /// The tile of [entry], calling [onTap], marked as the one chosen when [isChosen], as the share screen marks where a file goes (redix-app #115).
  const EntryCard({super.key, required this.entry, required this.onTap, this.isChosen = false});

  /// The entry.
  final EntryRow entry;

  /// Called when it is tapped.
  final VoidCallback onTap;

  /// True for the entry chosen, which the tile shows selected.
  final bool isChosen;

  /// The card's line under [entry]'s title, in [words]: its number, what it is unless an expense, its supplier, its date, and who entered it when someone else did. The
  /// home-screen widget's rows read it too, so a row says what the card says (redix-app #86 D9).
  static String detailsOf(EntryRow entry, Words words) =>
      partsLine([entry.numberIn(words), if (!entry.isExpense) words.text(entry.kind.wordKey), entry.supplierName, formatDate(entry.date), if (!entry.isMine) words.entriesEnteredBy.fill([entry.authorName])]);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      key: EntriesScreen.rowKey(entry.id),
      onTap: onTap,
      selected: isChosen,
      title: Text(entry.title, key: EntriesScreen.rowKey(entry.id).title),
      subtitle: Text(detailsOf(entry, Words.of(context)), key: EntriesScreen.detailsKey(entry.id)),
      trailing: Text(formatMoney(entry.amount), key: EntriesScreen.rowKey(entry.id).trailing, style: theme.textTheme.titleSmall),
    );
  }
}
