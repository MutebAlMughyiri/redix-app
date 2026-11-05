import 'package:flutter/material.dart';

import '../projects/members.dart';
import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/change_dialog.dart';
import '../words/words.dart';
import 'account.dart';
import 'account_dialog.dart';
import 'account_row.dart';
import 'accounts.dart';

/// A project's bank accounts and cash custodies (UC-015): everyone with access sees them, and whoever keeps the settings adds, changes and disables them (AC-22.1). Nothing is deleted (BR-15).
class AccountsScreen extends StatefulWidget {
  /// The screen, showing and changing the [accounts] of [project], choosing a custodian among [members].
  const AccountsScreen({super.key, required this.project, required this.accounts, required this.members});

  /// The project they belong to.
  final Project project;

  /// The accounts this screen shows and changes.
  final Accounts accounts;

  /// The people who can hold an account.
  final Members members;

  /// The screen's route.
  static const path = '/projects/:projectId/accounts';

  /// The route of the accounts of the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/accounts';

  /// The button that adds an account.
  static const addKey = Key('accounts.add');

  /// Edit, in an account's menu.
  static const editKey = Key('accounts.edit');

  /// Disable, in an account's menu.
  static const disableKey = Key('accounts.disable');

  /// Enable, in an account's menu.
  static const enableKey = Key('accounts.enable');

  /// The name, in the dialog.
  static const accountNameKey = Key('accounts.accountName');

  /// The custodian, in the dialog.
  static const custodianKey = Key('accounts.custodian');

  /// The opening balance, in the dialog.
  static const openingBalanceKey = Key('accounts.openingBalance');

  /// The button that saves, in the dialog.
  static const saveKey = ChangeDialog.saveKey;

  /// The line that says why a change was refused, in the dialog.
  static const dialogMessageKey = ChangeDialog.messageKey;

  /// The line that says the list could not be read.
  static const messageKey = ApiListBody.messageKey;

  /// The line shown while the project has no accounts.
  static const emptyKey = ApiListBody.emptyKey;

  /// The choice of [type], in the dialog that adds.
  static Key typeKey(AccountType type) => Key('accounts.type.${type.name}');

  /// The name of the account [id].
  static Key nameKey(String id) => Key('accounts.name.$id');

  /// The type and custodian of the account [id], or that it is disabled.
  static Key detailsKey(String id) => Key('accounts.details.$id');

  /// What the account [id] holds.
  static Key balanceKey(String id) => Key('accounts.balance.$id');

  /// The menu of the account [id].
  static Key menuKey(String id) => Key('accounts.menu.$id');

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  void initState() {
    super.initState();
    widget.accounts.loadOnOpen();
    if (widget.project.mayManageSettings) {
      widget.members.loadOnOpen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final project = widget.project;
    final accounts = widget.accounts;
    return Scaffold(
      appBar: AppBar(title: Text('${words.accountsTitle} · ${project.name}')),
      floatingActionButton: project.mayManageSettings
          ? FloatingActionButton.extended(
              key: AccountsScreen.addKey,
              icon: const Icon(Icons.add),
              label: Text(words.accountsNew),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AccountDialog(account: Account.none(), accounts: accounts, members: widget.members),
              ),
            )
          : null,
      body: ApiListBody(
        list: accounts,
        emptyText: words.accountsEmpty,
        itemBuilder: (account) => AccountRow(account: account, accounts: accounts, members: widget.members, mayChange: project.mayManageSettings),
      ),
    );
  }
}
