import 'package:flutter/material.dart';

import '../format/parts_line.dart';
import '../ui/part_keys.dart';
import '../words/words.dart';
import 'project.dart';
import 'projects_screen.dart';
import '../ui/app_color.dart';
import 'project_status_chip.dart';
import '../ui/act_once.dart';

/// One project on the list: its name, units and its status. One the user may open opens when tapped, and has a star that marks the default; one he was made
/// inactive in shows gray and disabled, saying so under its name, and does nothing when tapped (redix-api #126 D2).
class ProjectChoice extends StatelessWidget {
  /// The card of [project], calling [onOpen] and [onStar] when those are tapped; [isDefault] fills the star.
  const ProjectChoice({super.key, required this.project, required this.isDefault, required this.onOpen, required this.onStar});

  /// The project this card shows.
  final Project project;

  /// True when this is the user's default project.
  final bool isDefault;

  /// Called when a project the user may open is tapped.
  final VoidCallback onOpen;

  /// Called when the star is tapped.
  final TapAction onStar;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    final units = project.units.isEmpty ? words.projectsNoUnits : partsLine(project.units.map((unit) => unit.name));
    final details = project.isInactive ? words.projectsInactive : project.isFinished ? words.projectsReadOnly : units;
    return Card.outlined(
      key: ProjectsScreen.cardKey(project.id),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ProjectsScreen.cardKey(project.id).body,
        onTap: project.mayOpen ? onOpen : null,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(16, 8, project.mayOpen ? 4 : 16, 8),
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
                        Text(project.name, key: ProjectsScreen.nameKey(project.id), style: theme.textTheme.titleMedium?.merge(AppColor.quiet.textUnless(context, !project.isInactive))),
                        Text(details, key: ProjectsScreen.detailsKey(project.id), style: theme.textTheme.bodySmall),
                        if (project.rejectionReason.isNotEmpty)
                          Text(project.rejectionReason, key: ProjectsScreen.reasonKey(project.id), style: theme.textTheme.bodySmall?.copyWith(color: AppColor.refusal.of(context))),
                      ],
                    ),
                    projectStatusChip(context, project, ProjectsScreen.statusKey(project.id)),
                  ],
                ),
              ),
              if (project.mayOpen)
                ActOnce(builder: (once) => IconButton(
                  key: ProjectsScreen.starKey(project.id),
                  icon: Icon(isDefault ? Icons.star : Icons.star_border, key: ProjectsScreen.starKey(project.id).icon, color: isDefault ? AppColor.brand.of(context) : null),
                  tooltip: words.projectsDefaultProject,
                  onPressed: once(onStar),
                )),
            ],
          ),
        ),
      ),
    );
  }
}
