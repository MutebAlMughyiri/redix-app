import 'package:flutter/material.dart';

import '../format/date_format.dart';
import '../format/number_format.dart';
import '../ui/api_list_body.dart';
import '../ui/picker_field.dart';
import '../words/words.dart';
import 'creditable_invoice.dart';
import 'creditable_invoices.dart';

/// The field that links a credit note to the bill it returns, which it needs (D13), opening a sheet of what that supplier's bills have left to return.
class OriginalInvoicePicker extends StatelessWidget {
  /// The field showing [chosen], choosing among [invoices] of the supplier [supplierId] and answering [onChanged].
  const OriginalInvoicePicker({super.key, required this.invoices, required this.supplierId, required this.chosen, required this.onChanged});

  /// What can be chosen.
  final CreditableInvoices invoices;

  /// The credit note's supplier.
  final String supplierId;

  /// The bill chosen; none until one is.
  final CreditableInvoice chosen;

  /// Called with the bill chosen.
  final ValueChanged<CreditableInvoice> onChanged;

  /// The choice of the bill of the entry [id].
  static Key optionKey(String id) => Key('originalInvoice.option.$id');

  Future<void> _choose(BuildContext context) async {
    invoices.ofSupplier(supplierId);
    final picked = await showModalBottomSheet<CreditableInvoice>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheet) {
        final words = Words.of(sheet);
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Column(
            children: [
              Expanded(
                child: ApiListBody(
                  list: invoices,
                  emptyText: words.expensesNoCreditableInvoice,
                  itemBuilder: (invoice) => ListTile(
                    key: optionKey(invoice.entryId),
                    title: Text(invoice.label),
                    subtitle: Text('${formatDate(invoice.date)} · ${words.expensesReturnable} ${formatMoney(invoice.returnable)}'),
                    onTap: () => Navigator.of(sheet).pop(invoice),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return PickerField(label: words.expensesOriginalInvoice, value: chosen.label, onTap: () => _choose(context));
  }
}
