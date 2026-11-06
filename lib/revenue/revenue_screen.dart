import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../attachments/attachment_screen.dart';
import '../auth/permission.dart';
import '../entries/reverse_sheet.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'revenue_form_screen.dart';
import 'revenue_row.dart';
import 'revenues.dart';
import 'sales_invoice_screen.dart';

/// A project's revenue (UC-047, UC-048): everyone sees it, and whoever moves money records it.
class RevenueScreen extends StatefulWidget {
  /// The revenue of [project], in [revenues].
  const RevenueScreen({super.key, required this.project, required this.revenues});

  /// The address of the screen.
  static const path = '/projects/:projectId/revenue';

  /// The address of the screen for the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/revenue';

  /// The button recording revenue.
  static const newKey = Key('revenue.new');

  /// The button recording a sales invoice.
  static const newSaleKey = Key('revenue.newSale');

  /// The row of the revenue [id].
  static Key rowKey(String id) => Key('revenue.row.$id');

  /// What the statement expected for the refund [id], and the difference.
  static Key refundKey(String id) => Key('revenue.refund.$id');

  /// The button reversing the revenue [id].
  static Key reverseKey(String id) => Key('revenue.reverse.$id');

  /// The project.
  final Project project;

  /// Its revenue.
  final Revenues revenues;

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  @override
  void initState() {
    super.initState();
    widget.revenues.loadOnOpen();
  }

  Widget _row(RevenueRow row) {
    final words = Words.of(context);
    final project = widget.project;
    final details = [
      row.itemName,
      formatDate(row.date),
      row.accountName,
      if (row.invoiceNumber.isNotEmpty) '${row.buyerName} · ${row.invoiceNumber}',
      if (row.isReversed) words.capitalReversed,
    ];
    return Card.outlined(
      key: RevenueScreen.rowKey(row.id),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 4, 0),
        title: Text(row.description.isEmpty ? row.itemName : row.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(details.join(' · ')),
            if (row.isRefund)
              Text(
                '${words.revenueStatementRefund}: ${formatMoney(row.statementRefund)} · ${words.revenueRefundDifference}: ${formatMoney(row.refundDifference)}',
                key: RevenueScreen.refundKey(row.id),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(formatMoney(row.amount), style: Theme.of(context).textTheme.titleSmall),
            if (row.attachmentId.isNotEmpty)
              IconButton(icon: const Icon(Icons.receipt_long_outlined), onPressed: () => context.push(AttachmentScreen.pathOf(project.id, row.attachmentId), extra: row.contentType)),
            if (!project.isFinished && !row.isReversed && project.may(Permission.approveEntries))
              IconButton(
                key: RevenueScreen.reverseKey(row.id),
                icon: const Icon(Icons.undo),
                tooltip: words.capitalReverse,
                onPressed: () => ReverseSheet.show(context, (reason) => widget.revenues.reverse(row, reason)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final project = widget.project;
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.revenueTitle, subject: project.name)),
      bottomNavigationBar: project.mayMoveMoney
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  spacing: 8,
                  children: [
                    Expanded(child: FilledButton.icon(key: RevenueScreen.newKey, icon: const Icon(Icons.add), label: Text(words.revenueNew), onPressed: () => context.push(RevenueFormScreen.pathOf(project.id), extra: project))),
                    Expanded(child: FilledButton.tonalIcon(key: RevenueScreen.newSaleKey, icon: const Icon(Icons.receipt_outlined), label: Text(words.revenueNewSale), onPressed: () => context.push(SalesInvoiceScreen.pathOf(project.id), extra: project))),
                  ],
                ),
              ),
            )
          : null,
      body: ApiListBody(list: widget.revenues, emptyText: words.revenueEmpty, itemBuilder: _row),
    );
  }
}
