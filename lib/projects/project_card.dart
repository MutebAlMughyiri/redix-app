import 'package:flutter/material.dart';

import '../auth/permission.dart';
import '../format/date_format.dart';
import '../words/words.dart';
import 'project.dart';
import 'projects_screen.dart';

/// One project on the list: its name, the signed-in user's roles in it, its start date, status and units, with what those roles allow: Users, and Add unit and
/// Close project while it runs.
class ProjectCard extends StatelessWidget {
  /// The card of [project], calling [onUsers], [onAddUnit] and [onClose] when those are tapped.
  const ProjectCard({super.key, required this.project, required this.onUsers, required this.onAddUnit, required this.onClose});

  /// The project this card shows.
  final Project project;

  /// Called when Users is tapped.
  final VoidCallback onUsers;

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
    return Card.outlined(
      key: ProjectsScreen.cardKey(project.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
            child: OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              overflowSpacing: 4,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.name, key: ProjectsScreen.nameKey(project.id), style: theme.textTheme.titleMedium),
                    Text(project.roles.map(words.text).join(' · '), key: ProjectsScreen.rolesKey(project.id), style: theme.textTheme.bodySmall),
                    Text(
                      project.isFinished ? '$startDate · ${words.projectsReadOnly}' : startDate,
                      key: ProjectsScreen.detailsKey(project.id),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (project.rejectionReason.isNotEmpty)
                      Text(project.rejectionReason, key: ProjectsScreen.reasonKey(project.id), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                  ],
                ),
                Chip(
                  key: ProjectsScreen.statusKey(project.id),
                  label: Text(words.text(project.status.wordKey)),
                  backgroundColor: project.status == ProjectStatus.running ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (project.units.isEmpty) ListTile(dense: true, title: Text(words.projectsNoUnits, key: ProjectsScreen.noUnitsKey(project.id))),
          for (final unit in project.units) ListTile(dense: true, title: Text(unit.name, key: ProjectsScreen.unitKey(unit.id))),
          if (mayManageUsers || mayChange) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (mayManageUsers)
                    TextButton.icon(
                      key: ProjectsScreen.usersKey(project.id),
                      icon: const Icon(Icons.group_outlined),
                      label: Text(words.usersTitle),
                      onPressed: onUsers,
                    ),
                  if (mayChange) ...[
                    TextButton.icon(
                      key: ProjectsScreen.addUnitKey(project.id),
                      icon: const Icon(Icons.add),
                      label: Text(words.projectsAddUnit),
                      onPressed: onAddUnit,
                    ),
                    TextButton(
                      key: ProjectsScreen.closeKey(project.id),
                      style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                      onPressed: onClose,
                      child: Text(words.projectsClose),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
