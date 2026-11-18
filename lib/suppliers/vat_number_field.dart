// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../words/words.dart';
import 'suppliers_screen.dart';

/// Asks for a supplier's VAT number, which may stay empty (BR-16), and names the supplier already holding a number that was refused.
class VatNumberField extends StatelessWidget {
  /// The field typing into [controller]. A [holderName] that is not empty names who holds the number.
  const VatNumberField({super.key, required this.controller, required this.holderName});

  /// What was typed.
  final TextEditingController controller;

  /// The name of the supplier already holding the number; empty when none does.
  final String holderName;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return TextField(
      key: SuppliersScreen.vatNumberKey,
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: words.suppliersVatNumber,
        error: holderName.isEmpty ? null : Text('${words.suppliersHolder} $holderName', key: SuppliersScreen.holderKey),
      ),
    );
  }
}
