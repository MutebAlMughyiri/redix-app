import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../format/date_format.dart';
import '../words/words.dart';
import 'projects.dart';

/// The new project form (UC-006): its name, its start date and its units, sent to the API at once.
class NewProjectScreen extends StatefulWidget {
  /// The form, adding to [projects].
  const NewProjectScreen({super.key, required this.projects});

  /// The projects the new one joins.
  final Projects projects;

  /// The screen's route.
  static const path = '/projects/new';

  /// The project's name.
  static const nameKey = Key('newProject.name');

  /// The start date, which opens the date picker.
  static const startDateKey = Key('newProject.startDate');

  /// The next unit's name.
  static const unitNameKey = Key('newProject.unitName');

  /// The button that adds the unit to the list.
  static const addUnitKey = Key('newProject.addUnit');

  /// The button that creates the project.
  static const submitKey = Key('newProject.submit');

  /// The line that says why the project was refused.
  static const messageKey = Key('newProject.message');

  /// The unit at [index] of the list.
  static Key unitKey(int index) => Key('newProject.unit.$index');

  /// The button that takes the unit at [index] off the list.
  static Key removeUnitKey(int index) => Key('newProject.removeUnit.$index');

  @override
  State<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends State<NewProjectScreen> {
  final _name = TextEditingController();
  final _unitName = TextEditingController();
  final _units = <String>[];
  var _startDate = DateUtils.dateOnly(DateTime.now());
  var _message = '';
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _unitName.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  void _addUnit() {
    setState(() {
      _units.add(_unitName.text);
      _unitName.clear();
    });
  }

  Future<void> _create() async {
    setState(() {
      _saving = true;
      _message = '';
    });
    final refusal = await widget.projects.create(_name.text, _startDate, [..._units, if (_unitName.text.trim().isNotEmpty) _unitName.text]);
    if (!mounted) {
      return;
    }
    if (refusal.isEmpty) {
      context.pop();
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(words.projectsNew)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              key: NewProjectScreen.nameKey,
              controller: _name,
              decoration: InputDecoration(labelText: words.projectsName, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            InkWell(
              key: NewProjectScreen.startDateKey,
              onTap: _pickStartDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: words.projectsStartDate,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(formatDate(_startDate)),
              ),
            ),
            const SizedBox(height: 24),
            Text(words.projectsUnits, style: theme.textTheme.titleSmall),
            for (final (index, unit) in _units.indexed)
              ListTile(
                key: NewProjectScreen.unitKey(index),
                contentPadding: EdgeInsets.zero,
                title: Text(unit),
                trailing: IconButton(
                  key: NewProjectScreen.removeUnitKey(index),
                  icon: const Icon(Icons.close),
                  tooltip: words.projectsRemoveUnit,
                  onPressed: () => setState(() => _units.removeAt(index)),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              key: NewProjectScreen.unitNameKey,
              controller: _unitName,
              decoration: InputDecoration(
                labelText: words.projectsUnitName,
                border: const OutlineInputBorder(),
                suffixIcon: ValueListenableBuilder(
                  valueListenable: _unitName,
                  builder: (context, name, _) => TextButton.icon(
                    key: NewProjectScreen.addUnitKey,
                    icon: const Icon(Icons.add),
                    label: Text(words.projectsAddUnit),
                    onPressed: name.text.trim().isEmpty ? null : _addUnit,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: NewProjectScreen.submitKey,
              onPressed: _saving ? null : _create,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: Text(words.projectsCreate),
            ),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                words.text(_message),
                key: NewProjectScreen.messageKey,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
