// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import '../api_list.dart';
import '../auth/session.dart';
import '../structure/item_tables.dart';

/// One table an entry may go into (redix-app #84, redix-api #110). The table says what the entry is: an expense item's general or named table takes a purchase, a contract's a
/// contractor payment, a revenue item's table revenue, and a partner their capital's money in or out. Every entry asks the same things; what a table adds is answered here and
/// nowhere else.
class EntryTable {
  /// The table the API describes in [json], of the item [itemId] named [itemName], a revenue item when [isRevenue].
  EntryTable.fromJson(Map<String, dynamic> json, {required this.itemId, required this.itemName, required this.isRevenue})
    : id = json['id'] as String,
      kind = ItemTableKind.values.byName(json['kind'] as String),
      name = json['name'] as String,
      columnKeys = (json['columnKeys'] as List<dynamic>).cast<String>();

  /// No table chosen yet, which asks what a purchase asks.
  EntryTable.none() : id = '', kind = ItemTableKind.general, name = '', itemId = '', itemName = '', isRevenue = false, columnKeys = const [];

  /// The subgroup, contract or partner it prints.
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

  /// The keys of its item's columns an entry in it is asked, in their order, as the API says (FR-41, redix-api #129, R3).
  final List<String> columnKeys;

  /// Whether an entry in it is asked the column [key]; with no table chosen yet, everything a purchase asks.
  bool asks(String key) => isNone || columnKeys.contains(key);

  /// True while none is chosen.
  bool get isNone => id.isEmpty;

  /// True on the expense side: its entry says how it was paid, answers its item's columns, and may be a deduction, from an account the signed-in user may pay from. Revenue and
  /// a partner's money do none of these, and use any of the project's accounts (redix-api #110, D7).
  bool get isExpense => !isRevenue;

  /// True for a purchase's table, which asks the supplier.
  bool get asksSupplier => isExpense && !asksContract;

  /// True for a contract's payments, which show the contract's figures and ask whether the payment is inside it.
  bool get asksContract => kind == ItemTableKind.contract;

  /// True for a partner, whose entry is their capital's money in, or out as «نوع الحركة» says (redix-api #129).
  bool get isPartner => kind == ItemTableKind.partner;

  /// The word key saying what its entries are, under its name in the list.
  String get kindWordKey => kind.wordKeyOf(isRevenue: isRevenue);

  /// The column its entries' amount is in: a purchase's total, any other entry's amount (redix-api #129).
  String get amountColumn => asksSupplier ? 'total' : 'amount';

  /// The word key naming its entries' amount.
  String get amountWordKey => asksSupplier ? 'expenses.total' : 'expenses.amount';

  /// The word key naming its entries' file.
  String get fileWordKey => isPartner ? 'capital.receiptHint' : isRevenue ? 'revenue.file' : asksContract ? 'contractorPayments.receipt' : 'attachments.invoicePhoto';

  /// What a field shows of it: the table, then its sheet, the item, in brackets, as الجلاي (دفعات العظم) (the owner, 7 Nov 2026); the item's own table is its name alone.
  String get label => isNamedAfterItem ? itemName : '$name ($itemName)';

  /// True for the item's own table, named after it, which shows as its item's row; a partner's table shows under رأس المال as a contract's does under its item (redix-api #109).
  bool get isNamedAfterItem => kind == ItemTableKind.general;
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
    : id = json['id'] as String,
      name = json['name'] as String,
      items = [for (final item in json['items'] as List<dynamic>) TableItem.fromJson(item as Map<String, dynamic>)];

  /// The category's id.
  final String id;

  /// The category's name.
  final String name;

  /// Its items that take expenses.
  final List<TableItem> items;
}

/// Every table an entry may go into, by category and item, as the API offers them to the signed-in user (AC-05.3, AC-38.1, redix-api #110).
class EntryTables extends ApiList<TableCategory> {
  /// The tables of the project [projectId], seen through [session].
  EntryTables(Session session, String projectId) : super(session, '/projects/$projectId/entry-tables', 'categories', TableCategory.fromJson);

  /// The table [id], a group's, a contract's or a partner's; none when it is not on offer.
  EntryTable tableOf(String id) => all.expand((category) => category.items).expand((item) => item.tables).where((table) => table.id == id).firstOrNull ?? EntryTable.none();

  /// The general table of the item [itemId]; none when it takes no purchase.
  EntryTable generalTableOf(String itemId) => _tablesOf(itemId).where((table) => table.kind == ItemTableKind.general).firstOrNull ?? EntryTable.none();

  Iterable<EntryTable> _tablesOf(String itemId) => all.expand((category) => category.items).where((item) => item.id == itemId).expand((item) => item.tables);
}
