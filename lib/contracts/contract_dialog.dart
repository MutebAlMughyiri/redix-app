import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../attachments/attachment_screen.dart';
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
import '../ui/part_keys.dart';
import '../ui/picker_field.dart';
import '../words/words.dart';
import 'contract.dart';
import 'contracts.dart';
import 'contracts_screen.dart';
import '../ui/refusal_text.dart';

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
    return _isNew ? widget.contracts.add(_contractorId, _itemId, terms) : widget.contracts.amend(widget.contract, terms, _contractorId, _itemId);
  }

  Future<void> _addDocument() async {
    final file = await widget.capture.fromAnyFile();
    final refusal = file.isNone ? file.failure : await widget.attachments.keepDocument(file);
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
    Text(words.contractsDocuments, key: ContractsScreen.documentsHeadingKey, style: Theme.of(context).textTheme.titleSmall),
    for (final document in [...widget.contract.documents, ..._addedDocuments])
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton(
          key: ContractsScreen.openDocumentKey(document.id),
          onPressed: () => context.push(AttachmentScreen.pathOf(widget.project.id, document.id, fileName: document.fileName), extra: document.contentType),
          child: Text(document.fileName, key: ContractsScreen.documentKey(document.id)),
        ),
      ),
    const SizedBox(height: 8),
    if (widget.project.mayAttachFiles) OutlinedButton.icon(key: ContractsScreen.addDocumentKey, icon: Icon(Icons.attach_file, key: ContractsScreen.addDocumentKey.icon), label: Text(words.contractsAddDocument, key: ContractsScreen.addDocumentKey.label), onPressed: _addDocument),
    if (_documentMessage.isNotEmpty) refusalText(context, words.text(_documentMessage), ContractsScreen.documentMessageKey),
  ];

  Future<void> _pickContractor() async {
    final picked = await SupplierPicker.show(context, widget.project, widget.suppliers);
    if (picked.id.isNotEmpty && mounted) {
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
  ];

  Widget _amount(Key key, TextEditingController controller, String label) => TextField(
    key: key,
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label),
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
        if (contract.hasPayments) Text([contract.supplierName, contract.itemName].join(' · '), key: ContractsScreen.partiesKey) else ..._parties(words),
        SwitchListTile(
          key: ContractsScreen.openValueKey,
          contentPadding: EdgeInsets.zero,
          title: Text(words.contractsOpenValue, key: ContractsScreen.openValueKey.title),
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
          decoration: InputDecoration(labelText: words.contractsNotes),
        ),
        ..._documents(words),
      ],
    );
  }
}
