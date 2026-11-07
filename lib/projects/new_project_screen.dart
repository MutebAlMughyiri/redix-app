import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../format/date_format.dart';
import '../auth/sign_in_screen.dart';
import '../words/words.dart';
import 'project_registration.dart';
import 'projects.dart';

/// The form that registers a project (UC-006, UC-066): its name, its start date and its units. From the sign-in page it also takes the details of the manager, who has
/// no login yet. Either way the project waits for the admin.
class NewProjectScreen extends StatefulWidget {
  /// The form, adding to [projects]; [isPublic] when the sign-in page opens it.
  const NewProjectScreen({super.key, required this.projects, this.isPublic = false});

  /// The projects the new one joins.
  final Projects projects;

  /// True on the sign-in page's form, which also takes the manager's details.
  final bool isPublic;

  /// The route of the sign-in page's form, open with no session.
  static const registerPath = '/register';

  /// What happens next.
  static const hintKey = Key('newProject.hint');

  /// The manager's name, on the sign-in page's form.
  static const managerNameKey = Key('newProject.managerName');

  /// The manager's username, on the sign-in page's form.
  static const usernameKey = Key('newProject.username');

  /// The manager's mobile, on the sign-in page's form.
  static const mobileKey = Key('newProject.mobile');

  /// The manager's password, on the sign-in page's form.
  static const passwordKey = Key('newProject.password');

  /// The screen's route.
  static const path = '/projects/new';

  /// The project's name.
  static const nameKey = Key('newProject.name');

  /// The start date, which opens the date picker.
  static const startDateKey = Key('newProject.startDate');

  /// Where the categories and items are copied from, on the form of someone signed in.
  static const structureSourceKey = Key('newProject.structureSource');

  /// The next unit's name.
  static const unitNameKey = Key('newProject.unitName');

  /// The button that adds the unit to the list.
  static const addUnitKey = Key('newProject.addUnit');

  /// The button that sends the project for approval.
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
  final _managerName = TextEditingController();
  final _username = TextEditingController();
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  final _units = <String>[];
  var _structureSourceId = '';
  var _startDate = DateUtils.dateOnly(DateTime.now());
  var _message = '';
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _unitName.dispose();
    _managerName.dispose();
    _username.dispose();
    _mobile.dispose();
    _password.dispose();
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

  Future<String> _send(List<String> units) => widget.isPublic
      ? registerProject(_name.text, _startDate, units, displayName: _managerName.text, username: _username.text, mobile: _mobile.text, password: _password.text)
      : widget.projects.create(_name.text, _startDate, units, structureSourceId: _structureSourceId);

  void _leave() {
    if (!widget.isPublic) {
      context.pop();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Words.of(context).registerSent)));
    context.go(SignInScreen.path);
  }

  Future<void> _create() async {
    setState(() {
      _saving = true;
      _message = '';
    });
    final refusal = await _send([..._units, if (_unitName.text.trim().isNotEmpty) _unitName.text]);
    if (!mounted) {
      return;
    }
    if (refusal.isEmpty) {
      _leave();
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
            Text(words.registerHint, key: NewProjectScreen.hintKey, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
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
            if (!widget.isPublic) ...[
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                key: NewProjectScreen.structureSourceKey,
                initialValue: _structureSourceId,
                isExpanded: true,
                decoration: InputDecoration(labelText: words.projectsStructureSource, border: const OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: '', child: Text(words.projectsDefaultTemplate)),
                  for (final project in widget.projects.all.where((project) => project.isApproved)) DropdownMenuItem(value: project.id, child: Text(project.name)),
                ],
                onChanged: (id) => setState(() => _structureSourceId = id ?? ''),
              ),
            ],
            if (widget.isPublic) ...[
              const SizedBox(height: 24),
              Text(words.projectsManager, style: theme.textTheme.titleSmall),
              const SizedBox(height: 12),
              TextField(
                key: NewProjectScreen.managerNameKey,
                controller: _managerName,
                decoration: InputDecoration(labelText: words.usersName, helperText: words.usersNameHint, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                key: NewProjectScreen.usernameKey,
                controller: _username,
                autocorrect: false,
                decoration: InputDecoration(labelText: words.usersUsername, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                key: NewProjectScreen.mobileKey,
                controller: _mobile,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: words.usersMobile, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                key: NewProjectScreen.passwordKey,
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(labelText: words.signInPassword, border: const OutlineInputBorder()),
              ),
            ],
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
