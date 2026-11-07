import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/projects/new_project_screen.dart';

import '../app_harness.dart';

void main() {
  Future<FakeApi> openForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(2400, 7200);
    addTearDown(tester.view.reset);
    final api = FakeApi();
    await pumpRedix(tester, api);
    await tester.ensureVisible(find.byKey(SignInScreen.registerKey));
    await act(tester, api, () => tester.tap(find.byKey(SignInScreen.registerKey)));
    return api;
  }

  Future<void> fillAndSend(WidgetTester tester, FakeApi api, {String mobile = '0500000000'}) => act(tester, api, () async {
    await tester.enterText(find.byKey(NewProjectScreen.nameKey), 'غصون 8');
    await tester.enterText(find.byKey(NewProjectScreen.unitNameKey), 'الفلة الغربية');
    await tester.enterText(find.byKey(NewProjectScreen.managerNameKey), 'ريم');
    await tester.enterText(find.byKey(NewProjectScreen.usernameKey), 'reem');
    await tester.enterText(find.byKey(NewProjectScreen.mobileKey), mobile);
    await tester.enterText(find.byKey(NewProjectScreen.passwordKey), 'Chosen-pass-1');
    await tester.ensureVisible(find.byKey(NewProjectScreen.submitKey));
    await tester.tap(find.byKey(NewProjectScreen.submitKey));
  });

  String typed(WidgetTester tester, Key key) => tester.widget<TextField>(find.byKey(key)).controller!.text;

  testWidgets('a mobile typed in Arabic digits is sent in Western digits', (tester) async {
    final api = await openForm(tester);

    await fillAndSend(tester, api, mobile: '٠٥٠٠٠٠٠٠٠٠');

    expect(api.sentRegistrations.single.$2['mobile'], '0500000000');
  });

  testWidgets('the sign-in page leads to the form, with no session', (tester) async {
    await openForm(tester);

    expect(tester.widget<Text>(find.byKey(NewProjectScreen.hintKey)).data, 'en register.hint');
    expect(find.byKey(NewProjectScreen.managerNameKey), findsOneWidget);
    expect(find.byKey(NewProjectScreen.passwordKey), findsOneWidget);
  });

  testWidgets('the password is hidden, since it is theirs', (tester) async {
    await openForm(tester);

    expect(tester.widget<TextField>(find.byKey(NewProjectScreen.passwordKey)).obscureText, isTrue);
  });

  testWidgets('sending returns to sign-in and says it is waiting', (tester) async {
    final api = await openForm(tester);

    await fillAndSend(tester, api);

    final (path, body) = api.sentRegistrations.single;
    expect(path, '/projects/register');
    expect(body['name'], 'غصون 8');
    expect(body['units'], ['الفلة الغربية']);
    expect((body['displayName'], body['username'], body['mobile'], body['password']), ('ريم', 'reem', '0500000000', 'Chosen-pass-1'));
    expect(find.byKey(SignInScreen.usernameKey), findsOneWidget);
    expect(find.text('en register.sent'), findsOneWidget);
  });

  testWidgets('R5: the description written when registering goes with the project', (tester) async {
    final api = await openForm(tester);

    await tester.enterText(find.byKey(NewProjectScreen.descriptionKey), 'ثلاث فلل في حي الياسمين.');
    await fillAndSend(tester, api);

    expect(api.sentRegistrations.single.$2['description'], 'ثلاث فلل في حي الياسمين.');
  });

  testWidgets('R10: a description refused as too long says so and stays', (tester) async {
    final api = await openForm(tester);
    await tester.enterText(find.byKey(NewProjectScreen.descriptionKey), 'ثلاث فلل');

    api.registrationAnswer = (status: 400, code: 'invalidDescription');
    await fillAndSend(tester, api);

    expect(tester.widget<Text>(find.byKey(NewProjectScreen.messageKey)).data, 'en register.invalidDescription');
    expect(typed(tester, NewProjectScreen.descriptionKey), 'ثلاث فلل');
  });

  testWidgets('a refusal stays on the form with what was typed', (tester) async {
    final api = await openForm(tester);

    api.registrationAnswer = (status: 409, code: 'usernameTaken');
    await fillAndSend(tester, api);

    expect(tester.widget<Text>(find.byKey(NewProjectScreen.messageKey)).data, 'en register.usernameTaken');
    expect(typed(tester, NewProjectScreen.usernameKey), 'reem');
  });

  testWidgets('too many tries say so', (tester) async {
    final api = await openForm(tester);

    api.registrationAnswer = (status: 429, code: '');
    await fillAndSend(tester, api);

    expect(tester.widget<Text>(find.byKey(NewProjectScreen.messageKey)).data, 'en register.tooManyTries');
  });

  testWidgets('without a network the form says so, and nothing typed is lost', (tester) async {
    final api = await openForm(tester);

    api.online = false;
    await fillAndSend(tester, api);

    expect(tester.widget<Text>(find.byKey(NewProjectScreen.messageKey)).data, 'en register.noConnection');
    expect(typed(tester, NewProjectScreen.nameKey), 'غصون 8');
  });
}
