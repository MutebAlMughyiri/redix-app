import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../accounts/account.dart';
import '../accounts/accounts.dart';
import '../attachments/attachments.dart';
import '../attachments/invoice_capture.dart';
import '../attachments/picked_file.dart';
import '../expenses/entry_date.dart';
import '../expenses/invoice_section.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../structure/category.dart';
import '../structure/item_picker.dart';
import '../structure/offered_items.dart';
import '../ui/entry_field.dart';
import '../ui/labelled_chips.dart';
import '../ui/picker_field.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'revenues.dart';

/// Recording revenue on a revenue item (UC-047, FR-28): the item's type says what it is, a VAT refund included (D23). It counts at once (BR-30).
class RevenueFormScreen extends StatefulWidget {
  /// The screen recording revenue in [project] through [revenues] on one of [items], into one of [accounts].
  const RevenueFormScreen({super.key, required this.project, required this.revenues, required this.items, required this.accounts, required this.attachments, required this.capture});

  /// The address of the screen.
  static const path = '/projects/:projectId/revenue/new';

  /// The address of the screen for the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/revenue/new';

  /// The amount.
  static const amountKey = Key('revenueForm.amount');

  /// What was said about it.
  static const descriptionKey = Key('revenueForm.description');

  /// The button saving it.
  static const saveKey = Key('revenueForm.save');

  /// The line saying why it was refused.
  static const messageKey = Key('revenueForm.message');

  /// The choice of its revenue item.
  static const itemKey = Key('revenueForm.item');

  /// The choice of the account [id].
  static Key accountKey(String id) => Key('revenueForm.account.$id');

  /// The project.
  final Project project;

  /// The way to record it.
  final Revenues revenues;

  /// The revenue items it may come in on.
  final OfferedItems items;

  /// The accounts it may reach.
  final Accounts accounts;

  /// The way to keep its file.
  final Attachments attachments;

  /// The phone's camera and files.
  final InvoiceCapture capture;

  @override
  State<RevenueFormScreen> createState() => _RevenueFormScreenState();
}

class _RevenueFormScreenState extends State<RevenueFormScreen> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  var _item = Item.none();
  var _date = DateTime.now();
  var _accountId = '';
  var _file = PickedFile.none();
  var _fileMessage = '';
  var _message = '';
  var _saving = false;

  @override
  void initState() {
    super.initState();
    widget.accounts.loadOnOpen();
    widget.items.loadOnOpen();
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  String _isoOf(DateTime date) => date.toIso8601String().substring(0, 10);

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
      return 'revenue.invalidAmount';
    }
    var attachmentId = '';
    if (!_file.isNone) {
      final refusal = await widget.attachments.keep(_file);
      if (refusal.isNotEmpty) {
        return refusal;
      }
      attachmentId = widget.attachments.kept.id;
    }
    return widget.revenues.record({
      'itemId': _item.id,
      'date': _isoOf(_date),
      'amount': amount,
      'accountId': _accountId,
      'description': _description.text,
      if (attachmentId.isNotEmpty) 'attachmentId': attachmentId,
    });
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
      messenger.showSnackBar(SnackBar(content: Text(words.revenueSaved)));
      context.pop(true);
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
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.revenueNew, subject: widget.project.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ListenableBuilder(
          listenable: widget.accounts,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              ItemPicker(key: RevenueFormScreen.itemKey, items: widget.items, label: words.revenueItem, itemName: _item.name, onChanged: (item) => setState(() => _item = item)),
              entryField(key: RevenueFormScreen.amountKey, controller: _amount, label: words.revenueAmount, isNumber: true, onChanged: (_) {}),
              PickerField(label: words.revenueDate, value: formatDate(_date), onTap: _chooseDate),
              LabelledChips<Account>(
                label: words.revenueAccount,
                choices: widget.accounts.bankAndCash,
                keyOf: (account) => RevenueFormScreen.accountKey(account.id),
                nameOf: (account) => account.name,
                isChosen: (account) => account.id == _accountId,
                onChosen: (account) => setState(() => _accountId = account.id),
              ),
              entryField(key: RevenueFormScreen.descriptionKey, controller: _description, label: words.revenueDescription, onChanged: (_) {}),
              InvoiceSection(project: widget.project, file: _file, emptyLabel: words.revenueFile, message: _fileMessage, onCamera: () => _takeFrom(widget.capture.fromCamera), onFiles: () => _takeFrom(widget.capture.fromFiles)),
              if (_message.isNotEmpty) Text(words.text(_message), key: RevenueFormScreen.messageKey, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              FilledButton(key: RevenueFormScreen.saveKey, onPressed: _saving ? null : _save, child: Text(words.revenueSave)),
            ],
          ),
        ),
      ),
    );
  }
}
