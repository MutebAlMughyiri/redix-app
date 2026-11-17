import 'package:flutter/material.dart';

import '../format/date_format.dart';
import '../ui/api_list_body.dart';
import '../ui/part_keys.dart';
import '../ui/refusal_snack_bar.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'registered_project.dart';
import 'registered_projects.dart';
import '../ui/app_color.dart';
import '../format/parts_line.dart';
import '../ui/reason_sheet.dart';
import '../ui/act_once.dart';

/// Registered projects (UC-066): what is waiting for the admin, with the manager's details and a decision. This is all the admin can do (BR-29).
class RegisteredProjectsScreen extends StatefulWidget {
  /// The screen, showing and deciding [projects].
  const RegisteredProjectsScreen({super.key, required this.projects});

  /// The projects this screen shows and decides.
  final RegisteredProjects projects;

  /// The screen's route.
  static const path = '/registered-projects';

  /// The card of the project [id].
  static Key cardKey(String id) => Key('registered.card.$id');

  /// The project's name, start date and units, for the project [id].
  static Key detailsKey(String id) => Key('registered.details.$id');

  /// Who registered the project [id].
  static Key managerKey(String id) => Key('registered.manager.$id');

  /// What the project [id] is, as its manager wrote it; only when they wrote one (redix-api 93).
  static Key descriptionKey(String id) => Key('registered.description.$id');

  /// The button that approves the project [id].
  static Key approveKey(String id) => Key('registered.approve.$id');

  /// The button that rejects the project [id].
  static Key rejectKey(String id) => Key('registered.reject.$id');

  /// The name of the project [id].
  static Key nameKey(String id) => Key('registered.name.$id');

  @override
  State<RegisteredProjectsScreen> createState() => _RegisteredProjectsScreenState();
}

class _RegisteredProjectsScreenState extends State<RegisteredProjectsScreen> {
  @override
  void initState() {
    super.initState();
    widget.projects.loadOnOpen();
  }

  Widget _card(Words words, ThemeData theme, RegisteredProject project) {
    final details = [formatDate(project.startDate), ...project.units].join(' · ');
    final manager = partsLine([project.managerName, project.managerUsername, project.managerMobile]);
    return Card.outlined(
      key: RegisteredProjectsScreen.cardKey(project.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.name, key: RegisteredProjectsScreen.nameKey(project.id), style: theme.textTheme.titleMedium),
                Text(details, key: RegisteredProjectsScreen.detailsKey(project.id), style: theme.textTheme.bodySmall),
                Text(manager, key: RegisteredProjectsScreen.managerKey(project.id), style: theme.textTheme.bodySmall),
                if (project.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(project.description, key: RegisteredProjectsScreen.descriptionKey(project.id), style: theme.textTheme.bodyMedium),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ActOnce(builder: (once) => OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  key: RegisteredProjectsScreen.approveKey(project.id),
                  onPressed: once(() => showRefusalOf(context, widget.projects.approve(project))),
                  child: Text(words.registeredApprove, key: RegisteredProjectsScreen.approveKey(project.id).label),
                ),
                TextButton(
                  key: RegisteredProjectsScreen.rejectKey(project.id),
                  style: TextButton.styleFrom(foregroundColor: AppColor.refusal.of(context)),
                  onPressed: once(() => ReasonSheet.show(
                    context,
                    ReasonSheet(title: words.registeredReject, about: project.name, reasonLabel: words.registeredReason, sendLabel: words.registeredReject, onSend: (reason) => widget.projects.reject(project, reason)),
                  )),
                  child: Text(words.registeredReject, key: RegisteredProjectsScreen.rejectKey(project.id).label),
                ),
              ],
            )),
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
      appBar: AppBar(title: Text(words.registeredTitle, key: ScreenTitle.titleKey)),
      body: ApiListBody(
        list: widget.projects,
        emptyText: words.registeredEmpty,
        itemBuilder: (project) => _card(words, theme, project),
      ),
    );
  }
}
