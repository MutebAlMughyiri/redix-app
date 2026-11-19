// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../format/date_format.dart';
import '../projects/project.dart';
import '../ui/bottom_button.dart';
import '../ui/confirm_dialog.dart';
import '../ui/part_keys.dart';
import '../ui/messages.dart';
import '../ui/screen_title.dart';
import '../words/word_fill.dart';
import '../words/words.dart';
import 'periodic_report_screen.dart';
import 'periodic_reports.dart';

/// A project's periodic reports (FR-29 to FR-32): the next one and those issued before. The VAT refund and the item reports open from the home, and the contracts and the
/// partners have their own screens there (the owner, 9 Nov 2026).
class ReportsScreen extends StatefulWidget {
  /// The periodic reports of [project], from [periodicReports] and [nextReport].
  const ReportsScreen({super.key, required this.project, required this.periodicReports, required this.nextReport});

  /// The address of the screen.
  static const path = '/projects/:projectId/reports';

  /// The address of the screen for the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/reports';

  /// The button issuing the next periodic report: the screen's bottom button, grayed for whoever does not move money (the owner, 9 Nov 2026).
  static const issueKey = Key('reports.issue');

  /// The line saying no report was issued yet.
  static const noneIssuedKey = Key('reports.noneIssued');

  /// The way into the periodic report [number].
  static Key periodicKey(int number) => Key('reports.periodic.$number');

  /// The card of the periodic reports.
  static const periodicCardKey = Key('reports.periodicCard');

  /// The heading over the periodic reports.
  static const periodicHeadingKey = Key('reports.periodicHeading');

  /// The project.
  final Project project;

  /// Its periodic reports.
  final PeriodicReports periodicReports;

  /// What the next one takes.
  final NextReport nextReport;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    widget.periodicReports.loadOnOpen();
    widget.nextReport.loadOnOpen();
  }

  void _askToIssue(NextReportFigures next) {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: words.reportsIssueQuestion.fill(['${next.number}']),
        subject: widget.project.name,
        explanation: words.reportsIssueExplain.fill(['${next.waiting.count}']),
        confirmLabel: words.reportsIssue.fill(['${next.number}']),
        onConfirm: () async {
          final refusal = await widget.periodicReports.issue();
          await widget.nextReport.load();
          showMessage(messenger, words, refusal.isEmpty ? 'reports.issued' : refusal);
        },
      ),
    );
  }

  Widget _periodic() {
    final words = Words.of(context);
    final project = widget.project;
    return Card.outlined(
      key: ReportsScreen.periodicCardKey,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ListenableBuilder(
          listenable: widget.periodicReports,
          builder: (context, _) {
            final reports = widget.periodicReports.all;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Text(words.reportsPeriodic, key: ReportsScreen.periodicHeadingKey, style: Theme.of(context).textTheme.titleMedium),
                if (reports.isEmpty) Text(words.reportsNoneIssued, key: ReportsScreen.noneIssuedKey),
                for (final report in reports)
                  ListTile(
                    key: ReportsScreen.periodicKey(report.number),
                    contentPadding: EdgeInsets.zero,
                    title: Text('${words.reportsReportNumber} ${report.number}', key: ReportsScreen.periodicKey(report.number).title),
                    subtitle: Text(formatDate(report.issuedAt), key: ReportsScreen.periodicKey(report.number).subtitle),
                    trailing: Icon(Icons.chevron_right, key: ReportsScreen.periodicKey(report.number).icon),
                    onTap: () => context.push(PeriodicReportScreen.pathOf(project.id, report.number), extra: project),
                  ),
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
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.reportsTitle, subject: project.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _periodic(),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: widget.nextReport,
        builder: (context, _) => BottomButton(
          buttonKey: ReportsScreen.issueKey,
          icon: Icons.post_add,
          label: words.reportsIssue.fill(['${widget.nextReport.value.number}']),
          onPressed: project.mayIssueReports ? () => _askToIssue(widget.nextReport.value) : null,
        ),
      ),
    );
  }
}
