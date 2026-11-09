import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/change_password_screen.dart';
import '../auth/permission.dart';
import '../auth/session.dart';
import '../projects/project.dart';
import '../projects/projects.dart';
import '../projects/projects_screen.dart';
import '../projects/registered_projects_screen.dart';
import '../ui/app_color.dart';
import '../ui/confirm_dialog.dart';
import '../ui/part_keys.dart';
import '../ui/screen_title.dart';
import '../words/app_language.dart';
import '../words/language_switch.dart';
import '../words/words.dart';
import 'default_project_sheet.dart';
import '../format/parts_line.dart';
import '../ui/refusal_text.dart';

/// Settings (الإعدادات), all on one screen (Muteb, 9 Nov 2026): who is signed in, the way back to the project list, the default project, the registered projects for the
/// admin, the language (UC-004), signing in with fingerprint or face (UC-011), the way to change the password (UC-003), and signing out (UC-062). A project's own screens
/// open from its home.
class SettingsScreen extends StatefulWidget {
  /// The screen for the user signed in through [session], opened from [project], whose [projects] the default is chosen among, switching [language].
  const SettingsScreen({super.key, required this.session, required this.projects, required this.project, required this.language});

  /// The language choice it changes.
  final AppLanguage language;

  /// The session that says who is signed in and what they may do, and that it signs out of.
  final Session session;

  /// The user's projects, among which the default is chosen.
  final Projects projects;

  /// The project it was opened from, whose role name shows under the user's name; [Project.none] from the project list.
  final Project project;

  /// The screen's route.
  static const path = '/settings';

  /// Who is signed in: their name over the name they sign in with and, opened from a project, what they are called there.
  static const whoKey = Key('settings.who');

  /// The way back to the project list.
  static const switchProjectKey = Key('settings.switchProject');

  /// The way into the registered projects, for whoever approves them.
  static const registeredKey = Key('settings.registered');

  /// The way into the choice of the default project.
  static const defaultProjectKey = Key('settings.defaultProject');

  /// The heading over the choice of the language.
  static const languageKey = Key('settings.language');

  /// The switch that turns fingerprint or face on and off for this phone.
  static const biometricsKey = Key('settings.biometrics');

  /// The line that says why fingerprint or face did not change.
  static const biometricsMessageKey = Key('settings.biometricsMessage');

  /// The way into the password change.
  static const changePasswordKey = Key('settings.changePassword');

  /// The row that signs out, after asking.
  static const signOutKey = Key('settings.signOut');

  /// What signing out means, in the question.
  static const signOutExplainKey = ConfirmDialog.explanationKey;

  /// The button that signs out, in the question.
  static const confirmSignOutKey = ConfirmDialog.confirmKey;

  /// The button that changes nothing, in the question.
  static const cancelSignOutKey = ConfirmDialog.cancelKey;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  var _biometricsMessage = '';

  /// Nothing waits on the prompt, because a cancelled one may never answer: the switch can always be tapped again.
  Future<void> _setBiometrics(bool on) async {
    final refusal = await widget.session.setBiometrics(on: on, words: Words.of(context));
    if (mounted) {
      setState(() => _biometricsMessage = refusal);
    }
  }

  void _askToSignOut() {
    final words = Words.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: words.myAccountSignOutQuestion,
        explanation: words.myAccountSignOutExplain,
        confirmLabel: words.myAccountSignOut,
        onConfirm: widget.session.signOut,
      ),
    );
  }

  Widget _row(Key key, IconData icon, String title, VoidCallback onTap) =>
      ListTile(key: key, leading: Icon(icon, key: key.icon), title: Text(title, key: key.title), trailing: Icon(Icons.chevron_right, key: key.trailing), onTap: onTap);

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final session = widget.session;
    return Scaffold(
      appBar: AppBar(title: Text(words.settingsTitle, key: ScreenTitle.titleKey)),
      body: ListenableBuilder(
        listenable: Listenable.merge([session, widget.projects]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            ListTile(
              key: SettingsScreen.whoKey,
              leading: Icon(Icons.account_circle_outlined, key: SettingsScreen.whoKey.icon),
              title: Text(session.displayName, key: SettingsScreen.whoKey.title),
              subtitle: Text(partsLine([session.username, widget.projects.latest(widget.project).roleName]), key: SettingsScreen.whoKey.subtitle),
            ),
            const Divider(),
            _row(SettingsScreen.switchProjectKey, Icons.swap_horiz, words.settingsSwitchProject, () => context.go(ProjectsScreen.path)),
            _row(SettingsScreen.defaultProjectKey, Icons.star_outline, words.settingsDefaultProject, () => DefaultProjectSheet.show(context, session, widget.projects)),
            if (session.may(Permission.approveProjects))
              _row(SettingsScreen.registeredKey, Icons.approval_outlined, words.registeredTitle, () => context.push(RegisteredProjectsScreen.path)),
            ListTile(
              key: SettingsScreen.languageKey,
              leading: Icon(Icons.language, key: SettingsScreen.languageKey.icon),
              title: Text(words.myAccountLanguage, key: SettingsScreen.languageKey.title),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: LanguageSwitch(language: widget.language)),
            SwitchListTile(
              key: SettingsScreen.biometricsKey,
              secondary: Icon(Icons.fingerprint, key: SettingsScreen.biometricsKey.icon),
              title: Text(words.biometricsSignIn, key: SettingsScreen.biometricsKey.title),
              subtitle: Text(words.biometricsHint, key: SettingsScreen.biometricsKey.subtitle),
              value: session.usesBiometrics,
              onChanged: _setBiometrics,
            ),
            if (_biometricsMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: refusalText(context, words.text(_biometricsMessage), SettingsScreen.biometricsMessageKey),
              ),
            _row(SettingsScreen.changePasswordKey, Icons.lock_outline, words.myAccountChangePassword, () => context.push(ChangePasswordScreen.path)),
            ListTile(
              key: SettingsScreen.signOutKey,
              iconColor: AppColor.refusal.of(context),
              textColor: AppColor.refusal.of(context),
              leading: Icon(Icons.logout, key: SettingsScreen.signOutKey.icon),
              title: Text(words.myAccountSignOut, key: SettingsScreen.signOutKey.title),
              onTap: _askToSignOut,
            ),
          ],
        ),
      ),
    );
  }
}
