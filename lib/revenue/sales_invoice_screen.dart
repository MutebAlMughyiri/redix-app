import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../accounts/account.dart';
import '../accounts/accounts.dart';
import '../expenses/entry_date.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../ui/entry_field.dart';
import '../ui/labelled_chips.dart';
import '../ui/picker_field.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'revenue_row.dart';
import 'revenues.dart';

/// Recording a sales invoice (UC-048), on a sale already recorded or as a new one, so its amount counts once (AC-42.1).
class SalesInvoiceScreen extends StatefulWidget {
  /// The screen recording a sales invoice in [project] through [revenues], into one of [accounts].
  const SalesInvoiceScreen({super.key, required this.project, required this.revenues, required this.accounts});

  /// The address of the screen.
  static const path = '/projects/:projectId/sales-invoices/new';

  /// The address of the screen for the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/sales-invoices/new';

  /// The buyer.
  static const buyerKey = Key('salesInvoice.buyer');

  /// The buyer's VAT number.
  static const buyerVatNumberKey = Key('salesInvoice.buyerVatNumber');

  /// The invoice's number.
  static const numberKey = Key('salesInvoice.number');

  /// The amount before tax.
  static const amountKey = Key('salesInvoice.amount');

  /// The discount.
  static const discountKey = Key('salesInvoice.discount');

  /// The button saving it.
  static const saveKey = Key('salesInvoice.save');

  /// The line saying why it was refused.
  static const messageKey = Key('salesInvoice.message');

  /// The choice of the tax [type].
  static Key taxKey(String type) => Key('salesInvoice.tax.$type');

  /// The choice of the account [id].
  static Key accountKey(String id) => Key('salesInvoice.account.$id');

  /// The choice of the sale [id] already recorded.
  static Key saleKey(String id) => Key('salesInvoice.sale.$id');

  /// The project.
  final Project project;

  /// The way to record it, and the sales already recorded.
  final Revenues revenues;

  /// The accounts a new sale may reach.
  final Accounts accounts;

  @override
  State<SalesInvoiceScreen> createState() => _SalesInvoiceScreenState();
}

class _SalesInvoiceScreenState extends State<SalesInvoiceScreen> {
  static const _taxTypes = ['realEstateTransaction', 'vat'];

  final _buyer = TextEditingController();
  final _buyerVatNumber = TextEditingController();
  final _number = TextEditingController();
  final _amount = TextEditingController();
  final _discount = TextEditingController();
  var _taxType = 'realEstateTransaction';
  var _date = DateTime.now();
  var _accountId = '';
  var _saleId = '';
  var _message = '';
  var _saving = false;

  @override
  void initState() {
    super.initState();
    widget.accounts.loadOnOpen();
    widget.revenues.loadOnOpen();
  }

  @override
  void dispose() {
    for (final field in [_buyer, _buyerVatNumber, _number, _amount, _discount]) {
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

  Future<void> _save() async {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final amount = parseNumber(_amount.text);
    final discount = _discount.text.trim().isEmpty ? 0.0 : parseNumber(_discount.text);
    if (amount.isNaN || discount.isNaN) {
      setState(() => _message = amount.isNaN ? 'revenue.invalidAmount' : 'revenue.invalidDiscount');
      return;
    }
    setState(() => _saving = true);
    final refusal = await widget.revenues.recordSale({
      'buyerName': _buyer.text,
      'buyerVatNumber': westernDigits(_buyerVatNumber.text),
      'number': westernDigits(_number.text),
      'invoiceDate': _date.toIso8601String().substring(0, 10),
      'amount': amount,
      'discount': discount,
      'taxType': _taxType,
      'accountId': _accountId,
      if (_saleId.isNotEmpty) 'saleEntryId': _saleId,
    });
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
      appBar: AppBar(title: ScreenTitle(words.revenueNewSale, subject: widget.project.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ListenableBuilder(
          listenable: Listenable.merge([widget.accounts, widget.revenues]),
          builder: (context, _) {
            final openSales = widget.revenues.all.where((row) => row.isOpenSale).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                entryField(key: SalesInvoiceScreen.buyerKey, controller: _buyer, label: words.revenueBuyer, onChanged: (_) {}),
                entryField(key: SalesInvoiceScreen.buyerVatNumberKey, controller: _buyerVatNumber, label: words.revenueBuyerVatNumber, isNumber: true, onChanged: (_) {}),
                entryField(key: SalesInvoiceScreen.numberKey, controller: _number, label: words.revenueInvoiceNumber, onChanged: (_) {}),
                PickerField(label: words.revenueInvoiceDate, value: formatDate(_date), onTap: _chooseDate),
                entryField(key: SalesInvoiceScreen.amountKey, controller: _amount, label: words.revenueAmountBeforeTax, isNumber: true, onChanged: (_) {}),
                entryField(key: SalesInvoiceScreen.discountKey, controller: _discount, label: words.revenueDiscount, isNumber: true, onChanged: (_) {}),
                LabelledChips<String>(
                  label: words.revenueTaxType,
                  choices: _taxTypes,
                  keyOf: SalesInvoiceScreen.taxKey,
                  nameOf: (type) => words.text('revenue.tax${type[0].toUpperCase()}${type.substring(1)}'),
                  isChosen: (type) => type == _taxType,
                  onChosen: (type) => setState(() => _taxType = type),
                ),
                if (openSales.isNotEmpty)
                  LabelledChips<RevenueRow>(
                    label: words.revenueSale,
                    choices: openSales,
                    keyOf: (row) => SalesInvoiceScreen.saleKey(row.id),
                    nameOf: (row) => '${formatDate(row.date)} · ${formatMoney(row.amount)}',
                    isChosen: (row) => row.id == _saleId,
                    onChosen: (row) => setState(() => _saleId = row.id == _saleId ? '' : row.id),
                  ),
                if (_saleId.isEmpty)
                  LabelledChips<Account>(
                    label: words.revenueAccount,
                    choices: widget.accounts.all.where((account) => account.isActive && account.type != AccountType.partnerPocket),
                    keyOf: (account) => SalesInvoiceScreen.accountKey(account.id),
                    nameOf: (account) => account.name,
                    isChosen: (account) => account.id == _accountId,
                    onChosen: (account) => setState(() => _accountId = account.id),
                  ),
                if (_message.isNotEmpty) Text(words.text(_message), key: SalesInvoiceScreen.messageKey, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                FilledButton(key: SalesInvoiceScreen.saveKey, onPressed: _saving ? null : _save, child: Text(words.revenueSave)),
              ],
            );
          },
        ),
      ),
    );
  }
}
