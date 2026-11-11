import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/session.dart';
import '../home/home_screen.dart';
import '../notifications/notifications.dart';
import '../notifications/notifications_bell.dart';
import '../settings/shared_settings_screen.dart';
import '../ui/api_list_body.dart';
import '../ui/bottom_button.dart';
import '../ui/part_keys.dart';
import '../words/words.dart';
import 'default_project_toggle.dart';
import 'new_project_screen.dart';
import 'project_choice.dart';
import 'projects.dart';

/// The project list, the first screen after sign-in (UC-010, FR-37): the projects the user has access to, one to open, and the default project.
class ProjectsScreen extends StatefulWidget {
  /// The screen, showing [projects] to the user signed in through [session].
  const ProjectsScreen({super.key, required this.projects, required this.session, required this.notifications});

  /// What the user was told.
  final Notifications notifications;

  /// The projects this screen shows.
  final Projects projects;

  /// The session that holds the default project.
  final Session session;

  /// The screen's route.
  static const path = '/';

  /// The heading.
  static const titleKey = Key('projects.title');

  /// What the list holds.
  static const hintKey = Key('projects.hint');

  /// The button that opens Settings.
  static const sharedSettingsKey = Key('projects.sharedSettings');

  /// The button that opens the form to register a project.
  static const newProjectKey = Key('projects.new');

  /// The card of the project [id].
  static Key cardKey(String id) => Key('projects.card.$id');

  /// The name of the project [id].
  static Key nameKey(String id) => Key('projects.name.$id');

  /// The units of the project [id], or that it is read-only.
  static Key detailsKey(String id) => Key('projects.details.$id');

  /// The status of the project [id].
  static Key statusKey(String id) => Key('projects.status.$id');

  /// Why the admin refused the project [id].
  static Key reasonKey(String id) => Key('projects.reason.$id');

  /// The star that marks the project [id] as the default.
  static Key starKey(String id) => Key('projects.star.$id');

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  @override
  void initState() {
    super.initState();
    widget.projects.loadOnOpen();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    final session = widget.session;
    return Scaffold(
      appBar: AppBar(
        actions: [
          NotificationsBell(notifications: widget.notifications),
          IconButton(
            key: ProjectsScreen.sharedSettingsKey,
            icon: Icon(Icons.settings_outlined, key: ProjectsScreen.sharedSettingsKey.icon),
            tooltip: words.sharedSettingsTitle,
            onPressed: () => context.push(SharedSettingsScreen.path),
          ),
        ],
      ),
      bottomNavigationBar: BottomButton(
        buttonKey: ProjectsScreen.newProjectKey,
        label: words.projectsNew,
        onPressed: () => context.push(NewProjectScreen.path),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(words.projectsChoose, key: ProjectsScreen.titleKey, style: theme.textTheme.headlineSmall),
                Text(words.projectsChooseHint, key: ProjectsScreen.hintKey, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: session,
              builder: (context, _) => ApiListBody(
                list: widget.projects,
                emptyText: words.projectsEmpty,
                itemBuilder: (project) => ProjectChoice(
                  project: project,
                  isDefault: session.defaultProjectId == project.id,
                  onOpen: () => context.push(HomeScreen.pathOf(project.id)),
                  onStar: () => toggleDefaultProject(context, session, project),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
