import '../api_list.dart';
import '../auth/session.dart';
import '../structure/item_tables.dart';

/// One table of an item's sheet an expense may go into (redix-app #84). The table says what the entry is: its general or a named one takes a purchase, a contract's a contractor
/// payment, so what differs between the two is answered here and nowhere else.
class EntryTable {
  /// The table the API describes in [json], of the item [itemId] named [itemName].
  EntryTable.fromJson(Map<String, dynamic> json, {required this.itemId, required this.itemName})
    : id = json['id'] as String,
      kind = ItemTableKind.values.byName(json['kind'] as String),
      name = json['name'] as String;

  /// No table chosen yet, which asks what a purchase asks.
  EntryTable.none() : id = '', kind = ItemTableKind.general, name = '', itemId = '', itemName = '';

  /// The subgroup or contract it prints.
  final String id;

  /// What it prints.
  final ItemTableKind kind;

  /// The item's name for its general table, the subgroup's, or the contractor's.
  final String name;

  /// Its item.
  final String itemId;

  /// Its item's name.
  final String itemName;

  /// True while none is chosen.
  bool get isNone => id.isEmpty;

  /// True for a contract's payments.
  bool get isContract => kind == ItemTableKind.contract;

  /// The API route its entries are recorded on.
  String get route => isContract ? 'contractor-payments' : 'expenses';

  /// The column its entries' amount is in.
  String get amountColumn => isContract ? 'amount' : 'total';

  /// The word key naming its entries' amount.
  String get amountWordKey => isContract ? 'expenses.amount' : 'expenses.total';

  /// The word key naming its entries' file.
  String get fileWordKey => isContract ? 'contractorPayments.receipt' : 'attachments.invoicePhoto';

  /// What a field shows of it: the table, then its sheet, the item, in brackets, as الجلاي (دفعات العظم) (Muteb, 7 Nov 2026); the item's own table is its name alone.
  String get label => kind == ItemTableKind.general ? itemName : '$name ($itemName)';
}

/// An item and the tables of it an expense may go into, in the order its sheet prints them.
class TableItem {
  /// The item the API describes in [json].
  TableItem.fromJson(Map<String, dynamic> json) : this._(json['id'] as String, json['name'] as String, json['tables'] as List<dynamic>);

  TableItem._(this.id, this.name, List<dynamic> tables) : tables = [for (final table in tables) EntryTable.fromJson(table as Map<String, dynamic>, itemId: id, itemName: name)];

  /// The item's id.
  final String id;

  /// The item's name.
  final String name;

  /// Its tables.
  final List<EntryTable> tables;
}

/// A category of the items an expense may go into.
class TableCategory {
  /// The category the API describes in [json].
  TableCategory.fromJson(Map<String, dynamic> json)
    : name = json['name'] as String,
      items = [for (final item in json['items'] as List<dynamic>) TableItem.fromJson(item as Map<String, dynamic>)];

  /// The category's name.
  final String name;

  /// Its items that take expenses.
  final List<TableItem> items;
}

/// Every table an expense may go into, by category and item, as the API offers them (AC-05.3, AC-38.1).
class EntryTables extends ApiList<TableCategory> {
  /// The tables of the project [projectId], seen through [session].
  EntryTables(Session session, String projectId) : super(session, '/projects/$projectId/entry-tables', 'categories', TableCategory.fromJson);

  /// The table [id] of the item [itemId]; none when it is not on offer.
  EntryTable tableOf(String itemId, String id) => _tablesOf(itemId).where((table) => table.id == id).firstOrNull ?? EntryTable.none();

  /// The general table of the item [itemId]; none when it takes no purchase.
  EntryTable generalTableOf(String itemId) => _tablesOf(itemId).where((table) => table.kind == ItemTableKind.general).firstOrNull ?? EntryTable.none();

  Iterable<EntryTable> _tablesOf(String itemId) => all.expand((category) => category.items).where((item) => item.id == itemId).expand((item) => item.tables);
}
