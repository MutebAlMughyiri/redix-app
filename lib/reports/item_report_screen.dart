import 'package:flutter/material.dart';

import '../auth/permission.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../ui/api_object_body.dart';
import '../ui/part_keys.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'item_report.dart';
import 'report_files.dart';
import '../ui/refusal_text.dart';
import '../ui/amount_line.dart';

/// Everything spent on one item (UC-050): a table per subgroup, then each contract with its value, paid and remaining.
class ItemReportScreen extends StatefulWidget {
  /// The report of an item of [project], read through [report].
  const ItemReportScreen({super.key, required this.project, required this.itemId, required this.report, required this.files});

  /// The item.
  final String itemId;

  /// The way to its files.
  final ReportFiles files;

  /// The address of the screen.
  static const path = '/projects/:projectId/reports/items/:itemId';

  /// The address of the report of the item [itemId] in the project [projectId].
  static String pathOf(String projectId, String itemId) => '/projects/$projectId/reports/items/$itemId';

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
  @override
  void initState() {
    super.initState();
    widget.report.loadOnOpen();
  }

  Widget _row(ItemEntryRow row, List<String> columns) {
    final words = Words.of(context);
    final details = [
      formatDate(row.date),
      if (row.supplierName.isNotEmpty) row.supplierName,
      if (row.invoiceNumber.isNotEmpty) '${words.reportsInvoiceNumber} ${row.invoiceNumber}',
      if (row.quantity != 0) '${formatPlain(row.quantity)} × ${formatMoney(row.unitPrice)}',
      for (var index = 0; index < columns.length && index < row.values.length; index++)
        if (row.values[index].isNotEmpty) '${columns[index]}: ${row.values[index]}',
      if (row.isOutsideContract) words.reportsOutsideContract,
    ];
    return ListTile(
      key: ItemReportScreen.rowKey(row.entryId),
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(row.description.isEmpty ? row.supplierName : row.description, key: ItemReportScreen.rowKey(row.entryId).title),
      subtitle: Text(details.join(' · '), key: ItemReportScreen.rowKey(row.entryId).subtitle),
      trailing: Text(formatMoney(row.amount), key: ItemReportScreen.rowKey(row.entryId).trailing),
    );
  }

  Widget _subgroup(SubgroupReport subgroup, List<String> columns) {
    final words = Words.of(context);
    return Card.outlined(
      key: ItemReportScreen.subgroupKey(subgroup.id),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(subgroup.name.isEmpty ? words.reportsGeneralSubgroup : subgroup.name, key: ItemReportScreen.subgroupKey(subgroup.id).title, style: Theme.of(context).textTheme.titleSmall)),
                Text(formatMoney(subgroup.total), key: ItemReportScreen.subgroupTotalKey(subgroup.id), style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            for (final row in subgroup.rows) _row(row, columns),
          ],
        ),
      ),
    );
  }

  Widget _contract(ContractReport contract, List<String> columns) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    return Card.outlined(
      key: ItemReportScreen.contractCardKey(contract.id),
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
            for (final row in contract.payments) _row(row, columns),
            Align(alignment: AlignmentDirectional.centerEnd, child: Text('${words.reportsGrandTotal}: ${formatMoney(contract.paymentsTotal)}', key: ItemReportScreen.contractTotalKey(contract.id))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ListenableBuilder(
      listenable: widget.report,
      builder: (context, _) {
        final report = widget.report.value;
        return Scaffold(
          appBar: AppBar(title: ScreenTitle(report.itemName, subject: report.categoryName)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ApiObjectBody(
                object: widget.report,
                builder: (report) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card.outlined(
                      key: ItemReportScreen.totalKey.card,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: amountLine(ItemReportScreen.totalKey, words.reportsItemTotal, report.total, labelStyle: Theme.of(context).textTheme.titleMedium, amountStyle: Theme.of(context).textTheme.titleLarge),
                      ),
                    ),
                    if (widget.project.may(Permission.seeAllCapital))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ReportFileButtons(files: widget.files, address: '/projects/${widget.project.id}/reports/items/${widget.itemId}', name: report.itemName, kinds: const [ReportFileKind.pdf, ReportFileKind.excel]),
                      ),
                    for (final subgroup in report.subgroups) _subgroup(subgroup, report.columns),
                    for (final contract in report.contracts) _contract(contract, report.columns),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
