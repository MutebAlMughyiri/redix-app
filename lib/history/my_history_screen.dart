// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../ui/screen_title.dart';
import '../ui/search_scope.dart';
import '../words/words.dart';
import 'history_view.dart';
import 'my_history.dart';
import 'project_history.dart';

/// «سجلي», from Shared settings (redix-api #86, R9): every line of one's own login, whoever wrote it, newest first, a page at a time; every kind or one, and everything
/// or only what one did oneself. It belongs to no project, so its people are everyone and «أنا».
class MyHistoryScreen extends StatefulWidget {
  /// The [history] of the login of the person called [name].
  const MyHistoryScreen({super.key, required this.history, required this.name});

  /// The signed-in user's history.
  final MyHistory history;

  /// The signed-in user's name.
  final String name;

  /// The screen's route.
  static const path = '/me/history';

  /// The chip opening the list of kinds, under the search line.
  static const kindChoiceKey = Key('myHistory.kindChoice');

  /// Every kind, in that list.
  static const allKey = Key('myHistory.all');

  /// The kind [id] alone, in that list.
  static Key kindKey(String id) => Key('myHistory.kind.$id');

  /// The chip opening the list of people, under the search line.
  static const personChoiceKey = Key('myHistory.personChoice');

  /// The person [id] alone in that list; everyone for empty.
  static Key personKey(String id) => Key('myHistory.person.$id');

  /// The line [id].
  static Key lineKey(int id) => Key('myHistory.line.$id');

  /// The button reading the next page.
  static const moreKey = Key('myHistory.more');

  @override
  State<MyHistoryScreen> createState() => _MyHistoryScreenState();
}

class _MyHistoryScreenState extends State<MyHistoryScreen> {
  @override
  void initState() {
    super.initState();
    widget.history.open();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final history = widget.history;
    return SearchScope(
      onTyped: history.search,
      child: Scaffold(
        appBar: AppBar(
          title: ScreenTitle(words.historyMyTitle, subject: widget.name),
          actions: [ListenableBuilder(listenable: history, builder: (context, _) => SearchIcons.andFilters(filtersInUse: history.isFiltered))],
        ),
        body: ListenableBuilder(
          listenable: history,
          builder: (context, _) => HistoryView(
            history: history,
            title: words.historyMyTitle,
            choiceLabel: words.historyKind,
            choices: [for (final area in HistoryArea.ofALogin) (area.name, words.text(area.wordKey))],
            people: const [],
            choiceChipKey: MyHistoryScreen.kindChoiceKey,
            allKey: MyHistoryScreen.allKey,
            choiceKey: MyHistoryScreen.kindKey,
            personChipKey: MyHistoryScreen.personChoiceKey,
            personKey: MyHistoryScreen.personKey,
            lineKey: MyHistoryScreen.lineKey,
            moreKey: MyHistoryScreen.moreKey,
          ),
        ),
      ),
    );
  }
}
