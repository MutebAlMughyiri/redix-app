import 'package:flutter/material.dart';

import '../format/date_format.dart';
import '../ui/api_list_body.dart';
import '../ui/change_dialog.dart';
import '../ui/refusal_snack_bar.dart';
import '../words/words.dart';
import 'registered_project.dart';
import 'registered_projects.dart';
import 'reject_project_dialog.dart';

/// Registered projects (UC-066): what is waiting for the admin, with the manager's details and a decision. This is all the admin can do (BR-29).
class RegisteredProjectsScreen extends StatefulWidget {
  /// The screen, showing and deciding [projects].
  const RegisteredProjectsScreen({super.key, required this.projects});

  /// The projects this screen shows and decides.
  final RegisteredProjects projects;

  /// The screen's route.
  static const path = '/registered-projects';

  /// The line shown while nothing is waiting.
  static const emptyKey = ApiListBody.emptyKey;

  /// The line that says the list could not be read.
  static const messageKey = ApiListBody.messageKey;

  /// The button that reads the list again.
  static const retryKey = ApiListBody.retryKey;

  /// Which project, in the Reject dialog.
  static const rejectNameKey = Key('registered.rejectName');

  /// Why it is rejected, in the Reject dialog.
  static const reasonKey = Key('registered.reason');

  /// The button that rejects, in the Reject dialog.
  static const saveKey = ChangeDialog.saveKey;

  /// The line that says why a rejection was refused, in the Reject dialog.
  static const dialogMessageKey = ChangeDialog.messageKey;

  /// The card of the project [id].
  static Key cardKey(String id) => Key('registered.card.$id');

  /// The project's name, start date and units, for the project [id].
  static Key detailsKey(String id) => Key('registered.details.$id');

  /// Who registered the project [id].
  static Key managerKey(String id) => Key('registered.manager.$id');

  /// The button that approves the project [id].
  static Key approveKey(String id) => Key('registered.approve.$id');

  /// The button that rejects the project [id].
  static Key rejectKey(String id) => Key('registered.reject.$id');

  @override
  State<RegisteredProjectsScreen> createState() => _RegisteredProjectsScreenState();
}

class _RegisteredProjectsScreenState extends State<RegisteredProjectsScreen> {
  @override
  void initState() {
    super.initState();
    widget.projects.load();
  }

  Widget _card(Words words, ThemeData theme, RegisteredProject project) {
    final details = [formatDate(project.startDate), ...project.units].join(' · ');
    final manager = [project.managerName, project.managerUsername, if (project.managerMobile.isNotEmpty) project.managerMobile].join(' · ');
    return Card.outlined(
      key: RegisteredProjectsScreen.cardKey(project.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.name, style: theme.textTheme.titleMedium),
                Text(details, key: RegisteredProjectsScreen.detailsKey(project.id), style: theme.textTheme.bodySmall),
                Text(manager, key: RegisteredProjectsScreen.managerKey(project.id), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  key: RegisteredProjectsScreen.approveKey(project.id),
                  onPressed: () => showRefusalOf(context, widget.projects.approve(project)),
                  child: Text(words.registeredApprove),
                ),
                TextButton(
                  key: RegisteredProjectsScreen.rejectKey(project.id),
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => RejectProjectDialog(project: project, projects: widget.projects),
                  ),
                  child: Text(words.registeredReject),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(words.registeredTitle)),
      body: ApiListBody(
        list: widget.projects,
        emptyText: words.registeredEmpty,
        itemBuilder: (project) => _card(words, theme, project),
      ),
    );
  }
}
