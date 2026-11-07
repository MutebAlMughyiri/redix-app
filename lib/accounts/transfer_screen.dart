import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../attachments/attachments.dart';
import '../attachments/invoice_capture.dart';
import '../attachments/picked_file.dart';
import '../expenses/entry_date.dart';
import '../expenses/invoice_section.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../ui/entry_field.dart';
import '../ui/labelled_chips.dart';
import '../ui/part_keys.dart';
import '../ui/picker_field.dart';
import '../ui/refusal_snack_bar.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'account.dart';
import 'accounts.dart';
import 'transfers.dart';

/// Moving money between two accounts, or topping up a custody (UC-040). It counts at once (BR-30).
class TransferScreen extends StatefulWidget {
  /// The screen moving money among [accounts] of [project], through [transfers].
  const TransferScreen({super.key, required this.project, required this.accounts, required this.transfers, required this.attachments, required this.capture});

  /// The address of the screen.
  static const path = '/projects/:projectId/transfers/new';

  /// The address of the screen for the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/transfers/new';

  /// The amount.
  static const amountKey = Key('transfer.amount');

  /// The date.
  static const dateKey = Key('transfer.date');

  /// What it is for.
  static const descriptionKey = Key('transfer.description');

  /// The button moving it.
  static const saveKey = Key('transfer.save');

  /// The line saying why it was refused.
  static const messageKey = Key('transfer.message');

  /// The choice of the account [id] as where it leaves.
  static Key fromKey(String id) => Key('transfer.from.$id');

  /// The choice of the account [id] as where it arrives.
  static Key toKey(String id) => Key('transfer.to.$id');

  /// The choice of the account the money leaves.
  static const fromChoiceKey = Key('transfer.fromChoice');

  /// The choice of the account the money reaches.
  static const toChoiceKey = Key('transfer.toChoice');

  /// The project.
  final Project project;

  /// What it moves among.
  final Accounts accounts;

  /// The way to enter it.
  final Transfers transfers;

  /// The way to keep its file.
  final Attachments attachments;

  /// The phone's camera and files.
  final InvoiceCapture capture;

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  var _fromId = '';
  var _toId = '';
  var _date = DateTime.now();
  var _file = PickedFile.none();
  var _fileMessage = '';
  var _message = '';
  var _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _takeFrom(Future<PickedFile> Function() source) async {
    final file = await source();
    if (mounted) {
      setState(() {
        _fileMessage = file.failure;
        _file = file.isNone ? _file : file;
      });
    }
  }

  Future<void> _chooseDate() async {
    final chosen = await pickEntryDate(context, widget.project, _date);
    if (mounted) {
      setState(() => _date = chosen);
    }
  }

  Future<String> _send() async {
    final amount = parseNumber(_amount.text);
    if (amount.isNaN) {
      return 'transfers.invalidAmount';
    }
    if (_fromId.isEmpty || _toId.isEmpty) {
      return 'transfers.unknownAccount';
    }
    var attachmentId = '';
    if (!_file.isNone) {
      final refusal = await widget.attachments.keep(_file);
      if (refusal.isNotEmpty) {
        return refusal;
      }
      attachmentId = widget.attachments.kept.id;
    }
    return widget.transfers.add(_date, _fromId, _toId, amount, _description.text, attachmentId);
  }

  Future<void> _save() async {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    final refusal = await _send();
    if (!mounted) {
      return;
    }
    if (refusal.isEmpty) {
      showMessage(messenger, words, 'transfers.done');
      await widget.accounts.load();
      if (mounted) {
        context.pop();
      }
      return;
    }
    setState(() {
      _saving = false;
      _message = refusal;
    });
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final accounts = widget.accounts.all.where((account) => account.isActive).toList();
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.transfersTitle, subject: widget.project.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            LabelledChips<Account>(
              key: TransferScreen.fromChoiceKey,
              label: words.transfersFrom,
              choices: accounts,
              keyOf: (account) => TransferScreen.fromKey(account.id),
              nameOf: (account) => account.name,
              isChosen: (account) => account.id == _fromId,
              onChosen: (account) => setState(() => _fromId = account.id),
            ),
            LabelledChips<Account>(
              key: TransferScreen.toChoiceKey,
              label: words.transfersTo,
              choices: accounts,
              keyOf: (account) => TransferScreen.toKey(account.id),
              nameOf: (account) => account.name,
              isChosen: (account) => account.id == _toId,
              onChosen: (account) => setState(() => _toId = account.id),
            ),
            entryField(key: TransferScreen.amountKey, controller: _amount, label: words.transfersAmount, isNumber: true, onChanged: (_) {}),
            PickerField(key: TransferScreen.dateKey, label: words.transfersDate, value: formatDate(_date), onTap: _chooseDate),
            entryField(key: TransferScreen.descriptionKey, controller: _description, label: words.transfersDescription, onChanged: (_) {}),
            InvoiceSection(project: widget.project, file: _file, emptyLabel: words.transfersReceipt, message: _fileMessage, onCamera: () => _takeFrom(widget.capture.fromCamera), onFiles: () => _takeFrom(widget.capture.fromFiles)),
            if (_message.isNotEmpty) Text(words.text(_message), key: TransferScreen.messageKey, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            FilledButton(key: TransferScreen.saveKey, onPressed: _saving ? null : _save, child: Text(words.transfersSave, key: TransferScreen.saveKey.label)),
          ],
        ),
      ),
    );
  }
}
