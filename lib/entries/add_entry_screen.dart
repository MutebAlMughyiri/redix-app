import 'dart:async';

import 'package:flutter/material.dart';
import 'opened_entry.dart';
import '../accounts/account.dart';
import '../accounts/accounts.dart';
import '../api_list.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../accounts/offered_accounts.dart';
import '../attachments/attachments.dart';
import '../attachments/invoice_capture.dart';
import '../attachments/picked_file.dart';
import '../contractor_payments/contract_figures.dart';
import '../contracts/contract.dart';
import '../contracts/contracts.dart';
import '../expenses/column_value_field.dart';
import '../expenses/creditable_invoice.dart';
import '../expenses/creditable_invoices.dart';
import '../expenses/entry_date.dart';
import '../expenses/invoice_qr.dart';
import '../expenses/invoice_section.dart';
import '../expenses/original_invoice_picker.dart';
import '../expenses/payment_choice.dart';
import '../expenses/payment_choices.dart';
import '../expenses/qr_summary.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../settings/payment_methods.dart';
import '../structure/column_label.dart';
import '../structure/columns.dart';
import '../structure/item_column.dart';
import '../suppliers/quick_add_supplier_dialog.dart';
import '../suppliers/supplier.dart';
import '../suppliers/supplier_picker.dart';
import '../suppliers/suppliers.dart';
import '../ui/busy.dart';
import '../ui/entry_field.dart';
import '../ui/form_section.dart';
import '../ui/part_keys.dart';
import '../ui/picker_field.dart';
import '../ui/two_fields.dart';
import '../words/words.dart';
import 'entry_tables.dart';
import 'table_picker.dart';
import '../ui/refusal_snack_bar.dart';
import '../ui/screen_title.dart';
import 'entry_row.dart';
import 'saved_entry.dart';
import '../approvals/approvals.dart';
import 'entry_share.dart';
import 'reverse_sheet.dart';
import 'entry_recording.dart';
import '../attachments/entry_file.dart';
import '../ui/form_error.dart';
import '../ui/refusal_text.dart';
import '../ui/act_once.dart';

/// إضافة قيد (UC-022, UC-027, redix-app #84, redix-api #110): one form adds an entry to any table, and the table chosen says what it is. Every entry asks the same things in the
/// same place: its file, its table and date, its amount, its account and its notes, and is saved as a draft or sent for approval. A table adds only its own: a purchase its
/// supplier, credit note and what was bought (redix-api #96); a contract's payment the contract's figures, where going beyond its value only warns, and whether it is inside it;
/// a partner whether it is a withdrawal. An expense also says how it was paid and answers its item's columns, and a negative amount is a deduction, which says why in its notes.
/// A draft can wait for the required columns; sending cannot.
class AddEntryScreen extends StatefulWidget {
  /// The screen entering an entry in [project], recorded through [recording], into one of [tables], showing a contract's figures from [contracts], picking from [accounts] or
  /// [projectAccounts], [paymentMethods], [suppliers] and, for a credit note, [creditableInvoices], asking what [columnsOf] an item says, keeping the file through [attachments]
  /// from what [capture] gives, and offering to share it, read through [opened], once recorded.
  const AddEntryScreen({
    super.key,
    this.editingId = '',
    this.isReading = false,
    this.rejectionReason = '',
    required this.sharedFile,
    required this.project,
    required this.recording,
    required this.tables,
    required this.contracts,
    required this.accounts,
    required this.paymentMethods,
    required this.suppliers,
    required this.creditableInvoices,
    required this.columnsOf,
    required this.attachments,
    required this.capture,
    required this.opened,
    required this.approvals,
    required this.projectAccounts,
  });

  /// The entry being changed; empty for a new one.
  final String editingId;

  /// True to open [editingId] read only, as it was filled, until تعديل turns it into the form (redix-app #90).
  final bool isReading;

  /// The file it starts with, shared from another app (UC-046); none otherwise. The camera opens only when asked (Muteb, 8 Nov 2026).
  final PickedFile sharedFile;

  /// Why it was rejected; empty otherwise.
  final String rejectionReason;

  /// The project the entry belongs to.
  final Project project;

  /// The way to record it.
  final EntryRecording recording;

  /// The tables it may go into.
  final EntryTables tables;

  /// The project's contracts, for the figures of a contract's table.
  final Contracts contracts;

  /// What the signed-in user may pay an expense from.
  final OfferedAccounts accounts;

  /// The project's payment methods.
  final PaymentMethods paymentMethods;

  /// The register a purchase's supplier comes from.
  final Suppliers suppliers;

  /// What a credit note may return.
  final CreditableInvoices creditableInvoices;

  /// The columns of an item.
  final Columns Function(String itemId) columnsOf;

  /// The way to keep the file.
  final Attachments attachments;

  /// The phone's camera and files.
  final InvoiceCapture capture;

  /// The entry read by its id: an entry read only says where it stands and offers what can be done to it from it, whichever list opened it (findings row 201), and a
  /// recorded one is shared from it.
  final OpenedEntry opened;

  /// The entries waiting for a decision, through which an entry read only is approved (Muteb, 9 Nov 2026).
  final Approvals approvals;

  /// The project's accounts, any active one of which revenue reaches and a partner's money moves through.
  final Accounts projectAccounts;

  /// The screen's route.
  static const path = '/projects/:projectId/entries/new';

  /// The route of a new entry in the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/entries/new';

  /// The route of a new entry in the project [projectId] with the shared file.
  static String sharedPathOf(String projectId) => '/projects/$projectId/entries/new?shared=1';

  /// The button that opens the camera.
  static const cameraKey = Key('addEntry.camera');

  /// The button that opens the phone's files.
  static const filesKey = Key('addEntry.files');

  /// The picture of the file taken.
  static const invoicePictureKey = Key('addEntry.invoicePicture');

  /// The name of the file taken, or what to take.
  static const invoiceNameKey = Key('addEntry.invoiceName');

  /// The line that says why the file was not taken.
  static const invoiceMessageKey = Key('addEntry.invoiceMessage');

  /// The title over what the QR code holds.
  static const qrReadKey = Key('addEntry.qrRead');

  /// The seller the QR code names.
  static const qrSellerKey = Key('addEntry.qrSeller');

  /// The seller's VAT number in the QR code.
  static const qrVatNumberKey = Key('addEntry.qrVatNumber');

  /// When the QR code says the invoice was issued.
  static const qrTimeKey = Key('addEntry.qrTime');

  /// The total the QR code holds.
  static const qrAmountsKey = Key('addEntry.qrAmounts');

  /// The line that says the QR code's seller is not in the register.
  static const qrSupplierMissingKey = Key('addEntry.qrSupplierMissing');

  /// The button that adds the QR code's seller to the register.
  static const qrAddSupplierKey = Key('addEntry.qrAddSupplier');

  /// The line that says the QR code could not be read.
  static const qrMessageKey = Key('addEntry.qrMessage');

  /// Why the entry being changed was rejected.
  static const rejectionKey = Key('addEntry.rejection');

  /// The table.
  static const tableKey = Key('addEntry.table');

  /// A purchase's supplier.
  static const supplierKey = Key('addEntry.supplier');

  /// What is known of that supplier.
  static const supplierDetailsKey = Key('addEntry.supplierDetails');

  /// The date.
  static const dateKey = Key('addEntry.date');

  /// The switch that makes a purchase a credit note.
  static const creditNoteKey = Key('addEntry.creditNote');

  /// The bill a credit note returns.
  static const originalInvoiceKey = Key('addEntry.originalInvoice');

  /// What was bought.
  static const productKey = Key('addEntry.product');

  /// The price of one.
  static const unitPriceKey = Key('addEntry.unitPrice');

  /// How many.
  static const quantityKey = Key('addEntry.quantity');

  /// The amount: a purchase's total, or what is paid on a contract.
  static const amountKey = Key('addEntry.amount');

  /// The contract's value.
  static const valueKey = Key('addEntry.value');

  /// What was paid on the contract.
  static const paidKey = Key('addEntry.paid');

  /// What waits for approval on the contract, when anything does.
  static const pendingKey = Key('addEntry.pending');

  /// What remains of the contract after this payment.
  static const remainingKey = Key('addEntry.remaining');

  /// The bar of how much of the contract is reached.
  static const progressKey = Key('addEntry.progress');

  /// The warning that this payment goes beyond the contract's value.
  static const overrunKey = Key('addEntry.overrun');

  /// Inside the contract, on the switch of what a payment is.
  static const insideKey = Key('addEntry.inside');

  /// Outside the contract, on the same switch.
  static const outsideKey = Key('addEntry.outside');

  /// The line that says what outside the contract means.
  static const outsideExplainKey = Key('addEntry.outsideExplain');

  /// The notes.
  static const notesKey = Key('addEntry.notes');

  /// The button that sends it for approval.
  static const sendKey = Key('addEntry.send');

  /// The button that saves it as a draft.
  static const draftKey = Key('addEntry.draft');

  /// The line that says why it was refused.
  static const messageKey = Key('addEntry.message');

  /// The line that says the item's columns could not be read.
  static const columnsMessageKey = Key('addEntry.columnsMessage');

  /// The field of the item's column [key].
  static Key columnKey(String key) => Key('addEntry.column.$key');

  /// The section asking what the entry is for.
  static const forSectionKey = Key('addEntry.forSection');

  /// The section asking the item's own columns.
  static const columnsSectionKey = Key('addEntry.columnsSection');

  /// The section asking how it was paid.
  static const paymentSectionKey = Key('addEntry.paymentSection');

  /// The choice [option] of the list column [key].
  static Key columnOptionKey(String key, String option) => Key('addEntry.columnOption.$key.$option');

  /// The choice of a contractor payment's kind: inside the contract or outside it.
  static const kindKey = Key('addEntry.kind');

  /// Where an entry read only stands, in its status's color (redix-app #90).
  static const statusKey = Key('addEntry.status');

  /// The button turning an entry read only into the form: تعديل, or تصحيح once rejected.
  static const changeKey = Key('addEntry.change');

  /// The line saying why an entry read only cannot be changed.
  static const cannotChangeKey = Key('addEntry.cannotChange');

  /// The button sending a draft read only for approval.
  static const sendDraftKey = Key('addEntry.sendDraft');

  /// The button reversing an approved entry, which reads حذف (Muteb, 9 Nov 2026).
  static const reverseKey = Key('addEntry.reverse');

  /// The button approving an entry read only that waits, beside تعديل; grayed for whoever may not approve (Muteb, 9 Nov 2026).
  static const approveKey = Key('addEntry.approve');

  /// The title bar's button sharing an entry read only (redix-app #83).
  static const shareKey = Key('addEntry.share');

  /// The switch saying a partner's money is a withdrawal.
  static const withdrawalKey = Key('addEntry.withdrawal');

  /// The card of what the invoice's QR code says.
  static const qrSummaryKey = Key('addEntry.qrSummary');

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  late final _entryId = widget.editingId.isEmpty ? const Uuid().v7() : widget.editingId;
  var _keptOriginalId = '';
  final _product = TextEditingController();
  final _unitPrice = TextEditingController();
  final _quantity = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  final _customValues = <String, String>{};
  final _file = EntryFile();
  var _qr = InvoiceQr.none();
  var _qrMessage = '';
  var _qrSupplierMissing = false;
  var _table = EntryTable.none();
  var _columns = <ItemColumn>[];
  var _columnsMessage = '';
  var _supplier = Supplier.none();
  var _date = DateTime.now();
  var _isCreditNote = false;
  var _original = CreditableInvoice.none();
  var _isOutside = false;
  var _isWithdrawal = false;
  final _payment = PaymentChoice();
  var _message = '';
  var _refusedColumn = '';
  late var _reading = widget.isReading;
  var _saved = SavedEntry.none();

  @override
  void initState() {
    super.initState();
    widget.tables.loadOnOpen();
    widget.contracts.loadOnOpen();
    widget.accounts.loadOnOpen();
    widget.projectAccounts.loadOnOpen();
    widget.paymentMethods.loadOnOpen();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    for (final controller in [_product, _unitPrice, _quantity, _amount, _notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _start() {
    if (widget.editingId.isNotEmpty) {
      return _openEntry();
    }
    return widget.sharedFile.isNone ? Future.value() : _takeFrom(() async => widget.sharedFile);
  }

  /// Fills the form from the entry being changed (UC-033), in its table, whatever its kind. A credit note's total shows as typed, without its sign.
  Future<void> _openEntry() async {
    final saved = await widget.recording.read(widget.editingId);
    await Future.wait([widget.tables.load(), widget.contracts.load(), widget.accounts.load(), widget.projectAccounts.load(), widget.suppliers.load(), widget.opened.open(widget.editingId)]);
    if (!mounted || saved.isNone) {
      return;
    }
    final table = widget.tables.tableOf(saved.tableId);
    setState(() {
      _saved = saved;
      _supplier = widget.suppliers.all.where((supplier) => supplier.id == saved.supplierId).firstOrNull ?? Supplier.none();
      _product.text = saved.product;
      if (saved.unitPrice != 0) {
        _unitPrice.text = formatPlain(saved.unitPrice);
        _quantity.text = formatPlain(saved.quantity);
      }
      _isOutside = saved.isOutsideContract;
      _isWithdrawal = saved.isWithdrawal;
      _notes.text = saved.notes;
      _payment
        ..accountId = saved.accountId
        ..paymentMethodId = saved.paymentMethodId;
      _date = saved.date;
      _isCreditNote = saved.isCreditNote;
      _keptOriginalId = saved.originalEntryId;
      _amount.text = formatPlain(saved.isCreditNote ? saved.amount.abs() : saved.amount);
      _file.attachmentId = saved.attachmentId;
      _customValues.addAll(saved.customValues);
    });
    if (saved.attachmentId.isNotEmpty) {
      final kept = await whileBusy(context, widget.attachments.read(saved.attachmentId));
      if (mounted) {
        setState(() => _file.showKept(kept));
      }
    }
    if (!table.isNone) {
      final keptValues = Map.of(_customValues);
      await _chooseTable(table);
      if (mounted) {
        setState(() => _customValues.addAll(keptValues));
      }
    }
  }

  Future<void> _takeFrom(Future<PickedFile> Function() source) async {
    final file = await source();
    if (!mounted) {
      return;
    }
    setState(() {
      _file.take(file);
      if (!file.isNone) {
        _qr = InvoiceQr.none();
        _qrMessage = '';
        _qrSupplierMissing = false;
      }
    });
    if (!file.isNone && !file.isPdf) {
      await _readQr(file);
    }
  }

  /// Fills the date, the total and a purchase's supplier from the file's QR code (redix-api #96, D21).
  Future<void> _readQr(PickedFile file) async {
    final qr = InvoiceQr.parse(await whileBusy(context, widget.capture.qrTextOf(file)));
    if (!mounted) {
      return;
    }
    if (qr.isNone) {
      setState(() => _qrMessage = 'expenses.qrUnreadable');
      return;
    }
    setState(() {
      _qr = qr;
      _amount.text = formatPlain(qr.total);
      _date = qr.issuedAt;
    });
    final search = widget.suppliers.search;
    await search.find(qr.vatNumber);
    if (!mounted) {
      return;
    }
    final holders = search.all.where((supplier) => supplier.vatNumber == qr.vatNumber).toList();
    setState(() {
      _useSupplier(holders.isEmpty ? _supplier : holders.first);
      _qrSupplierMissing = holders.isEmpty;
    });
  }

  Future<void> _addSupplierFromQr() async {
    await showDialog<void>(
      context: context,
      builder: (_) => QuickAddSupplierDialog(
        project: widget.project,
        suppliers: widget.suppliers,
        typed: _qr.vatNumber,
        name: _qr.sellerName,
        onPicked: (supplier) => setState(() {
          _useSupplier(supplier);
          _qrSupplierMissing = false;
        }),
      ),
    );
  }

  /// Puts the entry in [table], reading its item's columns when the item changes.
  Future<void> _chooseTable(EntryTable table) async {
    final sameItem = table.itemId == _table.itemId;
    setState(() {
      _table = table;
      _refusedColumn = '';
      if (!sameItem) {
        _columns = [];
        _customValues.clear();
      }
    });
    if (sameItem || !table.isExpense) {
      return;
    }
    final columns = widget.columnsOf(table.itemId);
    await columns.load();
    if (mounted && _table.itemId == table.itemId) {
      setState(() {
        _columns = columns.all;
        _columnsMessage = columns.message;
      });
    }
  }

  /// Takes [supplier] for a purchase, and its usual item's general table while none is chosen.
  void _useSupplier(Supplier supplier) {
    if (supplier.id != _supplier.id) {
      _original = CreditableInvoice.none();
    }
    _supplier = supplier;
    final usual = widget.tables.generalTableOf(supplier.defaultItemId);
    if (_table.isNone && !usual.isNone) {
      unawaited(_chooseTable(usual));
    }
  }

  void _setCreditNote(bool isCreditNote) {
    _isCreditNote = isCreditNote;
    _original = CreditableInvoice.none();
  }

  Future<void> _pickSupplier() async {
    final picked = await SupplierPicker.show(context, widget.project, widget.suppliers);
    if (picked.id.isNotEmpty && mounted) {
      setState(() => _useSupplier(picked));
    }
  }

  Future<void> _chooseDate(DateTime current, ValueChanged<DateTime> onChosen) async {
    final chosen = await pickEntryDate(context, widget.project, current);
    if (mounted) {
      setState(() => onChosen(chosen));
    }
  }

  void _readListsAgain() {
    widget.tables.load();
    _accounts.load();
    widget.paymentMethods.load();
  }

  /// The accounts the table's entry may use.
  ApiList<Account> get _accounts => _table.isExpense ? widget.accounts : widget.projectAccounts;

  double get _typedAmount {
    final number = parseNumber(_amount.text);
    return number.isNaN ? 0 : number;
  }

  bool get _isDeduction => _typedAmount < 0;

  /// The contract of the table chosen; none for any other table.
  Contract get _contract => widget.contracts.all.where((contract) => _table.asksContract && contract.id == _table.id).firstOrNull ?? Contract.none();

  /// Each number field shown, its API name and the word key of what can be wrong with it.
  List<(String, TextEditingController, String)> get _numbers => [
    if (_table.asksSupplier) ...[('unitPrice', _unitPrice, 'expenses.invalidUnitPrice'), ('quantity', _quantity, 'expenses.invalidQuantity')],
    ('amount', _amount, 'expenses.invalidAmount'),
  ];

  /// The bill a credit note returns: the one chosen, or else the one it was saved with.
  String get _originalEntryId => _original.isNone ? _keptOriginalId : _original.entryId;

  /// What is sent for the entry, whatever its table (redix-api #110): what every entry has, then what only its table asks.
  Map<String, Object> _body(bool submit) {
    final accountId = _payment.chosenAccountIn(_accounts.all.where((account) => account.isActive).toList());
    return {
      'id': _entryId,
      if (!_table.isNone) ...{'itemId': _table.itemId, 'tableId': _table.id},
      'date': apiDate(_date),
      if (accountId.isNotEmpty) 'accountId': accountId,
      if (_table.isExpense && _payment.paymentMethodId.isNotEmpty) 'paymentMethodId': _payment.paymentMethodId,
      if (_file.attachmentId.isNotEmpty) 'attachmentId': _file.attachmentId,
      'notes': _notes.text,
      'customValues': ItemColumn.valuesToSend(_columns, _customValues),
      'submit': submit,
      for (final (name, field, _) in _numbers)
        if (field.text.trim().isNotEmpty) name: parseNumber(field.text),
      if (_table.asksContract) 'isOutsideContract': _isOutside,
      if (_table.asksWithdrawal) 'isWithdrawal': _isWithdrawal,
      if (_table.asksSupplier) ..._purchasePart,
    };
  }

  /// What only a purchase sends: its supplier, whether it is a credit note and of which bill, and what was bought.
  Map<String, Object> get _purchasePart => {
    if (_supplier.id.isNotEmpty) 'supplierId': _supplier.id,
    if (_isCreditNote) 'isCreditNote': true,
    if (_isCreditNote && _originalEntryId.isNotEmpty) 'originalEntryId': _originalEntryId,
    'product': _product.text,
  };

  /// The word key of what stops this being sent as it stands: a number field holding no number, or a deduction without its reason (D14); empty when nothing does.
  String get _whatIsWrong {
    for (final (_, field, wordKey) in _numbers) {
      if (field.text.trim().isNotEmpty && parseNumber(field.text).isNaN) {
        return wordKey;
      }
    }
    return _isDeduction && _notes.text.trim().isEmpty ? 'expenses.deductionNeedsNotes' : '';
  }

  Future<String> _record(bool submit) async {
    if (_whatIsWrong.isNotEmpty) {
      return _whatIsWrong;
    }
    final refusal = await whileBusy(context, _file.keep(widget.attachments));
    if (refusal == 'attachments.noConnection') {
      return widget.recording.keep(_body(submit), _file.picked, editing: widget.editingId, title: _table.label, details: _supplier.name);
    }
    if (refusal.isNotEmpty) {
      return refusal;
    }
    return widget.recording.record(_body(submit), editing: widget.editingId, title: _table.label, details: _supplier.name);
  }

  /// Says [wordKey] once the entry [entryId] is kept by the API, offering to share it (redix-app #83, R1). Everything the action needs is taken now, since the screen closes.
  void _offerShare(ScaffoldMessengerState messenger, Words words, String wordKey, String entryId) {
    final (capture, project, opened) = (widget.capture, widget.project, widget.opened);
    showMessage(messenger, words, wordKey, actionLabel: words.entriesShare, onAction: () => EntryShare.shareSaved(capture, project, opened, entryId, words));
  }

  Future<void> _save(bool submit) async {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final refusal = await _record(submit);
    if (!mounted) {
      return;
    }
    if (refusal.isEmpty) {
      final sent = widget.recording.wasOverrun ? 'contractorPayments.savedOverrun' : (submit ? 'expenses.sent' : 'expenses.saved');
      if (widget.recording.wasKept) {
        showMessage(messenger, words, 'expenses.keptOnPhone');
      } else {
        _offerShare(messenger, words, sent, _entryId);
      }
      context.pop(true);
      return;
    }
    setState(() {
      _message = refusal;
      _refusedColumn = widget.recording.refusedColumnKey;
    });
  }

  /// Whether the entry asks [key]: an expense when its item's columns hold it; revenue and a partner's money, which take no columns, always.
  bool _asks(String key) => _table.isNone || !_table.isExpense || _columns.any((column) => column.key == key);

  bool _requires(String key) => _columns.any((column) => column.key == key && column.isRequired);

  String _nameOf(String key, String word) => columnLabel(context, _columns, key, word);

  String _labelOf(String key, String word) => _requires(key) ? '${_nameOf(key, word)} *' : _nameOf(key, word);

  String? _errorOf(String key, Words words) => _refusedColumn == key ? words.text(_message) : null;

  Widget _textField(Key key, TextEditingController controller, String label, {bool isNumber = false, bool isSigned = false, int maxLines = 1, String? errorText}) =>
      entryField(key: key, controller: controller, label: label, isNumber: isNumber, isSigned: isSigned, maxLines: maxLines, errorText: errorText, onChanged: (_) => setState(() {}));

  List<Widget> _whatItIsFor(Words words) => [
    if (widget.rejectionReason.isNotEmpty) refusalText(context, '${words.entriesReason}: ${widget.rejectionReason}', AddEntryScreen.rejectionKey),
    _tablePicker(),
    PickerField(key: AddEntryScreen.dateKey, label: _nameOf('date', words.expensesDate), value: formatDate(_date), onTap: () => _chooseDate(_date, (date) => _date = date)),
    if (_table.asksContract) ..._theContract(words),
    if (_table.asksSupplier) ..._thePurchase(words),
    if (_table.asksWithdrawal) _theWithdrawal(words),
    _textField(AddEntryScreen.amountKey, _amount, _labelOf(_table.amountColumn, words.text(_table.amountWordKey)), isNumber: true, isSigned: _table.isExpense, errorText: _errorOf(_table.amountColumn, words)),
  ];

  /// What a purchase asks: its supplier, whether it is a credit note, and what was bought where the item's columns ask for it.
  List<Widget> _thePurchase(Words words) => [
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PickerField(key: AddEntryScreen.supplierKey, label: _nameOf('supplier', words.expensesSupplier), value: _supplier.name, onTap: _pickSupplier),
        if (_supplier.id.isNotEmpty) Text(_supplier.detailsIn(words), key: AddEntryScreen.supplierDetailsKey, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
    SwitchListTile(
      key: AddEntryScreen.creditNoteKey,
      contentPadding: EdgeInsets.zero,
      title: Text(words.expensesCreditNote, key: AddEntryScreen.creditNoteKey.title),
      subtitle: Text(words.expensesCreditNoteExplain, key: AddEntryScreen.creditNoteKey.subtitle),
      value: _isCreditNote,
      onChanged: (isCreditNote) => setState(() => _setCreditNote(isCreditNote)),
    ),
    if (_isCreditNote && _supplier.id.isNotEmpty)
      OriginalInvoicePicker(
        key: AddEntryScreen.originalInvoiceKey,
        invoices: widget.creditableInvoices,
        supplierId: _supplier.id,
        chosen: _original,
        onChanged: (invoice) => setState(() => _original = invoice),
      ),
    if (_asks('product')) _textField(AddEntryScreen.productKey, _product, _labelOf('product', words.expensesProduct), errorText: _errorOf('product', words)),
    if (_asks('unitPrice') || _asks('quantity'))
      TwoFields(
        _textField(AddEntryScreen.unitPriceKey, _unitPrice, _labelOf('unitPrice', words.expensesUnitPrice), isNumber: true, errorText: _errorOf('unitPrice', words)),
        _textField(AddEntryScreen.quantityKey, _quantity, _labelOf('quantity', words.expensesQuantity), isNumber: true, errorText: _errorOf('quantity', words)),
      ),
  ];

  /// What a contractor payment asks: the contract's figures with this payment counted, and whether it is inside the contract.
  List<Widget> _theContract(Words words) => [
    ListenableBuilder(listenable: widget.contracts, builder: (_, _) => ContractFigures(contract: _contract, counted: (_isOutside ? 0 : _typedAmount) - _saved.heldBy(_table.id))),
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        Text(words.contractorPaymentsKind, key: AddEntryScreen.kindKey.label, style: Theme.of(context).textTheme.titleSmall),
        SegmentedButton<bool>(
          key: AddEntryScreen.kindKey,
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: false, label: Text(words.contractorPaymentsInside, key: AddEntryScreen.insideKey)),
            ButtonSegment(value: true, label: Text(words.contractorPaymentsOutside, key: AddEntryScreen.outsideKey)),
          ],
          selected: {_isOutside},
          onSelectionChanged: (selected) => setState(() => _isOutside = selected.single),
        ),
        Text(words.contractorPaymentsOutsideExplain, key: AddEntryScreen.outsideExplainKey, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  ];

  /// What a partner asks: whether the money is a withdrawal, in the place a purchase asks whether it is a credit note.
  Widget _theWithdrawal(Words words) => SwitchListTile(
    key: AddEntryScreen.withdrawalKey,
    contentPadding: EdgeInsets.zero,
    title: Text(words.entriesWithdrawal, key: AddEntryScreen.withdrawalKey.title),
    subtitle: Text(words.entriesWithdrawalHint, key: AddEntryScreen.withdrawalKey.subtitle),
    value: _isWithdrawal,
    onChanged: (isWithdrawal) => setState(() => _isWithdrawal = isWithdrawal),
  );

  List<Widget> _itemsOwnFields(Words words) => [
    if (_columnsMessage.isNotEmpty) Text(words.text(_columnsMessage), key: AddEntryScreen.columnsMessageKey),
    for (final column in _columns.where((column) => column.isCustom))
      ColumnValueField(
        column: column,
        value: _customValues[column.key] ?? '',
        error: _refusedColumn == column.key ? _message : '',
        onChanged: (value) => _customValues[column.key] = value,
        onChooseDate: _chooseDate,
      ),
  ];

  Widget _paymentSection(Words words) => FormSection(key: AddEntryScreen.paymentSectionKey, [
    PaymentChoices(choice: _payment, accounts: _accounts, asksPaymentMethod: _table.isExpense, paymentMethods: widget.paymentMethods, onChanged: () => setState(() {}), onRetry: _readListsAgain),
    if (_asks('notes')) _textField(AddEntryScreen.notesKey, _notes, _labelOf('notes', words.expensesNotes), maxLines: 2, errorText: _errorOf('notes', words)),
  ]);

  Widget _tablePicker() => TablePicker(key: AddEntryScreen.tableKey, tables: widget.tables, chosen: _table, onChanged: _chooseTable);

  /// The entry read only, as the lists show it, read by its id (findings row 201); none until it answers.
  EntryRow get _row => widget.opened.value;

  String get _title {
    final words = Words.of(context);
    return _reading ? words.entriesView : (widget.editingId.isEmpty ? words.entriesNew : words.entriesEdit);
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final ownFields = _itemsOwnFields(words);
    return ListenableBuilder(
      listenable: widget.opened,
      builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: ScreenTitle(_title, subject: widget.project.name),
        actions: [
          if (_reading && !_row.isNone)
            IconButton(key: AddEntryScreen.shareKey, tooltip: words.entriesShare, icon: Icon(Icons.share_outlined, key: AddEntryScreen.shareKey.icon), onPressed: () => EntryShare.share(widget.capture, widget.project, _row, words)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_message.isNotEmpty) FormError(text: words.text(_message), textKey: AddEntryScreen.messageKey),
            if (_reading && !_row.isNone) _standing(words),
            InvoiceSection(
              project: widget.project,
              file: _file.picked,
              emptyLabel: words.text(_table.fileWordKey),
              message: _file.message,
              onCamera: () => _takeFrom(() => whileBusy(context, widget.capture.fromCamera())),
              onFiles: () => _takeFrom(() => whileBusy(context, widget.capture.fromFiles())),
              isReading: _reading,
            ),
            IgnorePointer(ignoring: _reading, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _entryFields(words, ownFields))),
            const SizedBox(height: 16),
            if (!_reading) _formActions(words) else if (!_row.isNone) _readingActions(words),
          ],
        ),
      ),
      ),
    );
  }

  /// Where an entry read only stands, in its status's color (redix-app #90).
  Widget _standing(Words words) {
    final status = _row.status;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(words.text(_row.statusWordKey), key: AddEntryScreen.statusKey, style: TextStyle(color: status.isMarked ? status.color.of(context) : null, fontWeight: FontWeight.w600)),
    );
  }

  /// What an entry read only offers at its bottom (redix-app #90, D3, D4): تعديل, grayed with the reason where it cannot work; اعتماد beside it on a waiting entry, grayed
  /// for whoever may not approve (Muteb, 9 Nov 2026); a draft's إرسال للاعتماد; and حذف, which reverses an approved entry, for whoever approves.
  Widget _readingActions(Words words) {
    final row = _row;
    final mayChange = row.allows(widget.project, row.kind.recordedWith);
    final mayReverse = widget.project.mayApproveEntries && row.isApproved && !row.isReversed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        ActOnce(builder: (once) => Row(
          spacing: 8,
          children: [
            Expanded(
              flex: 2,
              child: FilledButton(
                key: AddEntryScreen.changeKey,
                onPressed: once(mayChange ? () => setState(() => _reading = false) : null),
                child: Text(row.isRejected ? words.entriesFix : words.entriesEdit, key: AddEntryScreen.changeKey.label),
              ),
            ),
            if (row.isPending)
              Expanded(
                child: FilledButton.tonal(key: AddEntryScreen.approveKey, onPressed: once(widget.project.mayApproveEntries ? () => _approve(row) : null), child: Text(words.approvalsApprove, key: AddEntryScreen.approveKey.label)),
              ),
            if (row.isDraft && mayChange) Expanded(child: OutlinedButton(key: AddEntryScreen.sendDraftKey, onPressed: once(_sendDraft), child: Text(words.entriesSend, key: AddEntryScreen.sendDraftKey.label))),
            if (mayReverse)
              Expanded(
                child: OutlinedButton(key: AddEntryScreen.reverseKey, onPressed: once(() => ReverseSheet.show(context, widget.opened.reverse)), child: Text(words.entriesReverse, key: AddEntryScreen.reverseKey.label)),
              ),
          ],
        )),
        if (!mayChange) Text(words.text(row.isApproved ? 'entries.approvedCannotChange' : 'entries.notYours'), key: AddEntryScreen.cannotChangeKey, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  /// Approves [row] as Approvals does, then goes back to the list, which reads itself again (findings row 207); what the API could not approve shows why, and the page stays.
  Future<void> _approve(EntryRow row) async {
    final refusal = await showRefusalOf(context, widget.approvals.approve([row.id]));
    if (refusal.isNotEmpty || !mounted) {
      return;
    }
    final failed = widget.approvals.failed[row.id] ?? '';
    if (failed.isNotEmpty) {
      showMessage(ScaffoldMessenger.of(context), Words.of(context), failed);
      return;
    }
    context.pop(true);
  }

  Future<void> _sendDraft() async {
    final refusal = await showRefusalOf(context, widget.opened.send());
    if (refusal.isEmpty && mounted) {
      context.pop(true);
    }
  }

  /// Send and Save draft, under the form.
  Widget _formActions(Words words) => ActOnce(builder: (once) => Row(
    spacing: 8,
    children: [
      Expanded(
        flex: 2,
        child: FilledButton(key: AddEntryScreen.sendKey, onPressed: once(() => _save(true)), child: Text(words.expensesSend, key: AddEntryScreen.sendKey.label)),
      ),
      Expanded(
        child: OutlinedButton(key: AddEntryScreen.draftKey, onPressed: once(() => _save(false)), child: Text(words.expensesSaveDraft, key: AddEntryScreen.draftKey.label)),
      ),
    ],
  ));

  /// What every table asks, under the file: the QR code's reading, what it is for, the item's own columns, the account and notes.
  List<Widget> _entryFields(Words words, List<Widget> ownFields) => [
            if (_qrMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(words.text(_qrMessage), key: AddEntryScreen.qrMessageKey),
              ),
            if (!_qr.isNone) QrSummary(qr: _qr, offerSupplier: _qrSupplierMissing && _table.asksSupplier && widget.project.mayAddSupplier, onAddSupplier: _addSupplierFromQr),
            FormSection(key: AddEntryScreen.forSectionKey, _whatItIsFor(words)),
            if (ownFields.isNotEmpty) FormSection(key: AddEntryScreen.columnsSectionKey, ownFields),
            _paymentSection(words),
  ];
}
