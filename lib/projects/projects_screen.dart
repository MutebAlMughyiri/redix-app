import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../format/date_format.dart';
import '../words/words.dart';
import 'new_project_screen.dart';
import 'project.dart';
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
  static const emptyKey = Key('projects.empty');

  /// The line that says the list could not be read.
  static const messageKey = Key('projects.message');

  /// The button that reads the list again.
  static const retryKey = Key('projects.retry');

  /// The unit's name, in the Add unit dialog.
  static const unitNameKey = Key('projects.unitName');

  /// The button that adds the unit, in the Add unit dialog.
  static const saveUnitKey = Key('projects.saveUnit');

  /// The line that says why the unit was refused, in the Add unit dialog.
  static const unitMessageKey = Key('projects.unitMessage');

  /// The project's name, in the close question.
  static const closeNameKey = Key('projects.closeName');

  /// What closing means, in the close question.
  static const closeExplainKey = Key('projects.closeExplain');

  /// The button that closes the project, in the close question.
  static const confirmCloseKey = Key('projects.confirmClose');

  /// The button that keeps the project running, in the close question.
  static const cancelCloseKey = Key('projects.cancelClose');

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
    final errorColor = Theme.of(context).colorScheme.error;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(words.projectsCloseQuestion),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.name,
              key: ProjectsScreen.closeNameKey,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(words.projectsCloseExplain, key: ProjectsScreen.closeExplainKey),
          ],
        ),
        actions: [
          TextButton(key: ProjectsScreen.cancelCloseKey, onPressed: () => Navigator.of(dialogContext).pop(), child: Text(words.projectsCancel)),
          FilledButton(
            key: ProjectsScreen.confirmCloseKey,
            style: FilledButton.styleFrom(backgroundColor: errorColor),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _close(project);
            },
            child: Text(words.projectsClose),
          ),
        ],
      ),
    );
  }

  Future<void> _close(Project project) async {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final refusal = await widget.projects.close(project);
    if (refusal.isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(words.text(refusal))));
    }
  }

  void _askForUnit(Project project) {
    showDialog<void>(
      context: context,
      builder: (context) => _AddUnitDialog(project: project, projects: widget.projects),
    );
  }

  Widget _body(BuildContext context) {
    final words = Words.of(context);
    final projects = widget.projects;
    if (projects.message.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(words.text(projects.message), key: ProjectsScreen.messageKey, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(key: ProjectsScreen.retryKey, onPressed: projects.load, child: Text(words.projectsRetry)),
            ],
          ),
        ),
      );
    }
    if (projects.all.isEmpty) {
      return Center(
        child: projects.isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Text(words.projectsEmpty, key: ProjectsScreen.emptyKey, textAlign: TextAlign.center),
              ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        for (final project in projects.all)
          _ProjectCard(project: project, onAddUnit: () => _askForUnit(project), onClose: () => _askToClose(project)),
      ],
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
      body: ListenableBuilder(listenable: widget.projects, builder: (context, _) => _body(context)),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.onAddUnit, required this.onClose});

  final Project project;
  final VoidCallback onAddUnit;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    final startDate = '${words.projectsStartDate} ${formatDate(project.startDate)}';
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
                    Text(
                      project.isFinished ? '$startDate · ${words.projectsReadOnly}' : startDate,
                      key: ProjectsScreen.detailsKey(project.id),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                Chip(
                  key: ProjectsScreen.statusKey(project.id),
                  label: Text(project.isFinished ? words.projectsFinished : words.projectsRunning),
                  backgroundColor: project.isFinished ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.primaryContainer,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (project.units.isEmpty) ListTile(dense: true, title: Text(words.projectsNoUnits, key: ProjectsScreen.noUnitsKey(project.id))),
          for (final unit in project.units) ListTile(dense: true, title: Text(unit.name, key: ProjectsScreen.unitKey(unit.id))),
          if (!project.isFinished) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                children: [
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
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddUnitDialog extends StatefulWidget {
  const _AddUnitDialog({required this.project, required this.projects});

  final Project project;
  final Projects projects;

  @override
  State<_AddUnitDialog> createState() => _AddUnitDialogState();
}

class _AddUnitDialogState extends State<_AddUnitDialog> {
  final _name = TextEditingController();
  var _message = '';
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final refusal = await widget.projects.addUnit(widget.project, _name.text);
    if (!mounted) {
      return;
    }
    if (refusal.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = false;
      _message = refusal;
    });
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return AlertDialog(
      title: Text(words.projectsAddUnit),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: ProjectsScreen.unitNameKey,
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(labelText: words.projectsUnitName, border: const OutlineInputBorder()),
          ),
          if (_message.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              words.text(_message),
              key: ProjectsScreen.unitMessageKey,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(words.projectsCancel)),
        FilledButton(key: ProjectsScreen.saveUnitKey, onPressed: _saving ? null : _save, child: Text(words.projectsAddUnit)),
      ],
    );
  }
}
