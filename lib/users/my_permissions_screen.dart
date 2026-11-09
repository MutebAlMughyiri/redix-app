import 'package:flutter/material.dart';

import '../auth/permission.dart';
import '../projects/project.dart';
import '../projects/projects.dart';
import '../ui/api_list_body.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'permission_tick.dart';

/// صلاحياتي, from Settings (Muteb, 9 Nov 2026): what the signed-in user may do in a project, each permission as the project manager ticked it, read only.
class MyPermissionsScreen extends StatelessWidget {
  /// The permissions of the signed-in user in [project], read again from [projects] when pulled down.
  const MyPermissionsScreen({super.key, required this.project, required this.projects});

  /// The screen's route.
  static const path = '/projects/:projectId/my-permissions';

  /// The route of the permissions in the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/my-permissions';

  /// What this screen shows, and who changes it.
  static const hintKey = Key('myPermissions.hint');

  /// The tick of [permission].
  static Key permissionKey(Permission permission) => Key('myPermissions.${permission.name}');

  /// The project.
  final Project project;

  /// The user's projects, which hold what they may do in each.
  final Projects projects;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.permissionsMine, subject: project.name)),
      body: ListenableBuilder(
        listenable: projects,
        builder: (context, _) {
          final latest = projects.latest(project);
          return RefreshIndicator(
            onRefresh: projects.load,
            child: ListView(
              physics: ApiListBody.physics,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(words.permissionsMineHint, key: hintKey, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                for (final permission in Permission.inAProject) PermissionTick(key: permissionKey(permission), permission: permission, value: latest.may(permission), onChanged: null),
              ],
            ),
          );
        },
      ),
    );
  }
}
