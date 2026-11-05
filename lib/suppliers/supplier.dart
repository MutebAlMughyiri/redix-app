import '../words/words.dart';

/// Where a supplier stands, as the API names it.
enum SupplierStatus {
  /// In the register, for anyone to use.
  approved,

  /// Added from the field: it waits for the first expense on it to be approved.
  pendingApproval,
}

/// A supplier in a project's register, as the API answers it. The rules live in the API; the app only draws what it is told.
class Supplier {
  /// The supplier the API describes in [json].
  Supplier.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      vatNumber = json['vatNumber'] as String,
      mobile = json['mobile'] as String,
      defaultItemId = json['defaultItemId'] as String,
      defaultItemName = json['defaultItemName'] as String,
      status = SupplierStatus.values.byName(json['status'] as String),
      isActive = json['isActive'] as bool;

  /// No supplier, for the dialog that adds one and for a choice not made yet.
  Supplier.none() : id = '', name = '', vatNumber = '', mobile = '', defaultItemId = '', defaultItemName = '', status = SupplierStatus.approved, isActive = true;

  /// The supplier's id; empty for no supplier.
  final String id;

  /// The supplier's name, as it was typed.
  final String name;

  /// Its VAT number; empty for a supplier not VAT-registered.
  final String vatNumber;

  /// Its mobile; empty when none.
  final String mobile;

  /// The item its expenses usually go to; empty when none.
  final String defaultItemId;

  /// That item's name; empty when none.
  final String defaultItemName;

  /// Where it stands.
  final SupplierStatus status;

  /// False once disabled: it disappears from entry and stays in the reports.
  final bool isActive;

  /// What a list says about it, in [words]: that it is disabled or pending approval, its VAT number or that it has none, and its default item.
  String detailsIn(Words words) => [
    if (!isActive) words.suppliersDisabled else if (status == SupplierStatus.pendingApproval) words.suppliersPendingApproval,
    if (vatNumber.isEmpty) words.suppliersNotVatRegistered else vatNumber,
    if (defaultItemName.isNotEmpty) defaultItemName,
  ].join(' · ');
}
