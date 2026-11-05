import 'package:flutter/material.dart';

import '../auth/permission.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../ui/api_object_body.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'periodic_reports.dart';
import 'report_files.dart';

/// One periodic report as it was issued (UC-053): what everyone may read, and its files for whoever may export them (BR-31).
class PeriodicReportScreen extends StatefulWidget {
  /// The report read through [report], of [project], whose files come through [files].
  const PeriodicReportScreen({super.key, required this.project, required this.number, required this.report, required this.files});

  /// The address of the screen.
  static const path = '/projects/:projectId/reports/periodic/:number';

  /// The address of the report [number] of the project [projectId].
  static String pathOf(String projectId, int number) => '/projects/$projectId/reports/periodic/$number';

  /// The surplus.
  static const surplusKey = Key('periodicReport.surplus');

  /// The expenses' difference.
  static const differenceKey = Key('periodicReport.difference');

  /// The project.
  final Project project;

  /// The report's number.
  final int number;

  /// The report.
  final PeriodicReport report;

  /// The way to its files.
  final ReportFiles files;

  @override
  State<PeriodicReportScreen> createState() => _PeriodicReportScreenState();
}

class _PeriodicReportScreenState extends State<PeriodicReportScreen> {
  @override
  void initState() {
    super.initState();
    widget.report.loadOnOpen();
  }

  Widget _line(String label, double amount, {Key? key, bool isStrong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(label, style: isStrong ? const TextStyle(fontWeight: FontWeight.bold) : null)),
        Text(formatMoney(amount), key: key, style: isStrong ? const TextStyle(fontWeight: FontWeight.bold) : null),
      ],
    ),
  );

  Widget _section(String title, List<Widget> lines) => Card.outlined(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: Theme.of(context).textTheme.titleSmall), ...lines]),
    ),
  );

  Widget _body(PeriodicReportFigures report) {
    final words = Words.of(context);
    final project = widget.project;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${words.reportsReportNumber} ${report.number} · ${formatDate(report.issuedAt)}', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (project.may(Permission.seeAllCapital))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ReportFileButtons(files: widget.files, address: '/projects/${project.id}/periodic-reports/${report.number}', name: 'report-${report.number}', kinds: const [ReportFileKind.pdf, ReportFileKind.excel, ReportFileKind.print]),
          ),
        _section(words.accountsTitle, [for (final account in report.accounts) _line(account.label, account.amount), _line(words.reconciliationsActualTotal, report.accountsTotal, isStrong: true)]),
        _section(words.dashboardExpenses, [
          _line(words.reportsPrevious, report.previousExpenses),
          _line(words.reportsCurrent, report.expenses),
          _line(words.reportsDifference, report.expensesDifference, key: PeriodicReportScreen.differenceKey, isStrong: true),
        ]),
        _section(words.dashboardRevenue, [
          _line(words.capitalTotal, report.capital),
          _line(words.revenueVatRefund, report.vatRefunds),
          _line(words.revenueSale, report.sales),
          _line(words.dashboardRevenue, report.revenue, isStrong: true),
          _line(words.dashboardSurplusWithoutSales, report.revenueWithoutSales),
        ]),
        _section(words.dashboardByCategory, [for (final category in report.categories) _line(category.label, category.amount), _line(words.dashboardExpenses, report.expenses, isStrong: true)]),
        _section(words.dashboardSurplus, [
          _line(words.dashboardSurplus, report.surplus, key: PeriodicReportScreen.surplusKey, isStrong: true),
          _line(words.dashboardSurplusWithoutSales, report.surplusWithoutSales),
          _line(words.reportsLiquidation, report.liquidation),
          _line(words.reconciliationsDifference, report.reconciliationDifference),
          if (report.pendingCount > 0) _line('${words.vatPending} (${report.pendingCount})', report.pendingAmount),
        ]),
        _section(words.reportsPartners, [
          for (final partner in report.partners) _line('${partner.name} · ${formatShare(partner.sharePercent)}%', partner.balance),
          _line(words.capitalTotal, report.capitalTotal, isStrong: true),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.reportsPeriodic, subject: widget.project.name)),
      body: ListView(padding: const EdgeInsets.all(16), children: [ApiObjectBody(object: widget.report, builder: _body)]),
    );
  }
}
