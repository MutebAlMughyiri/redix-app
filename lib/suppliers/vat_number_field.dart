import 'package:flutter/material.dart';

import '../words/words.dart';
import 'suppliers_screen.dart';

/// Asks for a supplier's VAT number, or that it has none, and names the supplier already holding a number that was refused.
class VatNumberField extends StatelessWidget {
  /// The field typing into [controller], with no number asked while [notVatRegistered], which the switch changes through [onNotVatRegisteredChanged]. A [holderName] that is not empty names who holds the number.
  const VatNumberField({super.key, required this.controller, required this.notVatRegistered, required this.holderName, required this.onNotVatRegisteredChanged});

  /// What was typed.
  final TextEditingController controller;

  /// Whether the supplier has no VAT number.
  final bool notVatRegistered;

  /// The name of the supplier already holding the number; empty when none does.
  final String holderName;

  /// Called when the switch changes.
  final ValueChanged<bool> onNotVatRegisteredChanged;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Column(
      children: [
        SwitchListTile(
          key: SuppliersScreen.notVatRegisteredKey,
          contentPadding: EdgeInsets.zero,
          title: Text(words.suppliersNotVatRegistered),
          value: notVatRegistered,
          onChanged: onNotVatRegisteredChanged,
        ),
        if (!notVatRegistered)
          TextField(
            key: SuppliersScreen.vatNumberKey,
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: words.suppliersVatNumber,
              border: const OutlineInputBorder(),
              error: holderName.isEmpty ? null : Text('${words.suppliersHolder} $holderName', key: SuppliersScreen.holderKey),
            ),
          ),
      ],
    );
  }
}
