import 'package:flutter/material.dart';

import '../format/number_format.dart';
import '../projects/members.dart';
import '../ui/refusal_snack_bar.dart';
import '../words/words.dart';
import 'account.dart';
import 'account_dialog.dart';
import 'accounts.dart';
import 'accounts_screen.dart';

/// One account: its type and who holds it, or that it is disabled, what it holds and, for whoever keeps the settings, a menu of what can be done to it.
class AccountRow extends StatelessWidget {
  /// The row of [account], changed through [accounts] while [mayChange], choosing a custodian among [members].
  const AccountRow({super.key, required this.account, required this.accounts, required this.members, required this.mayChange});

  /// The account this row shows.
  final Account account;

  /// The way to change it.
  final Accounts accounts;

  /// The people who can hold it.
  final Members members;

  /// Whether the signed-in user may change it now.
  final bool mayChange;

  String _details(Words words) => account.isActive ? [words.text(account.type.wordKey), if (account.custodianName.isNotEmpty) account.custodianName].join(' · ') : words.accountsDisabled;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsetsDirectional.fromSTEB(16, 0, mayChange ? 4 : 16, 0),
        leading: Icon(account.type == AccountType.bank ? Icons.account_balance_outlined : Icons.payments_outlined),
        title: Text(
          account.name,
          key: AccountsScreen.nameKey(account.id),
          style: account.isActive ? null : TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        subtitle: Text(_details(words), key: AccountsScreen.detailsKey(account.id)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(formatMoney(account.balance), key: AccountsScreen.balanceKey(account.id), style: Theme.of(context).textTheme.titleSmall),
            if (mayChange)
              PopupMenuButton<VoidCallback>(
                key: AccountsScreen.menuKey(account.id),
                onSelected: (action) => action(),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    key: AccountsScreen.editKey,
                    value: () => showDialog<void>(
                      context: context,
                      builder: (_) => AccountDialog(account: account, accounts: accounts, members: members),
                    ),
                    child: Text(words.accountsEdit),
                  ),
                  if (account.isActive)
                    PopupMenuItem(key: AccountsScreen.disableKey, value: () => showRefusalOf(context, accounts.disable(account)), child: Text(words.accountsDisable))
                  else
                    PopupMenuItem(key: AccountsScreen.enableKey, value: () => showRefusalOf(context, accounts.enable(account)), child: Text(words.accountsEnable)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
