import 'package:flutter/material.dart';

import '../expenses/entry_date.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../ui/change_dialog.dart';
import '../ui/part_keys.dart';
import '../ui/picker_field.dart';
import '../words/word_fill.dart';
import '../words/words.dart';
import 'account.dart';
import 'accounts.dart';

/// Moves money from one of [project]'s active accounts to another (FR-23, redix-app #89): opened by Accounts' bottom button. To never offers From, so the same account
/// cannot be chosen twice; what From holds now shows under it, and the API refuses more than that (R26).
class TransferDialog extends StatefulWidget {
  /// The dialog moving money between the active [accounts] of [project].
  const TransferDialog({super.key, required this.project, required this.accounts});

  /// The project the accounts belong to, whose period bounds the date.
  final Project project;

  /// The accounts the money moves between.
  final Accounts accounts;

  /// The account the money leaves.
  static const fromKey = Key('transfer.from');

  /// What that account holds now.
  static const balanceNowKey = Key('transfer.balanceNow');

  /// The account the money reaches.
  static const toKey = Key('transfer.to');

  /// How much moves.
  static const amountKey = Key('transfer.amount');

  /// The day it moves.
  static const dateKey = Key('transfer.date');

  /// Notes on it.
  static const notesKey = Key('transfer.notes');

  /// The choice of the account [accountId] in the list of accounts keyed [listKey].
  static Key choiceKey(Key listKey, String accountId) => Key('${(listKey as ValueKey<String>).value}.$accountId');

  @override
  State<TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<TransferDialog> {
  late final _active = widget.accounts.bankAndCash;
  late var _from = _active.first;
  late var _to = _active.firstWhere((account) => account.id != _from.id);
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  late var _date = widget.project.todayBy(widget.accounts.clock);

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _chooseFrom(Account from) => setState(() {
    _from = from;
    if (_to.id == from.id) {
      _to = _active.firstWhere((account) => account.id != from.id);
    }
  });

  Future<String> _save() async {
    final amount = parseNumber(_amount.text);
    return amount.isNaN ? 'transfers.invalidAmount' : widget.accounts.transfer(_from, _to, amount, _date, _notes.text.trim());
  }

  Widget _picker(Key key, String label, Account chosen, Iterable<Account> offered, ValueChanged<Account> onChanged) => InputDecorator(
    decoration: InputDecoration(labelText: label),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        key: key,
        value: chosen.id,
        isExpanded: true,
        isDense: true,
        items: [for (final account in offered) DropdownMenuItem(key: TransferDialog.choiceKey(key, account.id), value: account.id, child: Text(account.name, key: TransferDialog.choiceKey(key, account.id).label, overflow: TextOverflow.ellipsis))],
        onChanged: (id) => onChanged(_active.firstWhere((account) => account.id == id)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ChangeDialog(
      title: words.transfersTitle,
      saveLabel: words.transfersSave,
      onSave: _save,
      children: [
        _picker(TransferDialog.fromKey, words.transfersFrom, _from, _active, _chooseFrom),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 4, start: 12),
          child: Text(words.transfersBalanceNow.fill([formatMoney(_from.balance)]), key: TransferDialog.balanceNowKey, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(height: 16),
        _picker(TransferDialog.toKey, words.transfersTo, _to, _active.where((account) => account.id != _from.id), (to) => setState(() => _to = to)),
        const SizedBox(height: 16),
        TextField(
          key: TransferDialog.amountKey,
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: words.transfersAmount),
        ),
        const SizedBox(height: 16),
        PickerField(
          key: TransferDialog.dateKey,
          label: words.transfersDate,
          value: formatDate(_date),
          onTap: () async {
            final date = await pickEntryDate(context, widget.project, widget.accounts.clock, _date);
            setState(() => _date = date);
          },
        ),
        const SizedBox(height: 16),
        TextField(key: TransferDialog.notesKey, controller: _notes, maxLines: 2, decoration: InputDecoration(labelText: words.transfersNotes)),
      ],
    );
  }
}
