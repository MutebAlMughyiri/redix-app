import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../auth/change_password_screen.dart';
import '../auth/permission.dart';
import '../auth/session.dart';
import '../config/local_config.dart';
import '../projects/project.dart';
import '../projects/projects.dart';
import '../projects/projects_screen.dart';
import '../projects/registered_projects_screen.dart';
import '../ui/api_list_body.dart';
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
/// admin, the language (UC-004), the appearance (redix-app #87, #97), signing in with fingerprint or face (UC-011), the way to change the password (UC-003), and signing out
/// (UC-062), each in its own border (Muteb, 10 Nov 2026: "i like borders for each component"). A project's own screens open from its home.
class GeneralSettingsScreen extends StatefulWidget {
  /// The screen for the user signed in through [session], opened from [project], whose [projects] the default is chosen among, switching [language] and the mode kept in
  /// [localConfig].
  const GeneralSettingsScreen({super.key, required this.session, required this.projects, required this.project, required this.language, required this.localConfig});

  /// The language choice it changes.
  final AppLanguage language;

  /// This phone's choices, where the appearance is kept.
  final LocalConfig localConfig;

  /// The session that says who is signed in and what they may do, and that it signs out of.
  final Session session;

  /// The user's projects, among which the default is chosen.
  final Projects projects;

  /// The project it was opened from, whose role name shows under the user's name; [Project.none] from the project list.
  final Project project;

  /// The screen's route.
  static const path = '/general-settings';

  /// Who is signed in: their name over the name they sign in with and, opened from a project, what they are called there.
  static const whoKey = Key('generalSettings.who');

  /// The way back to the project list.
  static const switchProjectKey = Key('generalSettings.switchProject');

  /// The way into the registered projects, for whoever approves them.
  static const registeredKey = Key('generalSettings.registered');

  /// The way into the choice of the default project.
  static const defaultProjectKey = Key('generalSettings.defaultProject');

  /// The heading over the choice of the language.
  static const languageKey = Key('generalSettings.language');

  /// The heading over the choice of the appearance.
  static const appearanceKey = Key('generalSettings.appearance');

  /// The choice of the appearance for this phone: System, Light or Dark.
  static const themeChoiceKey = Key('generalSettings.themeChoice');

  /// The System choice, light or dark as the phone is.
  static const themeSystemKey = Key('generalSettings.themeSystem');

  /// The Light choice.
  static const themeLightKey = Key('generalSettings.themeLight');

  /// The Dark choice.
  static const themeDarkKey = Key('generalSettings.themeDark');

  /// The switch that turns fingerprint or face on and off for this phone.
  static const biometricsKey = Key('generalSettings.biometrics');

  /// The line that says why fingerprint or face did not change.
  static const biometricsMessageKey = Key('generalSettings.biometricsMessage');

  /// The way into the password change.
  static const changePasswordKey = Key('generalSettings.changePassword');

  /// The row that signs out, after asking.
  static const signOutKey = Key('generalSettings.signOut');

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
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

  /// One component of the screen, in its own border, as the rows of every list in the app.
  Widget _bordered(List<Widget> parts) => Card.outlined(
    margin: const EdgeInsets.only(bottom: 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: parts),
  );

  Widget _row(Key key, IconData icon, String title, VoidCallback onTap) => _bordered([
    ListTile(key: key, leading: Icon(icon, key: key.icon), title: Text(title, key: key.title), trailing: Icon(Icons.chevron_right, key: key.trailing), onTap: onTap),
  ]);

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final session = widget.session;
    return Scaffold(
      appBar: AppBar(title: Text(words.generalSettingsTitle, key: ScreenTitle.titleKey)),
      body: ListenableBuilder(
        listenable: Listenable.merge([session, widget.projects, widget.localConfig]),
        builder: (context, _) => ListView(
          padding: ApiListBody.padding,
          children: [
            _bordered([
              ListTile(
                key: GeneralSettingsScreen.whoKey,
                leading: Icon(Icons.account_circle_outlined, key: GeneralSettingsScreen.whoKey.icon),
                title: Text(session.displayName, key: GeneralSettingsScreen.whoKey.title),
                subtitle: Text(partsLine([session.username, widget.projects.latest(widget.project).roleName]), key: GeneralSettingsScreen.whoKey.subtitle),
              ),
            ]),
            _row(GeneralSettingsScreen.switchProjectKey, Icons.swap_horiz, words.generalSettingsSwitchProject, () => context.go(ProjectsScreen.path)),
            _row(GeneralSettingsScreen.defaultProjectKey, Icons.star_outline, words.generalSettingsDefaultProject, () => DefaultProjectSheet.show(context, session, widget.projects)),
            if (session.may(Permission.approveProjects))
              _row(GeneralSettingsScreen.registeredKey, Icons.approval_outlined, words.registeredTitle, () => context.push(RegisteredProjectsScreen.path)),
            _bordered([
              ListTile(
                key: GeneralSettingsScreen.languageKey,
                leading: Icon(Icons.language, key: GeneralSettingsScreen.languageKey.icon),
                title: Text(words.myAccountLanguage, key: GeneralSettingsScreen.languageKey.title),
              ),
              Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: LanguageSwitch(language: widget.language)),
            ]),
            _bordered([
              ListTile(
                key: GeneralSettingsScreen.appearanceKey,
                leading: Icon(Icons.dark_mode_outlined, key: GeneralSettingsScreen.appearanceKey.icon),
                title: Text(words.generalSettingsAppearance, key: GeneralSettingsScreen.appearanceKey.title),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SegmentedButton<ThemeMode>(
                  key: GeneralSettingsScreen.themeChoiceKey,
                  segments: [
                    ButtonSegment(value: ThemeMode.system, label: Text(words.generalSettingsThemeSystem, key: GeneralSettingsScreen.themeSystemKey)),
                    ButtonSegment(value: ThemeMode.light, label: Text(words.generalSettingsThemeLight, key: GeneralSettingsScreen.themeLightKey)),
                    ButtonSegment(value: ThemeMode.dark, label: Text(words.generalSettingsThemeDark, key: GeneralSettingsScreen.themeDarkKey)),
                  ],
                  selected: {widget.localConfig.themeMode},
                  onSelectionChanged: (chosen) => widget.localConfig.chooseThemeMode(chosen.single),
                ),
              ),
            ]),
            _bordered([
              SwitchListTile(
                key: GeneralSettingsScreen.biometricsKey,
                secondary: Icon(Icons.fingerprint, key: GeneralSettingsScreen.biometricsKey.icon),
                title: Text(words.biometricsSignIn, key: GeneralSettingsScreen.biometricsKey.title),
                subtitle: Text(words.biometricsHint, key: GeneralSettingsScreen.biometricsKey.subtitle),
                value: session.usesBiometrics,
                onChanged: _setBiometrics,
              ),
              if (_biometricsMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: refusalText(context, words.text(_biometricsMessage), GeneralSettingsScreen.biometricsMessageKey),
                ),
            ]),
            _row(GeneralSettingsScreen.changePasswordKey, Icons.lock_outline, words.myAccountChangePassword, () => context.push(ChangePasswordScreen.path)),
            _bordered([
              ListTile(
                key: GeneralSettingsScreen.signOutKey,
                iconColor: AppColor.refusal.of(context),
                textColor: AppColor.refusal.of(context),
                leading: Icon(Icons.logout, key: GeneralSettingsScreen.signOutKey.icon),
                title: Text(words.myAccountSignOut, key: GeneralSettingsScreen.signOutKey.title),
                onTap: _askToSignOut,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
