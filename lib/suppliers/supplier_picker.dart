import 'package:flutter/material.dart';

import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../words/words.dart';
import 'quick_add_supplier_dialog.dart';
import 'supplier.dart';
import 'supplier_search.dart';
import 'suppliers.dart';

/// Picks a supplier from a project's register (UC-018): a sheet that searches by name or VAT number, so free text never names a supplier (BR-19), and adds a missing one without leaving what is being entered (UC-019).
class SupplierPicker extends StatefulWidget {
  /// The sheet picking from the [suppliers] of [project].
  const SupplierPicker({super.key, required this.project, required this.suppliers});

  /// The project the register belongs to.
  final Project project;

  /// The register it picks from.
  final Suppliers suppliers;

  /// The search field.
  static const searchKey = Key('supplierPicker.search');

  /// The button that closes the sheet without picking.
  static const closeKey = Key('supplierPicker.close');

  /// The button that adds a missing supplier.
  static const quickAddKey = Key('supplierPicker.quickAdd');

  /// The button that goes on with the supplier already holding the number, in the quick add.
  static const useExistingKey = Key('supplierPicker.useExisting');

  /// The line that says a new supplier waits for approval, in the quick add.
  static const pendingHintKey = Key('supplierPicker.pendingHint');

  /// The line that says the list could not be read.
  static const messageKey = ApiListBody.messageKey;

  /// The line shown while nothing matches.
  static const emptyKey = ApiListBody.emptyKey;

  /// The row of the supplier [id], which picks it.
  static Key rowKey(String id) => Key('supplierPicker.row.$id');

  /// What the sheet says about the supplier [id].
  static Key detailsKey(String id) => Key('supplierPicker.details.$id');

  /// Opens the sheet over [context], picking from the [suppliers] of [project]. Answers the supplier picked, with its VAT number, or no supplier when closed without picking.
  static Future<Supplier> show(BuildContext context, Project project, Suppliers suppliers) async =>
      await showModalBottomSheet<Supplier>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => SupplierPicker(project: project, suppliers: suppliers),
      ) ??
      Supplier.none();

  @override
  State<SupplierPicker> createState() => _SupplierPickerState();
}

class _SupplierPickerState extends State<SupplierPicker> {
  final _typed = TextEditingController();

  SupplierSearch get _search => widget.suppliers.search;

  @override
  void initState() {
    super.initState();
    _search.openAnew();
  }

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  Future<void> _quickAdd() async {
    var picked = Supplier.none();
    await showDialog<void>(
      context: context,
      builder: (_) => QuickAddSupplierDialog(project: widget.project, suppliers: widget.suppliers, typed: _typed.text, onPicked: (supplier) => picked = supplier),
    );
    if (picked.id.isNotEmpty && mounted) {
      Navigator.of(context).pop(picked);
    }
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
                controller: _typed,
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
            if (widget.project.mayAddSupplier)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(key: SupplierPicker.quickAddKey, icon: const Icon(Icons.add), label: Text(words.suppliersQuickAdd), onPressed: _quickAdd),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
