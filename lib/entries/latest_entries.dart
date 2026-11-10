import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../projects/project.dart';
import '../ui/part_keys.dart';
import '../words/words.dart';
import 'entries_screen.dart';
import 'entry_card.dart';
import 'project_entries.dart';

/// The project's entries on its home (UC-037, redix-app #84): the latest five by anyone, a spinner while they are first read, a search beside the heading, and the way to all of
/// them. It counts nothing: each row says where it stands (Muteb, 7 Nov 2026).
class LatestEntries extends StatelessWidget {
  /// The entries of [project], in [entries], calling [onOpen] with the route of what is tapped, so the home reads its figures again on coming back, and [onRemoved] once a swipe removes one (findings row 189).
  const LatestEntries({super.key, required this.project, required this.entries, required this.onOpen, required this.onRemoved});

  /// How many of the latest show.
  static const latest = 5;

  /// The project.
  final Project project;

  /// Its entries.
  final ProjectEntries entries;

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
            for (final entry in entries.all.take(latest)) SwipeableEntryCard(project: project, entries: entries, entry: entry, onOpen: onOpen, onRemoved: onRemoved),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                key: HomeScreen.entriesKey(project.id),
                onPressed: () => onOpen(EntriesScreen.pathOf(project.id)),
                child: Text(words.entriesSeeAll, key: HomeScreen.entriesKey(project.id).label),
              ),
            ),
          ],
        );
      },
    );
  }
}
