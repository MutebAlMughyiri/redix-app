import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../accounts/offered_accounts.dart';
import '../attachments/attachments.dart';
import '../attachments/invoice_capture.dart';
import '../attachments/picked_file.dart';
import '../contracts/contract.dart';
import '../contracts/contracts.dart';
import '../expenses/add_expense_screen.dart';
import '../expenses/column_value_field.dart';
import '../expenses/duplicate_invoice_dialog.dart';
import '../expenses/entry_date.dart';
import '../expenses/expenses.dart';
import '../expenses/invoice_figures.dart';
import '../expenses/invoice_section.dart';
import '../expenses/payment_choice.dart';
import '../expenses/payment_choices.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../settings/payment_methods.dart';
import '../structure/columns.dart';
import '../structure/item_column.dart';
import '../ui/entry_field.dart';
import '../ui/form_section.dart';
import '../ui/picker_field.dart';
import '../ui/two_fields.dart';
import '../structure/column_label.dart';
import '../structure/offered_items.dart';
import '../ui/labelled_chips.dart';
import '../words/words.dart';
import 'contract_figures.dart';
import 'contract_picker.dart';

/// A payment against a contract (UC-027): what the contract stands at with it shows before saving, and going beyond its value only warns. A negative amount is a deduction, which says why in place of a receipt. The figures only show what the API will compute.
class ContractorPaymentScreen extends StatefulWidget {
  /// Why the entry being changed was rejected.
  static const rejectionKey = Key('contractorPayment.rejection');

  /// The choice of the subgroup [id].
  static Key subgroupKey(String id) => Key('contractorPayment.subgroup.$id');

  /// The screen entering a payment in [project], recorded through [expenses], picking from [contracts], [accounts] and [paymentMethods], asking what [columnsOf] the contract's item says, and keeping the receipt through [attachments] from what [capture] gives.
  const ContractorPaymentScreen({
    super.key,
    this.editingId = '',
    this.rejectionReason = '',
    required this.project,
    required this.expenses,
    required this.contracts,
    required this.items,
    required this.accounts,
    required this.paymentMethods,
    required this.columnsOf,
    required this.attachments,
    required this.capture,
  });

  /// The entry being changed; empty for a new one.
  final String editingId;

  /// Why it was rejected; empty otherwise.
  final String rejectionReason;

  /// The project the payment belongs to.
  final Project project;

  /// The items on offer, for the subgroups of the contract's item.
  final OfferedItems items;

  /// The way to record it.
  final Expenses expenses;

  /// The project's contracts.
  final Contracts contracts;

  /// What the signed-in user may pay from.
  final OfferedAccounts accounts;

  /// The project's payment methods.
  final PaymentMethods paymentMethods;

  /// The columns of an item.
  final Columns Function(String itemId) columnsOf;

  /// The way to keep the receipt.
  final Attachments attachments;

  /// The phone's camera and files.
  final InvoiceCapture capture;

  /// The screen's route.
  static const path = '/projects/:projectId/contractor-payments/new';

  /// The route of a new payment in the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/contractor-payments/new';

  /// The screen's title.
  static const titleKey = Key('contractorPayment.title');

  /// The project's name, under the title.
  static const projectNameKey = Key('contractorPayment.projectName');

  /// The contract.
  static const contractKey = Key('contractorPayment.contract');

  /// The contract's value.
  static const valueKey = Key('contractorPayment.value');

  /// What was paid on it.
  static const paidKey = Key('contractorPayment.paid');

  /// What waits for approval on it, when anything does.
  static const pendingKey = Key('contractorPayment.pending');

  /// What remains after this payment.
  static const remainingKey = Key('contractorPayment.remaining');

  /// The bar of how much is reached.
  static const progressKey = Key('contractorPayment.progress');

  /// The warning that this payment goes beyond the contract's value.
  static const overrunKey = Key('contractorPayment.overrun');

  /// The amount.
  static const amountKey = Key('contractorPayment.amount');

  /// The date.
  static const dateKey = Key('contractorPayment.date');

  /// Inside the contract, on the switch of what the payment is.
  static const insideKey = Key('contractorPayment.inside');

  /// Outside the contract, on the same switch.
  static const outsideKey = Key('contractorPayment.outside');

  /// The line that says what outside the contract means.
  static const outsideExplainKey = Key('contractorPayment.outsideExplain');

  /// The title over the receipt.
  static const receiptKey = Key('contractorPayment.receipt');

  /// The button that opens the camera.
  static const cameraKey = AddExpenseScreen.cameraKey;

  /// The button that opens the phone's files.
  static const filesKey = AddExpenseScreen.filesKey;

  /// Why a deduction is deducted, in place of the receipt.
  static const deductionReasonKey = Key('contractorPayment.deductionReason');

  /// The switch that says it has a tax invoice.
  static const hasInvoiceKey = Key('contractorPayment.hasInvoice');

  /// The tax invoice's number.
  static const invoiceNumberKey = Key('contractorPayment.invoiceNumber');

  /// The tax invoice's date.
  static const invoiceDateKey = Key('contractorPayment.invoiceDate');

  /// The tax invoice's amount before VAT.
  static const invoiceAmountKey = Key('contractorPayment.invoiceAmount');

  /// The tax invoice's VAT, computed.
  static const invoiceVatKey = Key('contractorPayment.invoiceVat');

  /// The notes.
  static const notesKey = Key('contractorPayment.notes');

  /// The button that sends it for approval.
  static const sendKey = Key('contractorPayment.send');

  /// The button that saves it as a draft.
  static const draftKey = Key('contractorPayment.draft');

  /// The line that says why it was refused.
  static const messageKey = Key('contractorPayment.message');

  /// The line that says it was saved or sent, on the screen it goes back to.
  static const savedKey = Key('contractorPayment.saved');

  /// The line that says the columns could not be read.
  static const columnsMessageKey = Key('contractorPayment.columnsMessage');

  @override
  State<ContractorPaymentScreen> createState() => _ContractorPaymentScreenState();
}

class _ContractorPaymentScreenState extends State<ContractorPaymentScreen> {
  late final _entryId = widget.editingId.isEmpty ? const Uuid().v7() : widget.editingId;
  final _amount = TextEditingController();
  final _deductionReason = TextEditingController();
  final _invoiceNumber = TextEditingController();
  final _invoiceAmount = TextEditingController();
  final _notes = TextEditingController();
  final _payment = PaymentChoice();
  final _customValues = <String, String>{};
  var _contract = Contract.none();
  var _subgroupId = '';
  var _columns = <ItemColumn>[];
  var _columnsMessage = '';
  var _date = DateTime.now();
  var _invoiceDate = DateTime.now();
  var _isOutside = false;
  var _hasInvoice = false;
  var _receipt = PickedFile.none();
  var _receiptMessage = '';
  var _attachmentId = '';
  var _message = '';
  var _refusedColumn = '';
  var _saving = false;

  @override
  void initState() {
    super.initState();
    widget.contracts.loadOnOpen();
    widget.items.loadOnOpen();
    widget.accounts.loadOnOpen();
    widget.paymentMethods.loadOnOpen();
    if (widget.editingId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openEntry());
    }
  }

  /// Fills the form from the entry being changed (UC-033).
  Future<void> _openEntry() async {
    final held = await widget.expenses.read(widget.editingId);
    await Future.wait([widget.contracts.load(), widget.accounts.load(), widget.items.load()]);
    if (!mounted || held.isEmpty) {
      return;
    }
    final entry = held['entry'] as Map<String, dynamic>;
    final expense = held['expense'] as Map<String, dynamic>;
    final payment = held['contractorPayment'] as Map<String, dynamic>;
    final invoice = held['invoice'] as Map<String, dynamic>;
    final files = held['attachments'] as List<dynamic>;
    final contracts = widget.contracts.all.where((contract) => contract.id == payment['contractId']);
    final number = invoice['number'] as String? ?? '';
    setState(() {
      _amount.text = formatPlain((entry['amount'] as num).toDouble());
      _date = DateTime.parse(entry['entryDate'] as String);
      _isOutside = payment['isOutsideContract'] as bool;
      _notes.text = entry['notes'] as String;
      _deductionReason.text = expense['withoutInvoiceReason'] as String;
      _payment
        ..accountId = entry['accountId'] as String
        ..paymentMethodId = expense['paymentMethodId'] as String;
      if (number.isNotEmpty) {
        _hasInvoice = true;
        _invoiceNumber.text = number;
        _invoiceDate = DateTime.parse(invoice['invoiceDate'] as String);
        _invoiceAmount.text = formatPlain((invoice['amountBeforeDiscount'] as num).toDouble());
      }
      if (files.isNotEmpty) {
        _attachmentId = (files.first as Map<String, dynamic>)['attachmentId'] as String;
      }
      _customValues.addAll((jsonDecode(expense['customValues'] as String) as Map<String, dynamic>).map((key, value) => MapEntry(key, '$value')));
    });
    if (contracts.isNotEmpty) {
      final keptValues = Map.of(_customValues);
      final subgroupId = expense['subgroupId'] as String;
      await _chooseContract(contracts.first);
      if (mounted) {
        setState(() {
          _subgroupId = subgroupId;
          _customValues.addAll(keptValues);
        });
      }
    }
  }

  @override
  void dispose() {
    for (final controller in [_amount, _deductionReason, _invoiceNumber, _invoiceAmount, _notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  double _typed(TextEditingController field) {
    final number = parseNumber(field.text);
    return number.isNaN ? 0 : number;
  }

  bool get _isDeduction => _typed(_amount) < 0;

  bool get _sendsInvoice => _hasInvoice && !_isDeduction;

  double get _vatPercent => _contract.supplierVatNumber.isEmpty ? 0 : widget.project.vatPercent;

  String _isoOf(DateTime date) => date.toIso8601String().substring(0, 10);

  Future<void> _chooseContract(Contract contract) async {
    setState(() {
      _contract = contract;
      _subgroupId = '';
      _columns = [];
      _customValues.clear();
      _refusedColumn = '';
    });
    final columns = widget.columnsOf(contract.itemId);
    await columns.load();
    if (mounted && _contract.id == contract.id) {
      setState(() {
        _columns = columns.all;
        _columnsMessage = columns.message;
      });
    }
  }

  Future<void> _chooseDate(DateTime current, ValueChanged<DateTime> onChosen) async {
    final chosen = await pickEntryDate(context, widget.project, current);
    if (mounted) {
      setState(() => onChosen(chosen));
    }
  }

  Future<void> _takeFrom(Future<PickedFile> Function() source) async {
    final file = await source();
    if (!mounted) {
      return;
    }
    setState(() {
      _receiptMessage = file.failure;
      if (!file.isNone) {
        _receipt = file;
        _attachmentId = '';
      }
    });
  }

  void _readListsAgain() {
    widget.contracts.load();
    widget.accounts.load();
    widget.paymentMethods.load();
  }

  /// The word key of what stops this being sent as it stands; empty when nothing does.
  String get _whatIsWrong {
    if (_amount.text.trim().isNotEmpty && parseNumber(_amount.text).isNaN) {
      return 'expenses.invalidAmount';
    }
    if (_isDeduction && _deductionReason.text.trim().isEmpty) {
      return 'contractorPayments.deductionNeedsReason';
    }
    if (_sendsInvoice && _invoiceNumber.text.trim().isEmpty) {
      return 'expenses.invalidInvoiceNumber';
    }
    return _sendsInvoice && parseNumber(_invoiceAmount.text).isNaN ? 'expenses.invalidInvoiceAmount' : '';
  }

  Map<String, Object> _body(bool submit, bool confirmDuplicate) {
    final accountId = _payment.chosenAccountIn(widget.accounts.all);
    return {
      'id': _entryId,
      if (_contract.id.isNotEmpty) 'contractId': _contract.id,
      if (_subgroupId.isNotEmpty) 'subgroupId': _subgroupId,
      'isOutsideContract': _isOutside,
      'paymentDate': _isoOf(_date),
      if (_amount.text.trim().isNotEmpty) 'amount': parseNumber(_amount.text),
      if (accountId.isNotEmpty) 'accountId': accountId,
      if (_payment.paymentMethodId.isNotEmpty) 'paymentMethodId': _payment.paymentMethodId,
      if (_isDeduction) 'withoutInvoiceReason': _deductionReason.text else if (_attachmentId.isNotEmpty) 'attachmentId': _attachmentId,
      if (_sendsInvoice) ...{
        'invoiceNumber': westernDigits(_invoiceNumber.text),
        'invoiceDate': _isoOf(_invoiceDate),
        'invoiceAmountBeforeVat': parseNumber(_invoiceAmount.text),
      },
      'notes': _notes.text,
      'customValues': ItemColumn.valuesToSend(_columns, _customValues),
      'submit': submit,
      if (confirmDuplicate) 'confirmDuplicate': true,
    };
  }

  Future<String> _record(bool submit, bool confirmDuplicate) async {
    if (_whatIsWrong.isNotEmpty) {
      return _whatIsWrong;
    }
    if (!_isDeduction && !_receipt.isNone && _attachmentId.isEmpty) {
      final refusal = await widget.attachments.keep(_receipt);
      if (refusal == 'attachments.noConnection') {
        return widget.expenses.keepContractorPayment(_body(submit, confirmDuplicate), _receipt, editing: widget.editingId);
      }
      if (refusal.isNotEmpty) {
        return refusal;
      }
      _attachmentId = widget.attachments.kept.id;
    }
    return widget.expenses.recordContractorPayment(_body(submit, confirmDuplicate), editing: widget.editingId);
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
      final sent = widget.expenses.wasOverrun ? words.contractorPaymentsSavedOverrun : (submit ? words.expensesSent : words.expensesSaved);
      final saved = widget.expenses.wasKept ? words.expensesKeptOnPhone : sent;
      messenger.showSnackBar(SnackBar(content: Text(saved, key: ContractorPaymentScreen.savedKey)));
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
      final earlier = widget.expenses.earlier;
      showDialog<void>(
        context: context,
        builder: (_) => DuplicateInvoiceDialog(earlier: earlier, onConfirm: () => _save(submit, confirmDuplicate: true)),
      );
    }
  }

  Widget _textField(Key key, TextEditingController controller, String label, {bool isNumber = false, bool isSigned = false, int maxLines = 1}) =>
      entryField(key: key, controller: controller, label: label, isNumber: isNumber, isSigned: isSigned, maxLines: maxLines, onChanged: (_) => setState(() {}));

  List<Widget> _theContract(Words words) => [
    if (widget.rejectionReason.isNotEmpty) Text('${words.entriesReason}: ${widget.rejectionReason}', key: ContractorPaymentScreen.rejectionKey, style: TextStyle(color: Theme.of(context).colorScheme.error)),
    ContractPicker(key: ContractorPaymentScreen.contractKey, contracts: widget.contracts, chosen: _contract, onChanged: _chooseContract),
    if (_contract.id.isNotEmpty) ContractFigures(contract: _contract, counted: _isOutside ? 0 : _typed(_amount)),
    ListenableBuilder(listenable: widget.items, builder: (_, _) => _subgroupChoice(words)),
  ];

  /// The subgroups of the contract's item, when it has named ones (UC-012); a payment goes under its general one otherwise.
  Widget _subgroupChoice(Words words) {
    final item = widget.items.all.expand((category) => category.items).where((item) => item.id == _contract.itemId);
    if (item.isEmpty || item.first.namedSubgroups.isEmpty) {
      return const SizedBox.shrink();
    }
    return LabelledChips(
      label: words.expensesSubgroup,
      choices: item.first.subgroups,
      keyOf: (subgroup) => ContractorPaymentScreen.subgroupKey(subgroup.id),
      nameOf: (subgroup) => subgroup.name.isEmpty ? words.expensesGeneralSubgroup : subgroup.name,
      isChosen: (subgroup) => _subgroupId == subgroup.id || (_subgroupId.isEmpty && subgroup.name.isEmpty),
      onChosen: (subgroup) => setState(() => _subgroupId = subgroup.id),
    );
  }

  List<Widget> _thePayment(Words words) => [
    TwoFields(
      _textField(ContractorPaymentScreen.amountKey, _amount, columnLabel(context, _columns, 'amount', words.expensesAmount), isNumber: true, isSigned: true),
      PickerField(key: ContractorPaymentScreen.dateKey, label: words.contractorPaymentsDate, value: formatDate(_date), onTap: () => _chooseDate(_date, (date) => _date = date)),
    ),
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        Text(words.contractorPaymentsKind, style: Theme.of(context).textTheme.titleSmall),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: false, label: Text(words.contractorPaymentsInside, key: ContractorPaymentScreen.insideKey)),
            ButtonSegment(value: true, label: Text(words.contractorPaymentsOutside, key: ContractorPaymentScreen.outsideKey)),
          ],
          selected: {_isOutside},
          onSelectionChanged: (selected) => setState(() => _isOutside = selected.single),
        ),
        Text(words.contractorPaymentsOutsideExplain, key: ContractorPaymentScreen.outsideExplainKey, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
    PaymentChoices(choice: _payment, accounts: widget.accounts, paymentMethods: widget.paymentMethods, onChanged: () => setState(() {}), onRetry: _readListsAgain),
  ];

  List<Widget> _theReceipt(Words words) => _isDeduction
      ? [_textField(ContractorPaymentScreen.deductionReasonKey, _deductionReason, words.contractorPaymentsDeductionReason, maxLines: 2)]
      : [
          Text(words.contractorPaymentsReceipt, key: ContractorPaymentScreen.receiptKey, style: Theme.of(context).textTheme.titleSmall),
          InvoiceSection(
            project: widget.project,
            file: _receipt,
            emptyLabel: words.contractorPaymentsReceipt,
            message: _receiptMessage,
            onCamera: () => _takeFrom(widget.capture.fromCamera),
            onFiles: () => _takeFrom(widget.capture.fromFiles),
          ),
          SwitchListTile(
            key: ContractorPaymentScreen.hasInvoiceKey,
            contentPadding: EdgeInsets.zero,
            title: Text(words.contractorPaymentsHasInvoice),
            subtitle: Text(words.contractorPaymentsInvoiceExplain),
            value: _hasInvoice,
            onChanged: (hasInvoice) => setState(() => _hasInvoice = hasInvoice),
          ),
          if (_hasInvoice) ...[
            TwoFields(
              _textField(ContractorPaymentScreen.invoiceNumberKey, _invoiceNumber, words.expensesInvoiceNumber),
              PickerField(key: ContractorPaymentScreen.invoiceDateKey, label: words.expensesInvoiceDate, value: formatDate(_invoiceDate), onTap: () => _chooseDate(_invoiceDate, (date) => _invoiceDate = date)),
            ),
            _textField(ContractorPaymentScreen.invoiceAmountKey, _invoiceAmount, words.expensesAmountBeforeVat, isNumber: true),
            Text(
              '${words.expensesVat} ${formatPlain(_vatPercent)}%: ${formatMoney(InvoiceFigures.of(amount: _typed(_invoiceAmount), includesVat: false, discount: 0, vatRate: _vatPercent / 100).vat)}',
              key: ContractorPaymentScreen.invoiceVatKey,
            ),
          ],
        ];

  List<Widget> _itemsOwnFields(Words words) => [
    if (_columnsMessage.isNotEmpty) Text(words.text(_columnsMessage), key: ContractorPaymentScreen.columnsMessageKey),
    for (final column in _columns.where((column) => column.isCustom))
      ColumnValueField(
        column: column,
        value: _customValues[column.key] ?? '',
        error: _refusedColumn == column.key ? _message : '',
        onChanged: (value) => _customValues[column.key] = value,
        onChooseDate: _chooseDate,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final ownFields = _itemsOwnFields(words);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(words.contractorPaymentsNew, key: ContractorPaymentScreen.titleKey),
            Text(widget.project.name, key: ContractorPaymentScreen.projectNameKey, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormSection(_theContract(words)),
            FormSection(_thePayment(words)),
            FormSection(_theReceipt(words)),
            if (ownFields.isNotEmpty) FormSection(ownFields),
            const SizedBox(height: 16),
            _textField(ContractorPaymentScreen.notesKey, _notes, columnLabel(context, _columns, 'notes', words.expensesNotes), maxLines: 2),
            const SizedBox(height: 16),
            if (_message.isNotEmpty) ...[
              Text(words.text(_message), key: ContractorPaymentScreen.messageKey, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 8),
            ],
            Row(
              spacing: 8,
              children: [
                Expanded(
                  flex: 2,
                  child: FilledButton(key: ContractorPaymentScreen.sendKey, onPressed: _saving ? null : () => _save(true), child: Text(words.expensesSend)),
                ),
                Expanded(
                  child: OutlinedButton(key: ContractorPaymentScreen.draftKey, onPressed: _saving ? null : () => _save(false), child: Text(words.expensesSaveDraft)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
