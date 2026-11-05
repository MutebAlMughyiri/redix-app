import 'package:flutter/material.dart';

import '../format/number_format.dart';
import '../words/words.dart';
import 'add_expense_screen.dart';
import 'invoice_figures.dart';

/// The computed amounts of an expense, read-only and rounded to two decimals (UC-022 step 6).
class FiguresBox extends StatelessWidget {
  /// The box showing [figures], at the VAT [vatPercent].
  const FiguresBox({super.key, required this.figures, required this.vatPercent});

  /// What it shows.
  final InvoiceFigures figures;

  /// The VAT rate as a percentage.
  final double vatPercent;

  Widget _row(BuildContext context, String label, Key key, double amount, TextStyle? style) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(label, style: style)),
        const SizedBox(width: 8),
        Text(formatMoney(amount), key: key, style: style),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    return Card.filled(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            _row(context, words.expensesAfterDiscount, AddExpenseScreen.afterDiscountKey, figures.afterDiscount, theme.textTheme.bodyMedium),
            _row(context, '${words.expensesVat} ${formatPlain(vatPercent)}%', AddExpenseScreen.vatKey, figures.vat, theme.textTheme.bodyMedium),
            const Divider(),
            _row(context, words.expensesTotal, AddExpenseScreen.totalKey, figures.total, theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
