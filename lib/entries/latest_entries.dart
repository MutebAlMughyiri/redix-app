// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../projects/project.dart';
import '../ui/part_keys.dart';
import '../ui/messages.dart';
import '../words/words.dart';
import 'entries_screen.dart';
import 'entry_card.dart';
import 'newest_entries.dart';
import '../ui/row_stripe.dart';

/// The project's entries on its home (UC-037, redix-app #84): the newest by anyone, as many at a time as this phone shows, a spinner while they are first read, a search beside the
/// heading, and Show more for as many again (redix-app #105). It counts nothing: each row says where it stands (Muteb, 7 Nov 2026).
class LatestEntries extends StatelessWidget {
  /// The entries of [project], in [entries], calling [onOpen] with the route of what is tapped, so the home reads its figures again on coming back, and [onRemoved] once a swipe removes one (findings row 189).
  const LatestEntries({super.key, required this.project, required this.entries, required this.onOpen, required this.onRemoved});

  /// The project.
  final Project project;

  /// Its newest entries.
  final NewestEntries entries;

  /// Opens a route of the project through the home.
  final ValueChanged<String> onOpen;

  /// Reads again the figures a removal changes.
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ListenableBuilder(
      listenable: entries,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(child: Text(words.entriesTitle, key: HomeScreen.entriesHeadingKey(project.id), style: Theme.of(context).textTheme.titleMedium)),
                  IconButton(
                    key: HomeScreen.searchEntriesKey(project.id),
                    icon: Icon(Icons.search, key: HomeScreen.searchEntriesKey(project.id).icon),
                    tooltip: words.entriesSearch,
                    onPressed: () => onOpen(EntriesScreen.searchPathOf(project.id)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            if (entries.isLoading && entries.all.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(key: HomeScreen.entriesLoadingKey)),
              ),
            if (!entries.isLoading && entries.all.isEmpty) Text(entries.message.isEmpty ? words.entriesEmpty : words.text(entries.message), key: HomeScreen.entriesEmptyKey(project.id)),
            for (final (index, entry) in entries.all.indexed)
              RowStripe(index: index, child: SwipeableEntryCard(project: project, entries: entries, entry: entry, onOpen: onOpen, onRemoved: onRemoved)),
            if (entries.mayHaveMore)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  key: HomeScreen.moreEntriesKey(project.id),
                  onPressed: () => showRefusalOf(context, entries.showMore()),
                  child: Text(words.entriesShowMore, key: HomeScreen.moreEntriesKey(project.id).label),
                ),
              ),
          ],
        );
      },
    );
  }
}
