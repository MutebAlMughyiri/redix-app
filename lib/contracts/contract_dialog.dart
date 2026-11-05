import 'package:flutter/material.dart';

import '../attachments/attachment.dart';
import '../attachments/attachments.dart';
import '../attachments/invoice_capture.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../structure/item_picker.dart';
import '../structure/offered_items.dart';
import '../suppliers/supplier_picker.dart';
import '../suppliers/suppliers.dart';
import '../ui/change_dialog.dart';
import '../ui/picker_field.dart';
import '../words/words.dart';
import 'contract.dart';
import 'contracts.dart';
import 'contracts_screen.dart';

/// Asks for a contract's terms, and its contractor, item and unit while no payment names it.
class ContractDialog extends StatefulWidget {
  /// The dialog amending [contract], or adding one when it is [Contract.none], through [contracts] of [project], picking from [suppliers] and [items], and keeping its documents through [attachments] from what [capture] picks.
  const ContractDialog({super.key, required this.contract, required this.project, required this.contracts, required this.suppliers, required this.items, required this.attachments, required this.capture});

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

  /// The way to keep a document.
  final Attachments attachments;

  /// The phone's files.
  final InvoiceCapture capture;

  @override
  State<ContractDialog> createState() => _ContractDialogState();
}

class _ContractDialogState extends State<ContractDialog> {
  late final _value = TextEditingController(text: widget.contract.value == 0 ? '' : formatPlain(widget.contract.value));
  late final _unitPrice = TextEditingController(text: widget.contract.unitPrice == 0 ? '' : formatPlain(widget.contract.unitPrice));
  late final _quantity = TextEditingController(text: widget.contract.quantity == 0 ? '' : formatPlain(widget.contract.quantity));
  late final _notes = TextEditingController(text: widget.contract.notes);
  late var _isOpenValue = widget.contract.isOpenValue;
  late var _contractorId = widget.contract.supplierId;
  late var _contractorName = widget.contract.supplierName;
  late var _itemId = widget.contract.itemId;
  late var _itemName = widget.contract.itemName;
  late var _unitId = widget.contract.unitId;
  final _addedDocuments = <Attachment>[];
  var _documentMessage = '';

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
    final terms = (value: value, isOpenValue: _isOpenValue, unitPrice: unitPrice, quantity: quantity, notes: _notes.text, attachmentIds: [for (final document in _addedDocuments) document.id]);
    return _isNew ? widget.contracts.add(_contractorId, _itemId, _unitId, terms) : widget.contracts.amend(widget.contract, terms, _contractorId, _itemId, _unitId);
  }

  Future<void> _addDocument() async {
    final file = await widget.capture.fromFiles();
    final refusal = file.isNone ? file.failure : await widget.attachments.keep(file);
    if (!mounted) {
      return;
    }
    setState(() {
      _documentMessage = refusal;
      if (!file.isNone && refusal.isEmpty) {
        _addedDocuments.add(widget.attachments.kept);
      }
    });
  }

  List<Widget> _documents(Words words) => [
    const SizedBox(height: 16),
    Text(words.contractsDocuments, style: Theme.of(context).textTheme.titleSmall),
    for (final document in [...widget.contract.documents, ..._addedDocuments])
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(document.fileName, key: ContractsScreen.documentKey(document.id)),
      ),
    const SizedBox(height: 8),
    OutlinedButton.icon(key: ContractsScreen.addDocumentKey, icon: const Icon(Icons.attach_file), label: Text(words.contractsAddDocument), onPressed: _addDocument),
    if (_documentMessage.isNotEmpty) Text(words.text(_documentMessage), key: ContractsScreen.documentMessageKey, style: TextStyle(color: Theme.of(context).colorScheme.error)),
  ];

  Future<void> _pickContractor() async {
    final picked = await SupplierPicker.show(context, widget.project, widget.suppliers);
    if (picked.id.isNotEmpty) {
      setState(() {
        _contractorId = picked.id;
        _contractorName = picked.name;
      });
    }
  }

  List<Widget> _parties(Words words) => [
    PickerField(key: ContractsScreen.contractorKey, label: words.contractsContractor, value: _contractorName, onTap: _pickContractor),
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
        if (contract.hasPayments) Text([contract.supplierName, contract.itemName, contract.unitName].join(' · '), key: ContractsScreen.partiesKey) else ..._parties(words),
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
        ..._documents(words),
      ],
    );
  }
}
