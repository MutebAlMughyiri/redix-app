import 'package:flutter/material.dart';

import '../format/date_format.dart';
import '../format/number_format.dart';
import '../ui/confirm_dialog.dart';
import '../words/words.dart';
import 'earlier_entry.dart';

/// The question when a supplier's invoice number is entered again (AC-17.1): it shows the [earlier] entry.
class DuplicateInvoiceDialog extends StatelessWidget {
  /// The question about [earlier], calling [onConfirm] to save it anyway.
  const DuplicateInvoiceDialog({super.key, required this.earlier, required this.onConfirm});

  /// The entry the number repeats.
  final EarlierEntry earlier;

  /// Saves it anyway.
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ConfirmDialog(
      title: words.expensesDuplicateTitle,
      subject: '${earlier.projectName} · ${formatDate(earlier.invoiceDate)} · ${formatMoney(earlier.total)}',
      explanation: words.expensesDuplicateExplain,
      confirmLabel: words.expensesSaveAnyway,
      onConfirm: onConfirm,
    );
  }
}
