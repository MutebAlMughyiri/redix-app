import 'package:flutter/material.dart';

import '../accounts/account.dart';
import '../accounts/accounts.dart';
import '../attachments/attachments.dart';
import '../expenses/entry_date.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../partners/capital.dart';
import '../projects/project.dart';
import '../ui/entry_field.dart';
import '../ui/labelled_chips.dart';
import '../ui/part_keys.dart';
import '../ui/picker_field.dart';
import '../words/words.dart';
import 'entry_tables.dart';
import 'project_entries.dart';
import '../attachments/entry_file.dart';

/// What Add entry asks for a revenue item's table or a partner (redix-api #101), under the file every entry shares: the amount, the date, the account and a description, and for a
/// partner whether it is a withdrawal. One button sends it for approval at once; it is never a draft.
class DirectEntryFields extends StatefulWidget {
  /// The fields of [table] in [project], recorded through [entries] or [capital], reaching one of [accounts], with Add entry's [file] kept through [attachments]; [onSent] runs once
  /// it is sent, with the id the API gave it.
  const DirectEntryFields({
    super.key,
    required this.project,
    required this.table,
    required this.entries,
    required this.capital,
    required this.accounts,
    required this.attachments,
    required this.file,
    required this.onSent,
  });

  /// The project.
  final Project project;

  /// The revenue item's table, or the partner.
  final EntryTable table;

  /// The project's entries, through which revenue is recorded and then listed.
  final ProjectEntries entries;

  /// The way to record a partner's money.
  final Capital capital;

  /// The accounts it may reach.
  final Accounts accounts;

  /// The way to keep its file.
  final Attachments attachments;

  /// Add entry's file, the same for every entry.
  final EntryFile file;

  /// Runs once it is sent for approval.
  final ValueChanged<String> onSent;

  /// The switch that makes a partner's entry a withdrawal, in the place of a purchase's credit note.
  static const withdrawalKey = Key('directEntry.withdrawal');

  /// The amount.
  static const amountKey = Key('directEntry.amount');

  /// The date.
  static const dateKey = Key('directEntry.date');

  /// The choice of the account.
  static const accountChoiceKey = Key('directEntry.accountChoice');

  /// The account [id], among the choices.
  static Key accountKey(String id) => Key('directEntry.account.$id');

  /// The description.
  static const descriptionKey = Key('directEntry.description');

  /// The line that says why it was refused.
  static const messageKey = Key('directEntry.message');

  /// The button that sends it for approval.
  static const sendKey = Key('directEntry.send');

  @override
  State<DirectEntryFields> createState() => _DirectEntryFieldsState();
}

class _DirectEntryFieldsState extends State<DirectEntryFields> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  var _date = DateTime.now();
  var _accountId = '';
  var _isWithdrawal = false;
  var _message = '';
  var _sending = false;

  @override
  void initState() {
    super.initState();
    widget.accounts.loadOnOpen();
  }

  @override
  void dispose() {
    for (final field in [_amount, _description]) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final chosen = await pickEntryDate(context, widget.project, _date);
    if (mounted) {
      setState(() => _date = chosen);
    }
  }

  Future<String> _record() async {
    final table = widget.table;
    final amount = parseNumber(_amount.text);
    if (amount.isNaN) {
      return table.isPartner ? 'capital.invalidAmount' : 'revenue.invalidAmount';
    }
    final refusal = await widget.file.keep(widget.attachments);
    if (refusal.isNotEmpty) {
      return refusal;
    }
    final body = <String, Object>{
      'date': apiDate(_date),
      'amount': amount,
      'accountId': _accountId,
      'description': _description.text,
      if (widget.file.attachmentId.isNotEmpty) 'attachmentId': widget.file.attachmentId,
    };
    return table.isPartner
        ? widget.capital.record({...body, 'partnerId': table.id, 'type': _isWithdrawal ? 'withdrawal' : 'contribution'})
        : widget.entries.recordRevenue({...body, 'itemId': table.itemId, 'subgroupId': table.id});
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final refusal = await _record();
    if (!mounted) {
      return;
    }
    if (refusal.isEmpty) {
      widget.onSent(widget.table.isPartner ? widget.capital.lastId : widget.entries.lastId);
      return;
    }
    setState(() {
      _sending = false;
      _message = refusal;
    });
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ListenableBuilder(
      listenable: widget.accounts,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          if (widget.table.isPartner)
            SwitchListTile(
              key: DirectEntryFields.withdrawalKey,
              contentPadding: EdgeInsets.zero,
              title: Text(words.entriesWithdrawal, key: DirectEntryFields.withdrawalKey.title),
              subtitle: Text(words.entriesWithdrawalHint, key: DirectEntryFields.withdrawalKey.subtitle),
              value: _isWithdrawal,
              onChanged: (isWithdrawal) => setState(() => _isWithdrawal = isWithdrawal),
            ),
          entryField(key: DirectEntryFields.amountKey, controller: _amount, label: words.expensesAmount, isNumber: true, onChanged: (_) => setState(() {})),
          PickerField(key: DirectEntryFields.dateKey, label: words.expensesDate, value: formatDate(_date), onTap: _chooseDate),
          LabelledChips<Account>(
            key: DirectEntryFields.accountChoiceKey,
            label: words.revenueAccount,
            choices: widget.accounts.bankAndCash,
            keyOf: (account) => DirectEntryFields.accountKey(account.id),
            nameOf: (account) => account.name,
            isChosen: (account) => account.id == _accountId,
            onChosen: (account) => setState(() => _accountId = account.id),
          ),
          entryField(key: DirectEntryFields.descriptionKey, controller: _description, label: words.revenueDescription, onChanged: (_) {}),
          if (_message.isNotEmpty) Text(words.text(_message), key: DirectEntryFields.messageKey, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          FilledButton(key: DirectEntryFields.sendKey, onPressed: _sending ? null : _send, child: Text(words.expensesSend, key: DirectEntryFields.sendKey.label)),
        ],
      ),
    );
  }
}
