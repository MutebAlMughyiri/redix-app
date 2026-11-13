import '../api_object.dart';
import '../auth/session.dart';
import '../structure/item_column.dart';

/// A column a table of an item's report prints, its name and what it holds (redix-api #129, R1).
class ReportColumn {
  /// A column as the API answers it.
  ReportColumn.fromJson(Map<String, dynamic> json) : key = json['key'] as String, name = json['name'] as String, dataType = ColumnDataType.values.byName(json['dataType'] as String);

  /// Its key: `description` is «الوصف», the row's title.
  final String key;

  /// Its name.
  final String name;

  /// What it holds, which says how its values show.
  final ColumnDataType dataType;
}

/// One purchase or payment in an item's report.
class ItemEntryRow {
  /// A row as the API answers it.
  ItemEntryRow.fromJson(Map<String, dynamic> json)
    : entryId = json['entryId'] as String,
      date = DateTime.parse(json['date'] as String),
      amount = (json['amount'] as num).toDouble(),
      isOutsideContract = json['isOutsideContract'] as bool,
      values = (json['values'] as List<dynamic>).cast<String>();

  /// The entry.
  final String entryId;

  /// The day it was paid.
  final DateTime date;

  /// What was paid.
  final double amount;

  /// True for a payment outside its contract.
  final bool isOutsideContract;

  /// What it shows under each of its table's columns, in their order (redix-api #129, R1).
  final List<String> values;
}

/// One subgroup's purchases.
class SubgroupReport {
  /// A subgroup as the API answers it.
  SubgroupReport.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      total = (json['total'] as num).toDouble(),
      columns = [for (final column in json['columns'] as List<dynamic>) ReportColumn.fromJson(column as Map<String, dynamic>)],
      rows = [for (final row in json['rows'] as List<dynamic>) ItemEntryRow.fromJson(row as Map<String, dynamic>)];

  /// The subgroup.
  final String id;

  /// Its name; empty for the general one.
  final String name;

  /// Its purchases.
  final double total;

  /// The columns it prints, its item's own, in their order (redix-api #129, R1).
  final List<ReportColumn> columns;

  /// Each purchase.
  final List<ItemEntryRow> rows;
}

/// One contract with its payments.
class ContractReport {
  /// A contract as the API answers it.
  ContractReport.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      contractorName = json['contractorName'] as String,
      value = (json['value'] as num).toDouble(),
      isOpenValue = json['isOpenValue'] as bool,
      paid = (json['paid'] as num).toDouble(),
      remaining = (json['remaining'] as num).toDouble(),
      isOverrun = json['isOverrun'] as bool,
      paymentsTotal = (json['paymentsTotal'] as num).toDouble(),
      columns = [for (final column in json['columns'] as List<dynamic>) ReportColumn.fromJson(column as Map<String, dynamic>)],
      payments = [for (final row in json['payments'] as List<dynamic>) ItemEntryRow.fromJson(row as Map<String, dynamic>)];

  /// The contract.
  final String id;

  /// The contractor.
  final String contractorName;

  /// What it is worth.
  final double value;

  /// True when it has no fixed value.
  final bool isOpenValue;

  /// What was paid inside it.
  final double paid;

  /// Its value less that.
  final double remaining;

  /// True when more was paid than it is worth.
  final bool isOverrun;

  /// Every payment on it, what counts in the item.
  final double paymentsTotal;

  /// The columns its table prints, its item's own a payment is asked, in their order (redix-api #129, R1).
  final List<ReportColumn> columns;

  /// Each payment.
  final List<ItemEntryRow> payments;
}

/// Everything spent on one item (UC-050).
class ItemReportFigures {
  /// A report as the API answers it.
  ItemReportFigures.fromJson(Map<String, dynamic> json)
    : itemName = json['itemName'] as String,
      categoryName = json['categoryName'] as String,
      total = (json['total'] as num).toDouble(),
      subgroups = [for (final row in json['subgroups'] as List<dynamic>) SubgroupReport.fromJson(row as Map<String, dynamic>)],
      contracts = [for (final row in json['contracts'] as List<dynamic>) ContractReport.fromJson(row as Map<String, dynamic>)];

  /// Nothing yet.
  ItemReportFigures.none() : itemName = '', categoryName = '', total = 0, subgroups = const [], contracts = const [];

  /// The item's name.
  final String itemName;

  /// Its category.
  final String categoryName;

  /// Its purchases and contractor payments.
  final double total;

  /// Its purchases, by subgroup.
  final List<SubgroupReport> subgroups;

  /// Its contracts.
  final List<ContractReport> contracts;
}

/// The report of one item of a project.
class ItemReport extends ApiObject<ItemReportFigures> {
  /// The report of the item [itemId] in the project [projectId], seen through [session].
  ItemReport(Session session, String address)
    : super(session, address, 'reports', (json) => ItemReportFigures.fromJson(json! as Map<String, dynamic>), ItemReportFigures.none());
}
