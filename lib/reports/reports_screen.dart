import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../projects/project.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'vat_statement_screen.dart';

/// A project's reports, each a way in (FR-29 to FR-33).
class ReportsScreen extends StatelessWidget {
  /// The reports of [project].
  const ReportsScreen({super.key, required this.project});

  /// The address of the screen.
  static const path = '/projects/:projectId/reports';

  /// The address of the screen for the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/reports';

  /// The way into the VAT statement.
  static const vatKey = Key('reports.vat');

  /// The project.
  final Project project;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.reportsTitle, subject: project.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card.outlined(
            child: ListTile(
              key: vatKey,
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(words.vatTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(VatStatementScreen.pathOf(project.id), extra: project),
            ),
          ),
        ],
      ),
    );
  }
}
