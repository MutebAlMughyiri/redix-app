import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/api_list_body.dart';
import '../ui/change_dialog.dart';
import '../ui/confirm_dialog.dart';
import '../ui/refusal_snack_bar.dart';
import '../words/words.dart';
import 'add_unit_dialog.dart';
import 'new_project_screen.dart';
import 'project.dart';
import 'project_card.dart';
import 'projects.dart';

/// The projects (UC-006): one card per project, where a running one takes a new unit or is closed. A finished one offers no change (AC-04.1).
class ProjectsScreen extends StatefulWidget {
  /// The screen, showing and changing [projects].
  const ProjectsScreen({super.key, required this.projects});

  /// The projects this screen shows and changes.
  final Projects projects;

  /// The screen's route.
  static const path = '/projects';

  /// The button that opens the new project form.
  static const newProjectKey = Key('projects.new');

  /// The line shown while there are no projects.
  static const emptyKey = ApiListBody.emptyKey;

  /// The line that says the list could not be read.
  static const messageKey = ApiListBody.messageKey;

  /// The button that reads the list again.
  static const retryKey = ApiListBody.retryKey;

  /// The unit's name, in the Add unit dialog.
  static const unitNameKey = Key('projects.unitName');

  /// The button that adds the unit, in the Add unit dialog.
  static const saveUnitKey = ChangeDialog.saveKey;

  /// The line that says why the unit was refused, in the Add unit dialog.
  static const unitMessageKey = ChangeDialog.messageKey;

  /// The project's name, in the close question.
  static const closeNameKey = ConfirmDialog.subjectKey;

  /// What closing means, in the close question.
  static const closeExplainKey = ConfirmDialog.explanationKey;

  /// The button that closes the project, in the close question.
  static const confirmCloseKey = ConfirmDialog.confirmKey;

  /// The button that keeps the project running, in the close question.
  static const cancelCloseKey = ConfirmDialog.cancelKey;

  /// The card of the project [id].
  static Key cardKey(String id) => Key('projects.card.$id');

  /// The name of the project [id].
  static Key nameKey(String id) => Key('projects.name.$id');

  /// The start date of the project [id], and whether it is read-only.
  static Key detailsKey(String id) => Key('projects.details.$id');

  /// The status of the project [id].
  static Key statusKey(String id) => Key('projects.status.$id');

  /// The unit [id].
  static Key unitKey(String id) => Key('projects.unit.$id');

  /// The line of a project [id] with no units.
  static Key noUnitsKey(String id) => Key('projects.noUnits.$id');

  /// The button that adds a unit to the running project [id].
  static Key addUnitKey(String id) => Key('projects.addUnit.$id');

  /// The button that closes the running project [id].
  static Key closeKey(String id) => Key('projects.close.$id');

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  @override
  void initState() {
    super.initState();
    widget.projects.load();
  }

  void _askToClose(Project project) {
    final words = Words.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: words.projectsCloseQuestion,
        subject: project.name,
        explanation: words.projectsCloseExplain,
        confirmLabel: words.projectsClose,
        onConfirm: () => showRefusalOf(context, widget.projects.close(project)),
      ),
    );
  }

  void _askForUnit(Project project) {
    showDialog<void>(
      context: context,
      builder: (_) => AddUnitDialog(project: project, projects: widget.projects),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(words.projectsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: ProjectsScreen.newProjectKey,
        icon: const Icon(Icons.add),
        label: Text(words.projectsNew),
        onPressed: () => context.push(NewProjectScreen.path),
      ),
      body: ApiListBody(
        list: widget.projects,
        emptyText: words.projectsEmpty,
        itemBuilder: (project) => ProjectCard(project: project, onAddUnit: () => _askForUnit(project), onClose: () => _askToClose(project)),
      ),
    );
  }
}
