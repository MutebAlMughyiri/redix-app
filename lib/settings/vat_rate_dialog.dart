import 'package:flutter/material.dart';

import '../format/number_format.dart';
import '../projects/project.dart';
import '../projects/projects.dart';
import '../ui/change_dialog.dart';
import '../words/words.dart';
import 'payment_methods_screen.dart';

/// Asks for a project's VAT rate, as a percentage (BR-14).
class VatRateDialog extends StatefulWidget {
  /// The dialog changing the rate of [project] through [projects].
  const VatRateDialog({super.key, required this.project, required this.projects});

  /// The project whose rate this is.
  final Project project;

  /// The way to change it.
  final Projects projects;

  @override
  State<VatRateDialog> createState() => _VatRateDialogState();
}

class _VatRateDialogState extends State<VatRateDialog> {
  late final _percent = TextEditingController(text: formatPercent(widget.project.vatPercent));

  @override
  void dispose() {
    _percent.dispose();
    super.dispose();
  }

  Future<String> _save() async {
    final percent = parseNumber(_percent.text);
    return percent.isNaN ? 'projects.invalidVatRate' : widget.projects.setVatPercent(widget.project, percent);
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ChangeDialog(
      title: words.paymentMethodsChangeVatRate,
      saveLabel: words.paymentMethodsSave,
      onSave: _save,
      children: [
        TextField(
          key: PaymentMethodsScreen.vatPercentKey,
          controller: _percent,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: words.paymentMethodsVatPercent, border: const OutlineInputBorder()),
        ),
      ],
    );
  }
}
