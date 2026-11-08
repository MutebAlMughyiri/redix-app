import 'package:flutter/material.dart';

import '../format/date_format.dart';
import '../ui/change_dialog.dart';
import '../ui/confirm_dialog.dart';
import '../ui/name_dialog.dart';
import '../ui/part_keys.dart';
import '../ui/refusal_snack_bar.dart';
import '../ui/screen_title.dart';
import '../ui/swipe_to_remove.dart';
import '../words/words.dart';
import 'add_unit_dialog.dart';
import 'project.dart';
import 'projects.dart';
import 'unit_row.dart';

/// More info (معلومات المشروع, redix-api 93): the project's own record on one page, its name, start date, status, units and description. Everyone in the project reads it;
/// whoever manages it renames it, adds, renames and deletes units, keeps its description and closes it, while it is open (AC-04.1).
class ProjectInfoScreen extends StatefulWidget {
  /// The page of [project], read live from [projects], which is also the way to change it.
  const ProjectInfoScreen({super.key, required this.project, required this.projects});

  /// The project, as Settings held it when the page was opened.
  final Project project;

  /// The projects, among them this one.
  final Projects projects;

  /// The screen's route.
  static const path = '/projects/:projectId/info';

  /// The route of the page of the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/info';

  /// The project's name.
  static const nameKey = Key('projectInfo.name');

  /// The button that renames the project.
  static const renameKey = Key('projectInfo.rename');

  /// The project's start date, and whether it is read-only.
  static const detailsKey = Key('projectInfo.details');

  /// The project's status.
  static const statusKey = Key('projectInfo.status');

  /// The heading of the units.
  static const unitsKey = Key('projectInfo.units');

  /// The button that adds a unit.
  static const addUnitKey = Key('projectInfo.addUnit');

  /// The line that says the project has no units.
  static const noUnitsKey = Key('projectInfo.noUnits');

  /// The row of the unit [id].
  static Key unitRowKey(String id) => Key('projectInfo.unitRow.$id');

  /// The name of the unit [id].
  static Key unitKey(String id) => Key('projectInfo.unit.$id');

  /// The menu of the unit [id].
  static Key unitMenuKey(String id) => Key('projectInfo.unitMenu.$id');

  /// Rename, in a unit's menu.
  static const renameUnitKey = Key('projectInfo.renameUnit');

  /// The line saying a unit is removed by a swipe (redix-api #102).
  static const swipeHintKey = Key('projectInfo.swipeHint');

  /// The unit's name, in the Add unit dialog.
  static const unitNameKey = Key('projectInfo.unitName');

  /// The button that adds the unit, in the Add unit dialog.
  static const saveUnitKey = ChangeDialog.saveKey;

  /// The line that says why the unit was refused, in the Add unit dialog.
  static const unitMessageKey = ChangeDialog.messageKey;

  /// The heading of the description.
  static const descriptionHeadingKey = Key('projectInfo.descriptionHeading');

  /// The field the description is written in, for whoever manages the project.
  static const descriptionKey = Key('projectInfo.description');

  /// The description as it reads for everyone else, or that there is none yet.
  static const descriptionTextKey = Key('projectInfo.descriptionText');

  /// The button that keeps the description.
  static const saveDescriptionKey = Key('projectInfo.saveDescription');

  /// The button that closes the project.
  static const closeKey = Key('projectInfo.close');

  /// The project's name, in the close question.
  static const closeNameKey = ConfirmDialog.subjectKey;

  /// What closing means, in the close question.
  static const closeExplainKey = ConfirmDialog.explanationKey;

  /// The button that closes the project, in the close question.
  static const confirmCloseKey = ConfirmDialog.confirmKey;

  /// The button that keeps the project active, in the close question.
  static const cancelCloseKey = ConfirmDialog.cancelKey;

  @override
  State<ProjectInfoScreen> createState() => _ProjectInfoScreenState();
}

class _ProjectInfoScreenState extends State<ProjectInfoScreen> {
  late final _description = TextEditingController(text: widget.project.description);

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  void _askToRename(Project project) {
    final words = Words.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => NameDialog(title: words.projectsRename, label: words.projectsName, saveLabel: words.projectsSave, name: project.name, onSave: (name) => widget.projects.rename(project, name)),
    );
  }

  void _askForUnit(Project project) {
    showDialog<void>(context: context, builder: (_) => AddUnitDialog(project: project, projects: widget.projects));
  }

  void _askToRenameUnit(Project project, Unit unit) {
    final words = Words.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => NameDialog(
        title: words.projectsRenameUnit,
        label: words.projectsUnitName,
        saveLabel: words.projectsSave,
        name: unit.name,
        onSave: (name) => widget.projects.renameUnit(project, unit, name),
      ),
    );
  }

  Future<void> _saveDescription(Project project) async {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final refusal = await widget.projects.describe(project, _description.text);
    showMessage(messenger, words, refusal.isEmpty ? 'projectInfo.saved' : refusal);
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

  List<Widget> _descriptionParts(Words words, ThemeData theme, Project project, bool mayChange) => mayChange
      ? [
          TextField(
            key: ProjectInfoScreen.descriptionKey,
            controller: _description,
            minLines: 3,
            maxLines: 8,
            maxLength: Project.descriptionMaxLength,
            decoration: InputDecoration(helperText: words.projectInfoDescriptionHint, border: const OutlineInputBorder()),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton(
              key: ProjectInfoScreen.saveDescriptionKey,
              onPressed: () => _saveDescription(project),
              child: Text(words.projectInfoSave, key: ProjectInfoScreen.saveDescriptionKey.label),
            ),
          ),
        ]
      : [Text(project.description.isEmpty ? words.projectInfoNoDescription : project.description, key: ProjectInfoScreen.descriptionTextKey, style: theme.textTheme.bodyMedium)];

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(words.projectInfoTitle, key: ScreenTitle.titleKey)),
      body: ListenableBuilder(
        listenable: widget.projects,
        builder: (context, _) {
          final project = widget.projects.latest(widget.project);
          final mayChange = project.mayManageProject;
          final startDate = '${words.projectsStartDate} ${formatDate(project.startDate)}';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: Text(project.name, key: ProjectInfoScreen.nameKey, style: theme.textTheme.titleLarge)),
                  if (mayChange)
                    IconButton(
                      key: ProjectInfoScreen.renameKey,
                      tooltip: words.projectsRename,
                      icon: Icon(Icons.edit_outlined, key: ProjectInfoScreen.renameKey.icon),
                      onPressed: () => _askToRename(project),
                    ),
                ],
              ),
              OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                overflowSpacing: 4,
                children: [
                  Text(project.isFinished ? '$startDate · ${words.projectsReadOnly}' : startDate, key: ProjectInfoScreen.detailsKey, style: theme.textTheme.bodySmall),
                  Chip(
                    key: ProjectInfoScreen.statusKey,
                    label: Text(words.text(project.status.wordKey), key: ProjectInfoScreen.statusKey.label),
                    backgroundColor: project.status == ProjectStatus.active ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const Divider(height: 24),
              OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(words.projectsUnits, key: ProjectInfoScreen.unitsKey, style: theme.textTheme.titleSmall),
                  if (mayChange)
                    TextButton.icon(
                      key: ProjectInfoScreen.addUnitKey,
                      icon: Icon(Icons.add, key: ProjectInfoScreen.addUnitKey.icon),
                      label: Text(words.projectsAddUnit, key: ProjectInfoScreen.addUnitKey.label),
                      onPressed: () => _askForUnit(project),
                    ),
                ],
              ),
              if (project.units.isEmpty) Text(words.projectsNoUnits, key: ProjectInfoScreen.noUnitsKey, style: theme.textTheme.bodyMedium),
              if (mayChange && project.units.isNotEmpty) const SwipeHint(key: ProjectInfoScreen.swipeHintKey),
              for (final unit in project.units)
                UnitRow(unit: unit, mayChange: mayChange, onRename: () => _askToRenameUnit(project, unit), onRemove: () => widget.projects.deleteUnit(project, unit)),
              const Divider(height: 24),
              Text(words.projectInfoDescription, key: ProjectInfoScreen.descriptionHeadingKey, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              ..._descriptionParts(words, theme, project, mayChange),
              if (mayChange) ...[
                const Divider(height: 32),
                OutlinedButton.icon(
                  key: ProjectInfoScreen.closeKey,
                  style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
                  icon: Icon(Icons.lock_outline, key: ProjectInfoScreen.closeKey.icon),
                  label: Text(words.projectsClose, key: ProjectInfoScreen.closeKey.label),
                  onPressed: () => _askToClose(project),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
