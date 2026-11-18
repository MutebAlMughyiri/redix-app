// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../structure/item_picker.dart';
import '../structure/offered_items.dart';
import '../ui/change_dialog.dart';
import '../words/words.dart';
import 'supplier.dart';
import 'suppliers.dart';
import 'suppliers_screen.dart';
import 'vat_number_field.dart';

/// Asks for a supplier's name, VAT number or that it has none, mobile and default item.
class SupplierDialog extends StatefulWidget {
  /// The dialog changing [supplier], or adding one when it is [Supplier.none], through [suppliers], choosing the default item among [items].
  const SupplierDialog({super.key, required this.supplier, required this.suppliers, required this.items});

  /// The supplier this dialog changes.
  final Supplier supplier;

  /// The way to change it.
  final Suppliers suppliers;

  /// The items it can default to.
  final OfferedItems items;

  @override
  State<SupplierDialog> createState() => _SupplierDialogState();
}

class _SupplierDialogState extends State<SupplierDialog> {
  late final _name = TextEditingController(text: widget.supplier.name);
  late final _vatNumber = TextEditingController(text: widget.supplier.vatNumber);
  late final _mobile = TextEditingController(text: widget.supplier.mobile);
  late var _defaultItemId = widget.supplier.defaultItemId;
  late var _defaultItemName = widget.supplier.defaultItemName;
  var _holderName = '';

  bool get _isNew => widget.supplier.id.isEmpty;

  @override
  void dispose() {
    _name.dispose();
    _vatNumber.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<String> _save() async {
    final fields = (name: _name.text, vatNumber: _vatNumber.text, mobile: _mobile.text, defaultItemId: _defaultItemId);
    final refusal = await (_isNew ? widget.suppliers.add(fields) : widget.suppliers.edit(widget.supplier, fields));
    if (mounted) {
      setState(() => _holderName = widget.suppliers.holder.name);
    }
    return refusal;
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ChangeDialog(
      title: _isNew ? words.suppliersNew : words.suppliersEdit,
      saveLabel: _isNew ? words.suppliersNew : words.suppliersSave,
      onSave: _save,
      children: [
        TextField(
          key: SuppliersScreen.supplierNameKey,
          controller: _name,
          autofocus: _isNew,
          decoration: InputDecoration(labelText: words.suppliersName),
        ),
        const SizedBox(height: 8),
        VatNumberField(controller: _vatNumber, holderName: _holderName),
        const SizedBox(height: 16),
        TextField(
          key: SuppliersScreen.mobileKey,
          controller: _mobile,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: words.suppliersMobile),
        ),
        const SizedBox(height: 16),
        ItemPicker(
          key: SuppliersScreen.defaultItemKey,
          items: widget.items,
          label: words.suppliersDefaultItem,
          none: words.suppliersNoDefaultItem,
          itemName: _defaultItemName,
          onChanged: (item) => setState(() {
            _defaultItemId = item.id;
            _defaultItemName = item.name;
          }),
        ),
      ],
    );
  }
}
