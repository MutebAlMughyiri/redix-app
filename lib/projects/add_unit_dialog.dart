import 'package:flutter/material.dart';

import '../ui/change_dialog.dart';
import '../words/words.dart';
import 'project.dart';
import 'projects.dart';
import '../settings/settings_screen.dart';

/// Asks for a new unit's name and adds it to an active project.
class AddUnitDialog extends StatefulWidget {
  /// The dialog adding a unit to [project] through [projects].
  const AddUnitDialog({super.key, required this.project, required this.projects});

  /// The project the unit joins.
  final Project project;

  /// The way to change it.
  final Projects projects;

  @override
  State<AddUnitDialog> createState() => _AddUnitDialogState();
}

class _AddUnitDialogState extends State<AddUnitDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ChangeDialog(
      title: words.projectsAddUnit,
      saveLabel: words.projectsAddUnit,
      onSave: () => widget.projects.addUnit(widget.project, _name.text),
      children: [
        TextField(
          key: SettingsScreen.unitNameKey,
          controller: _name,
          autofocus: true,
          decoration: InputDecoration(labelText: words.projectsUnitName, border: const OutlineInputBorder()),
        ),
      ],
    );
  }
}
