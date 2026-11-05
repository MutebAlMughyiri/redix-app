import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../accounts/offered_accounts.dart';
import '../attachments/attachments.dart';
import '../attachments/invoice_capture.dart';
import '../attachments/picked_file.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../settings/payment_methods.dart';
import '../structure/category.dart';
import '../structure/column_label.dart';
import '../structure/columns.dart';
import '../structure/item_column.dart';
import '../structure/item_picker.dart';
import '../structure/offered_items.dart';
import '../suppliers/supplier.dart';
import '../suppliers/quick_add_supplier_dialog.dart';
import '../suppliers/supplier_picker.dart';
import '../suppliers/suppliers.dart';
import '../ui/confirm_dialog.dart';
import '../ui/entry_field.dart';
import '../ui/form_section.dart';
import '../ui/labelled_chips.dart';
import '../ui/picker_field.dart';
import '../ui/two_fields.dart';
import '../words/words.dart';
import 'column_value_field.dart';
import 'creditable_invoice.dart';
import 'creditable_invoices.dart';
import 'duplicate_invoice_dialog.dart';
import 'entry_date.dart';
import 'expenses.dart';
import 'figures_box.dart';
import 'invoice_figures.dart';
import 'invoice_qr.dart';
import 'invoice_section.dart';
import 'original_invoice_picker.dart';
import 'payment_choice.dart';
import 'payment_choices.dart';
import 'qr_summary.dart';

/// A new purchase expense (UC-021, UC-022): the invoice first, then what it was for and how it was paid. The amounts below the fields only show what the API will compute. A draft can wait for the invoice and the required columns; sending cannot.
class AddExpenseScreen extends StatefulWidget {
  /// The screen entering an expense in [project], recorded through [expenses], picking from [items], [accounts], [paymentMethods], [suppliers] and, for a credit note, [creditableInvoices], asking what [columnsOf] an item says, and keeping the invoice through [attachments] from what [capture] gives.
  const AddExpenseScreen({
    super.key,
    required this.project,
    required this.expenses,
    required this.items,
    required this.accounts,
    required this.paymentMethods,
    required this.suppliers,
    required this.creditableInvoices,
    required this.columnsOf,
    required this.attachments,
    required this.capture,
  });

  /// The project the expense belongs to.
  final Project project;

  /// The way to record it.
  final Expenses expenses;

  /// The items that take purchases.
  final OfferedItems items;

  /// What the signed-in user may pay from.
  final OfferedAccounts accounts;

  /// The project's payment methods.
  final PaymentMethods paymentMethods;

  /// The register its supplier comes from.
  final Suppliers suppliers;

  /// What a credit note may return.
  final CreditableInvoices creditableInvoices;

  /// The columns of an item.
  final Columns Function(String itemId) columnsOf;

  /// The way to keep the invoice.
  final Attachments attachments;

  /// The phone's camera and files.
  final InvoiceCapture capture;

  /// The screen's route.
  static const path = '/projects/:projectId/expenses/new';

  /// The route of a new expense in the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/expenses/new';

  /// The screen's title.
  static const titleKey = Key('addExpense.title');

  /// The project's name, under the title.
  static const projectNameKey = Key('addExpense.projectName');

  /// The button that opens the camera.
  static const cameraKey = Key('addExpense.camera');

  /// The button that opens the phone's files.
  static const filesKey = Key('addExpense.files');

  /// The picture of the invoice.
  static const invoicePictureKey = Key('addExpense.invoicePicture');

  /// The line under the place of the invoice: what it is for until there is one, and the name of a PDF.
  static const invoiceNameKey = Key('addExpense.invoiceName');

  /// The line that says why the last try gave no file.
  static const invoiceMessageKey = Key('addExpense.invoiceMessage');

  /// The title over what was read from the invoice's QR code.
  static const qrReadKey = Key('addExpense.qrRead');

  /// The seller, from the QR code.
  static const qrSellerKey = Key('addExpense.qrSeller');

  /// The VAT number, from the QR code.
  static const qrVatNumberKey = Key('addExpense.qrVatNumber');

  /// The date and time, from the QR code.
  static const qrTimeKey = Key('addExpense.qrTime');

  /// The total and the VAT, from the QR code.
  static const qrAmountsKey = Key('addExpense.qrAmounts');

  /// The line that says no supplier holds the QR code's number.
  static const qrSupplierMissingKey = Key('addExpense.qrSupplierMissing');

  /// The button that adds the seller to the register.
  static const qrAddSupplierKey = Key('addExpense.qrAddSupplier');

  /// The line that says no QR code could be read.
  static const qrMessageKey = Key('addExpense.qrMessage');

  /// The warning that the QR code's VAT differs from the computed VAT.
  static const qrVatDiffersKey = Key('addExpense.qrVatDiffers');

  /// The switch that says the expense has no invoice.
  static const withoutInvoiceKey = Key('addExpense.withoutInvoice');

  /// Why it has none.
  static const withoutInvoiceReasonKey = Key('addExpense.withoutInvoiceReason');

  /// The item.
  static const itemKey = Key('addExpense.item');

  /// The supplier.
  static const supplierKey = Key('addExpense.supplier');

  /// What is known of the supplier: its VAT number or that it has none.
  static const supplierDetailsKey = Key('addExpense.supplierDetails');

  /// The invoice's number.
  static const invoiceNumberKey = Key('addExpense.invoiceNumber');

  /// The invoice's date.
  static const invoiceDateKey = Key('addExpense.invoiceDate');

  /// The switch that says this is a credit note.
  static const creditNoteKey = Key('addExpense.creditNote');

  /// The invoice a credit note returns.
  static const originalInvoiceKey = Key('addExpense.originalInvoice');

  /// The product.
  static const productKey = Key('addExpense.product');

  /// The unit price.
  static const unitPriceKey = Key('addExpense.unitPrice');

  /// The quantity.
  static const quantityKey = Key('addExpense.quantity');

  /// The amount including VAT, on the switch of what the amount is.
  static const includingVatKey = Key('addExpense.includingVat');

  /// The amount before VAT, on the same switch.
  static const beforeVatKey = Key('addExpense.beforeVat');

  /// The amount.
  static const amountKey = Key('addExpense.amount');

  /// The discount.
  static const discountKey = Key('addExpense.discount');

  /// The switch that says the invoice is not taxable.
  static const notTaxableKey = Key('addExpense.notTaxable');

  /// The amount before VAT after the discount, computed.
  static const afterDiscountKey = Key('addExpense.afterDiscount');

  /// The VAT, computed.
  static const vatKey = Key('addExpense.vat');

  /// The total, computed.
  static const totalKey = Key('addExpense.total');

  /// The line that says the user holds nothing to pay from.
  static const noAccountKey = PaymentChoices.noAccountKey;

  /// The switch that says the payment differs from the invoice.
  static const paymentDiffersKey = Key('addExpense.paymentDiffers');

  /// The payment's date.
  static const paymentDateKey = Key('addExpense.paymentDate');

  /// The amount paid.
  static const paymentAmountKey = Key('addExpense.paymentAmount');

  /// The bank fees.
  static const bankFeesKey = Key('addExpense.bankFees');

  /// The notes.
  static const notesKey = Key('addExpense.notes');

  /// The button that sends it for approval.
  static const sendKey = Key('addExpense.send');

  /// The button that saves it as a draft.
  static const draftKey = Key('addExpense.draft');

  /// The line that says why it was refused.
  static const messageKey = Key('addExpense.message');

  /// The line that says it was saved or sent, on the screen it goes back to.
  static const savedKey = Key('addExpense.saved');

  /// The line that says a list could not be read.
  static const listMessageKey = PaymentChoices.listMessageKey;

  /// The button that reads that list again.
  static const retryKey = PaymentChoices.retryKey;

  /// The earlier entry, in the question about a repeated invoice.
  static const earlierKey = ConfirmDialog.subjectKey;

  /// The button that saves it anyway, in that question.
  static const saveAnywayKey = ConfirmDialog.confirmKey;

  /// The choice of the unit [id].
  static Key unitKey(String id) => Key('addExpense.unit.$id');

  /// The choice of the subgroup [id].
  static Key subgroupKey(String id) => Key('addExpense.subgroup.$id');

  /// The field of the column [key].
  static Key columnKey(String key) => Key('addExpense.column.$key');

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _entryId = const Uuid().v7();
  final _invoiceNumber = TextEditingController();
  final _product = TextEditingController();
  final _unitPrice = TextEditingController();
  final _quantity = TextEditingController();
  final _amount = TextEditingController();
  final _discount = TextEditingController();
  final _paymentAmount = TextEditingController();
  final _bankFees = TextEditingController();
  final _notes = TextEditingController();
  final _withoutInvoiceReason = TextEditingController();
  final _customValues = <String, String>{};
  var _invoice = PickedFile.none();
  var _invoiceMessage = '';
  var _attachmentId = '';
  var _qr = InvoiceQr.none();
  var _qrMessage = '';
  var _qrSupplierMissing = false;
  var _item = Item.none();
  var _columns = <ItemColumn>[];
  var _columnsMessage = '';
  var _subgroupId = '';
  var _unitId = '';
  var _supplier = Supplier.none();
  var _invoiceDate = DateTime.now();
  var _paymentDate = DateTime.now();
  var _amountIncludesVat = true;
  var _isNotTaxable = false;
  var _paymentDiffers = false;
  var _withoutInvoice = false;
  var _isCreditNote = false;
  var _original = CreditableInvoice.none();
  final _payment = PaymentChoice();
  var _message = '';
  var _refusedColumn = '';
  var _saving = false;

  @override
  void initState() {
    super.initState();
    widget.items.loadOnOpen();
    widget.accounts.loadOnOpen();
    widget.paymentMethods.loadOnOpen();
    WidgetsBinding.instance.addPostFrameCallback((_) => _takeFrom(widget.capture.fromCamera));
  }

  @override
  void dispose() {
    for (final controller in [_invoiceNumber, _product, _unitPrice, _quantity, _amount, _discount, _paymentAmount, _bankFees, _notes, _withoutInvoiceReason]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _takeFrom(Future<PickedFile> Function() source) async {
    final file = await source();
    if (!mounted) {
      return;
    }
    setState(() {
      _invoiceMessage = file.failure;
      if (!file.isNone) {
        _invoice = file;
        _attachmentId = '';
        _qr = InvoiceQr.none();
        _qrMessage = '';
        _qrSupplierMissing = false;
      }
    });
    if (!file.isNone && !file.isPdf) {
      await _readQr(file);
    }
  }

  Future<void> _readQr(PickedFile file) async {
    final qr = InvoiceQr.parse(await widget.capture.qrTextOf(file));
    if (!mounted) {
      return;
    }
    if (qr.isNone) {
      setState(() => _qrMessage = 'expenses.qrUnreadable');
      return;
    }
    setState(() {
      _qr = qr;
      _amountIncludesVat = true;
      _amount.text = formatPlain(qr.total);
      _invoiceDate = qr.issuedAt;
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

  Future<void> _chooseItem(Item item) async {
    setState(() {
      _item = item;
      _subgroupId = '';
      _columns = [];
      _customValues.clear();
      _refusedColumn = '';
    });
    final columns = widget.columnsOf(item.id);
    await columns.load();
    if (mounted && _item.id == item.id) {
      setState(() {
        _columns = columns.all;
        _columnsMessage = columns.message;
      });
    }
  }

  void _useSupplier(Supplier supplier) {
    if (supplier.id != _supplier.id) {
      _original = CreditableInvoice.none();
    }
    _supplier = supplier;
    final usual = widget.items.all.expand((category) => category.items).where((item) => item.id == supplier.defaultItemId);
    if (_item.id.isEmpty && usual.isNotEmpty) {
      unawaited(_chooseItem(usual.first));
    }
  }

  void _setCreditNote(bool isCreditNote) {
    _isCreditNote = isCreditNote;
    _original = CreditableInvoice.none();
  }

  Future<void> _pickSupplier() async {
    final picked = await SupplierPicker.show(context, widget.project, widget.suppliers);
    if (picked.id.isNotEmpty) {
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
    widget.items.load();
    widget.accounts.load();
    widget.paymentMethods.load();
  }

  double _typed(TextEditingController field) {
    final number = parseNumber(field.text);
    return number.isNaN ? 0 : number;
  }

  bool get _hasNoVat => _isNotTaxable || _withoutInvoice || _typed(_amount) < 0 || (_supplier.id.isNotEmpty && _supplier.vatNumber.isEmpty);

  double get _vatPercent {
    if (!_original.isNone) {
      return _original.vatRate * 100;
    }
    return _hasNoVat ? 0 : widget.project.vatPercent;
  }

  InvoiceFigures get _figures {
    final typed = _typed(_amount);
    final figures = InvoiceFigures.of(
      amount: typed != 0 ? typed : _typed(_unitPrice) * _typed(_quantity),
      includesVat: typed == 0 || _amountIncludesVat,
      discount: _typed(_discount),
      vatRate: _vatPercent / 100,
    );
    return _isCreditNote ? figures.negated : figures;
  }

  String _isoOf(DateTime date) => date.toIso8601String().substring(0, 10);

  bool get _paysOtherThanInvoiced => _paymentDiffers && !_withoutInvoice;

  /// Each number field's API name, field and the word key of what can be wrong with it.
  List<(String, TextEditingController, String)> get _numbers => [
    ('unitPrice', _unitPrice, 'expenses.invalidUnitPrice'),
    ('quantity', _quantity, 'expenses.invalidQuantity'),
    ('amount', _amount, 'expenses.invalidAmount'),
    ('discount', _discount, 'expenses.invalidDiscount'),
    if (_paysOtherThanInvoiced) ('paymentAmount', _paymentAmount, 'expenses.invalidPaymentAmount'),
    if (_paysOtherThanInvoiced) ('bankFees', _bankFees, 'expenses.invalidBankFees'),
  ];

  Map<String, Object> _body(bool submit, bool confirmDuplicate) => {
    'id': _entryId,
    if (_item.id.isNotEmpty) 'itemId': _item.id,
    if (_subgroupId.isNotEmpty) 'subgroupId': _subgroupId,
    if (_unitId.isNotEmpty) 'unitId': _unitId,
    if (_supplier.id.isNotEmpty) 'supplierId': _supplier.id,
    if (_withoutInvoice)
      'withoutInvoiceReason': _withoutInvoiceReason.text
    else ...{
      'invoiceNumber': westernDigits(_invoiceNumber.text),
      'invoiceDate': _isoOf(_invoiceDate),
      if (_attachmentId.isNotEmpty) 'attachmentId': _attachmentId,
    },
    if (_isCreditNote) 'isCreditNote': true,
    if (!_original.isNone) 'originalEntryId': _original.entryId,
    'product': _product.text,
    'amountIncludesVat': _amountIncludesVat,
    'isNotTaxable': _isNotTaxable,
    if (_payment.chosenAccountIn(widget.accounts.all).isNotEmpty) 'accountId': _payment.chosenAccountIn(widget.accounts.all),
    if (_payment.paymentMethodId.isNotEmpty) 'paymentMethodId': _payment.paymentMethodId,
    if (_paymentDiffers || _withoutInvoice) 'paymentDate': _isoOf(_paymentDate),
    'notes': _notes.text,
    'customValues': ItemColumn.valuesToSend(_columns, _customValues),
    'submit': submit,
    if (confirmDuplicate) 'confirmDuplicate': true,
    for (final (name, field, _) in _numbers)
      if (field.text.trim().isNotEmpty) name: parseNumber(field.text),
  };

  /// The word key of the first number field holding no number; empty when none does.
  String get _notANumber {
    for (final (_, field, wordKey) in _numbers) {
      if (field.text.trim().isNotEmpty && parseNumber(field.text).isNaN) {
        return wordKey;
      }
    }
    return '';
  }

  Future<String> _record(bool submit, bool confirmDuplicate) async {
    if (_notANumber.isNotEmpty) {
      return _notANumber;
    }
    if (_withoutInvoice && _withoutInvoiceReason.text.trim().isEmpty) {
      return 'expenses.invalidWithoutInvoiceReason';
    }
    if (!_withoutInvoice && !_invoice.isNone && _attachmentId.isEmpty) {
      final refusal = await widget.attachments.keep(_invoice);
      if (refusal == 'attachments.noConnection') {
        return widget.expenses.keepPurchase(_body(submit, confirmDuplicate), _invoice);
      }
      if (refusal.isNotEmpty) {
        return refusal;
      }
      _attachmentId = widget.attachments.kept.id;
    }
    return widget.expenses.record(_body(submit, confirmDuplicate));
  }

  void _askAboutDuplicate(bool submit) {
    final earlier = widget.expenses.earlier;
    showDialog<void>(
      context: context,
      builder: (_) => DuplicateInvoiceDialog(earlier: earlier, onConfirm: () => _save(submit, confirmDuplicate: true)),
    );
  }

  Future<void> _save(bool submit, {bool confirmDuplicate = false}) async {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    final refusal = await _record(submit, confirmDuplicate);
    if (!mounted) {
      return;
    }
    if (refusal.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(widget.expenses.wasKept ? words.expensesKeptOnPhone : (submit ? words.expensesSent : words.expensesSaved), key: AddExpenseScreen.savedKey)));
      context.pop();
      return;
    }
    final isDuplicate = refusal == 'expenses.duplicateInvoice';
    setState(() {
      _saving = false;
      _message = isDuplicate ? '' : refusal;
      _refusedColumn = widget.expenses.refusedColumnKey;
    });
    if (isDuplicate) {
      _askAboutDuplicate(submit);
    }
  }

  bool _asks(String key) => _item.id.isEmpty || _columns.any((column) => column.key == key);

  bool _requires(String key) => _columns.any((column) => column.key == key && column.isRequired);

  String _nameOf(String key, String word) => columnLabel(context, _columns, key, word);

  String _labelOf(String key, String word) => _requires(key) ? '${_nameOf(key, word)} *' : _nameOf(key, word);

  String? _errorOf(String key, Words words) => _refusedColumn == key ? words.text(_message) : null;

  Widget _textField(Key key, TextEditingController controller, String label, {bool isNumber = false, bool isSigned = false, int maxLines = 1, String? errorText}) =>
      entryField(key: key, controller: controller, label: label, isNumber: isNumber, isSigned: isSigned, maxLines: maxLines, errorText: errorText, onChanged: (_) => setState(() {}));

  String _amountLabel(Words words) {
    if (_withoutInvoice) {
      return words.expensesAmount;
    }
    return _amountIncludesVat ? words.expensesAmountIncludingVat : words.expensesAmountBeforeVat;
  }

  List<Widget> _whatItWasFor(Words words) => [
    ItemPicker(key: AddExpenseScreen.itemKey, items: widget.items, label: words.expensesItem, itemName: _item.name, onChanged: _chooseItem),
    if (_item.namedSubgroups.isNotEmpty)
      LabelledChips(
        label: words.expensesSubgroup,
        choices: _item.subgroups,
        keyOf: (subgroup) => AddExpenseScreen.subgroupKey(subgroup.id),
        nameOf: (subgroup) => subgroup.name.isEmpty ? words.expensesGeneralSubgroup : subgroup.name,
        isChosen: (subgroup) => _subgroupId == subgroup.id || (_subgroupId.isEmpty && subgroup.name.isEmpty),
        onChosen: (subgroup) => setState(() => _subgroupId = subgroup.id),
      ),
    LabelledChips(
      label: _nameOf('unit', words.expensesUnit),
      choices: widget.project.entryUnits,
      keyOf: (unit) => AddExpenseScreen.unitKey(unit.id),
      nameOf: (unit) => unit.name,
      isChosen: (unit) => _unitId == unit.id,
      onChosen: (unit) => setState(() => _unitId = unit.id),
    ),
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PickerField(key: AddExpenseScreen.supplierKey, label: _nameOf('supplier', words.expensesSupplier), value: _supplier.name, onTap: _pickSupplier),
        if (_supplier.id.isNotEmpty) Text(_supplier.detailsIn(words), key: AddExpenseScreen.supplierDetailsKey, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
    if (!_withoutInvoice)
      TwoFields(
        _textField(AddExpenseScreen.invoiceNumberKey, _invoiceNumber, _nameOf('invoiceNumber', words.expensesInvoiceNumber)),
        PickerField(key: AddExpenseScreen.invoiceDateKey, label: words.expensesInvoiceDate, value: formatDate(_invoiceDate), onTap: () => _chooseDate(_invoiceDate, (date) => _invoiceDate = date)),
      ),
    if (!_withoutInvoice)
      SwitchListTile(
        key: AddExpenseScreen.creditNoteKey,
        contentPadding: EdgeInsets.zero,
        title: Text(words.expensesCreditNote),
        subtitle: Text(words.expensesCreditNoteExplain),
        value: _isCreditNote,
        onChanged: (isCreditNote) => setState(() => _setCreditNote(isCreditNote)),
      ),
    if (_isCreditNote && _supplier.id.isNotEmpty)
      OriginalInvoicePicker(
        key: AddExpenseScreen.originalInvoiceKey,
        invoices: widget.creditableInvoices,
        supplierId: _supplier.id,
        chosen: _original,
        onChanged: (invoice) => setState(() => _original = invoice),
      ),
    if (_asks('product')) _textField(AddExpenseScreen.productKey, _product, _labelOf('product', words.expensesProduct), errorText: _errorOf('product', words)),
    if (_asks('unitPrice') || _asks('quantity'))
      TwoFields(
        _textField(AddExpenseScreen.unitPriceKey, _unitPrice, _labelOf('unitPrice', words.expensesUnitPrice), isNumber: true, errorText: _errorOf('unitPrice', words)),
        _textField(AddExpenseScreen.quantityKey, _quantity, _labelOf('quantity', words.expensesQuantity), isNumber: true, errorText: _errorOf('quantity', words)),
      ),
    if (!_withoutInvoice)
      SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: true, label: Text(words.expensesIncludingVat, key: AddExpenseScreen.includingVatKey)),
          ButtonSegment(value: false, label: Text(words.expensesBeforeVat, key: AddExpenseScreen.beforeVatKey)),
        ],
        selected: {_amountIncludesVat},
        onSelectionChanged: (selected) => setState(() => _amountIncludesVat = selected.single),
      ),
    TwoFields(
      _textField(AddExpenseScreen.amountKey, _amount, _amountLabel(words), isNumber: true, isSigned: true),
      _textField(AddExpenseScreen.discountKey, _discount, _nameOf('discount', words.expensesDiscount), isNumber: true),
    ),
    if (!_withoutInvoice)
      SwitchListTile(
        key: AddExpenseScreen.notTaxableKey,
        contentPadding: EdgeInsets.zero,
        title: Text(words.expensesNotTaxable),
        value: _isNotTaxable,
        onChanged: (isNotTaxable) => setState(() => _isNotTaxable = isNotTaxable),
      ),
    FiguresBox(figures: _figures, vatPercent: _vatPercent),
    if (!_withoutInvoice && !_qr.isNone && (_figures.vat.abs() - _qr.vat).abs() > InvoiceQr.vatTolerance)
      Text(words.expensesQrVatDiffers, key: AddExpenseScreen.qrVatDiffersKey, style: TextStyle(color: Theme.of(context).colorScheme.error)),
  ];

  List<Widget> _itemsOwnFields(Words words) => [
    if (_columnsMessage.isNotEmpty) Text(words.text(_columnsMessage), key: AddExpenseScreen.listMessageKey),
    for (final column in _columns.where((column) => column.isCustom))
      ColumnValueField(
        column: column,
        value: _customValues[column.key] ?? '',
        error: _refusedColumn == column.key ? _message : '',
        onChanged: (value) => _customValues[column.key] = value,
        onChooseDate: _chooseDate,
      ),
  ];

  Widget _paymentSection(Words words) => FormSection([
    PaymentChoices(choice: _payment, accounts: widget.accounts, paymentMethods: widget.paymentMethods, onChanged: () => setState(() {}), onRetry: _readListsAgain),
    if (!_withoutInvoice)
      SwitchListTile(
        key: AddExpenseScreen.paymentDiffersKey,
        contentPadding: EdgeInsets.zero,
        title: Text(words.expensesPaymentDiffers),
        value: _paymentDiffers,
        onChanged: (paymentDiffers) => setState(() => _paymentDiffers = paymentDiffers),
      ),
    if (_paymentDiffers || _withoutInvoice)
      PickerField(key: AddExpenseScreen.paymentDateKey, label: words.expensesPaymentDate, value: formatDate(_paymentDate), onTap: () => _chooseDate(_paymentDate, (date) => _paymentDate = date)),
    if (_paysOtherThanInvoiced)
      TwoFields(
        _textField(AddExpenseScreen.paymentAmountKey, _paymentAmount, words.expensesPaymentAmount, isNumber: true),
        _textField(AddExpenseScreen.bankFeesKey, _bankFees, words.expensesBankFees, isNumber: true),
      ),
    if (_asks('notes')) _textField(AddExpenseScreen.notesKey, _notes, _labelOf('notes', words.expensesNotes), maxLines: 2, errorText: _errorOf('notes', words)),
  ]);

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final ownFields = _itemsOwnFields(words);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(words.expensesNew, key: AddExpenseScreen.titleKey),
            Text(widget.project.name, key: AddExpenseScreen.projectNameKey, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          if (_withoutInvoice)
            _textField(AddExpenseScreen.withoutInvoiceReasonKey, _withoutInvoiceReason, words.expensesWithoutInvoiceReason, maxLines: 2)
          else ...[
            InvoiceSection(file: _invoice, emptyLabel: words.attachmentsInvoicePhoto, message: _invoiceMessage, onCamera: () => _takeFrom(widget.capture.fromCamera), onFiles: () => _takeFrom(widget.capture.fromFiles)),
            if (_qrMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(words.text(_qrMessage), key: AddExpenseScreen.qrMessageKey),
              ),
            if (!_qr.isNone) QrSummary(qr: _qr, offerSupplier: _qrSupplierMissing && widget.project.mayAddSupplier, onAddSupplier: _addSupplierFromQr),
          ],
          SwitchListTile(
            key: AddExpenseScreen.withoutInvoiceKey,
            contentPadding: EdgeInsets.zero,
            title: Text(words.expensesWithoutInvoice),
            value: _withoutInvoice,
            onChanged: (withoutInvoice) => setState(() {
              _withoutInvoice = withoutInvoice;
              _setCreditNote(false);
            }),
          ),
          FormSection(_whatItWasFor(words)),
          if (ownFields.isNotEmpty) FormSection(ownFields),
          _paymentSection(words),
          const SizedBox(height: 16),
          if (_message.isNotEmpty) ...[
            Text(words.text(_message), key: AddExpenseScreen.messageKey, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                flex: 2,
                child: FilledButton(key: AddExpenseScreen.sendKey, onPressed: _saving ? null : () => _save(true), child: Text(words.expensesSend)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(key: AddExpenseScreen.draftKey, onPressed: _saving ? null : () => _save(false), child: Text(words.expensesSaveDraft)),
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }
}
