import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../home/home_screen.dart';
import '../projects/project.dart';
import '../words/words.dart';
import 'entries_screen.dart';
import 'entry_tile.dart';
import 'project_entries.dart';

/// The project's entries on its home (UC-037, redix-app #84): the latest five by anyone, how many of the user's own wait and were rejected, a search beside the heading, and the
/// way to all of them.
class HomeEntries extends StatelessWidget {
  /// The entries of [project], in [entries].
  const HomeEntries({super.key, required this.project, required this.entries});

  /// How many of the latest show.
  static const latest = 5;

  /// The project.
  final Project project;

  /// Its entries.
  final ProjectEntries entries;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ListenableBuilder(
      listenable: entries,
      builder: (context, _) {
        final mine = entries.mine;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(child: Text(words.entriesTitle, style: Theme.of(context).textTheme.titleMedium)),
                  IconButton(
                    key: HomeScreen.searchEntriesKey(project.id),
                    icon: const Icon(Icons.search),
                    tooltip: words.entriesSearch,
                    onPressed: () => context.push(EntriesScreen.searchPathOf(project.id), extra: project),
                  ),
                ],
              ),
            ),
            if (mine.isNotEmpty)
              Wrap(
                spacing: 8,
                children: [
                  Chip(key: HomeScreen.waitingCountKey(project.id), label: Text('${words.entriesPendingApproval} · ${mine.where((entry) => entry.isPending).length}')),
                  Chip(key: HomeScreen.rejectedCountKey(project.id), label: Text('${words.entriesRejected} · ${mine.where((entry) => entry.isRejected).length}')),
                ],
              ),
            const SizedBox(height: 4),
            if (!entries.isLoading && entries.all.isEmpty) Text(words.entriesEmpty),
            for (final entry in entries.all.take(latest)) EntryTile(entry: entry, onTap: () => EntriesScreen.openActions(context, project, entries, entry)),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                key: HomeScreen.entriesKey(project.id),
                onPressed: () => context.push(EntriesScreen.pathOf(project.id), extra: project),
                child: Text(words.entriesSeeAll),
              ),
            ),
          ],
        );
      },
    );
  }
}
