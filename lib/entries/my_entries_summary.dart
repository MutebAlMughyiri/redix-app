import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../home/home_screen.dart';
import '../projects/project.dart';
import '../words/words.dart';
import 'entries_screen.dart';
import 'entry_tile.dart';
import 'project_entries.dart';

/// What the signed-in user entered, on the project's home (UC-037): how many wait and how many were rejected, and the latest with where each stands.
class MyEntriesSummary extends StatelessWidget {
  /// The summary of [entries] in [project].
  const MyEntriesSummary({super.key, required this.project, required this.entries});

  /// How many of the latest show.
  static const latest = 3;

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
        final waiting = mine.where((entry) => entry.isPending).length;
        final rejected = mine.where((entry) => entry.isRejected).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (mine.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(words.entriesLatest, style: Theme.of(context).textTheme.titleMedium),
              ),
              Wrap(
                spacing: 8,
                children: [
                  Chip(key: HomeScreen.waitingCountKey(project.id), label: Text('${words.entriesPendingApproval} · $waiting')),
                  Chip(key: HomeScreen.rejectedCountKey(project.id), label: Text('${words.entriesRejected} · $rejected')),
                ],
              ),
              const SizedBox(height: 4),
              for (final entry in mine.take(latest)) EntryTile(entry: entry, onTap: () => EntriesScreen.openActions(context, project, entries, entry)),
            ],
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
