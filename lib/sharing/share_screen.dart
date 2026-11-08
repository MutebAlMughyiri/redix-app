import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../attachments/attachments.dart';
import '../attachments/invoice_capture.dart';
import '../attachments/picked_file.dart';
import '../entries/add_entry_screen.dart';
import '../expenses/invoice_qr.dart';
import '../expenses/qr_summary.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../projects/projects.dart';
import '../structure/category.dart';
import '../structure/item_picker.dart';
import '../structure/offered_items.dart';
import '../ui/bottom_button.dart';
import '../ui/form_section.dart';
import '../ui/labelled_chips.dart';
import '../ui/part_keys.dart';
import '../ui/refusal_snack_bar.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'attachable_entries.dart';
import 'attachable_entry.dart';
import '../ui/app_color.dart';

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


  /// The line saying why it was refused.
  static const messageKey = Key('share.message');

  /// The choice of the project [id].
  static Key projectKey(String id) => Key('share.project.$id');

  /// The expense [id].
  static Key entryKey(String id) => Key('share.entry.$id');

  /// The mark on the expense [id] that matches the QR code.
  static Key matchingKey(String id) => Key('share.matching.$id');

  /// The choice of the project the file goes to.
  static const projectChoiceKey = Key('share.projectChoice');

  /// The section asking what the file is for.
  static const forSectionKey = Key('share.forSection');

  /// The heading over the expenses a file can go to.
  static const expenseHeadingKey = Key('share.expenseHeading');

  /// Why the expenses could not be read.
  static const entriesMessageKey = Key('share.entriesMessage');

  /// The line saying no expense waits for a file.
  static const emptyKey = Key('share.empty');

  /// The file shared, when it is a PDF.
  static const fileKey = Key('share.file');

  /// The line asking for an item first.
  static const chooseItemKey = Key('share.chooseItem');

  /// The spinner while the projects are read.
  static const loadingKey = Key('share.loading');

  /// The picture shared, when it is one.
  static const pictureKey = Key('share.picture');

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
      showMessage(messenger, words, 'share.attached');
      widget.onDone();
      return;
    }
    setState(() {
      _saving = false;
      _message = refusal;
    });
  }

  Future<void> _newExpense() async {
    final saved = await context.push<bool>(AddEntryScreen.sharedPathOf(_project.id), extra: _project);
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
      title: Text(title, key: ShareScreen.entryKey(entry.id).title),
      subtitle: Text('${entry.supplierName} · ${formatDate(entry.date)}', key: ShareScreen.entryKey(entry.id).subtitle),
      secondary: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(formatMoney(entry.amount), key: ShareScreen.entryKey(entry.id).trailing),
          if (entry.isMatching) Text(words.shareMatching, key: ShareScreen.matchingKey(entry.id), style: TextStyle(color: AppColor.brand.of(context))),
        ],
      ),
    );
  }

  List<Widget> _differences(AttachableEntry entry) {
    final words = Words.of(context);
    final style = TextStyle(color: AppColor.refusal.of(context));
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
            Text(words.shareExpense, key: ShareScreen.expenseHeadingKey, style: Theme.of(context).textTheme.titleSmall),
            if (entries.message.isNotEmpty) Text(words.text(entries.message), key: ShareScreen.entriesMessageKey),
            if (!entries.isLoading && entries.message.isEmpty && entries.all.isEmpty) Text(words.shareEmpty, key: ShareScreen.emptyKey),
            RadioGroup<String>(
              groupValue: _chosen,
              onChanged: (id) => setState(() => _chosen = id ?? ''),
              child: Column(children: [for (final entry in entries.all) _entryRow(entry)]),
            ),
            for (final entry in chosen) ..._differences(entry),
            if (_message.isNotEmpty) Text(words.text(_message), key: ShareScreen.messageKey, style: TextStyle(color: AppColor.refusal.of(context))),
            if (chosen.isNotEmpty) FilledButton(key: ShareScreen.attachKey, onPressed: _saving ? null : _attach, child: Text(words.shareAttach, key: ShareScreen.attachKey.label)),
          ],
        );
      },
    );
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
          if (widget.file.isPdf) ListTile(key: ShareScreen.fileKey, leading: Icon(Icons.picture_as_pdf_outlined, key: ShareScreen.fileKey.icon), title: Text(widget.file.name, key: ShareScreen.fileKey.title)) else SizedBox(height: 160, child: Image.memory(widget.file.bytes, key: ShareScreen.pictureKey, fit: BoxFit.contain)),
          if (!_qr.isNone) QrSummary(qr: _qr, offerSupplier: false, onAddSupplier: () {}),
          if (_open.length > 1)
            LabelledChips(
              key: ShareScreen.projectChoiceKey,
              label: words.shareProject,
              choices: _open,
              keyOf: (choice) => ShareScreen.projectKey(choice.id),
              nameOf: (choice) => choice.name,
              isChosen: (choice) => choice.id == project.id,
              onChosen: _chooseProject,
            ),
          FormSection(key: ShareScreen.forSectionKey, [
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(key: ShareScreen.purchasesKey, label: Text(words.approvalsPurchases, key: ShareScreen.purchasesKey.label), selected: _type == ItemType.purchases, onSelected: (_) => _chooseType(ItemType.purchases)),
                ChoiceChip(key: ShareScreen.contractorPaymentsKey, label: Text(words.approvalsContractorPayments, key: ShareScreen.contractorPaymentsKey.label), selected: _type == ItemType.contractorPayments, onSelected: (_) => _chooseType(ItemType.contractorPayments)),
              ],
            ),
            ItemPicker(key: ShareScreen.itemKey, items: widget.itemsOf(project.id, _type), label: words.expensesItem, itemName: _item.name, onChanged: _chooseItem),
            if (_item.id.isEmpty) Text(words.shareChooseItem, key: ShareScreen.chooseItemKey) else _expenses(),
          ]),
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
        leading: IconButton(key: ShareScreen.closeKey, icon: Icon(Icons.close, key: ShareScreen.closeKey.icon), onPressed: widget.onDone),
        title: Text(words.shareTitle, key: ScreenTitle.titleKey),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: widget.projects,
        builder: (context, _) => _open.isEmpty ? const SizedBox.shrink() : BottomButton(buttonKey: ShareScreen.newExpenseKey, label: words.shareNewExpense, onPressed: _newExpense),
      ),
      body: ListenableBuilder(
        listenable: widget.projects,
        builder: (context, _) {
          if (_open.isNotEmpty) {
            return _body();
          }
          return widget.projects.isLoading ? const Center(child: CircularProgressIndicator(key: ShareScreen.loadingKey)) : Center(child: Text(widget.projects.message.isEmpty ? words.shareNoProject : words.text(widget.projects.message), key: ShareScreen.noProjectKey));
        },
      ),
    );
  }
}
