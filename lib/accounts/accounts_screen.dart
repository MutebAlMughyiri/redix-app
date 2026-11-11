import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../format/number_format.dart';
import '../projects/members.dart';
import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/bottom_button.dart';
import '../ui/part_keys.dart';
import '../ui/title_bar_add.dart';
import '../ui/screen_title.dart';
import '../words/word_fill.dart';
import '../words/words.dart';
import 'account.dart';
import 'account_dialog.dart';
import 'account_history_screen.dart';
import 'account_row.dart';
import 'accounts.dart';
import 'reconcile_screen.dart';
import 'reconciliation.dart';
import 'reconciliation_card.dart';
import 'transfer_dialog.dart';

/// A project's bank accounts and cash custodies with their actual balances, on one screen (UC-015, redix-app #89): the surplus, the counted total and the difference on
/// top; each account, grouped by type, with what it holds and what was counted at the last check. Transfer and Update the actual balances are the bottom bar, for whoever
/// moves money; Add account and History sit in the top bar. Whoever keeps the settings adds, changes, disables and deletes accounts.
class AccountsScreen extends StatefulWidget {
  /// The screen, showing and changing the [accounts] of [project] against its [reconciliations], choosing a custodian among [members].
  const AccountsScreen({super.key, required this.project, required this.accounts, required this.reconciliations, required this.members});

  /// The project they belong to.
  final Project project;

  /// The accounts this screen shows and changes.
  final Accounts accounts;

  /// The accounts against the books.
  final Reconciliations reconciliations;

  /// The people who can hold an account.
  final Members members;

  /// The screen's route.
  static const path = '/projects/:projectId/accounts';

  /// The route of the accounts of the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/accounts';

  /// The button that adds an account, in the top bar.
  static const addKey = Key('accounts.add');

  /// The button that opens History, in the top bar.
  static const historyKey = Key('accounts.history');

  /// The button that moves money between two accounts, at the bottom.
  static const transferKey = Key('accounts.transfer');

  /// The button that enters the actual balances again, at the bottom.
  static const updateKey = Key('accounts.update');

  /// Edit, in an account's menu.
  static const editKey = Key('accounts.edit');

  /// Disable, in an account's menu.
  static const disableKey = Key('accounts.disable');

  /// Enable, in an account's menu.
  static const enableKey = Key('accounts.enable');

  /// Delete, in an account's menu.
  static const deleteKey = Key('accounts.delete');

  /// The name, in the dialog.
  static const accountNameKey = Key('accounts.accountName');

  /// The custodian, in the dialog.
  static const custodianKey = Key('accounts.custodian');

  /// The choice of [type], in the dialog that adds.
  static Key typeKey(AccountType type) => Key('accounts.type.${type.name}');

  /// The heading over the accounts of [type].
  static Key groupKey(AccountType type) => Key('accounts.group.${type.name}');

  /// The name of the account [id].
  static Key nameKey(String id) => Key('accounts.name.$id');

  /// The type and custodian of the account [id], or that it is disabled, and what was counted at the last check.
  static Key detailsKey(String id) => Key('accounts.details.$id');

  /// What the account [id] holds.
  static Key balanceKey(String id) => Key('accounts.balance.$id');

  /// The menu of the account [id].
  static Key menuKey(String id) => Key('accounts.menu.$id');

  /// The row of the account [id].
  static Key rowKey(String id) => Key('accounts.row.$id');

  /// The heading over the account types, in the dialog.
  static const typeHeadingKey = Key('accounts.typeHeading');

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  void initState() {
    super.initState();
    widget.accounts.loadOnOpen();
    widget.reconciliations.loadOnOpen();
    if (widget.project.mayManageSettings) {
      widget.members.loadOnOpen();
    }
  }

  void _transfer() => showDialog<void>(context: context, builder: (_) => TransferDialog(project: widget.project, accounts: widget.accounts));

  void _add() => showDialog<void>(context: context, builder: (_) => AccountDialog(account: Account.none(), accounts: widget.accounts, members: widget.members));

  /// What was counted at the last check for each account it held, as its line says it.
  Map<String, String> _counted(Words words) => {
    for (final row in widget.reconciliations.value.balances)
      if (row.wasChecked) row.accountId: words.accountsCounted.fill([formatMoney(row.actualBalance)]),
  };

  Widget _heading(Words words, AccountType type) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
    child: Text(words.text(type.groupWordKey), key: AccountsScreen.groupKey(type), style: Theme.of(context).textTheme.titleSmall),
  );

  /// The [rows] of the accounts, which the API gives banks first, each type under its heading.
  List<Widget> _grouped(Words words, List<Widget> rows) {
    final all = widget.accounts.all;
    return [
      for (final (index, account) in all.indexed) ...[
        if (index == 0 || all[index - 1].type != account.type) _heading(words, account.type),
        rows[index],
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final project = widget.project;
    final accounts = widget.accounts;
    return Scaffold(
      appBar: AppBar(
        title: ScreenTitle(words.accountsTitle, subject: project.name),
        actions: [
          TitleBarAdd(buttonKey: AccountsScreen.addKey, tooltip: words.accountsNew, onPressed: project.mayManageSettings ? _add : null),
          IconButton(
            key: AccountsScreen.historyKey,
            tooltip: words.accountsHistory,
            icon: Icon(Icons.history, key: AccountsScreen.historyKey.icon),
            onPressed: () => context.push(AccountHistoryScreen.pathOf(project.id), extra: project),
          ),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: accounts,
        builder: (context, _) => BottomButton(
          buttonKey: AccountsScreen.transferKey,
          icon: Icons.sync_alt,
          label: words.transfersButton,
          onPressed: project.mayMoveMoney && accounts.bankAndCash.length > 1 ? _transfer : null,
          second: BottomAction(
            key: AccountsScreen.updateKey,
            icon: Icons.edit_note,
            label: words.accountsReconcile,
            onPressed: project.mayMoveMoney ? () => context.push(ReconcileScreen.pathOf(project.id), extra: project) : null,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.reconciliations,
        builder: (context, _) {
          final counted = _counted(words);
          return ApiListBody(
            list: accounts,
            emptyText: words.accountsEmpty,
            alsoRefresh: widget.reconciliations.load,
            itemBuilder: (account) => AccountRow(
              account: account,
              amount: formatMoney(account.balance),
              counted: counted[account.id] ?? '',
              menu: project.mayManageSettings ? AccountMenu(account: account, accounts: accounts, members: widget.members) : AccountRow.noMenu,
            ),
            listOf: (rows) => ListView(
              padding: ApiListBody.padding,
              physics: ApiListBody.physics,
              children: [ReconciliationCard(reconciliations: widget.reconciliations), ..._grouped(words, rows)],
            ),
          );
        },
      ),
    );
  }
}
