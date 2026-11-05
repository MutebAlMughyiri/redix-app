import 'package:flutter/material.dart';

import '../auth/permission.dart';
import '../format/date_format.dart';
import '../home/home_screen.dart';
import '../words/words.dart';
import 'project.dart';
import 'unit_row.dart';

/// The open project: the signed-in user's roles in it, its start date, status and units, with what those roles allow: Users, Categories and items, Payment methods, Accounts, Partners, Suppliers, Contracts, and Add unit and Close project while it runs.
class ProjectCard extends StatelessWidget {
  /// The card of [project], calling [onUsers], [onCategories], [onPaymentMethods], [onAccounts], [onPartners], [onSuppliers], [onContracts], [onLiquidate], [onAddUnit], [onRename], [onRenameUnit], [onDeleteUnit] and [onClose] when those are tapped.
  const ProjectCard({
    super.key,
    required this.project,
    required this.onUsers,
    required this.onCategories,
    required this.onPaymentMethods,
    required this.onAccounts,
    required this.onPartners,
    required this.onSuppliers,
    required this.onContracts,
    required this.onApprovals,
    required this.onRevenue,
    required this.onReports,
    required this.onLiquidate,
    required this.onAddUnit,
    required this.onRename,
    required this.onRenameUnit,
    required this.onDeleteUnit,
    required this.onClose,
  });

  /// The project this card shows.
  final Project project;

  /// Called when Users is tapped.
  final VoidCallback onUsers;

  /// Called when Categories and items is tapped.
  final VoidCallback onCategories;

  /// Called when Payment methods and VAT is tapped.
  final VoidCallback onPaymentMethods;

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

  /// Called when Liquidate and close is tapped.
  final VoidCallback onLiquidate;

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
    final mayManageUsers = project.may(Permission.manageUsers);
    final mayChange = !project.isFinished && project.may(Permission.manageProject);
    final mayShapeStructure = project.may(Permission.manageStructure);
    final mayKeepSettings = project.may(Permission.manageSettings);
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
                    Text(project.roles.map(words.text).join(' · '), key: HomeScreen.rolesKey(project.id), style: theme.textTheme.bodySmall),
                    Text(
                      project.isFinished ? '$startDate · ${words.projectsReadOnly}' : startDate,
                      key: HomeScreen.detailsKey(project.id),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                Chip(
                  key: HomeScreen.statusKey(project.id),
                  label: Text(words.text(project.status.wordKey)),
                  backgroundColor: project.status == ProjectStatus.running ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (project.units.isEmpty) ListTile(dense: true, title: Text(words.projectsNoUnits, key: HomeScreen.noUnitsKey(project.id))),
          for (final unit in project.units) UnitRow(unit: unit, mayChange: mayChange, onRename: () => onRenameUnit(unit), onDelete: () => onDeleteUnit(unit)),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              children: [
                if (mayManageUsers)
                  TextButton.icon(
                    key: HomeScreen.usersKey(project.id),
                    icon: const Icon(Icons.group_outlined),
                    label: Text(words.usersTitle),
                    onPressed: onUsers,
                  ),
                if (mayShapeStructure)
                  TextButton.icon(
                    key: HomeScreen.categoriesKey(project.id),
                    icon: const Icon(Icons.category_outlined),
                    label: Text(words.categoriesTitle),
                    onPressed: onCategories,
                  ),
                if (mayKeepSettings)
                  TextButton.icon(
                    key: HomeScreen.paymentMethodsKey(project.id),
                    icon: const Icon(Icons.credit_card_outlined),
                    label: Text(words.paymentMethodsTitle),
                    onPressed: onPaymentMethods,
                  ),
                TextButton.icon(
                  key: HomeScreen.accountsKey(project.id),
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: Text(words.accountsTitle),
                  onPressed: onAccounts,
                ),
                TextButton.icon(
                  key: HomeScreen.partnersKey(project.id),
                  icon: const Icon(Icons.handshake_outlined),
                  label: Text(words.partnersTitle),
                  onPressed: onPartners,
                ),
                TextButton.icon(
                  key: HomeScreen.suppliersKey(project.id),
                  icon: const Icon(Icons.storefront_outlined),
                  label: Text(words.suppliersTitle),
                  onPressed: onSuppliers,
                ),
                TextButton.icon(
                  key: HomeScreen.contractsKey(project.id),
                  icon: const Icon(Icons.description_outlined),
                  label: Text(words.contractsTitle),
                  onPressed: onContracts,
                ),
                TextButton.icon(
                  key: HomeScreen.revenueKey(project.id),
                  icon: const Icon(Icons.trending_up),
                  label: Text(words.revenueTitle),
                  onPressed: onRevenue,
                ),
                TextButton.icon(
                  key: HomeScreen.reportsKey(project.id),
                  icon: const Icon(Icons.summarize_outlined),
                  label: Text(words.reportsTitle),
                  onPressed: onReports,
                ),
                if (project.may(Permission.approveEntries))
                  TextButton.icon(
                    key: HomeScreen.approvalsKey(project.id),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: Text(words.approvalsTitle),
                    onPressed: onApprovals,
                  ),
                if (project.may(Permission.moveMoney))
                  TextButton.icon(
                    key: HomeScreen.liquidateKey(project.id),
                    icon: const Icon(Icons.request_quote_outlined),
                    label: Text(words.liquidationTitle),
                    onPressed: onLiquidate,
                  ),
                if (mayChange) ...[
                  TextButton.icon(
                    key: HomeScreen.addUnitKey(project.id),
                    icon: const Icon(Icons.add),
                    label: Text(words.projectsAddUnit),
                    onPressed: onAddUnit,
                  ),
                  TextButton.icon(
                    key: HomeScreen.renameKey(project.id),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(words.projectsRename),
                    onPressed: onRename,
                  ),
                  TextButton(
                    key: HomeScreen.closeKey(project.id),
                    style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                    onPressed: onClose,
                    child: Text(words.projectsClose),
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
