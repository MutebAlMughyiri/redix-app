// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../projects/members.dart';
import '../ui/confirm_dialog.dart';
import '../ui/part_keys.dart';
import '../ui/messages.dart';
import '../words/words.dart';
import 'account.dart';
import 'account_dialog.dart';
import 'accounts.dart';
import 'accounts_screen.dart';
import '../ui/app_color.dart';
import '../format/parts_line.dart';
import '../ui/row_menu.dart';

/// One account: its type and who holds it, or that it is disabled, what was counted at the last check, what it holds and, for whoever keeps the settings, a menu of
/// what can be done to it.
class AccountRow extends StatelessWidget {
  /// The row of [account] showing [amount] and [counted], ending in [menu].
  const AccountRow({super.key, required this.account, required this.amount, this.counted = '', this.menu = noMenu});

  /// The end of a row with no menu: as wide as the menu's own space, so a row's amount lines up the same on every screen.
  static const noMenu = SizedBox(width: 12);

  /// The account this row shows.
  final Account account;

  /// What it holds, as written.
  final String amount;

  /// What was counted at the last check, as its line says it; empty when that check did not hold it (redix-app #89).
  final String counted;

  /// What ends the row: its [AccountMenu], or [noMenu].
  final Widget menu;

  String _details(Words words) => account.isActive ? partsLine([words.text(account.type.wordKey), account.custodianName, counted]) : partsLine([words.accountsDisabled, counted]);

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Card.outlined(
      key: AccountsScreen.rowKey(account.id),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        key: AccountsScreen.rowKey(account.id).body,
        contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 4, 0),
        leading: Icon(account.type == AccountType.bank ? Icons.account_balance_outlined : Icons.payments_outlined, key: AccountsScreen.rowKey(account.id).icon),
        title: Text(
          account.name,
          key: AccountsScreen.nameKey(account.id),
          style: AppColor.quiet.textUnless(context, account.isActive),
        ),
        subtitle: Text(_details(words), key: AccountsScreen.detailsKey(account.id)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(amount, key: AccountsScreen.balanceKey(account.id), style: Theme.of(context).textTheme.titleSmall),
            menu,
          ],
        ),
      ),
    );
  }
}

/// What can be done to an account, for whoever keeps the settings: its ⋮ menu. Delete stays in it gray, saying why, once something names the account (BR-15).
class AccountMenu extends StatelessWidget {
  /// The menu of [account], changed through [accounts], choosing a custodian among [members].
  const AccountMenu({super.key, required this.account, required this.accounts, required this.members});

  /// The account.
  final Account account;

  /// The way to change it.
  final Accounts accounts;

  /// The people who can hold it.
  final Members members;

  void _askToDelete(BuildContext context) {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: words.accountsDeleteQuestion,
        subject: account.name,
        explanation: words.accountsDeleteCannotUndo,
        confirmLabel: words.accountsDelete,
        onConfirm: () async {
          final refusal = await accounts.delete(account);
          showMessage(messenger, words, refusal.isEmpty ? 'accounts.deleted' : refusal);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return rowMenu(AccountsScreen.menuKey(account.id), [
      rowMenuItem(AccountsScreen.editKey, words.accountsEdit, () => showDialog<void>(context: context, builder: (_) => AccountDialog(account: account, accounts: accounts, members: members))),
      if (account.isActive)
        rowMenuItem(AccountsScreen.disableKey, words.accountsDisable, () => showRefusalOf(context, accounts.disable(account)))
      else
        rowMenuItem(AccountsScreen.enableKey, words.accountsEnable, () => showRefusalOf(context, accounts.enable(account))),
      rowMenuItem(AccountsScreen.deleteKey, words.accountsDelete, () => _askToDelete(context), reason: account.isUsed ? words.accountsAccountInUse : ''),
    ]);
  }
}
