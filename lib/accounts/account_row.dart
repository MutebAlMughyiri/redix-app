import 'package:flutter/material.dart';

import '../projects/members.dart';
import '../ui/part_keys.dart';
import '../ui/refusal_snack_bar.dart';
import '../words/words.dart';
import 'account.dart';
import 'account_dialog.dart';
import 'accounts.dart';
import 'accounts_screen.dart';
import '../ui/app_color.dart';
import '../format/parts_line.dart';
import '../ui/row_menu.dart';

/// One account: its type and who holds it, or that it is disabled, what it holds and, for whoever keeps the settings, a menu of what can be done to it.
class AccountRow extends StatelessWidget {
  /// The row of [account] showing [amount], changed through [accounts] while [mayChange], choosing a custodian among [members].
  const AccountRow({super.key, required this.account, required this.amount, required this.accounts, required this.members, required this.mayChange});

  /// The account this row shows.
  final Account account;

  /// What it holds, as written: its balance on Accounts, what it really held at the latest check on the actual balances.
  final String amount;

  /// The way to change it.
  final Accounts accounts;

  /// The people who can hold it.
  final Members members;

  /// Whether the signed-in user may change it now.
  final bool mayChange;

  String _details(Words words) => account.isActive ? partsLine([words.text(account.type.wordKey), account.custodianName]) : words.accountsDisabled;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Card.outlined(
      key: AccountsScreen.rowKey(account.id),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        key: AccountsScreen.rowKey(account.id).body,
        contentPadding: EdgeInsetsDirectional.fromSTEB(16, 0, mayChange ? 4 : 16, 0),
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
            if (mayChange)
              rowMenu(AccountsScreen.menuKey(account.id), [
                  rowMenuItem(AccountsScreen.editKey, words.accountsEdit, () => showDialog<void>(
                      context: context,
                      builder: (_) => AccountDialog(account: account, accounts: accounts, members: members),
                    )),
                  if (account.isActive)
                    rowMenuItem(AccountsScreen.disableKey, words.accountsDisable, () => showRefusalOf(context, accounts.disable(account)))
                  else
                    rowMenuItem(AccountsScreen.enableKey, words.accountsEnable, () => showRefusalOf(context, accounts.enable(account))),
                ]),
          ],
        ),
      ),
    );
  }
}
