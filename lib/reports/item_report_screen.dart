import 'package:flutter/material.dart';

import '../format/date_format.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../ui/api_object_body.dart';
import '../ui/list_search.dart';
import '../ui/search_scope.dart';
import '../ui/part_keys.dart';
import '../ui/screen_title.dart';
import '../ui/search_line.dart';
import '../words/word_fill.dart';
import '../words/words.dart';
import '../structure/item_column.dart';
import 'item_report.dart';
import 'report_files.dart';
import '../ui/refusal_text.dart';
import '../ui/amount_line.dart';
import '../ui/row_stripe.dart';

/// Everything spent on one item (UC-050): a table per subgroup, then each contract with its value, paid and remaining; or one contract's table alone, as Contracts opens it
/// (Muteb, 12 Nov 2026). The search line over them keeps the rows holding what was typed, and every row of a subgroup or contract whose own name holds it (redix-app #104);
/// the totals stay the item's.
class ItemReportScreen extends StatefulWidget {
  /// The report at [address], an item's or a contract's, of [project], read through [report].
  const ItemReportScreen({super.key, required this.project, required this.address, required this.report, required this.files});

  /// The report's address on the API, which its files are named after.
  final String address;

  /// The way to its files.
  final ReportFiles files;

  /// The address of the screen.
  static const path = '/projects/:projectId/reports/items/:itemId';

  /// The address of the report of the item [itemId] in the project [projectId].
  static String pathOf(String projectId, String itemId) => '/projects/$projectId/reports/items/$itemId';

  /// The address of the screen holding one contract's table.
  static const contractPath = '/projects/:projectId/reports/contracts/:contractId';

  /// The address of the report of the contract [contractId] in the project [projectId].
  static String contractPathOf(String projectId, String contractId) => '/projects/$projectId/reports/contracts/$contractId';

  /// The item's total.
  static const totalKey = Key('itemReport.total');

  /// The total of the subgroup [id].
  static Key subgroupTotalKey(String id) => Key('itemReport.subgroupTotal.$id');

  /// The row of the entry [id].
  static Key rowKey(String id) => Key('itemReport.row.$id');

  /// The figures of the contract [id].
  static Key contractKey(String id) => Key('itemReport.contract.$id');

  /// The alert of the overrun contract [id].
  static Key overrunKey(String id) => Key('itemReport.overrun.$id');

  /// The card of the subgroup [id].
  static Key subgroupKey(String id) => Key('itemReport.subgroup.$id');

  /// The card of the contract [id].
  static Key contractCardKey(String id) => Key('itemReport.contractCard.$id');

  /// The contractor of the contract [id].
  static Key contractorKey(String id) => Key('itemReport.contractor.$id');

  /// The total paid on the contract [id].
  static Key contractTotalKey(String id) => Key('itemReport.contractTotal.$id');

  /// The project.
  final Project project;

  /// The report.
  final ItemReport report;

  @override
  State<ItemReportScreen> createState() => _ItemReportScreenState();
}

class _ItemReportScreenState extends State<ItemReportScreen> {
  var _typed = '';

  @override
  void initState() {
    super.initState();
    widget.report.loadOnOpen();
  }

  /// What a row is searched by: what it shows under its columns, and its amount.
  static String _textOf(ItemEntryRow row) => [...row.values, formatDate(row.date), searchableAmount(row.amount)].join(' ');

  /// A row as its table prints it (redix-api #129, R1): «الوصف» its title, then what it shows under each other column of its table, a date and an amount as the app writes them, then its amount.
  Widget _row(ItemEntryRow row, List<ReportColumn> columns) {
    final described = columns.indexWhere((column) => column.key == 'description');
    final details = [
      for (var index = 0; index < columns.length && index < row.values.length; index++)
        if (index != described && row.values[index].isNotEmpty) '${columns[index].name}: ${_shown(columns[index], row.values[index])}',
    ];
    return ListTile(
      key: ItemReportScreen.rowKey(row.entryId),
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(described >= 0 && described < row.values.length ? row.values[described] : '', key: ItemReportScreen.rowKey(row.entryId).title),
      subtitle: Text(details.join(' · '), key: ItemReportScreen.rowKey(row.entryId).subtitle),
      trailing: Text(formatMoney(row.amount), key: ItemReportScreen.rowKey(row.entryId).trailing),
    );
  }

  /// A value as the app writes what its column holds: a date as a day, an amount as money, anything else as kept.
  static String _shown(ReportColumn column, String value) => switch (column.dataType) {
    ColumnDataType.date => formatDate(DateTime.parse(value)),
    ColumnDataType.amount => formatMoney(parseNumber(value)),
    _ => value,
  };

  Widget _subgroup(SubgroupReport subgroup, List<ItemEntryRow> rows) {
    final words = Words.of(context);
    return Card.outlined(
      key: ItemReportScreen.subgroupKey(subgroup.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(_nameOf(subgroup, words), key: ItemReportScreen.subgroupKey(subgroup.id).title, style: Theme.of(context).textTheme.titleSmall)),
                Text(formatMoney(subgroup.total), key: ItemReportScreen.subgroupTotalKey(subgroup.id), style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            for (final (index, row) in rows.indexed) RowStripe(index: index, child: _row(row, subgroup.columns)),
          ],
        ),
      ),
    );
  }

  /// What the subgroup is called: its name, or the general one's word.
  static String _nameOf(SubgroupReport subgroup, Words words) => subgroup.name.isEmpty ? words.reportsGeneralSubgroup : subgroup.name;

  Widget _contract(ContractReport contract, List<ItemEntryRow> payments) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    return Card.outlined(
      key: ItemReportScreen.contractCardKey(contract.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(contract.contractorName, key: ItemReportScreen.contractorKey(contract.id), style: theme.textTheme.titleSmall),
            Text(
              [
                '${words.reportsContractValue}: ${contract.isOpenValue ? words.reportsOpenValue : formatMoney(contract.value)}',
                '${words.reportsPaid}: ${formatMoney(contract.paid)}',
                if (!contract.isOpenValue) '${words.reportsRemaining}: ${formatMoney(contract.remaining)}',
              ].join(' · '),
              key: ItemReportScreen.contractKey(contract.id),
            ),
            if (contract.isOverrun) refusalText(context, words.reportsOverrun, ItemReportScreen.overrunKey(contract.id)),
            for (final (index, row) in payments.indexed) RowStripe(index: index, child: _row(row, contract.columns)),
            Align(alignment: AlignmentDirectional.centerEnd, child: Text('${words.reportsGrandTotal}: ${formatMoney(contract.paymentsTotal)}', key: ItemReportScreen.contractTotalKey(contract.id))),
          ],
        ),
      ),
    );
  }

  /// The report as [report] holds it: the item's total, its files, and the subgroups and contracts holding what was typed.
  Widget _report(ItemReportFigures report, Words words) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      amountLine(ItemReportScreen.totalKey, words.reportsItemTotal, report.total, labelStyle: Theme.of(context).textTheme.titleMedium, amountStyle: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ReportFileButtons(files: widget.files, address: widget.address, name: report.itemName, mayTake: widget.project.mayTakeReportFiles, kinds: const [ReportFileKind.pdf, ReportFileKind.excel]),
      ),
      for (final subgroup in report.subgroups)
        if (ListSearch.groupOf(_nameOf(subgroup, words), subgroup.rows, _textOf, _typed) case (isShown: true, :final children)) _subgroup(subgroup, children),
      for (final contract in report.contracts)
        if (ListSearch.groupOf(contract.contractorName, contract.payments, _textOf, _typed) case (isShown: true, :final children)) _contract(contract, children),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ListenableBuilder(
      listenable: widget.report,
      builder: (context, _) {
        final report = widget.report.value;
        return SearchScope(
          onTyped: (typed) => setState(() => _typed = typed),
          child: Scaffold(
            appBar: AppBar(title: ScreenTitle(report.itemName, subject: report.categoryName), actions: const [SearchIcons()]),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SearchLine(hint: words.commonSearchIn.fill([report.itemName])),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [ApiObjectBody(object: widget.report, builder: (report) => _report(report, words))],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
