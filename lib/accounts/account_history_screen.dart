import 'package:flutter/material.dart';

import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/part_keys.dart';
import '../ui/refusal_snack_bar.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'account_history.dart';
import 'accounts.dart';

/// السجل, from Accounts' top bar (redix-app #89, R17): what was done to the project's accounts and what moved their money, newest first, a page at a time; every
/// account or one, everyone's lines or the signed-in user's own. Each line says what, how much, which accounts, who and when.
class AccountHistoryScreen extends StatefulWidget {
  /// The [history] of [project]'s [accounts].
  const AccountHistoryScreen({super.key, required this.project, required this.history, required this.accounts});

  /// The project.
  final Project project;

  /// Its account history.
  final AccountHistory history;

  /// Its accounts, one filter each.
  final Accounts accounts;

  /// The screen's route.
  static const path = '/projects/:projectId/accounts/history';

  /// The route of the account history of the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/accounts/history';

  /// The filter showing every account.
  static const allKey = Key('history.all');

  /// The filter showing the account [id] alone.
  static Key accountKey(String id) => Key('history.account.$id');

  /// The filter showing what the signed-in user did.
  static const mineKey = Key('history.mine');

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
    widget.history.filter('', false);
    widget.accounts.loadOnOpen();
  }

  Widget _filters(Words words) {
    final history = widget.history;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ChoiceChip(key: AccountHistoryScreen.allKey, label: Text(words.historyAllAccounts, key: AccountHistoryScreen.allKey.label), selected: history.accountId.isEmpty, onSelected: (_) => history.filter('', history.mine)),
        for (final account in widget.accounts.all)
          ChoiceChip(
            key: AccountHistoryScreen.accountKey(account.id),
            label: Text(account.name, key: AccountHistoryScreen.accountKey(account.id).label),
            selected: history.accountId == account.id,
            onSelected: (_) => history.filter(account.id, history.mine),
          ),
        FilterChip(key: AccountHistoryScreen.mineKey, label: Text(words.historyMine, key: AccountHistoryScreen.mineKey.label), selected: history.mine, onSelected: (mine) => history.filter(history.accountId, mine)),
      ],
    );
  }

  Widget _line(AccountHistoryLine line, Words words) => Card.outlined(
    key: AccountHistoryScreen.lineKey(line.id),
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Icon(line.kind.icon, key: AccountHistoryScreen.lineKey(line.id).icon),
      title: Text(line.textIn(words), key: AccountHistoryScreen.lineKey(line.id).title),
      subtitle: Text(line.whoAndWhenIn(words), key: AccountHistoryScreen.lineKey(line.id).subtitle),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final history = widget.history;
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.accountsHistory, subject: widget.project.name)),
      body: ListenableBuilder(
        listenable: Listenable.merge([history, widget.accounts]),
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: _filters(words)),
            Expanded(
              child: ApiListBody(
                list: history,
                emptyText: words.historyEmpty,
                itemBuilder: (line) => _line(line, words),
                listOf: (items) => ListView(
                  padding: ApiListBody.padding,
                  physics: ApiListBody.physics,
                  children: [
                    ...items,
                    if (history.mayHaveMore)
                      TextButton(key: AccountHistoryScreen.moreKey, onPressed: () => showRefusalOf(context, history.more()), child: Text(words.historyMore, key: AccountHistoryScreen.moreKey.label)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
