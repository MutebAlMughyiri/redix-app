import 'package:flutter/material.dart';

import '../auth/permission.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../ui/api_object_body.dart';
import '../ui/part_keys.dart';
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

  /// The report's number and the day it was issued.
  static const titleKey = Key('periodicReport.title');

  /// The section [name].
  static Key sectionKey(String name) => Key('periodicReport.section.$name');

  /// The line [line] of the section [section]: a fixed line's name, or a listed line's number in the report, which keeps no id for its accounts, categories or partners and
  /// does not keep their names apart.
  static Key lineKey(String section, String line) => Key('periodicReport.line.$section.$line');

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

  Widget _line(Key key, String label, double amount, {bool isStrong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(label, key: key.label, style: isStrong ? const TextStyle(fontWeight: FontWeight.bold) : null)),
        Text(formatMoney(amount), key: key, style: isStrong ? const TextStyle(fontWeight: FontWeight.bold) : null),
      ],
    ),
  );

  Widget _section(String name, String title, List<Widget> lines) => Card.outlined(
    key: PeriodicReportScreen.sectionKey(name),
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, key: PeriodicReportScreen.sectionKey(name).title, style: Theme.of(context).textTheme.titleSmall), ...lines]),
    ),
  );

  Widget _body(PeriodicReportFigures report) {
    final words = Words.of(context);
    final project = widget.project;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${words.reportsReportNumber} ${report.number} · ${formatDate(report.issuedAt)}', key: PeriodicReportScreen.titleKey, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (project.may(Permission.seeAllCapital))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ReportFileButtons(files: widget.files, address: '/projects/${project.id}/periodic-reports/${report.number}', name: 'report-${report.number}', kinds: const [ReportFileKind.pdf, ReportFileKind.excel, ReportFileKind.print]),
          ),
        _section('accounts', words.accountsTitle, [
          for (final (number, account) in report.accounts.indexed) _line(PeriodicReportScreen.lineKey('accounts', '$number'), account.label, account.amount),
          _line(PeriodicReportScreen.lineKey('accounts', 'total'), words.reconciliationsActualTotal, report.accountsTotal, isStrong: true),
        ]),
        _section('expenses', words.dashboardExpenses, [
          _line(PeriodicReportScreen.lineKey('expenses', 'previous'), words.reportsPrevious, report.previousExpenses),
          _line(PeriodicReportScreen.lineKey('expenses', 'current'), words.reportsCurrent, report.expenses),
          _line(PeriodicReportScreen.differenceKey, words.reportsDifference, report.expensesDifference, isStrong: true),
        ]),
        _section('revenue', words.dashboardRevenue, [
          _line(PeriodicReportScreen.lineKey('revenue', 'capital'), words.capitalTotal, report.capital),
          _line(PeriodicReportScreen.lineKey('revenue', 'vatRefunds'), words.revenueVatRefund, report.vatRefunds),
          _line(PeriodicReportScreen.lineKey('revenue', 'sales'), words.revenueSale, report.sales),
          _line(PeriodicReportScreen.lineKey('revenue', 'total'), words.dashboardRevenue, report.revenue, isStrong: true),
          _line(PeriodicReportScreen.lineKey('revenue', 'withoutSales'), words.dashboardSurplusWithoutSales, report.revenueWithoutSales),
        ]),
        _section('categories', words.dashboardByCategory, [
          for (final (number, category) in report.categories.indexed) _line(PeriodicReportScreen.lineKey('categories', '$number'), category.label, category.amount),
          _line(PeriodicReportScreen.lineKey('categories', 'total'), words.dashboardExpenses, report.expenses, isStrong: true),
        ]),
        _section('surplus', words.reportsSurplus, [
          _line(PeriodicReportScreen.surplusKey, words.reportsSurplus, report.surplus, isStrong: true),
          _line(PeriodicReportScreen.lineKey('surplus', 'withoutSales'), words.dashboardSurplusWithoutSales, report.surplusWithoutSales),
          _line(PeriodicReportScreen.lineKey('surplus', 'liquidation'), words.reportsLiquidation, report.liquidation),
          _line(PeriodicReportScreen.lineKey('surplus', 'reconciliation'), words.reconciliationsDifference, report.reconciliationDifference),
          if (report.pendingCount > 0) _line(PeriodicReportScreen.lineKey('surplus', 'pending'), '${words.reportsPending} (${report.pendingCount})', report.pendingAmount),
        ]),
        _section('partners', words.reportsPartners, [
          for (final (number, partner) in report.partners.indexed) _line(PeriodicReportScreen.lineKey('partners', '$number'), '${partner.name} · ${formatShare(partner.sharePercent)}%', partner.balance),
          _line(PeriodicReportScreen.lineKey('partners', 'total'), words.capitalTotal, report.capitalTotal, isStrong: true),
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
