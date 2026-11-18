// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../projects/members.dart';
import '../projects/project.dart';
import '../history/history_view.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import '../ui/search_scope.dart';
import 'account_history.dart';
import 'accounts.dart';

/// السجل, from Accounts' top bar (redix-app #89, R17): what was done to the project's accounts and what moved their money, newest first, a page at a time; every
/// account or one, everyone's lines or one person's. Each line says what, how much, which accounts, who and when.
class AccountHistoryScreen extends StatefulWidget {
  /// The [history] of [project]'s [accounts], filtered by its [members].
  const AccountHistoryScreen({super.key, required this.project, required this.history, required this.accounts, required this.members});

  /// The project.
  final Project project;

  /// Its account history.
  final AccountHistory history;

  /// Its accounts, one filter each.
  final Accounts accounts;

  /// Its people, one filter each.
  final Members members;

  /// The screen's route.
  static const path = '/projects/:projectId/accounts/history';

  /// The route of the account history of the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/accounts/history';

  /// The chip opening the list of accounts, under the search line.
  static const accountChoiceKey = Key('history.accountChoice');

  /// Every account, in that list.
  static const allKey = Key('history.all');

  /// The account [id] alone, in that list.
  static Key accountKey(String id) => Key('history.account.$id');

  /// The chip opening the list of people, under the search line.
  static const personChoiceKey = Key('history.personChoice');

  /// The person [id] alone in that list; everyone for empty.
  static Key personKey(String id) => Key('history.person.$id');

  /// The line [id].
  static Key lineKey(int id) => Key('history.line.$id');

  /// The button reading the next page.
  static const moreKey = Key('history.more');

  @override
  State<AccountHistoryScreen> createState() => _AccountHistoryScreenState();
}

class _AccountHistoryScreenState extends State<AccountHistoryScreen> {
  @override
  void initState() {
    super.initState();
    widget.history.open();
    widget.accounts.loadOnOpen();
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
          title: ScreenTitle(words.accountsHistory, subject: widget.project.name),
          actions: [ListenableBuilder(listenable: history, builder: (context, _) => SearchIcons.andFilters(filtersInUse: history.isFiltered))],
        ),
        body: ListenableBuilder(
          listenable: Listenable.merge([history, widget.accounts, widget.members]),
          builder: (context, _) => HistoryView(
            history: history,
            title: words.accountsHistory,
            choiceLabel: words.historyAccount,
            choices: [for (final account in widget.accounts.all) (account.id, account.name)],
            people: [for (final member in widget.members.all) (member.id, member.displayName)],
            choiceChipKey: AccountHistoryScreen.accountChoiceKey,
            allKey: AccountHistoryScreen.allKey,
            choiceKey: AccountHistoryScreen.accountKey,
            personChipKey: AccountHistoryScreen.personChoiceKey,
            personKey: AccountHistoryScreen.personKey,
            lineKey: AccountHistoryScreen.lineKey,
            moreKey: AccountHistoryScreen.moreKey,
          ),
        ),
      ),
    );
  }
}
