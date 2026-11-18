// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../auth/permission.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../ui/change_dialog.dart';
import '../ui/part_keys.dart';
import '../words/words.dart';
import 'supplier.dart';
import 'supplier_picker.dart';
import 'suppliers.dart';
import 'suppliers_screen.dart';
import 'vat_number_field.dart';

/// Asks for a missing supplier's name and VAT number, without leaving what is being entered (UC-019). A number another supplier holds names that supplier, and offers it instead.
class QuickAddSupplierDialog extends StatefulWidget {
  /// The dialog adding to [suppliers] of [project], starting from what the search held in [typed] or the seller [name] of an invoice's QR code, and calling [onPicked] with the supplier to go on with.
  const QuickAddSupplierDialog({super.key, required this.project, required this.suppliers, required this.typed, this.name = '', required this.onPicked});

  /// The project the supplier joins.
  final Project project;

  /// The way to add it.
  final Suppliers suppliers;

  /// What the search held: digits start the VAT number, anything else the name.
  final String typed;

  /// The name to start from, when something other than the search knows it; empty otherwise.
  final String name;

  /// Called with the supplier added, or the one offered instead.
  final ValueChanged<Supplier> onPicked;

  @override
  State<QuickAddSupplierDialog> createState() => _QuickAddSupplierDialogState();
}

class _QuickAddSupplierDialogState extends State<QuickAddSupplierDialog> {
  late final _typed = westernDigits(widget.typed.trim());
  late final _isNumber = RegExp(r'^\d+$').hasMatch(_typed);
  late final _name = TextEditingController(text: widget.name.isNotEmpty ? widget.name : (_isNumber ? '' : _typed));
  late final _vatNumber = TextEditingController(text: _isNumber ? _typed : '');
  var _holder = Supplier.none();

  @override
  void dispose() {
    _name.dispose();
    _vatNumber.dispose();
    super.dispose();
  }

  Future<String> _save() async {
    final suppliers = widget.suppliers;
    final refusal = await suppliers.add((name: _name.text, vatNumber: _vatNumber.text, mobile: '', defaultItemId: ''));
    if (refusal.isEmpty) {
      widget.onPicked(suppliers.added);
    } else if (mounted) {
      setState(() => _holder = suppliers.holder);
    }
    return refusal;
  }

  void _useHolder() {
    widget.onPicked(_holder);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ChangeDialog(
      title: words.suppliersQuickAdd,
      saveLabel: words.suppliersAddAndPick,
      onSave: _save,
      children: [
        TextField(
          key: SuppliersScreen.supplierNameKey,
          controller: _name,
          autofocus: true,
          decoration: InputDecoration(labelText: words.suppliersName),
        ),
        const SizedBox(height: 8),
        VatNumberField(controller: _vatNumber, holderName: _holder.name),
        if (_holder.isActive && _holder.id.isNotEmpty) TextButton(key: SupplierPicker.useExistingKey, onPressed: _useHolder, child: Text(words.suppliersUseExisting, key: SupplierPicker.useExistingKey.label)),
        if (!widget.project.may(Permission.manageSettings)) ...[
          const SizedBox(height: 8),
          Text(words.suppliersPendingHint, key: SupplierPicker.pendingHintKey, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
