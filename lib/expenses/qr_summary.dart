import 'package:flutter/material.dart';

import '../format/date_format.dart';
import '../format/number_format.dart';
import '../words/words.dart';
import 'add_expense_screen.dart';
import 'invoice_qr.dart';

/// What was read from the invoice's QR code (AC-11.1): its five fields, and an offer to add the seller when no supplier holds its number.
class QrSummary extends StatelessWidget {
  /// The summary of [qr]. When [offerSupplier], it says no supplier holds the number, and [onAddSupplier] adds it.
  const QrSummary({super.key, required this.qr, required this.offerSupplier, required this.onAddSupplier});

  /// What was read.
  final InvoiceQr qr;

  /// Whether to offer adding the seller.
  final bool offerSupplier;

  /// Adds the seller to the register.
  final VoidCallback onAddSupplier;

  String _timeOf(DateTime time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    return Card.filled(
      margin: const EdgeInsets.only(top: 12),
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(words.expensesQrRead, key: AddExpenseScreen.qrReadKey, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(qr.sellerName, key: AddExpenseScreen.qrSellerKey),
            Text(qr.vatNumber, key: AddExpenseScreen.qrVatNumberKey),
            Text('${formatDate(qr.issuedAt)} ${_timeOf(qr.issuedAt)}', key: AddExpenseScreen.qrTimeKey),
            Text('${words.expensesTotal} ${formatMoney(qr.total)} · ${words.expensesVat} ${formatMoney(qr.vat)}', key: AddExpenseScreen.qrAmountsKey),
            if (offerSupplier) ...[
              const SizedBox(height: 8),
              Text(words.expensesQrSupplierMissing, key: AddExpenseScreen.qrSupplierMissingKey),
              const SizedBox(height: 4),
              OutlinedButton(key: AddExpenseScreen.qrAddSupplierKey, onPressed: onAddSupplier, child: Text(words.expensesQrAddSupplier)),
            ],
          ],
        ),
      ),
    );
  }
}
