/// What an item is for (FR-38), as the API names it, each knowing its word.
enum ItemType {
  /// Purchases only.
  purchases('categories.typePurchases'),

  /// Contractor payments only.
  contractorPayments('categories.typeContractorPayments'),

  /// Both purchases and contractor payments.
  both('categories.typeBoth'),

  /// Revenue: a unit sold, with its sales invoice.
  sale('categories.typeSale'),

  /// Revenue: VAT refunded, recorded like any other revenue (redix-api #96, D23).
  vatRefund('categories.typeVatRefund'),

  /// Revenue: anything else that comes in.
  otherRevenue('categories.typeOtherRevenue');

  const ItemType(this.wordKey);

  /// The key of the word that names this type.
  final String wordKey;

  /// True for a revenue type: its entries are money coming in, on the revenue side of the summary (FR-38).
  bool get isRevenue => index >= sale.index;
}

/// A group inside an item, such as مواد, as the API answers it. The item's general group has an empty name.
class Subgroup {
  /// The subgroup the API describes in [json].
  Subgroup.fromJson(Map<String, dynamic> json) : id = json['id'] as String, name = json['name'] as String;

  /// The subgroup's id.
  final String id;

  /// The subgroup's name, as it was typed; empty for the item's general group.
  final String name;
}

/// An item (البند) under a category, as the API answers it.
class Item {
  /// The item the API describes in [json].
  Item.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      type = ItemType.values.byName(json['type'] as String),
      isActive = json['isActive'] as bool,
      subgroups = [for (final subgroup in json['subgroups'] as List<dynamic>) Subgroup.fromJson(subgroup as Map<String, dynamic>)],
      showsTablePercentages = json['showsTablePercentages'] as bool;

  /// No item, for a screen whose list is not read yet.
  Item.none() : id = '', name = '', type = ItemType.both, isActive = false, subgroups = [], showsTablePercentages = false;

  /// The item's id.
  final String id;

  /// The item's name, as it was typed.
  final String name;

  /// What it is for.
  final ItemType type;

  /// False once disabled: it disappears from entry and stays in the reports.
  final bool isActive;

  /// Its subgroups in order, the general one first.
  final List<Subgroup> subgroups;

  /// True when its sheet in the report calculates each table's percentage of the grand total.
  final bool showsTablePercentages;

  /// The subgroups a person named, without the general one.
  List<Subgroup> get namedSubgroups => subgroups.where((subgroup) => subgroup.name.isNotEmpty).toList();

}

/// A category (التصنيف الرئيسي) of a project's expenses, as the API answers it.
class Category {
  /// The category the API describes in [json].
  Category.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      isActive = json['isActive'] as bool,
      items = [for (final item in json['items'] as List<dynamic>) Item.fromJson(item as Map<String, dynamic>)];

  Category._(this.id, this.name, this.isActive, this.items);

  /// The category's id.
  final String id;

  /// The category's name, as it was typed.
  final String name;

  /// False once disabled: it and its items disappear from entry and stay in the reports.
  final bool isActive;

  /// Its items, in order.
  final List<Item> items;

  /// The same category holding [items], for showing a new order at once.
  Category withItems(List<Item> items) => Category._(id, name, isActive, items);
}
