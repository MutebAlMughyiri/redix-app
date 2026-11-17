import 'package:flutter/material.dart';

import '../format/date_format.dart';
import '../format/number_format.dart';
import '../words/words.dart';
import '../entries/add_entry_screen.dart';
import '../ui/part_keys.dart';
import 'invoice_qr.dart';

/// What was read from the invoice's QR code (AC-11.1): its five fields, and an offer to add the seller when no supplier holds its number. It sits inside the invoice's
/// section, so it has no border of its own (redix-app #96, D1).
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
    return Column(
      key: AddEntryScreen.qrSummaryKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(words.expensesQrRead, key: AddEntryScreen.qrReadKey, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(qr.sellerName, key: AddEntryScreen.qrSellerKey),
        Text(qr.vatNumber, key: AddEntryScreen.qrVatNumberKey),
        Text('${formatDate(qr.issuedAt)} ${_timeOf(qr.issuedAt)}', key: AddEntryScreen.qrTimeKey),
        Text('${words.expensesTotal} ${formatMoney(qr.total)}', key: AddEntryScreen.qrAmountsKey),
        if (offerSupplier) ...[
          const SizedBox(height: 8),
          Text(words.expensesQrSupplierMissing, key: AddEntryScreen.qrSupplierMissingKey),
          const SizedBox(height: 4),
          OutlinedButton(key: AddEntryScreen.qrAddSupplierKey, onPressed: onAddSupplier, child: Text(words.expensesQrAddSupplier, key: AddEntryScreen.qrAddSupplierKey.label)),
        ],
      ],
    );
  }
}
