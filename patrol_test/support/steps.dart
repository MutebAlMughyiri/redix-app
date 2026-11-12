import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/patrol.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:redix/auth/change_password_screen.dart';
import 'package:redix/auth/session.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/main.dart';
import 'package:redix/projects/member_picker.dart';
import 'package:redix/projects/project_settings_card.dart';
import 'package:redix/projects/project_info_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/shared_settings_screen.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/ui/name_dialog.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/refusal_snack_bar.dart';
import 'package:redix/ui/swipe_to_remove.dart';
import 'package:redix/words/app_language.dart';
import 'package:redix/words/language_switch.dart';
import 'package:redix/words/words.dart';

import 'given.dart';
import 'made_up_invoice.dart';
import 'package:redix/config/local_config.dart';

/// The app's session while it is open, and whether it is open: every case of a class shares the one open app.
var _session = Session();
var _appIsOpen = false;
var _localConfig = LocalConfig();

/// Every widget whose key starts with [start].
Finder keyStartingWith(String start) => find.byWidgetPredicate((widget) => widget.key is ValueKey<String> && (widget.key! as ValueKey<String>).value.startsWith(start));

/// The steps every case is written in, each finding what it needs by its exact key.
extension Steps on PatrolIntegrationTester {
  /// The words of the screen showing now.
  Words get words => Words.of(tester.element(find.byType(Scaffold).first));

  /// Whether the phone's back has somewhere to go inside the app.
  bool get canGoBack => GoRouter.of(tester.element(find.byType(Scaffold).first)).canPop();

  /// Leaves the app on the sign-in screen, ready for the next case: the first case of a class opens the app, and every other one signs out of the one already open.
  Future<void> startApp() async {
    if (_appIsOpen) {
      await _backToSignIn();
    } else {
      await _open();
    }
    if (!_localConfig.showsHomeDetails) {
      await _localConfig.toggleHomeDetails();
    }
    await _localConfig.chooseThemeMode(ThemeMode.light);
    await pumpAndSettle();
  }

  /// Whether the screen showing now is drawn in the dark mode.
  bool get isDark => Theme.of(tester.element(find.byType(Scaffold).first)).brightness == Brightness.dark;

  /// Whether the phone's own setting is dark, whatever the app is drawn in.
  bool get phoneIsDark => MediaQuery.platformBrightnessOf(tester.element(find.byType(Scaffold).first)) == Brightness.dark;

  /// Closes the app's screens and starts it again, for what must be kept for the next start.
  Future<void> restartApp() => _open();

  /// Forgets all the phone keeps of the app's settings and words, as a first start finds it.
  Future<void> forgetTheSettings() async {
    await (await SharedPreferences.getInstance()).clear();
  }

  Future<void> _open() async {
    if (_appIsOpen) {
      await pumpWidget(const SizedBox());
    }
    _session = Session();
    final language = AppLanguage();
    await _session.restore();
    await language.restore();
    _localConfig = LocalConfig();
    await _localConfig.restore();
    await pumpWidgetAndSettle(RedixApp(session: _session, language: language, localConfig: _localConfig, capture: CameraWithAPicture()));
    _appIsOpen = true;
  }

  /// Goes to Settings and signs out with its button, whatever screen the last case stopped on, and turns the app back to English if the case turned it to Arabic.
  Future<void> _backToSignIn() async {
    final context = tester.element(find.byType(Scaffold).first);
    ScaffoldMessenger.of(context).clearSnackBars();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    GoRouter.of(context).go(SharedSettingsScreen.path);
    await pumpAndSettle();
    final signIn = find.byKey(SignInScreen.usernameKey);
    final signOut = find.byKey(SharedSettingsScreen.signOutKey);
    final changePassword = find.byKey(ChangePasswordScreen.currentKey);
    await until(() => signIn.evaluate().isNotEmpty || changePassword.evaluate().isNotEmpty || find.byKey(SharedSettingsScreen.whoKey).evaluate().isNotEmpty);
    if (signIn.evaluate().isEmpty && changePassword.evaluate().isEmpty) {
      await goTo(this(signOut));
      await signOutFromSettings();
    }
    if (changePassword.evaluate().isNotEmpty) {
      await _session.signOut();
    }
    await reach(this(signIn));
    if (Directionality.of(tester.element(signIn)) == TextDirection.rtl) {
      await this(LanguageSwitch.englishKey).tap();
      await until(() => Directionality.of(tester.element(signIn)) == TextDirection.ltr);
    }
  }

  /// Types [username] and [password] on the sign-in screen and sends them, returning once the API has answered.
  Future<void> signIn(String username, String password) async {
    await reach(this(SignInScreen.usernameKey));
    await this(SignInScreen.usernameKey).enterText(username);
    await this(SignInScreen.passwordKey).enterText(password);
    await goTo(this(SignInScreen.submitKey));
    await this(SignInScreen.submitKey).tap();
    await answered(SignInScreen.submitKey);
  }

  /// Starts the app and signs [person] in, standing on the project list.
  Future<void> onTheList(Person person) async {
    await startApp();
    await signIn(person.username, person.password);
    await reach(this(ProjectsScreen.cardKey(person.projectId)));
  }

  /// Opens the project [projectId] from the list, standing on its home.
  Future<void> openProject(String projectId) async {
    await reach(this(ProjectsScreen.cardKey(projectId)));
    await this(ProjectsScreen.cardKey(projectId)).tap();
    await reach(this(HomeScreen.titleKey));
  }

  /// Signs [person] in and stands on the home of their project.
  Future<void> onTheHome(Person person) async {
    await onTheList(person);
    await openProject(person.projectId);
  }

  /// Signs [person] in and stands on More info of their project.
  Future<void> onMoreInfo(Person person) async {
    await onTheHome(person);
    await tapOn(HomeScreen.projectInfoKey(person.projectId));
    await reach(this(ProjectInfoScreen.nameKey));
  }

  /// Signs [person] in and opens what [key] leads to from the home of their project.
  Future<void> fromTheHome(Person person, Key key) async {
    await onTheHome(person);
    await tapOn(key);
  }

  /// Signs [person] in and opens the screen at [path] from the project's home, as a Project settings button would, for a screen whose button is grayed until a later
  /// release while its work stays (Muteb, 12 Nov 2026): the VAT refund.
  Future<void> openPathFromTheHome(Person person, String path) async {
    await onTheHome(person);
    final card = find.byType(ProjectSettingsCard);
    await this(card).waitUntilExists();
    unawaited(GoRouter.of(tester.element(card)).push(path, extra: tester.widget<ProjectSettingsCard>(card).project));
    await pumpAndSettle();
  }

  /// Opens the menu [menu] and chooses [item].
  Future<void> menuChoice(Key menu, Key item) async {
    await tapOn(menu);
    await reach(this(item));
    await this(item).tap();
  }

  /// Types [name] into the dialog showing now and saves it.
  Future<void> saveName(String name) async {
    await reach(this(NameDialog.nameKey));
    await this(NameDialog.nameKey).enterText(name);
    await this(ChangeDialog.saveKey).tap();
  }

  /// Waits for the message of [wordKey] at the bottom of the screen, and checks it says [text].
  Future<void> messageSays(String wordKey, String text) => says(messageKeyOf(wordKey).label, text);

  /// Waits for the message of [wordKey] at the bottom of the screen.
  Future<void> messageShows(String wordKey) => this(messageKeyOf(wordKey).label).waitUntilExists();

  /// Signs out from the home of the project [projectId], through Settings.
  Future<void> signOutFromTheHome(String projectId) async {
    await this(HomeScreen.sharedSettingsKey(projectId)).tap();
    await signOutFromSettings();
  }

  /// Signs out from the home and signs [person] in, standing on the home of their project.
  Future<void> switchPersonTo(Person person, {required String projectId}) async {
    await signOutFromTheHome(projectId);
    await signIn(person.username, person.password);
    await openProject(person.projectId);
  }

  /// How far down the screen [key] is.
  double topOf(Key key) => tester.getTopLeft(find.byKey(key)).dy;

  /// Drags the handle [handle] down by [distance], as reordering does.
  Future<void> dragDown(Key handle, {double distance = 160}) async {
    await tester.timedDrag(find.byKey(handle), Offset(0, distance), const Duration(milliseconds: 600));
    await pumpAndSettle();
  }

  /// Whether the tick [key] of a permission is ticked.
  bool isTicked(Key key) => tester.widget<CheckboxListTile>(find.byKey(key.body)).value!;

  /// Whether the tick [key] of a permission can be changed.
  bool canTick(Key key) => tester.widget<CheckboxListTile>(find.byKey(key.body)).onChanged != null;

  /// Signs out from Settings, answering the question with yes.
  Future<void> signOutFromSettings() async {
    await tapOn(SharedSettingsScreen.signOutKey);
    await this(ConfirmDialog.confirmKey).tap();
  }

  /// Signs out from the project list, through Settings.
  Future<void> signOutFromTheList() async {
    await this(ProjectsScreen.sharedSettingsKey).tap();
    await signOutFromSettings();
  }

  /// Waits until [isTrue], because what a case waits for changes only once the API has answered.
  Future<void> until(bool Function() isTrue) async {
    for (var tries = 0; tries < 60 && !isTrue(); tries++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await pump();
    }
  }

  /// Waits until the button [key] works again or has left the screen, which is how a form shows the API has answered.
  Future<void> answered(Key key) async {
    final button = find.byKey(key);
    await until(() => button.evaluate().isEmpty || tester.widget<ButtonStyleButton>(button).onPressed != null);
  }

  /// Waits until the text [key] holds [part], and checks it does.
  Future<void> saysContaining(Key key, String part) async {
    final finder = find.byKey(key);
    await until(() => finder.evaluate().isNotEmpty && (tester.widget<Text>(finder).data ?? '').contains(part));
    expect(tester.widget<Text>(finder).data, contains(part));
  }

  /// Waits until the text [key] says [text].
  Future<void> says(Key key, String text) async {
    final finder = find.byKey(key);
    await until(() => finder.evaluate().isNotEmpty && tester.widget<Text>(finder).data == text);
    expect(tester.widget<Text>(finder).data, text);
  }

  /// Waits until [finder] finds nothing, because a row leaves only once the API has answered.
  Future<void> gone(PatrolFinder finder) async {
    await until(() => finder.evaluate().isEmpty);
    expect(finder, findsNothing);
  }

  /// What the field [key] holds.
  String typed(Key key) => tester.widget<TextField>(find.byKey(key)).controller!.text;

  /// Whether the button [key] can be pressed.
  bool isEnabled(Key key) => switch (tester.widget(find.byKey(key))) {
    final IconButton icon => icon.onPressed != null,
    final widget => (widget as ButtonStyleButton).enabled,
  };

  /// Brings the field [key] into view and types [text] into it.
  Future<void> fill(Key key, String text) async {
    await goTo(this(key));
    await this(key).enterText(text);
  }

  /// Brings [key] into view and taps it.
  Future<void> tapOn(Key key) async {
    await goTo(this(key));
    await this(key).tap();
  }

  /// Opens the [MemberPicker] keyed [pickerKey] and chooses [id] in its list; nobody when that is empty. The open list draws over the closed one, so the last match is tapped.
  Future<void> chooseMember(Key pickerKey, String id) async {
    await tapOn(pickerKey.field);
    await pumpAndSettle();
    await tester.tap(find.byKey(MemberPicker.optionKey(id)).last);
    await pumpAndSettle();
  }

  /// The pages of the home's Project settings, four buttons each, swiped sideways and going round (Muteb, 11 Nov 2026).
  Finder get projectSettingPages => find.descendant(of: find.byType(ProjectSettingsCard), matching: find.byType(PageView));

  /// What brings [finder] into view: the Project settings' card for one of their buttons, since scrolling the button would also turn the pages; else [finder] itself.
  Finder _scrolledFor(Finder finder) => find.descendant(of: projectSettingPages, matching: finder).evaluate().isNotEmpty ? projectSettingPages : finder;

  /// Swipes the home's Project settings one page on, toward the start of the reading line, as a person does.
  Future<void> swipeProjectSettings() async {
    await tester.ensureVisible(projectSettingPages);
    await pumpAndSettle();
    final width = tester.getSize(projectSettingPages).width;
    final rightToLeft = Directionality.of(tester.element(projectSettingPages)) == TextDirection.rtl;
    await tester.drag(projectSettingPages, Offset((rightToLeft ? width : -width) * 0.8, 0));
    await pumpAndSettle();
  }

  /// Swipes the home's Project settings round until [finder] shows; nothing when it shows already or no Project settings are on screen.
  Future<void> _swipeTo(Finder finder) async {
    for (var turn = 0; turn < 4 && finder.evaluate().isEmpty && projectSettingPages.evaluate().isNotEmpty; turn++) {
      await swipeProjectSettings();
    }
  }

  /// Whether any page of the home's Project settings holds the button keyed [key]: looks at every page, as many as their dots, and stands where it stops.
  Future<bool> anyProjectSettingPage(Key key) async {
    final pages = find.byWidgetPredicate((widget) => widget.key is ValueKey<String> && (widget.key! as ValueKey<String>).value.startsWith('home.settingsDot.')).evaluate().length;
    for (var page = 1; page < pages && find.byKey(key).evaluate().isEmpty; page++) {
      await swipeProjectSettings();
    }
    return find.byKey(key).evaluate().isNotEmpty;
  }

  /// The list a step scrolls: the first that scrolls up and down, since the text field of a search line above a list scrolls sideways (redix-app #104).
  Finder get scrolledList => find.byWidgetPredicate((widget) => widget is Scrollable && axisDirectionToAxis(widget.axisDirection) == Axis.vertical).first;

  /// Brings [finder] into view, above or below what shows now: one not built yet is further down the list, or on another page of the Project settings.
  Future<void> goTo(PatrolFinder finder) async {
    await pumpAndSettle();
    await _swipeTo(finder);
    if (finder.evaluate().isEmpty) {
      await finder.scrollTo(view: scrolledList);
      return;
    }
    for (var attempt = 0; attempt < 10 && finder.hitTestable().evaluate().isEmpty; attempt++) {
      await tester.ensureVisible(_scrolledFor(finder));
      await pumpAndSettle();
      if (finder.hitTestable().evaluate().isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    }
  }

  /// Scrolls up to [finder], which a long list stopped building once it was scrolled past.
  Future<void> goUpTo(PatrolFinder finder) async {
    await pumpAndSettle();
    if (finder.evaluate().isEmpty) {
      await finder.scrollTo(view: scrolledList, scrollDirection: AxisDirection.up);
    }
  }

  /// Waits for [finder], and brings it into view: a phone 360 points wide shows less than the emulator.
  Future<void> reach(PatrolFinder finder) async {
    await pumpAndSettle();
    await _swipeTo(finder);
    await finder.waitUntilExists();
    await pumpAndSettle();
    if (finder.hitTestable().evaluate().isEmpty) {
      await tester.ensureVisible(_scrolledFor(finder));
      await pumpAndSettle();
    }
  }

  /// The id in the key of the element whose key starts with [prefix] and that shows [text]: a case names what it makes and learns its id from that name once, then finds it by its key.
  Future<String> idShowing(String prefix, String text) async {
    await pumpAndSettle();
    if (find.text(text).evaluate().isEmpty) {
      await this(find.text(text)).scrollTo(view: scrolledList);
    }
    final keyed = this(find.ancestor(of: find.text(text), matching: keyStartingWith(prefix), matchRoot: true));
    await keyed.waitUntilExists();
    final ids = {for (final element in keyed.evaluate()) (element.widget.key! as ValueKey<String>).value.substring(prefix.length)}.where((id) => !id.contains('.')).toSet();
    expect(ids, hasLength(1), reason: 'one $prefix showing $text');
    return ids.single;
  }

  /// Swipes the row keyed [rowKey] from its end toward its start by [share] of its width, as removing it does, in whichever language the phone reads.
  Future<void> swipeAway(Key rowKey, {double share = 0.8}) async {
    final row = find.byKey(rowKey.swipe);
    await goTo(this(row));
    expectRedBar(rowKey);
    final distance = tester.getSize(row).width * share;
    await tester.drag(row, Offset(Directionality.of(tester.element(row)) == TextDirection.rtl ? distance : -distance, 0));
    await pumpAndSettle();
  }

  /// The row [rowKey], which can be removed, shows its red bar on screen, along the end edge of its card: the right in English, the left in Arabic (redix-app #88).
  void expectRedBar(Key rowKey) {
    const reason = 'a row that can be removed shows its red bar (redix-app #88)';
    final bar = find.byKey(rowKey.bar);
    expect(bar, findsOneWidget, reason: reason);
    final barRect = tester.getRect(bar);
    final cardRect = tester.getRect(find.byKey(rowKey.card));
    final screen = Offset.zero & (tester.view.physicalSize / tester.view.devicePixelRatio);
    final endEdge = Directionality.of(tester.element(bar)) == TextDirection.rtl ? barRect.left - cardRect.left : cardRect.right - barRect.right;
    expect(barRect.width, SwipeToRemove.barWidth, reason: reason);
    expect(barRect.height, greaterThan(0), reason: reason);
    expect(endEdge.abs(), lessThan(1), reason: reason);
    expect(barRect.top >= cardRect.top - 1 && barRect.bottom <= cardRect.bottom + 1, isTrue, reason: reason);
    expect(screen.contains(barRect.center), isTrue, reason: reason);
  }

  /// Pulls the list showing now down, which reads it again.
  Future<void> pullDown() async {
    await tester.fling(scrolledList, const Offset(0, 500), 1200);
    await pumpAndSettle();
  }

  /// Takes a guide's picture with the keyboard closed, because under Patrol it stays up once a field was typed in, even after the field loses focus.
  Future<void> picture(String name) async {
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await pumpAndSettle();
    await takeNativeScreenshot(name);
  }

  /// Goes back a screen with the phone's own back, the keyboard closed first, since while it is open back only closes it.
  Future<void> back() async {
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    await pumpAndSettle();
    await platform.android.pressBack();
    await pumpAndSettle();
  }
}
