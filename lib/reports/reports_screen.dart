import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/permission.dart';
import '../contracts/contracts_screen.dart';
import '../format/date_format.dart';
import '../partners/partners_screen.dart';
import '../projects/project.dart';
import '../ui/api_object_body.dart';
import '../ui/confirm_dialog.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'dashboard.dart';
import 'item_report_screen.dart';
import 'periodic_report_screen.dart';
import 'periodic_reports.dart';
import 'report_files.dart';
import 'vat_statement_screen.dart';

/// A project's reports (FR-29 to FR-33): the periodic report and those issued before, the VAT statement, an item's report, the contracts, and the partners.
class ReportsScreen extends StatefulWidget {
  /// The reports of [project], whose items come from [dashboard], its periodic reports from [periodicReports] and [nextReport], and its files through [files].
  const ReportsScreen({super.key, required this.project, required this.dashboard, required this.periodicReports, required this.nextReport, required this.files});

  /// The address of the screen.
  static const path = '/projects/:projectId/reports';

  /// The address of the screen for the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/reports';

  /// The button issuing the next periodic report.
  static const issueKey = Key('reports.issue');

  /// The line saying no report was issued yet.
  static const noneIssuedKey = Key('reports.noneIssued');

  /// The way into the VAT statement.
  static const vatKey = Key('reports.vat');

  /// The way into the contracts.
  static const contractsKey = Key('reports.contracts');

  /// The way into the partners.
  static const partnersKey = Key('reports.partners');

  /// The way into the periodic report [number].
  static Key periodicKey(int number) => Key('reports.periodic.$number');

  /// The way into the report of the item [id].
  static Key itemKey(String id) => Key('reports.item.$id');

  /// The project.
  final Project project;

  /// Its figures, which name its items.
  final Dashboard dashboard;

  /// Its periodic reports.
  final PeriodicReports periodicReports;

  /// What the next one takes.
  final NextReport nextReport;

  /// The way to its files.
  final ReportFiles files;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    widget.dashboard.loadOnOpen();
    widget.periodicReports.loadOnOpen();
    widget.nextReport.loadOnOpen();
  }

  Widget _way(Key key, IconData icon, String title, String path) => Card.outlined(
    child: ListTile(key: key, leading: Icon(icon), title: Text(title), trailing: const Icon(Icons.chevron_right), onTap: () => context.push(path, extra: widget.project)),
  );

  void _askToIssue(NextReportFigures next) {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: words.reportsIssueQuestion.replaceFirst('{0}', '${next.number}'),
        subject: widget.project.name,
        explanation: words.reportsIssueExplain.replaceFirst('{1}', '${next.pendingCount}'),
        confirmLabel: words.reportsIssue.replaceFirst('{0}', '${next.number}'),
        onConfirm: () async {
          final refusal = await widget.periodicReports.issue();
          await widget.nextReport.load();
          messenger.showSnackBar(SnackBar(content: Text(words.text(refusal.isEmpty ? 'reports.issued' : refusal))));
        },
      ),
    );
  }

  Widget _periodic() {
    final words = Words.of(context);
    final project = widget.project;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ListenableBuilder(
          listenable: Listenable.merge([widget.periodicReports, widget.nextReport]),
          builder: (context, _) {
            final reports = widget.periodicReports.all;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Text(words.reportsPeriodic, style: Theme.of(context).textTheme.titleMedium),
                if (reports.isEmpty) Text(words.reportsNoneIssued, key: ReportsScreen.noneIssuedKey),
                for (final report in reports)
                  ListTile(
                    key: ReportsScreen.periodicKey(report.number),
                    contentPadding: EdgeInsets.zero,
                    title: Text('${words.reportsReportNumber} ${report.number}'),
                    subtitle: Text(formatDate(report.issuedAt)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(PeriodicReportScreen.pathOf(project.id, report.number), extra: project),
                  ),
                if (project.mayMoveMoney)
                  FilledButton(key: ReportsScreen.issueKey, onPressed: () => _askToIssue(widget.nextReport.value), child: Text(words.reportsIssue.replaceFirst('{0}', '${widget.nextReport.value.number}'))),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final project = widget.project;
    final exports = project.may(Permission.seeAllCapital);
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.reportsTitle, subject: project.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _periodic(),
          const SizedBox(height: 8),
          _way(ReportsScreen.vatKey, Icons.receipt_long_outlined, words.vatTitle, VatStatementScreen.pathOf(project.id)),
          _way(ReportsScreen.contractsKey, Icons.description_outlined, words.reportsContracts, ContractsScreen.pathOf(project.id)),
          if (exports)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ReportFileButtons(files: widget.files, address: '/projects/${project.id}/reports/contracts', name: 'contracts', kinds: const [ReportFileKind.pdf, ReportFileKind.excel]),
            ),
          _way(ReportsScreen.partnersKey, Icons.handshake_outlined, words.reportsPartners, PartnersScreen.pathOf(project.id)),
          const SizedBox(height: 12),
          Text(words.reportsItem, style: Theme.of(context).textTheme.titleMedium),
          ApiObjectBody(
            object: widget.dashboard,
            builder: (figures) => Column(
              children: [
                for (final category in figures.categories)
                  ExpansionTile(
                    title: Text(category.name),
                    children: [
                      for (final item in category.items)
                        ListTile(
                          key: ReportsScreen.itemKey(item.id),
                          title: Text(item.name),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(ItemReportScreen.pathOf(project.id, item.id), extra: project),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
