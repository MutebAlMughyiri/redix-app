import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../format/date_format.dart';
import '../auth/sign_in_screen.dart';
import '../ui/part_keys.dart';
import '../ui/refusal_snack_bar.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'project.dart';
import 'project_registration.dart';
import 'projects.dart';
import '../ui/typed_names.dart';

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

  /// The project's description, optional (redix-api 93).
  static const descriptionKey = Key('newProject.description');

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

  /// The unit added [number]th, from 0, which keeps its key when another is swiped off.
  static Key unitKey(int number) => Key('newProject.unit.$number');


  /// The heading over the units.
  static const unitsHeadingKey = Key('newProject.unitsHeading');

  /// The next partner's name (redix-api #109).
  static const partnerNameKey = Key('newProject.partnerName');

  /// The button that adds the partner to the list.
  static const addPartnerKey = Key('newProject.addPartner');

  /// The partner added [number]th, from 0.
  static Key partnerKey(int number) => Key('newProject.partner.$number');


  /// The heading over the partners.
  static const partnersHeadingKey = Key('newProject.partnersHeading');

  /// The heading over the manager.
  static const managerHeadingKey = Key('newProject.managerHeading');

  /// The choice of the project [id] to copy the structure from; the default template's is empty.
  static Key structureSourceOptionKey(String id) => Key('newProject.structureSource.$id');

  @override
  State<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends State<NewProjectScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _managerName = TextEditingController();
  final _username = TextEditingController();
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  final _units = NameList();
  final _partners = NameList();
  var _structureSourceId = '';
  var _startDate = DateUtils.dateOnly(DateTime.now());
  var _message = '';
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _units.dispose();
    _partners.dispose();
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

  Future<String> _send() => widget.isPublic
      ? registerProject(_name.text, _startDate, _units.all, _partners.all, _description.text, displayName: _managerName.text, username: _username.text, mobile: _mobile.text, password: _password.text)
      : widget.projects.create(_name.text, _startDate, _units.all, _partners.all, _description.text, structureSourceId: _structureSourceId);

  void _leave() {
    if (!widget.isPublic) {
      context.pop();
      return;
    }
    showMessage(ScaffoldMessenger.of(context), Words.of(context), 'register.sent');
    context.go(SignInScreen.path);
  }

  Future<void> _create() async {
    setState(() {
      _saving = true;
      _message = '';
    });
    final refusal = await _send();
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
      appBar: AppBar(title: Text(words.projectsNew, key: ScreenTitle.titleKey)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(words.registerHint, key: NewProjectScreen.hintKey, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              key: NewProjectScreen.nameKey,
              controller: _name,
              decoration: InputDecoration(labelText: words.projectsName),
            ),
            const SizedBox(height: 16),
            TextField(
              key: NewProjectScreen.descriptionKey,
              controller: _description,
              minLines: 2,
              maxLines: 6,
              maxLength: Project.descriptionMaxLength,
              decoration: InputDecoration(labelText: words.projectsDescription),
            ),
            const SizedBox(height: 16),
            InkWell(
              key: NewProjectScreen.startDateKey,
              onTap: _pickStartDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: words.projectsStartDate,
                  suffixIcon: Icon(Icons.calendar_today_outlined, key: NewProjectScreen.startDateKey.icon),
                ),
                child: Text(formatDate(_startDate), key: NewProjectScreen.startDateKey.label),
              ),
            ),
            const SizedBox(height: 24),
            TypedNames(
              names: _units,
              heading: words.projectsUnits,
              label: words.projectsUnitName,
              addLabel: words.projectsAddUnit,
              headingKey: NewProjectScreen.unitsHeadingKey,
              fieldKey: NewProjectScreen.unitNameKey,
              addKey: NewProjectScreen.addUnitKey,
              rowKey: NewProjectScreen.unitKey,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 24),
            TypedNames(
              names: _partners,
              heading: words.partnersTitle,
              label: words.partnersName,
              addLabel: words.partnersNew,
              headingKey: NewProjectScreen.partnersHeadingKey,
              fieldKey: NewProjectScreen.partnerNameKey,
              addKey: NewProjectScreen.addPartnerKey,
              rowKey: NewProjectScreen.partnerKey,
              onChanged: () => setState(() {}),
            ),
            if (!widget.isPublic) ...[
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                key: NewProjectScreen.structureSourceKey,
                initialValue: _structureSourceId,
                isExpanded: true,
                decoration: InputDecoration(labelText: words.projectsStructureSource),
                items: [
                  DropdownMenuItem(key: NewProjectScreen.structureSourceOptionKey(''), value: '', child: Text(words.projectsDefaultTemplate, key: NewProjectScreen.structureSourceOptionKey('').label)),
                  for (final project in widget.projects.all.where((project) => project.isApproved)) DropdownMenuItem(key: NewProjectScreen.structureSourceOptionKey(project.id), value: project.id, child: Text(project.name, key: NewProjectScreen.structureSourceOptionKey(project.id).label)),
                ],
                onChanged: (id) => setState(() => _structureSourceId = id ?? ''),
              ),
            ],
            if (widget.isPublic) ...[
              const SizedBox(height: 24),
              Text(words.projectsManager, key: NewProjectScreen.managerHeadingKey, style: theme.textTheme.titleSmall),
              const SizedBox(height: 12),
              TextField(
                key: NewProjectScreen.managerNameKey,
                controller: _managerName,
                decoration: InputDecoration(labelText: words.usersName, helperText: words.usersNameHint),
              ),
              const SizedBox(height: 16),
              TextField(
                key: NewProjectScreen.usernameKey,
                controller: _username,
                autocorrect: false,
                decoration: InputDecoration(labelText: words.usersUsername),
              ),
              const SizedBox(height: 16),
              TextField(
                key: NewProjectScreen.mobileKey,
                controller: _mobile,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: words.usersMobile),
              ),
              const SizedBox(height: 16),
              TextField(
                key: NewProjectScreen.passwordKey,
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(labelText: words.signInPassword),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: NewProjectScreen.submitKey,
              onPressed: _saving ? null : _create,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: Text(words.projectsCreate, key: NewProjectScreen.submitKey.label),
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
