import 'package:flutter/material.dart';

import '../format/date_format.dart';
import '../format/number_format.dart';
import '../ui/api_list_body.dart';
import '../ui/picker_field.dart';
import '../words/words.dart';
import 'creditable_invoice.dart';
import 'creditable_invoices.dart';

/// The field that links a credit note to its original invoice, opening a sheet of what that supplier's invoices have left to return, or none.
class OriginalInvoicePicker extends StatelessWidget {
  /// The field showing [chosen], choosing among [invoices] of the supplier [supplierId] and answering [onChanged].
  const OriginalInvoicePicker({super.key, required this.invoices, required this.supplierId, required this.chosen, required this.onChanged});

  /// What can be chosen.
  final CreditableInvoices invoices;

  /// The credit note's supplier.
  final String supplierId;

  /// The invoice chosen; none when it is not linked.
  final CreditableInvoice chosen;

  /// Called with the invoice chosen, or none.
  final ValueChanged<CreditableInvoice> onChanged;

  /// The choice of the invoice of the entry [id]; of none when that is empty.
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
              ListTile(key: optionKey(''), title: Text(words.expensesNoOriginalInvoice), onTap: () => Navigator.of(sheet).pop(CreditableInvoice.none())),
              Expanded(
                child: ApiListBody(
                  list: invoices,
                  emptyText: words.expensesNoCreditableInvoice,
                  itemBuilder: (invoice) => ListTile(
                    key: optionKey(invoice.entryId),
                    title: Text(invoice.number),
                    subtitle: Text('${formatDate(invoice.invoiceDate)} · ${words.expensesReturnable} ${formatMoney(invoice.returnable)}'),
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
    return PickerField(label: words.expensesOriginalInvoice, value: chosen.isNone ? words.expensesNoOriginalInvoice : chosen.number, onTap: () => _choose(context));
  }
}
