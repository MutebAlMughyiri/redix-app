import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/patrol.dart';
import 'package:redix/auth/session.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/main.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/settings/settings_screen.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/words/app_language.dart';
import 'package:redix/words/words.dart';

/// The steps every case is written in, each finding what it needs by its exact key.
extension Steps on PatrolIntegrationTester {
  /// The words of the screen showing now.
  Words get words => Words.of(tester.element(find.byType(Scaffold).first));

  /// Whether the phone's back has somewhere to go inside the app.
  bool get canGoBack => GoRouter.of(tester.element(find.byType(Scaffold).first)).canPop();

  /// Starts the app as the phone would, from what it keeps.
  Future<void> startApp() async {
    final session = Session();
    final language = AppLanguage();
    await session.restore();
    await language.restore();
    await pumpWidgetAndSettle(RedixApp(session: session, language: language));
  }

  /// Closes the app and starts it again, for what must be kept for the next start.
  Future<void> restartApp() async {
    await pumpWidget(const SizedBox());
    await startApp();
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

  /// Signs out from the project list, through Settings, answering the question with yes.
  Future<void> signOutFromTheList() async {
    await this(ProjectsScreen.settingsKey).tap();
    await goTo(this(SettingsScreen.signOutKey));
    await this(SettingsScreen.signOutKey).tap();
    await this(ConfirmDialog.confirmKey).tap();
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

  /// Waits until the text [key] says [text].
  Future<void> says(Key key, String text) async {
    final finder = find.byKey(key);
    await until(() => finder.evaluate().isNotEmpty && tester.widget<Text>(finder).data == text);
    expect(tester.widget<Text>(finder).data, text);
  }

  /// Brings [finder] into view, above or below what shows now: one not built yet is further down the list.
  Future<void> goTo(PatrolFinder finder) async {
    await pumpAndSettle();
    if (finder.evaluate().isEmpty) {
      await finder.scrollTo();
      return;
    }
    if (finder.hitTestable().evaluate().isEmpty) {
      await tester.ensureVisible(finder);
      await pumpAndSettle();
    }
  }

  /// Waits for [finder], and brings it into view: a phone 360 points wide shows less than the emulator.
  Future<void> reach(PatrolFinder finder) async {
    await finder.waitUntilExists();
    await pumpAndSettle();
    if (finder.hitTestable().evaluate().isEmpty) {
      await tester.ensureVisible(finder);
      await pumpAndSettle();
    }
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
