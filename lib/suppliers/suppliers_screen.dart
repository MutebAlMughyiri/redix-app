import 'package:flutter/material.dart';

import '../projects/project.dart';
import '../structure/offered_items.dart';
import '../ui/api_list_body.dart';
import '../ui/bottom_button.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'supplier.dart';
import 'supplier_dialog.dart';
import 'supplier_row.dart';
import 'suppliers.dart';
import '../ui/list_search.dart';
import '../words/word_fill.dart';
import '../format/parts_line.dart';

/// A project's supplier register (UC-017): everyone with access sees it, and whoever keeps the settings adds, changes and disables its suppliers.
class SuppliersScreen extends StatefulWidget {
  /// The screen, showing and changing the [suppliers] of [project], choosing a default item among [items].
  const SuppliersScreen({super.key, required this.project, required this.suppliers, required this.items});

  /// The project they belong to.
  final Project project;

  /// The register this screen shows and changes.
  final Suppliers suppliers;

  /// The items a supplier can default to.
  final OfferedItems items;

  /// The screen's route.
  static const path = '/projects/:projectId/suppliers';

  /// The route of the suppliers of the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/suppliers';

  /// The button that adds a supplier.
  static const addKey = Key('suppliers.add');

  /// Edit, in a supplier's menu.
  static const editKey = Key('suppliers.edit');

  /// Disable, in a supplier's menu.
  static const disableKey = Key('suppliers.disable');

  /// Enable, in a supplier's menu.
  static const enableKey = Key('suppliers.enable');

  /// The name, in the dialog.
  static const supplierNameKey = Key('suppliers.supplierName');

  /// The VAT number, in the dialog.
  static const vatNumberKey = Key('suppliers.vatNumber');

  /// The line naming who already holds the VAT number, in the dialog.
  static const holderKey = Key('suppliers.holder');

  /// The mobile, in the dialog.
  static const mobileKey = Key('suppliers.mobile');

  /// The default item, in the dialog.
  static const defaultItemKey = Key('suppliers.defaultItem');

  /// The name of the supplier [id].
  static Key nameKey(String id) => Key('suppliers.name.$id');

  /// What the register says about the supplier [id].
  static Key detailsKey(String id) => Key('suppliers.details.$id');

  /// The menu of the supplier [id].
  static Key menuKey(String id) => Key('suppliers.menu.$id');

  /// The row of the supplier [id].
  static Key rowKey(String id) => Key('suppliers.row.$id');

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  @override
  void initState() {
    super.initState();
    widget.suppliers.loadOnOpen();
    if (widget.project.mayManageSettings) {
      widget.items.loadOnOpen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final project = widget.project;
    final suppliers = widget.suppliers;
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.suppliersTitle, subject: project.name)),
      bottomNavigationBar: BottomButton(
        buttonKey: SuppliersScreen.addKey,
        label: words.suppliersNew,
        onPressed: project.mayManageSettings ? () => showDialog<void>(context: context, builder: (_) => SupplierDialog(supplier: Supplier.none(), suppliers: suppliers, items: widget.items)) : null,
      ),
      body: ApiListBody<Supplier>(
        list: suppliers,
        emptyText: words.suppliersEmpty,
        search: ListSearch(
          hint: words.commonSearchIn.fill([words.suppliersTitle]),
          textOf: (supplier) => partsLine([supplier.name, supplier.vatNumber, supplier.mobile, supplier.defaultItemName]),
        ),
        itemBuilder: (supplier) => SupplierRow(supplier: supplier, suppliers: suppliers, items: widget.items, mayChange: project.mayManageSettings),
      ),
    );
  }
}
