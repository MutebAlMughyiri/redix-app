import '../api_list.dart';
import '../auth/session.dart';
import '../structure/item_tables.dart';

/// One table an entry may go into (redix-app #84, redix-api #101). The table says what the entry is: an expense item's general or named table takes a purchase, a contract's a
/// contractor payment, a revenue item's table revenue, and a partner their capital's money in or out; what differs between them is answered here and nowhere else.
class EntryTable {
  /// The table the API describes in [json], of the item [itemId] named [itemName], a revenue item when [isRevenue].
  EntryTable.fromJson(Map<String, dynamic> json, {required this.itemId, required this.itemName, required this.isRevenue})
    : id = json['id'] as String,
      kind = ItemTableKind.values.byName(json['kind'] as String),
      name = json['name'] as String;

  /// No table chosen yet, which asks what a purchase asks.
  EntryTable.none() : id = '', kind = ItemTableKind.general, name = '', itemId = '', itemName = '', isRevenue = false;

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

  /// True for a revenue item's table, whose entries are revenue.
  final bool isRevenue;

  /// True while none is chosen.
  bool get isNone => id.isEmpty;

  /// True for a contract's payments.
  bool get isContract => kind == ItemTableKind.contract;

  /// True for a partner, whose entries are their capital's money in or out.
  bool get isPartner => kind == ItemTableKind.partner;

  /// True for revenue and a partner's money: Finance enters it and sends it for approval at once, with no draft and none of an expense's fields (redix-api #101, D9).
  bool get isDirect => isRevenue || isPartner;

  /// The word key saying what its entries are, under its name in the list.
  String get kindWordKey => isPartner ? 'categories.tableCapital' : isRevenue ? 'categories.tableRevenue' : isContract ? 'categories.tableContract' : 'categories.tablePurchases';

  /// The API route its entries are recorded on.
  String get route => isContract ? 'contractor-payments' : 'expenses';

  /// The column its entries' amount is in.
  String get amountColumn => isContract ? 'amount' : 'total';

  /// The word key naming its entries' amount.
  String get amountWordKey => isContract ? 'expenses.amount' : 'expenses.total';

  /// The word key naming its entries' file.
  String get fileWordKey => isContract ? 'contractorPayments.receipt' : 'attachments.invoicePhoto';

  /// What a field shows of it: the table, then its sheet, the item, in brackets, as الجلاي (دفعات العظم) (Muteb, 7 Nov 2026); the item's own table is its name alone.
  String get label => isNamedAfterItem ? itemName : '$name ($itemName)';

  /// True for the item's own table, named after it, and for a partner: each shows as its item's row.
  bool get isNamedAfterItem => kind == ItemTableKind.general || isPartner;
}

/// An item and the tables of it an expense may go into, in the order its sheet prints them.
class TableItem {
  /// The item the API describes in [json].
  TableItem.fromJson(Map<String, dynamic> json) : this._(json['id'] as String, json['name'] as String, json['tables'] as List<dynamic>, json['isRevenue'] as bool);

  TableItem._(this.id, this.name, List<dynamic> tables, bool isRevenue)
    : tables = [for (final table in tables) EntryTable.fromJson(table as Map<String, dynamic>, itemId: id, itemName: name, isRevenue: isRevenue)];

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

  /// The category's name; empty for the partners' group, which the API sends with no name (redix-api #101).
  final String name;

  /// True for the partners' group.
  bool get isPartners => name.isEmpty;

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
