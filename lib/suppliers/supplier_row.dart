import 'package:flutter/material.dart';

import '../structure/offered_items.dart';
import '../ui/part_keys.dart';
import '../ui/refusal_snack_bar.dart';
import '../words/words.dart';
import 'supplier.dart';
import 'supplier_dialog.dart';
import 'suppliers.dart';
import 'suppliers_screen.dart';
import '../ui/app_color.dart';
import '../ui/row_menu.dart';

/// One supplier: its name, what the register says about it and, for whoever keeps the settings, a menu of what can be done to it.
class SupplierRow extends StatelessWidget {
  /// The row of [supplier], changed through [suppliers] while [mayChange], choosing a default item among [items].
  const SupplierRow({super.key, required this.supplier, required this.suppliers, required this.items, required this.mayChange});

  /// The supplier this row shows.
  final Supplier supplier;

  /// The way to change it.
  final Suppliers suppliers;

  /// The items it can default to.
  final OfferedItems items;

  /// Whether the signed-in user may change it now.
  final bool mayChange;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Card.outlined(
      key: SuppliersScreen.rowKey(supplier.id),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        key: SuppliersScreen.rowKey(supplier.id).body,
        contentPadding: EdgeInsetsDirectional.fromSTEB(16, 0, mayChange ? 4 : 16, 0),
        title: Text(
          supplier.name,
          key: SuppliersScreen.nameKey(supplier.id),
          style: AppColor.quiet.textUnless(context, supplier.isActive),
        ),
        subtitle: Text(supplier.detailsIn(words), key: SuppliersScreen.detailsKey(supplier.id)),
        trailing: mayChange
            ? rowMenu(SuppliersScreen.menuKey(supplier.id), [
                  rowMenuItem(SuppliersScreen.editKey, words.suppliersEdit, () => showDialog<void>(
                      context: context,
                      builder: (_) => SupplierDialog(supplier: supplier, suppliers: suppliers, items: items),
                    )),
                  if (supplier.isActive)
                    rowMenuItem(SuppliersScreen.disableKey, words.suppliersDisable, () => showRefusalOf(context, suppliers.disable(supplier)))
                  else
                    rowMenuItem(SuppliersScreen.enableKey, words.suppliersEnable, () => showRefusalOf(context, suppliers.enable(supplier))),
                ])
            : null,
      ),
    );
  }
}
