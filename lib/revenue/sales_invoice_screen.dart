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
import '../ui/part_keys.dart';
import '../ui/picker_field.dart';
import '../ui/refusal_snack_bar.dart';
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

  /// What the buyer paid.
  static const amountKey = Key('salesInvoice.amount');

  /// The button saving it.
  static const saveKey = Key('salesInvoice.save');

  /// The line saying why it was refused.
  static const messageKey = Key('salesInvoice.message');

  /// The choice of the account [id].
  static Key accountKey(String id) => Key('salesInvoice.account.$id');

  /// The choice of the sale [id] already recorded.
  static Key saleKey(String id) => Key('salesInvoice.sale.$id');

  /// The invoice's date.
  static const dateKey = Key('salesInvoice.date');

  /// The choice of the sale it is for.
  static const saleChoiceKey = Key('salesInvoice.saleChoice');

  /// The choice of the account it was paid into.
  static const accountChoiceKey = Key('salesInvoice.accountChoice');

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
  final _buyer = TextEditingController();
  final _buyerVatNumber = TextEditingController();
  final _number = TextEditingController();
  final _amount = TextEditingController();
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
    for (final field in [_buyer, _buyerVatNumber, _number, _amount]) {
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
    final total = parseNumber(_amount.text);
    if (total.isNaN) {
      setState(() => _message = 'revenue.invalidAmount');
      return;
    }
    setState(() => _saving = true);
    final refusal = await widget.revenues.recordSale({
      'buyerName': _buyer.text,
      'buyerVatNumber': westernDigits(_buyerVatNumber.text),
      'number': westernDigits(_number.text),
      'invoiceDate': _date.toIso8601String().substring(0, 10),
      'total': total,
      'accountId': _accountId,
      if (_saleId.isNotEmpty) 'saleEntryId': _saleId,
    });
    if (!mounted) {
      return;
    }
    if (refusal.isEmpty) {
      showMessage(messenger, words, 'revenue.saved');
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
                PickerField(key: SalesInvoiceScreen.dateKey, label: words.revenueInvoiceDate, value: formatDate(_date), onTap: _chooseDate),
                entryField(key: SalesInvoiceScreen.amountKey, controller: _amount, label: words.revenueTotal, isNumber: true, onChanged: (_) {}),
                if (openSales.isNotEmpty)
                  LabelledChips<RevenueRow>(
                    key: SalesInvoiceScreen.saleChoiceKey,
                    label: words.revenueSale,
                    choices: openSales,
                    keyOf: (row) => SalesInvoiceScreen.saleKey(row.id),
                    nameOf: (row) => '${formatDate(row.date)} · ${formatMoney(row.amount)}',
                    isChosen: (row) => row.id == _saleId,
                    onChosen: (row) => setState(() => _saleId = row.id == _saleId ? '' : row.id),
                  ),
                if (_saleId.isEmpty)
                  LabelledChips<Account>(
                    key: SalesInvoiceScreen.accountChoiceKey,
                    label: words.revenueAccount,
                    choices: widget.accounts.bankAndCash,
                    keyOf: (account) => SalesInvoiceScreen.accountKey(account.id),
                    nameOf: (account) => account.name,
                    isChosen: (account) => account.id == _accountId,
                    onChosen: (account) => setState(() => _accountId = account.id),
                  ),
                if (_message.isNotEmpty) Text(words.text(_message), key: SalesInvoiceScreen.messageKey, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                FilledButton(key: SalesInvoiceScreen.saveKey, onPressed: _saving ? null : _save, child: Text(words.revenueSave, key: SalesInvoiceScreen.saveKey.label)),
              ],
            );
          },
        ),
      ),
    );
  }
}
