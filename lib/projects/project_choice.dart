import 'package:flutter/material.dart';

import '../words/words.dart';
import 'project.dart';
import 'projects_screen.dart';

/// One project on the list: its name, units, the signed-in user's roles and its status. An approved one opens when tapped, and has a star that marks the default.
class ProjectChoice extends StatelessWidget {
  /// The card of [project], calling [onOpen] and [onStar] when those are tapped; [isDefault] fills the star.
  const ProjectChoice({super.key, required this.project, required this.isDefault, required this.onOpen, required this.onStar});

  /// The project this card shows.
  final Project project;

  /// True when this is the user's default project.
  final bool isDefault;

  /// Called when an approved project is tapped.
  final VoidCallback onOpen;

  /// Called when the star is tapped.
  final VoidCallback onStar;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    final units = project.units.isEmpty ? words.projectsNoUnits : project.units.map((unit) => unit.name).join(' · ');
    return Card.outlined(
      key: ProjectsScreen.cardKey(project.id),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: project.isApproved ? onOpen : null,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(16, 8, project.isApproved ? 4 : 16, 8),
          child: Row(
            children: [
              Expanded(
                child: OverflowBar(
                  alignment: MainAxisAlignment.spaceBetween,
                  overflowSpacing: 4,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project.name, key: ProjectsScreen.nameKey(project.id), style: theme.textTheme.titleMedium),
                        Text(project.isFinished ? words.projectsReadOnly : units, key: ProjectsScreen.detailsKey(project.id), style: theme.textTheme.bodySmall),
                        Text(project.roles.map(words.text).join(' · '), key: ProjectsScreen.rolesKey(project.id), style: theme.textTheme.bodySmall),
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
              if (project.isApproved)
                IconButton(
                  key: ProjectsScreen.starKey(project.id),
                  icon: Icon(isDefault ? Icons.star : Icons.star_border, color: isDefault ? theme.colorScheme.primary : null),
                  tooltip: words.projectsDefaultProject,
                  onPressed: onStar,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
