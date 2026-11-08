import 'package:flutter/material.dart';

import '../auth/permission.dart';
import '../home/home_screen.dart';
import '../ui/part_keys.dart';
import '../words/words.dart';
import 'project.dart';

/// The open project's buttons, with what the signed-in user's permissions allow: Accounts, Partners, Suppliers, Contracts, Reports, Settings, Approvals and Documents.
/// A finished project says first, in one line, that it is read-only (redix-api 93).
class ProjectCard extends StatelessWidget {
  /// The card of [project], calling [onAccounts], [onPartners], [onSuppliers], [onContracts], [onApprovals], [onReports] and [onDocuments] when those are tapped.
  const ProjectCard({
    super.key,
    required this.project,
    required this.onAccounts,
    required this.onPartners,
    required this.onSuppliers,
    required this.onContracts,
    required this.onApprovals,
    required this.onReports,
    required this.onDocuments,
  });

  /// The project this card shows.
  final Project project;

  /// Called when Accounts is tapped.
  final VoidCallback onAccounts;

  /// Called when Partners is tapped.
  final VoidCallback onPartners;

  /// Called when Suppliers is tapped.
  final VoidCallback onSuppliers;

  /// Called when Contracts is tapped.
  final VoidCallback onContracts;

  /// Called when Waiting for approval is tapped.
  final VoidCallback onApprovals;

  /// Called when Reports is tapped.
  final VoidCallback onReports;

  /// Called when Documents is tapped.
  final VoidCallback onDocuments;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Card.outlined(
      key: HomeScreen.cardKey(project.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (project.isFinished) ...[
            ListTile(
              key: HomeScreen.finishedKey(project.id),
              dense: true,
              leading: Icon(Icons.lock_outline, key: HomeScreen.finishedKey(project.id).icon),
              title: Text('${words.projectsFinished} · ${words.projectsReadOnly}', key: HomeScreen.finishedKey(project.id).title),
            ),
            const Divider(height: 1),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  key: HomeScreen.accountsKey(project.id),
                  icon: Icon(Icons.account_balance_wallet_outlined, key: HomeScreen.accountsKey(project.id).icon),
                  label: Text(words.accountsTitle, key: HomeScreen.accountsKey(project.id).label),
                  onPressed: onAccounts,
                ),
                TextButton.icon(
                  key: HomeScreen.partnersKey(project.id),
                  icon: Icon(Icons.handshake_outlined, key: HomeScreen.partnersKey(project.id).icon),
                  label: Text(words.partnersTitle, key: HomeScreen.partnersKey(project.id).label),
                  onPressed: onPartners,
                ),
                TextButton.icon(
                  key: HomeScreen.suppliersKey(project.id),
                  icon: Icon(Icons.storefront_outlined, key: HomeScreen.suppliersKey(project.id).icon),
                  label: Text(words.suppliersTitle, key: HomeScreen.suppliersKey(project.id).label),
                  onPressed: onSuppliers,
                ),
                TextButton.icon(
                  key: HomeScreen.contractsKey(project.id),
                  icon: Icon(Icons.description_outlined, key: HomeScreen.contractsKey(project.id).icon),
                  label: Text(words.contractsTitle, key: HomeScreen.contractsKey(project.id).label),
                  onPressed: onContracts,
                ),
                TextButton.icon(
                  key: HomeScreen.reportsKey(project.id),
                  icon: Icon(Icons.summarize_outlined, key: HomeScreen.reportsKey(project.id).icon),
                  label: Text(words.reportsTitle, key: HomeScreen.reportsKey(project.id).label),
                  onPressed: onReports,
                ),
                if (project.may(Permission.approveEntries))
                  TextButton.icon(
                    key: HomeScreen.approvalsKey(project.id),
                    icon: Icon(Icons.fact_check_outlined, key: HomeScreen.approvalsKey(project.id).icon),
                    label: Text(words.approvalsTitle, key: HomeScreen.approvalsKey(project.id).label),
                    onPressed: onApprovals,
                  ),
                TextButton.icon(
                  key: HomeScreen.documentsKey(project.id),
                  icon: Icon(Icons.folder_outlined, key: HomeScreen.documentsKey(project.id).icon),
                  label: Text(words.documentsTitle, key: HomeScreen.documentsKey(project.id).label),
                  onPressed: onDocuments,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
