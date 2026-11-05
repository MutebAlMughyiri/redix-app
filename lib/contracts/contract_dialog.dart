import 'package:flutter/material.dart';

import '../format/number_format.dart';
import '../projects/project.dart';
import '../structure/item_picker.dart';
import '../structure/offered_items.dart';
import '../suppliers/supplier.dart';
import '../suppliers/supplier_picker.dart';
import '../suppliers/suppliers.dart';
import '../ui/change_dialog.dart';
import '../ui/picker_field.dart';
import '../words/words.dart';
import 'contract.dart';
import 'contracts.dart';
import 'contracts_screen.dart';

/// Asks for a contract's terms, and for a new contract its contractor, item and unit, which are set once.
class ContractDialog extends StatefulWidget {
  /// The dialog amending [contract], or adding one when it is [Contract.none], through [contracts] of [project], picking from [suppliers] and [items].
  const ContractDialog({super.key, required this.contract, required this.project, required this.contracts, required this.suppliers, required this.items});

  /// The contract this dialog amends.
  final Contract contract;

  /// The project it belongs to, whose units it can be for.
  final Project project;

  /// The way to change it.
  final Contracts contracts;

  /// The register its contractor comes from.
  final Suppliers suppliers;

  /// The items that take contractor payments.
  final OfferedItems items;

  @override
  State<ContractDialog> createState() => _ContractDialogState();
}

class _ContractDialogState extends State<ContractDialog> {
  late final _value = TextEditingController(text: widget.contract.value == 0 ? '' : formatPlain(widget.contract.value));
  late final _unitPrice = TextEditingController(text: widget.contract.unitPrice == 0 ? '' : formatPlain(widget.contract.unitPrice));
  late final _quantity = TextEditingController(text: widget.contract.quantity == 0 ? '' : formatPlain(widget.contract.quantity));
  late final _notes = TextEditingController(text: widget.contract.notes);
  late var _isOpenValue = widget.contract.isOpenValue;
  var _contractor = Supplier.none();
  var _itemId = '';
  var _itemName = '';
  var _unitId = '';

  bool get _isNew => widget.contract.id.isEmpty;

  @override
  void dispose() {
    _value.dispose();
    _unitPrice.dispose();
    _quantity.dispose();
    _notes.dispose();
    super.dispose();
  }

  double _optional(String typed) => typed.trim().isEmpty ? 0 : parseNumber(typed);

  Future<String> _save() async {
    final value = _isOpenValue ? 0.0 : parseNumber(_value.text);
    final unitPrice = _optional(_unitPrice.text);
    final quantity = _optional(_quantity.text);
    if (value.isNaN) {
      return 'contracts.invalidValue';
    }
    if (unitPrice.isNaN) {
      return 'contracts.invalidUnitPrice';
    }
    if (quantity.isNaN) {
      return 'contracts.invalidQuantity';
    }
    final terms = (value: value, isOpenValue: _isOpenValue, unitPrice: unitPrice, quantity: quantity, notes: _notes.text);
    return _isNew ? widget.contracts.add(_contractor.id, _itemId, _unitId, terms) : widget.contracts.amend(widget.contract, terms);
  }

  Future<void> _pickContractor() async {
    final picked = await SupplierPicker.show(context, widget.project, widget.suppliers);
    if (picked.id.isNotEmpty) {
      setState(() => _contractor = picked);
    }
  }

  List<Widget> _parties(Words words) => [
    PickerField(key: ContractsScreen.contractorKey, label: words.contractsContractor, value: _contractor.name, onTap: _pickContractor),
    const SizedBox(height: 16),
    ItemPicker(
      key: ContractsScreen.itemKey,
      items: widget.items,
      label: words.contractsItem,
      itemName: _itemName,
      onChanged: (item) => setState(() {
        _itemId = item.id;
        _itemName = item.name;
      }),
    ),
    const SizedBox(height: 16),
    Text(words.contractsUnit, style: Theme.of(context).textTheme.titleSmall),
    RadioGroup<String>(
      groupValue: _unitId,
      onChanged: (unitId) => setState(() => _unitId = unitId ?? _unitId),
      child: Column(
        children: [
          for (final unit in widget.project.entryUnits) RadioListTile<String>(key: ContractsScreen.unitKey(unit.id), contentPadding: EdgeInsets.zero, value: unit.id, title: Text(unit.name)),
        ],
      ),
    ),
  ];

  Widget _amount(Key key, TextEditingController controller, String label) => TextField(
    key: key,
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
  );

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final contract = widget.contract;
    return ChangeDialog(
      title: _isNew ? words.contractsNew : words.contractsEdit,
      saveLabel: _isNew ? words.contractsNew : words.contractsSave,
      onSave: _save,
      children: [
        if (_isNew) ..._parties(words) else Text([contract.supplierName, contract.itemName, contract.unitName].join(' · '), key: ContractsScreen.partiesKey),
        SwitchListTile(
          key: ContractsScreen.openValueKey,
          contentPadding: EdgeInsets.zero,
          title: Text(words.contractsOpenValue),
          value: _isOpenValue,
          onChanged: (isOpenValue) => setState(() => _isOpenValue = isOpenValue),
        ),
        if (!_isOpenValue) ...[_amount(ContractsScreen.valueKey, _value, words.contractsContractValue), const SizedBox(height: 16)],
        _amount(ContractsScreen.unitPriceKey, _unitPrice, words.contractsUnitPrice),
        const SizedBox(height: 16),
        _amount(ContractsScreen.quantityKey, _quantity, words.contractsQuantity),
        const SizedBox(height: 16),
        TextField(
          key: ContractsScreen.notesKey,
          controller: _notes,
          maxLines: 3,
          decoration: InputDecoration(labelText: words.contractsNotes, border: const OutlineInputBorder()),
        ),
      ],
    );
  }
}
