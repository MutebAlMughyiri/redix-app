// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../projects/members.dart';
import '../projects/project.dart';
import '../ui/screen_title.dart';
import '../ui/search_scope.dart';
import '../words/words.dart';
import 'history_view.dart';
import 'project_history.dart';

/// «سجل المشروع», from Project settings (redix-api #86): every action in the project, one line each, newest first, a page at a time, each only for whoever may see its
/// record; every kind or one, everyone's lines or one person's. Every history looks the same (redix-app #101).
class ProjectHistoryScreen extends StatefulWidget {
  /// The [history] of [project], filtered by its [members].
  const ProjectHistoryScreen({super.key, required this.project, required this.history, required this.members});

  /// The project.
  final Project project;

  /// Its history.
  final ProjectHistory history;

  /// Its people, one filter each.
  final Members members;

  /// The screen's route.
  static const path = '/projects/:projectId/history';

  /// The route of the history of the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/history';

  /// The chip opening the list of kinds, under the search line.
  static const kindChoiceKey = Key('projectHistory.kindChoice');

  /// Every kind, in that list.
  static const allKey = Key('projectHistory.all');

  /// The kind [id] alone, in that list.
  static Key kindKey(String id) => Key('projectHistory.kind.$id');

  /// The chip opening the list of people, under the search line.
  static const personChoiceKey = Key('projectHistory.personChoice');

  /// The person [id] alone in that list; everyone for empty.
  static Key personKey(String id) => Key('projectHistory.person.$id');

  /// The line [id].
  static Key lineKey(int id) => Key('projectHistory.line.$id');

  /// The button reading the next page.
  static const moreKey = Key('projectHistory.more');

  @override
  State<ProjectHistoryScreen> createState() => _ProjectHistoryScreenState();
}

class _ProjectHistoryScreenState extends State<ProjectHistoryScreen> {
  @override
  void initState() {
    super.initState();
    widget.history.open();
    widget.members.loadOnOpen();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final history = widget.history;
    return SearchScope(
      onTyped: history.search,
      child: Scaffold(
        appBar: AppBar(
          title: ScreenTitle(words.historyProjectTitle, subject: widget.project.name),
          actions: [ListenableBuilder(listenable: history, builder: (context, _) => SearchIcons.andFilters(filtersInUse: history.isFiltered))],
        ),
        body: ListenableBuilder(
          listenable: Listenable.merge([history, widget.members]),
          builder: (context, _) => HistoryView(
            history: history,
            title: words.historyProjectTitle,
            choiceLabel: words.historyKind,
            choices: [for (final area in HistoryArea.inAProject) (area.name, words.text(area.wordKey))],
            people: [for (final member in widget.members.all) (member.id, member.displayName)],
            choiceChipKey: ProjectHistoryScreen.kindChoiceKey,
            allKey: ProjectHistoryScreen.allKey,
            choiceKey: ProjectHistoryScreen.kindKey,
            personChipKey: ProjectHistoryScreen.personChoiceKey,
            personKey: ProjectHistoryScreen.personKey,
            lineKey: ProjectHistoryScreen.lineKey,
            moreKey: ProjectHistoryScreen.moreKey,
          ),
        ),
      ),
    );
  }
}
