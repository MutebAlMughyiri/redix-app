import 'package:flutter/material.dart';

import '../ui/api_list_body.dart';
import '../words/words.dart';
import 'supplier.dart';
import 'supplier_search.dart';
import 'suppliers.dart';

/// Picks a supplier from a project's register (UC-018): a sheet that searches by name or VAT number, so free text never names a supplier (BR-19).
class SupplierPicker extends StatefulWidget {
  /// The sheet picking from [suppliers].
  const SupplierPicker({super.key, required this.suppliers});

  /// The register it picks from.
  final Suppliers suppliers;

  /// The search field.
  static const searchKey = Key('supplierPicker.search');

  /// The button that closes the sheet without picking.
  static const closeKey = Key('supplierPicker.close');

  /// The line that says the list could not be read.
  static const messageKey = ApiListBody.messageKey;

  /// The line shown while nothing matches.
  static const emptyKey = ApiListBody.emptyKey;

  /// The row of the supplier [id], which picks it.
  static Key rowKey(String id) => Key('supplierPicker.row.$id');

  /// What the sheet says about the supplier [id].
  static Key detailsKey(String id) => Key('supplierPicker.details.$id');

  /// Opens the sheet over [context], picking from [suppliers]. Answers the supplier picked, with its VAT number, or no supplier when closed without picking.
  static Future<Supplier> show(BuildContext context, Suppliers suppliers) async =>
      await showModalBottomSheet<Supplier>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => SupplierPicker(suppliers: suppliers),
      ) ??
      Supplier.none();

  @override
  State<SupplierPicker> createState() => _SupplierPickerState();
}

class _SupplierPickerState extends State<SupplierPicker> {
  SupplierSearch get _search => widget.suppliers.search;

  @override
  void initState() {
    super.initState();
    _search.openAnew();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(child: Text(words.suppliersPick, style: Theme.of(context).textTheme.titleLarge)),
                  const CloseButton(key: SupplierPicker.closeKey),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                key: SupplierPicker.searchKey,
                onChanged: _search.find,
                decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: words.suppliersSearchHint, border: const OutlineInputBorder()),
              ),
            ),
            Expanded(
              child: ApiListBody(
                list: _search,
                emptyText: words.suppliersNoMatch,
                itemBuilder: (supplier) => ListTile(
                  key: SupplierPicker.rowKey(supplier.id),
                  contentPadding: EdgeInsets.zero,
                  title: Text(supplier.name),
                  subtitle: Text(supplier.detailsIn(words), key: SupplierPicker.detailsKey(supplier.id)),
                  onTap: () => Navigator.of(context).pop(supplier),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
