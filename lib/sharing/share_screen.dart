import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../attachments/attachments.dart';
import '../attachments/invoice_capture.dart';
import '../attachments/picked_file.dart';
import '../expenses/add_expense_screen.dart';
import '../expenses/invoice_qr.dart';
import '../expenses/qr_summary.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../partners/capital_move_screen.dart';
import '../projects/project.dart';
import '../projects/projects.dart';
import '../structure/category.dart';
import '../structure/item_picker.dart';
import '../structure/offered_items.dart';
import '../ui/form_section.dart';
import '../ui/labelled_chips.dart';
import '../words/words.dart';
import 'attachable_entries.dart';
import 'attachable_entry.dart';

/// What opens when a picture or a PDF is shared to the app (UC-038, FR-49): put it on an expense entered without an invoice (UC-039), or start a new expense with it (UC-046).
class ShareScreen extends StatefulWidget {
  /// The screen holding [file], read through [capture], in one of [projects].
  const ShareScreen({super.key, required this.file, required this.capture, required this.projects, required this.itemsOf, required this.entriesOf, required this.attachmentsOf, required this.onDone});

  /// The address of the screen.
  static const path = '/share';

  /// The way out.
  static const closeKey = Key('share.close');

  /// The line saying there is no project to enter in.
  static const noProjectKey = Key('share.noProject');

  /// The item.
  static const itemKey = Key('share.item');

  /// The choice of purchases.
  static const purchasesKey = Key('share.purchases');

  /// The choice of contractor payments.
  static const contractorPaymentsKey = Key('share.contractorPayments');

  /// The line saying the amounts differ.
  static const amountDiffersKey = Key('share.amountDiffers');

  /// The line saying the supplier differs.
  static const supplierDiffersKey = Key('share.supplierDiffers');

  /// The button attaching it.
  static const attachKey = Key('share.attach');

  /// The button starting a new expense with it.
  static const newExpenseKey = Key('share.newExpense');

  /// The button using it as a capital movement's bank receipt.
  static const capitalReceiptKey = Key('share.capitalReceipt');

  /// The line saying why it was refused.
  static const messageKey = Key('share.message');

  /// The choice of the project [id].
  static Key projectKey(String id) => Key('share.project.$id');

  /// The expense [id].
  static Key entryKey(String id) => Key('share.entry.$id');

  /// The mark on the expense [id] that matches the QR code.
  static Key matchingKey(String id) => Key('share.matching.$id');

  /// The shared file.
  final PickedFile file;

  /// The phone's barcode reader.
  final InvoiceCapture capture;

  /// The projects to choose from.
  final Projects projects;

  /// What a project offers of a type of item.
  final OfferedItems Function(String projectId, ItemType type) itemsOf;

  /// What a project's items hold.
  final AttachableEntries Function(String projectId) entriesOf;

  /// Where a project keeps files.
  final Attachments Function(String projectId) attachmentsOf;

  /// Called when the file was used, or the person left.
  final VoidCallback onDone;

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  var _qr = InvoiceQr.none();
  var _projectId = '';
  var _type = ItemType.purchases;
  OfferedItems? _shownItems;
  var _item = Item.none();
  var _chosen = '';
  var _message = '';
  var _saving = false;

  @override
  void initState() {
    super.initState();
    widget.projects.loadOnOpen();
    if (!widget.file.isPdf) {
      unawaited(_readQr());
    }
  }

  Future<void> _readQr() async {
    final qr = InvoiceQr.parse(await widget.capture.qrTextOf(widget.file));
    if (mounted) {
      setState(() => _qr = qr);
    }
  }

  List<Project> get _open => widget.projects.all.where((project) => project.mayEnterExpenses && project.mayAttachFiles).toList();

  Project get _project => _open.firstWhere((project) => project.id == _projectId, orElse: () => _open.first);

  void _chooseProject(Project project) {
    setState(() {
      _projectId = project.id;
      _item = Item.none();
      _chosen = '';
    });
  }

  void _chooseType(ItemType type) {
    setState(() {
      _type = type;
      _item = Item.none();
      _chosen = '';
    });
  }

  Future<void> _chooseItem(Item item) async {
    setState(() {
      _item = item;
      _chosen = '';
    });
    final entries = widget.entriesOf(_project.id);
    await entries.findIn(item.id, _qr);
    final matching = entries.all.where((entry) => entry.isMatching);
    if (mounted && matching.isNotEmpty) {
      setState(() => _chosen = matching.first.id);
    }
  }

  Future<void> _attach() async {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final entries = widget.entriesOf(_project.id);
    final entry = entries.all.firstWhere((entry) => entry.id == _chosen);
    setState(() => _saving = true);
    final attachments = widget.attachmentsOf(_project.id);
    var refusal = await attachments.keep(widget.file);
    if (refusal.isEmpty) {
      refusal = await entries.attach(entry, attachments.kept.id);
    }
    if (!mounted) {
      return;
    }
    if (refusal.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(words.shareAttached)));
      widget.onDone();
      return;
    }
    setState(() {
      _saving = false;
      _message = refusal;
    });
  }

  Future<void> _newExpense() async {
    final saved = await context.push<bool>(AddExpenseScreen.sharedPathOf(_project.id), extra: _project);
    if (saved ?? false) {
      widget.onDone();
    }
  }

  Future<void> _capitalReceipt() async {
    final saved = await context.push<bool>(CapitalMoveScreen.sharedPathOf(_project.id), extra: _project);
    if (saved ?? false) {
      widget.onDone();
    }
  }

  Widget _entryRow(AttachableEntry entry) {
    final words = Words.of(context);
    final title = entry.product.isEmpty ? entry.supplierName : entry.product;
    return RadioListTile<String>(
      key: ShareScreen.entryKey(entry.id),
      value: entry.id,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text('${entry.supplierName} · ${formatDate(entry.date)}'),
      secondary: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(formatMoney(entry.amount)),
          if (entry.isMatching) Text(words.shareMatching, key: ShareScreen.matchingKey(entry.id), style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }

  List<Widget> _differences(AttachableEntry entry) {
    final words = Words.of(context);
    final style = TextStyle(color: Theme.of(context).colorScheme.error);
    return [
      if (!_qr.isNone && _qr.total != entry.amount) Text(words.shareAmountDiffers.replaceFirst('{0}', formatMoney(_qr.total)).replaceFirst('{1}', formatMoney(entry.amount)), key: ShareScreen.amountDiffersKey, style: style),
      if (!_qr.isNone && _qr.vatNumber != entry.supplierVatNumber) Text(words.shareSupplierDiffers, key: ShareScreen.supplierDiffersKey, style: style),
    ];
  }

  Widget _expenses() {
    final words = Words.of(context);
    final entries = widget.entriesOf(_project.id);
    return ListenableBuilder(
      listenable: entries,
      builder: (context, _) {
        final chosen = entries.all.where((entry) => entry.id == _chosen);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Text(words.shareExpense, style: Theme.of(context).textTheme.titleSmall),
            if (entries.message.isNotEmpty) Text(words.text(entries.message)),
            if (!entries.isLoading && entries.message.isEmpty && entries.all.isEmpty) Text(words.shareEmpty),
            RadioGroup<String>(
              groupValue: _chosen,
              onChanged: (id) => setState(() => _chosen = id ?? ''),
              child: Column(children: [for (final entry in entries.all) _entryRow(entry)]),
            ),
            for (final entry in chosen) ..._differences(entry),
            if (_message.isNotEmpty) Text(words.text(_message), key: ShareScreen.messageKey, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (chosen.isNotEmpty) FilledButton(key: ShareScreen.attachKey, onPressed: _saving ? null : _attach, child: Text(words.shareAttach)),
          ],
        );
      },
    );
  }

  OfferedItems _itemsOf(Project project) {
    final items = widget.itemsOf(project.id, _type);
    if (!identical(items, _shownItems)) {
      _shownItems = items;
      items.loadOnOpen();
    }
    return items;
  }

  Widget _body() {
    final words = Words.of(context);
    final project = _project;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          if (widget.file.isPdf) ListTile(leading: const Icon(Icons.picture_as_pdf_outlined), title: Text(widget.file.name)) else SizedBox(height: 160, child: Image.memory(widget.file.bytes, fit: BoxFit.contain)),
          if (!_qr.isNone) QrSummary(qr: _qr, offerSupplier: false, onAddSupplier: () {}),
          if (_open.length > 1)
            LabelledChips(
              label: words.shareProject,
              choices: _open,
              keyOf: (choice) => ShareScreen.projectKey(choice.id),
              nameOf: (choice) => choice.name,
              isChosen: (choice) => choice.id == project.id,
              onChosen: _chooseProject,
            ),
          FormSection([
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(key: ShareScreen.purchasesKey, label: Text(words.approvalsPurchases), selected: _type == ItemType.purchases, onSelected: (_) => _chooseType(ItemType.purchases)),
                ChoiceChip(key: ShareScreen.contractorPaymentsKey, label: Text(words.approvalsContractorPayments), selected: _type == ItemType.contractorPayments, onSelected: (_) => _chooseType(ItemType.contractorPayments)),
              ],
            ),
            ItemPicker(key: ShareScreen.itemKey, items: _itemsOf(project), label: words.expensesItem, itemName: _item.name, onChanged: _chooseItem),
            if (_item.id.isEmpty) Text(words.shareChooseItem) else _expenses(),
          ]),
          OutlinedButton(key: ShareScreen.newExpenseKey, onPressed: _newExpense, child: Text(words.shareNewExpense)),
          if (project.mayMoveMoney) OutlinedButton(key: ShareScreen.capitalReceiptKey, onPressed: _capitalReceipt, child: Text(words.shareCapitalReceipt)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(key: ShareScreen.closeKey, icon: const Icon(Icons.close), onPressed: widget.onDone),
        title: Text(words.shareTitle),
      ),
      body: ListenableBuilder(
        listenable: widget.projects,
        builder: (context, _) {
          if (_open.isNotEmpty) {
            return _body();
          }
          return widget.projects.isLoading ? const Center(child: CircularProgressIndicator()) : Center(child: Text(widget.projects.message.isEmpty ? words.shareNoProject : words.text(widget.projects.message), key: ShareScreen.noProjectKey));
        },
      ),
    );
  }
}
