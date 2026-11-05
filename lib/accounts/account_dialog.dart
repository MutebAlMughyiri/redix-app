import 'package:flutter/material.dart';

import '../format/number_format.dart';
import '../projects/member_picker.dart';
import '../projects/members.dart';
import '../ui/change_dialog.dart';
import '../words/words.dart';
import 'account.dart';
import 'accounts.dart';
import 'accounts_screen.dart';

/// Asks for an account's name, opening balance and who holds it, and for a new account its type, which is set once.
class AccountDialog extends StatefulWidget {
  /// The dialog changing [account], or adding one when it is [Account.none], through [accounts], choosing the custodian among [members].
  const AccountDialog({super.key, required this.account, required this.accounts, required this.members});

  /// The account this dialog changes.
  final Account account;

  /// The way to change it.
  final Accounts accounts;

  /// The people who can hold it.
  final Members members;

  @override
  State<AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<AccountDialog> {
  late final _name = TextEditingController(text: widget.account.name);
  late final _openingBalance = TextEditingController(text: formatPlain(widget.account.openingBalance));
  late var _type = widget.account.type;
  late var _custodianId = widget.account.custodianId;

  bool get _isNew => widget.account.id.isEmpty;

  @override
  void dispose() {
    _name.dispose();
    _openingBalance.dispose();
    super.dispose();
  }

  Future<String> _save() async {
    final openingBalance = parseNumber(_openingBalance.text);
    if (openingBalance.isNaN) {
      return 'accounts.invalidOpeningBalance';
    }
    return _isNew
        ? widget.accounts.add(_type, _name.text, openingBalance, _custodianId)
        : widget.accounts.edit(widget.account, _name.text, openingBalance, _custodianId);
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ChangeDialog(
      title: _isNew ? words.accountsNew : words.accountsEdit,
      saveLabel: _isNew ? words.accountsNew : words.accountsSave,
      onSave: _save,
      children: [
        if (_isNew) ...[
          Text(words.accountsType, style: Theme.of(context).textTheme.titleSmall),
          RadioGroup<AccountType>(
            groupValue: _type,
            onChanged: (type) => setState(() => _type = type ?? _type),
            child: Column(
              children: [
                for (final type in AccountType.values.where((type) => type != AccountType.partnerPocket))
                  RadioListTile<AccountType>(key: AccountsScreen.typeKey(type), contentPadding: EdgeInsets.zero, value: type, title: Text(words.text(type.wordKey))),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          key: AccountsScreen.accountNameKey,
          controller: _name,
          autofocus: _isNew,
          decoration: InputDecoration(labelText: words.accountsName, border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          key: AccountsScreen.openingBalanceKey,
          controller: _openingBalance,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          decoration: InputDecoration(labelText: words.accountsOpeningBalance, border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        MemberPicker(
          key: AccountsScreen.custodianKey,
          members: widget.members,
          label: words.accountsCustodian,
          nobody: words.accountsNoCustodian,
          userId: _custodianId,
          currentId: widget.account.custodianId,
          currentName: widget.account.custodianName,
          onChanged: (userId) => setState(() => _custodianId = userId),
        ),
      ],
    );
  }
}
