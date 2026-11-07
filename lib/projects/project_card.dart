import 'package:flutter/material.dart';

import '../auth/permission.dart';
import '../format/date_format.dart';
import '../home/home_screen.dart';
import '../ui/part_keys.dart';
import '../words/words.dart';
import 'project.dart';
import 'unit_row.dart';

/// The open project: its start date, status and units, with what the signed-in user's permissions allow: Accounts, Partners, Suppliers, Contracts, Reports, Settings, and Add unit and Close project while it runs.
class ProjectCard extends StatelessWidget {
  /// The card of [project], calling [onAccounts], [onPartners], [onSuppliers], [onContracts], [onSettings], [onLiquidate], [onDocuments], [onAddUnit], [onRename], [onRenameUnit], [onDeleteUnit] and [onClose] when those are tapped.
  const ProjectCard({
    super.key,
    required this.project,
    required this.onAccounts,
    required this.onPartners,
    required this.onSuppliers,
    required this.onContracts,
    required this.onApprovals,
    required this.onRevenue,
    required this.onReports,
    required this.onSettings,
    required this.onLiquidate,
    required this.onDocuments,
    required this.onAddUnit,
    required this.onRename,
    required this.onRenameUnit,
    required this.onDeleteUnit,
    required this.onClose,
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

  /// Called when Revenue is tapped.
  final VoidCallback onRevenue;

  /// Called when Reports is tapped.
  final VoidCallback onReports;

  /// Opens Settings, which holds the users, the categories and items, and the payment methods.
  final VoidCallback onSettings;

  /// Called when Liquidate and close is tapped.
  final VoidCallback onLiquidate;

  /// Called when Documents is tapped.
  final VoidCallback onDocuments;

  /// Called when Add unit is tapped.
  final VoidCallback onAddUnit;

  /// Called when Rename project is tapped.
  final VoidCallback onRename;

  /// Called when a unit's Rename is chosen.
  final void Function(Unit unit) onRenameUnit;

  /// Called when a unit's Delete is chosen.
  final void Function(Unit unit) onDeleteUnit;

  /// Called when Close project is tapped.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    final startDate = '${words.projectsStartDate} ${formatDate(project.startDate)}';
    final mayChange = project.mayManageProject;
    return Card.outlined(
      key: HomeScreen.cardKey(project.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 12, 8),
            child: OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              overflowSpacing: 4,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.isFinished ? '$startDate · ${words.projectsReadOnly}' : startDate,
                      key: HomeScreen.detailsKey(project.id),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                Chip(
                  key: HomeScreen.statusKey(project.id),
                  label: Text(words.text(project.status.wordKey), key: HomeScreen.statusKey(project.id).label),
                  backgroundColor: project.status == ProjectStatus.running ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (project.units.isEmpty) ListTile(key: HomeScreen.noUnitsRowKey(project.id), dense: true, title: Text(words.projectsNoUnits, key: HomeScreen.noUnitsKey(project.id))),
          for (final unit in project.units) UnitRow(unit: unit, mayChange: mayChange, onRename: () => onRenameUnit(unit), onDelete: () => onDeleteUnit(unit)),
          const Divider(height: 1),
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
                  key: HomeScreen.revenueKey(project.id),
                  icon: Icon(Icons.trending_up, key: HomeScreen.revenueKey(project.id).icon),
                  label: Text(words.revenueTitle, key: HomeScreen.revenueKey(project.id).label),
                  onPressed: onRevenue,
                ),
                TextButton.icon(
                  key: HomeScreen.reportsKey(project.id),
                  icon: Icon(Icons.summarize_outlined, key: HomeScreen.reportsKey(project.id).icon),
                  label: Text(words.reportsTitle, key: HomeScreen.reportsKey(project.id).label),
                  onPressed: onReports,
                ),
                TextButton.icon(
                  key: HomeScreen.settingsKey(project.id),
                  icon: Icon(Icons.tune, key: HomeScreen.settingsKey(project.id).icon),
                  label: Text(words.settingsTitle, key: HomeScreen.settingsKey(project.id).label),
                  onPressed: onSettings,
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
                if (project.may(Permission.moveMoney))
                  TextButton.icon(
                    key: HomeScreen.liquidateKey(project.id),
                    icon: Icon(Icons.request_quote_outlined, key: HomeScreen.liquidateKey(project.id).icon),
                    label: Text(words.liquidationTitle, key: HomeScreen.liquidateKey(project.id).label),
                    onPressed: onLiquidate,
                  ),
                if (mayChange) ...[
                  TextButton.icon(
                    key: HomeScreen.addUnitKey(project.id),
                    icon: Icon(Icons.add, key: HomeScreen.addUnitKey(project.id).icon),
                    label: Text(words.projectsAddUnit, key: HomeScreen.addUnitKey(project.id).label),
                    onPressed: onAddUnit,
                  ),
                  TextButton.icon(
                    key: HomeScreen.renameKey(project.id),
                    icon: Icon(Icons.edit_outlined, key: HomeScreen.renameKey(project.id).icon),
                    label: Text(words.projectsRename, key: HomeScreen.renameKey(project.id).label),
                    onPressed: onRename,
                  ),
                  TextButton(
                    key: HomeScreen.closeKey(project.id),
                    style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                    onPressed: onClose,
                    child: Text(words.projectsClose, key: HomeScreen.closeKey(project.id).label),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
