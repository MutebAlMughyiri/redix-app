import 'package:flutter/material.dart';

import '../projects/project.dart';
import '../ui/refusal_snack_bar.dart';
import '../words/words.dart';
import 'project_role.dart';
import 'user.dart';
import 'user_projects_screen.dart';
import 'users.dart';

/// One project on a user's Projects and roles screen: a tick that gives or takes it away, and the role while it is given. Each is saved at once.
class UserProjectRow extends StatelessWidget {
  /// The row of [project] for [user], changed through [users].
  const UserProjectRow({super.key, required this.user, required this.project, required this.users});

  /// The user being given projects.
  final User user;

  /// The project this row shows.
  final Project project;

  /// The way to change the user's projects.
  final Users users;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final isGiven = user.hasProject(project.id);
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            key: UserProjectsScreen.tickKey(project.id),
            controlAffinity: ListTileControlAffinity.leading,
            value: isGiven,
            title: Text(project.isFinished ? '${project.name} (${words.projectsFinished})' : project.name),
            onChanged: (_) => showRefusalOf(context, isGiven ? users.remove(user, project.id) : users.assign(user, project.id, ProjectRole.reader)),
          ),
          if (isGiven)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final role in ProjectRole.values)
                    ChoiceChip(
                      key: UserProjectsScreen.roleKey(project.id, role),
                      label: Text(words.text(role.wordKey)),
                      selected: user.roleIn(project.id) == role,
                      onSelected: (_) => showRefusalOf(context, users.assign(user, project.id, role)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
