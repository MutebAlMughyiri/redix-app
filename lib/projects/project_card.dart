import 'package:flutter/material.dart';

import '../auth/permission.dart';
import '../format/date_format.dart';
import '../home/home_screen.dart';
import '../words/words.dart';
import 'project.dart';

/// The open project: the signed-in user's roles in it, its start date, status and units, with what those roles allow: Users, Categories and items, Payment methods, Accounts, Partners, and Add unit and Close project while it runs.
class ProjectCard extends StatelessWidget {
  /// The card of [project], calling [onUsers], [onCategories], [onPaymentMethods], [onAccounts], [onPartners], [onAddUnit] and [onClose] when those are tapped.
  const ProjectCard({
    super.key,
    required this.project,
    required this.onUsers,
    required this.onCategories,
    required this.onPaymentMethods,
    required this.onAccounts,
    required this.onPartners,
    required this.onAddUnit,
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

  /// Called when Add unit is tapped.
  final VoidCallback onAddUnit;

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
          for (final unit in project.units) ListTile(dense: true, title: Text(unit.name, key: HomeScreen.unitKey(unit.id))),
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
                if (project.may(Permission.seeAllCapital))
                  TextButton.icon(
                    key: HomeScreen.partnersKey(project.id),
                    icon: const Icon(Icons.handshake_outlined),
                    label: Text(words.partnersTitle),
                    onPressed: onPartners,
                  ),
                if (mayChange) ...[
                  TextButton.icon(
                    key: HomeScreen.addUnitKey(project.id),
                    icon: const Icon(Icons.add),
                    label: Text(words.projectsAddUnit),
                    onPressed: onAddUnit,
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
