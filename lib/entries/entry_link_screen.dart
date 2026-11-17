import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

import '../approvals/approvals_screen.dart';
import '../home/home_screen.dart';
import '../projects/projects.dart';
import '../words/words.dart';
import 'entries_screen.dart';
import 'project_entries.dart';
import 'entry_row.dart';
import '../ui/load_failure.dart';
import '../ui/screen_message.dart';

/// Where a shared entry's link lands (redix-app #83): the one place that decides, from what the reader may do now, where the entry opens. Waiting, for whoever may decide it, in
/// Approvals on that entry alone (R7); otherwise on its sheet in القيود, saying where it stands (R8); not found when the reader's lists do not hold it (R9), and why with a way to try
/// again when they could not be read.
class EntryLinkScreen extends StatefulWidget {
  /// The landing of the entry [entryId] of the project [projectId], among [projects], its entries read through [entriesOf].
  const EntryLinkScreen({super.key, required this.projectId, required this.entryId, required this.projects, required this.entriesOf});

  /// The screen's route, the path a shared link names.
  static const path = '/projects/:projectId/entries/:entryId/open';

  /// The route of the entry [entryId] of the project [projectId].
  static String pathOf(String projectId, String entryId) => '/projects/$projectId/entries/$entryId/open';

  /// True when [location] is a shared entry's link, which sign-in opens once signed in (R8).
  static bool isLink(String location) => RegExp(r'^/projects/[^/]+/entries/[^/]+/open$').hasMatch(location);

  /// The line saying the entry cannot be found.
  static const notFoundKey = Key('entryLink.notFound');

  /// The spinner while the entry is looked for.
  static const loadingKey = Key('entryLink.loading');

  /// The project.
  final String projectId;

  /// The entry.
  final String entryId;

  /// The signed-in user's projects.
  final Projects projects;

  /// A project's entries.
  final ProjectEntries Function(String projectId) entriesOf;

  @override
  State<EntryLinkScreen> createState() => _EntryLinkScreenState();
}

class _EntryLinkScreenState extends State<EntryLinkScreen> {
  var _isNotFound = false;
  var _failure = '';

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) => _land());
  }

  Future<void> _land() async {
    await widget.projects.load();
    final project = widget.projects.byId(widget.projectId);
    final entries = widget.entriesOf(widget.projectId);
    if (!project.isNone) {
      await entries.load();
    }
    final found = project.isNone ? <EntryRow>[] : entries.all.where((entry) => entry.id == widget.entryId).toList();
    if (!mounted) {
      return;
    }
    final failure = widget.projects.message.isNotEmpty ? widget.projects.message : entries.message;
    if (failure.isNotEmpty) {
      setState(() => _failure = failure);
      return;
    }
    if (found.isEmpty) {
      setState(() => _isNotFound = true);
      return;
    }
    final router = GoRouter.of(context);
    router.go(HomeScreen.pathOf(project.id));
    unawaited(router.push(found.single.isPending && project.mayApproveEntries ? ApprovalsScreen.pathOfEntry(project.id, widget.entryId) : EntriesScreen.pathOfEntry(project.id, widget.entryId), extra: project));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: _failure.isNotEmpty
        ? LoadFailure(
            message: _failure,
            onRetry: () {
              setState(() => _failure = '');
              _land();
            },
          )
        : _isNotFound
        ? ScreenMessage(Words.of(context).entriesNotFound, textKey: EntryLinkScreen.notFoundKey)
        : const Center(child: CircularProgressIndicator(key: EntryLinkScreen.loadingKey)),
  );
}
