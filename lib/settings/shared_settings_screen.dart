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
import 'my_email_code_dialog.dart';
import 'my_email_dialog.dart';
import '../format/parts_line.dart';
import '../ui/refusal_text.dart';

/// Settings (الإعدادات), all on one screen (Muteb, 9 Nov 2026): who is signed in, the way back to the project list, the default project, the registered projects for the
/// admin, the language (UC-004), the appearance (redix-app #87, #97), how many entries the home shows at a time (redix-app #105), signing in with fingerprint or face (UC-011), «بريدي», the
/// user's own email changed with a code to the new address (redix-api #127, AC-10.4), the way to change the password (UC-003), and signing out
/// (UC-062), each in its own border (Muteb, 10 Nov 2026: "i like borders for each component"). A project's own screens open from its home.
class SharedSettingsScreen extends StatefulWidget {
  /// The screen for the user signed in through [session], opened from [project], whose [projects] the default is chosen among, switching [language] and the mode kept in
  /// [localConfig].
  const SharedSettingsScreen({super.key, required this.session, required this.projects, required this.project, required this.language, required this.localConfig});

  /// The language choice it changes.
  final AppLanguage language;

  /// This phone's choices, where the appearance and the entries shown are kept.
  final LocalConfig localConfig;

  /// The session that says who is signed in and what they may do, and that it signs out of.
  final Session session;

  /// The user's projects, among which the default is chosen.
  final Projects projects;

  /// The project it was opened from, whose role name shows under the user's name; [Project.none] from the project list.
  final Project project;

  /// The screen's route.
  static const path = '/shared-settings';

  /// Who is signed in: their name over the name they sign in with and, opened from a project, what they are called there.
  static const whoKey = Key('sharedSettings.who');

  /// What Settings shows under its title, which scrolls.
  static const bodyKey = Key('sharedSettings.body');

  /// The way back to the project list.
  static const switchProjectKey = Key('sharedSettings.switchProject');

  /// The way into the registered projects, for whoever approves them.
  static const registeredKey = Key('sharedSettings.registered');

  /// The way into the choice of the default project.
  static const defaultProjectKey = Key('sharedSettings.defaultProject');

  /// The heading over the choice of the language.
  static const languageKey = Key('sharedSettings.language');

  /// The heading over the choice of the appearance.
  static const appearanceKey = Key('sharedSettings.appearance');

  /// The choice of the appearance for this phone: System, Light or Dark.
  static const themeChoiceKey = Key('sharedSettings.themeChoice');

  /// The System choice, light or dark as the phone is.
  static const themeSystemKey = Key('sharedSettings.themeSystem');

  /// The Light choice.
  static const themeLightKey = Key('sharedSettings.themeLight');

  /// The Dark choice.
  static const themeDarkKey = Key('sharedSettings.themeDark');

  /// The row of how many entries the home shows at a time (redix-app #105).
  static const entriesShownKey = Key('sharedSettings.entriesShown');

  /// The choice of that number, from 5 to 20.
  static const entriesShownChoiceKey = Key('sharedSettings.entriesShownChoice');

  /// The number [count] among the choices.
  static Key entriesShownOptionKey(int count) => Key('sharedSettings.entriesShown.$count');

  /// The switch that turns fingerprint or face on and off for this phone.
  static const biometricsKey = Key('sharedSettings.biometrics');

  /// The line that says why fingerprint or face did not change.
  static const biometricsMessageKey = Key('sharedSettings.biometricsMessage');

  /// «بريدي»: the user's email, and the way to change it (redix-api #127, AC-10.4).
  static const myEmailKey = Key('sharedSettings.myEmail');

  /// The new address, in «بريدي»'s first step.
  static const myEmailFieldKey = Key('sharedSettings.myEmailField');

  /// The sentence naming the address the code went to, in «بريدي»'s second step.
  static const myEmailSentToKey = Key('sharedSettings.myEmailSentTo');

  /// The code, in «بريدي»'s second step.
  static const myEmailCodeKey = Key('sharedSettings.myEmailCode');

  /// The way into the password change.
  static const changePasswordKey = Key('sharedSettings.changePassword');

  /// The row that signs out, after asking.
  static const signOutKey = Key('sharedSettings.signOut');

  @override
  State<SharedSettingsScreen> createState() => _SharedSettingsScreenState();
}

class _SharedSettingsScreenState extends State<SharedSettingsScreen> {
  var _biometricsMessage = '';

  /// Nothing waits on the prompt, because a cancelled one may never answer: the switch can always be tapped again.
  Future<void> _setBiometrics(bool on) async {
    final refusal = await widget.session.setBiometrics(on: on, words: Words.of(context));
    if (mounted) {
      setState(() => _biometricsMessage = refusal);
    }
  }

  /// The new address first; once its code is sent, the code (AC-10.4).
  Future<void> _changeMyEmail() async {
    var sentTo = '';
    await showDialog<void>(context: context, builder: (_) => MyEmailDialog(session: widget.session, onSent: (email) => sentTo = email));
    if (sentTo.isNotEmpty && mounted) {
      await showDialog<void>(context: context, builder: (_) => MyEmailCodeDialog(session: widget.session, email: sentTo));
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
      appBar: AppBar(title: Text(words.sharedSettingsTitle, key: ScreenTitle.titleKey)),
      body: ListenableBuilder(
        listenable: Listenable.merge([session, widget.projects, widget.localConfig]),
        builder: (context, _) => ListView(
          key: SharedSettingsScreen.bodyKey,
          padding: ApiListBody.padding,
          children: [
            _bordered([
              ListTile(
                key: SharedSettingsScreen.whoKey,
                leading: Icon(Icons.account_circle_outlined, key: SharedSettingsScreen.whoKey.icon),
                title: Text(session.displayName, key: SharedSettingsScreen.whoKey.title),
                subtitle: Text(partsLine([session.username, widget.projects.latest(widget.project).roleName]), key: SharedSettingsScreen.whoKey.subtitle),
              ),
            ]),
            _row(SharedSettingsScreen.switchProjectKey, Icons.swap_horiz, words.sharedSettingsSwitchProject, () => context.push(ProjectsScreen.path)),
            _row(SharedSettingsScreen.defaultProjectKey, Icons.star_outline, words.sharedSettingsDefaultProject, () => DefaultProjectSheet.show(context, session, widget.projects)),
            if (session.may(Permission.approveProjects))
              _row(SharedSettingsScreen.registeredKey, Icons.approval_outlined, words.registeredTitle, () => context.push(RegisteredProjectsScreen.path)),
            _bordered([
              ListTile(
                key: SharedSettingsScreen.languageKey,
                leading: Icon(Icons.language, key: SharedSettingsScreen.languageKey.icon),
                title: Text(words.myAccountLanguage, key: SharedSettingsScreen.languageKey.title),
              ),
              Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: LanguageSwitch(language: widget.language)),
            ]),
            _bordered([
              ListTile(
                key: SharedSettingsScreen.appearanceKey,
                leading: Icon(Icons.dark_mode_outlined, key: SharedSettingsScreen.appearanceKey.icon),
                title: Text(words.sharedSettingsAppearance, key: SharedSettingsScreen.appearanceKey.title),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SegmentedButton<ThemeMode>(
                  key: SharedSettingsScreen.themeChoiceKey,
                  segments: [
                    ButtonSegment(value: ThemeMode.system, label: Text(words.sharedSettingsThemeSystem, key: SharedSettingsScreen.themeSystemKey)),
                    ButtonSegment(value: ThemeMode.light, label: Text(words.sharedSettingsThemeLight, key: SharedSettingsScreen.themeLightKey)),
                    ButtonSegment(value: ThemeMode.dark, label: Text(words.sharedSettingsThemeDark, key: SharedSettingsScreen.themeDarkKey)),
                  ],
                  selected: {widget.localConfig.themeMode},
                  onSelectionChanged: (chosen) => widget.localConfig.chooseThemeMode(chosen.single),
                ),
              ),
            ]),
            _bordered([
              ListTile(
                key: SharedSettingsScreen.entriesShownKey,
                leading: Icon(Icons.format_list_numbered, key: SharedSettingsScreen.entriesShownKey.icon),
                title: Text(words.sharedSettingsEntriesShown, key: SharedSettingsScreen.entriesShownKey.title),
                subtitle: Text(words.sharedSettingsEntriesShownHint, key: SharedSettingsScreen.entriesShownKey.subtitle),
                trailing: DropdownButton<int>(
                  key: SharedSettingsScreen.entriesShownChoiceKey,
                  value: widget.localConfig.entriesShown,
                  items: [
                    for (final count in LocalConfig.entriesShownChoices)
                      DropdownMenuItem(key: SharedSettingsScreen.entriesShownOptionKey(count), value: count, child: Text('$count', key: SharedSettingsScreen.entriesShownOptionKey(count).title)),
                  ],
                  selectedItemBuilder: (_) => [for (final count in LocalConfig.entriesShownChoices) Text('$count')],
                  onChanged: (count) => widget.localConfig.chooseEntriesShown(count ?? widget.localConfig.entriesShown),
                ),
              ),
            ]),
            _bordered([
              SwitchListTile(
                key: SharedSettingsScreen.biometricsKey,
                secondary: Icon(Icons.fingerprint, key: SharedSettingsScreen.biometricsKey.icon),
                title: Text(words.biometricsSignIn, key: SharedSettingsScreen.biometricsKey.title),
                subtitle: Text(words.biometricsHint, key: SharedSettingsScreen.biometricsKey.subtitle),
                value: session.usesBiometrics,
                onChanged: _setBiometrics,
              ),
              if (_biometricsMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: refusalText(context, words.text(_biometricsMessage), SharedSettingsScreen.biometricsMessageKey),
                ),
            ]),
            _bordered([
              ListTile(
                key: SharedSettingsScreen.myEmailKey,
                leading: Icon(Icons.alternate_email, key: SharedSettingsScreen.myEmailKey.icon),
                title: Text(words.settingsMyEmail, key: SharedSettingsScreen.myEmailKey.title),
                subtitle: Text(session.email, key: SharedSettingsScreen.myEmailKey.subtitle),
                trailing: Icon(Icons.chevron_right, key: SharedSettingsScreen.myEmailKey.trailing),
                onTap: _changeMyEmail,
              ),
            ]),
            _row(SharedSettingsScreen.changePasswordKey, Icons.lock_outline, words.myAccountChangePassword, () => context.push(ChangePasswordScreen.path)),
            _bordered([
              ListTile(
                key: SharedSettingsScreen.signOutKey,
                iconColor: AppColor.refusal.of(context),
                textColor: AppColor.refusal.of(context),
                leading: Icon(Icons.logout, key: SharedSettingsScreen.signOutKey.icon),
                title: Text(words.myAccountSignOut, key: SharedSettingsScreen.signOutKey.title),
                onTap: _askToSignOut,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
