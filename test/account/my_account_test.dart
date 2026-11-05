import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/account/my_account_screen.dart';
import 'package:redix/accounts/account.dart';
import 'package:redix/expenses/add_expense_screen.dart';
import 'package:redix/accounts/accounts_screen.dart';
import 'package:redix/auth/change_password_screen.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/contracts/contract.dart';
import 'package:redix/contracts/contracts_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/partners/partners_screen.dart';
import 'package:redix/projects/member_picker.dart';
import 'package:redix/projects/new_project_screen.dart';
import 'package:redix/projects/project.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/projects/registered_projects_screen.dart';
import 'package:redix/settings/payment_methods_screen.dart';
import 'package:redix/settings/settings_screen.dart';
import 'package:redix/structure/apply_to_all_dialog.dart';
import 'package:redix/structure/categories_screen.dart';
import 'package:redix/structure/category.dart';
import 'package:redix/structure/columns.dart';
import 'package:redix/structure/item_columns_screen.dart';
import 'package:redix/structure/subgroups_screen.dart';
import 'package:redix/suppliers/supplier_picker.dart';
import 'package:redix/suppliers/suppliers.dart';
import 'package:redix/suppliers/suppliers_screen.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/users/new_user_screen.dart';
import 'package:redix/users/user_roles_screen.dart';
import 'package:redix/users/users_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_harness.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  TextDirection direction(WidgetTester tester, Key key) => Directionality.of(tester.element(find.byKey(key)));

  Future<void> openMyAccount(WidgetTester tester, FakeApi api) async {
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.settingsKey)));
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.myAccountKey)));
  }

  SwitchListTile biometricsSwitch(WidgetTester tester) => tester.widget<SwitchListTile>(find.byKey(MyAccountScreen.biometricsKey));

  testWidgets('turning on fingerprint or face asks first, then tells the server', (tester) async {
    final api = FakeApi();
    final prompt = FakePrompt();
    await pumpRedix(tester, api, stored: {'session': keptSession}, prompt: prompt);
    await openMyAccount(tester, api);
    expect(biometricsSwitch(tester).value, isFalse);

    await act(tester, api, () => tester.tap(find.byKey(MyAccountScreen.biometricsKey)));

    expect(prompt.shown, 1);
    expect(api.sentBiometrics, [true]);
    expect(biometricsSwitch(tester).value, isTrue);
    expect(find.byKey(MyAccountScreen.biometricsMessageKey), findsNothing);
  });

  testWidgets('a phone with no fingerprint or face stays off, tells the server nothing, and says what to do', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, stored: {'session': keptSession}, prompt: FakePrompt()..fails = true);
    await openMyAccount(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(MyAccountScreen.biometricsKey)));

    expect(api.sentBiometrics, isEmpty);
    expect(biometricsSwitch(tester).value, isFalse);
    expect(text(tester, MyAccountScreen.biometricsMessageKey), 'en biometrics.notAvailable');
  });

  testWidgets('a prompt with no answer leaves the switch off, and it can be tapped again', (tester) async {
    final api = FakeApi();
    final prompt = FakePrompt()..neverAnswers = true;
    await pumpRedix(tester, api, stored: {'session': keptSession}, prompt: prompt);
    await openMyAccount(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(MyAccountScreen.biometricsKey)));
    expect(biometricsSwitch(tester).value, isFalse);

    prompt.neverAnswers = false;
    await act(tester, api, () => tester.tap(find.byKey(MyAccountScreen.biometricsKey)));
    expect(biometricsSwitch(tester).value, isTrue);
  });

  testWidgets('without a network it stays off and says so', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, stored: {'session': keptSession}, prompt: FakePrompt());
    await openMyAccount(tester, api);

    api.online = false;
    await act(tester, api, () => tester.tap(find.byKey(MyAccountScreen.biometricsKey)));

    expect(biometricsSwitch(tester).value, isFalse);
    expect(text(tester, MyAccountScreen.biometricsMessageKey), 'en biometrics.notChanged');
  });

  testWidgets('a refused change stays as it was and says so', (tester) async {
    final api = FakeApi()..biometricsStatus = 403;
    await pumpRedix(tester, api, stored: {'session': keptSession}, prompt: FakePrompt());
    await openMyAccount(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(MyAccountScreen.biometricsKey)));

    expect(biometricsSwitch(tester).value, isFalse);
    expect(text(tester, MyAccountScreen.biometricsMessageKey), 'en biometrics.notChanged');
  });

  testWidgets('turning it off asks nothing', (tester) async {
    final api = FakeApi()..usesBiometrics = true;
    final prompt = FakePrompt();
    await pumpRedix(tester, api, stored: {'session': keptBiometricSession}, prompt: prompt);
    expect(prompt.shown, 1);
    await openMyAccount(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(MyAccountScreen.biometricsKey)));

    expect(prompt.shown, 1);
    expect(api.sentBiometrics, [false]);
    expect(biometricsSwitch(tester).value, isFalse);
  });

  Future<void> choose(WidgetTester tester, FakeApi api, Key language) => act(tester, api, () => tester.tap(find.byKey(language)));

  testWidgets('choosing English on an Arabic phone switches every screen to English, left to right', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, locale: const Locale('ar'), stored: {'session': keptSession});
    await openMyAccount(tester, api);

    await choose(tester, api, MyAccountScreen.englishKey);

    expect(text(tester, MyAccountScreen.englishKey), 'en myAccount.english');
    expect(direction(tester, MyAccountScreen.englishKey), TextDirection.ltr);
    await act(tester, api, tester.pageBack);
    await act(tester, api, tester.pageBack);
    expect(text(tester, ProjectsScreen.titleKey), 'en projects.choose');
    expect(direction(tester, ProjectsScreen.titleKey), TextDirection.ltr);
  });

  testWidgets('the chosen language is kept on the phone and used at the next start', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, locale: const Locale('ar'), stored: {'session': keptSession});
    await openMyAccount(tester, api);
    await choose(tester, api, MyAccountScreen.englishKey);
    final preferences = await SharedPreferences.getInstance();
    final kept = {for (final key in preferences.getKeys()) key: preferences.get(key) ?? ''};

    await tester.pumpWidget(const SizedBox());
    await pumpRedix(tester, FakeApi(), locale: const Locale('ar'), stored: {'session': keptSession}, preferences: kept);

    expect(text(tester, ProjectsScreen.titleKey), 'en projects.choose');
  });

  testWidgets('without a network the language stays and the app says switching needs a network', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, locale: const Locale('ar'), stored: {'session': keptSession});
    await openMyAccount(tester, api);

    api.online = false;
    await choose(tester, api, MyAccountScreen.englishKey);

    expect(text(tester, MyAccountScreen.messageKey), 'ar myAccount.languageNeedsNetwork');
    expect(direction(tester, MyAccountScreen.messageKey), TextDirection.rtl);
    expect((await SharedPreferences.getInstance()).containsKey('language'), isFalse);
  });

  testWidgets('the password change opens from My account and goes back to it', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await openMyAccount(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(MyAccountScreen.changePasswordKey)));
    expect(find.byKey(ChangePasswordScreen.currentKey), findsOneWidget);

    await act(tester, api, tester.pageBack);
    expect(find.byKey(MyAccountScreen.changePasswordKey), findsOneWidget);
  });

  Future<void> signOut(WidgetTester tester, FakeApi api) async {
    await act(tester, api, () => tester.tap(find.byKey(MyAccountScreen.signOutKey)));
    await act(tester, api, () => tester.tap(find.byKey(MyAccountScreen.confirmSignOutKey)));
  }

  testWidgets('signing out asks first, says what it means, and Cancel changes nothing', (tester) async {
    final api = FakeApi();
    final session = await pumpRedix(tester, api, stored: {'session': keptSession});
    await openMyAccount(tester, api);

    await act(tester, api, () => tester.tap(find.byKey(MyAccountScreen.signOutKey)));
    expect(text(tester, MyAccountScreen.signOutExplainKey), 'en myAccount.signOutExplain');
    expect(find.byKey(ConfirmDialog.subjectKey), findsNothing);

    await act(tester, api, () => tester.tap(find.byKey(MyAccountScreen.cancelSignOutKey)));
    expect(api.signOuts, 0);
    expect(session.isOpen, isTrue);
    expect(find.byKey(MyAccountScreen.signOutKey), findsOneWidget);
  });

  testWidgets('signing out tells the API, forgets the session, and leads to sign-in with no message', (tester) async {
    final api = FakeApi();
    final session = await pumpRedix(tester, api, stored: {'session': keptSession});
    await openMyAccount(tester, api);

    await signOut(tester, api);

    expect(api.signOuts, 1);
    expect(session.isOpen, isFalse);
    expect(await const FlutterSecureStorage().read(key: 'session'), isNull);
    expect(find.byKey(SignInScreen.usernameKey), findsOneWidget);
    expect(find.byKey(SignInScreen.messageKey), findsNothing);
  });

  testWidgets('without a network the phone still signs out', (tester) async {
    final api = FakeApi();
    final session = await pumpRedix(tester, api, stored: {'session': keptSession});
    await openMyAccount(tester, api);

    api.online = false;
    await signOut(tester, api);

    expect(session.isOpen, isFalse);
    expect(find.byKey(SignInScreen.usernameKey), findsOneWidget);
  });

  testWidgets('the chosen language stays after signing out', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, locale: const Locale('ar'), stored: {'session': keptSession});
    await openMyAccount(tester, api);
    await choose(tester, api, MyAccountScreen.englishKey);

    await signOut(tester, api);

    expect(text(tester, SignInScreen.titleKey), 'en app.title');
    expect(direction(tester, SignInScreen.titleKey), TextDirection.ltr);
  });

  testWidgets("the next user on this phone never sees the last user's projects, even for a moment", (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await pumpRedix(tester, api, stored: {'session': keptSession});
    expect(find.byKey(ProjectsScreen.cardKey('project-0')), findsOneWidget);
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.settingsKey)));
    await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.myAccountKey)));
    await signOut(tester, api);
    api.projects.clear();

    await act(tester, api, () async {
      await tester.enterText(find.byKey(SignInScreen.usernameKey), 'nawaf');
      await tester.enterText(find.byKey(SignInScreen.passwordKey), 'secret');
      await tester.tap(find.byKey(SignInScreen.submitKey));
      for (var frame = 0; frame < 20; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(find.byKey(ProjectsScreen.cardKey('project-0')), findsNothing);
      }
    });
  });

  testWidgets('the next user signs in as themselves', (tester) async {
    final api = FakeApi()..permissions = admin;
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await openMyAccount(tester, api);
    await signOut(tester, api);

    api.permissions = [];
    await act(tester, api, () async {
      await tester.enterText(find.byKey(SignInScreen.usernameKey), 'nawaf');
      await tester.enterText(find.byKey(SignInScreen.passwordKey), 'secret');
      await tester.tap(find.byKey(SignInScreen.submitKey));
    });
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.settingsKey)));

    expect(find.byKey(SettingsScreen.registeredKey), findsNothing);
    expect(find.byKey(SettingsScreen.myAccountKey), findsOneWidget);
  });

  for (final (language, textDirection) in [('ar', TextDirection.rtl), ('en', TextDirection.ltr)]) {
    testWidgets('AC-N03: on a phone 360 points wide in $language, every screen reads ${textDirection.name} and fits', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      void expectFits(Key key) {
        final rect = tester.getRect(find.byKey(key));
        expect(direction(tester, key), textDirection);
        expect(rect.left, greaterThanOrEqualTo(0), reason: '$key starts off the screen');
        expect(rect.right, lessThanOrEqualTo(360), reason: '$key ends off the screen');
      }

      final api = FakeApi()
        ..mustChangePassword = true
        ..permissions = admin;
      final running = api.addProject('غصون 6', units: ['الفلة الغربية', 'الفلة الجنوبية']);
      final finished = api.addProject('غصون 5', status: 'finished', units: ['الفلة الشرقية']);
      final manager = api.addUser('متعب', username: 'muteb');
      final field = api.addUser('نواف', username: 'nawaf', mobile: '0500000000');
      final disabled = api.addUser('سالم', username: 'salem', isActive: false);
      for (final (user, role) in [(manager, 'role-manager'), (field, 'role-field'), (disabled, 'role-reader')]) {
        api.giveRole(user, running['id'] as String, role);
      }
      final session = await pumpRedix(tester, api, locale: Locale(language));
      [SignInScreen.logoKey, SignInScreen.titleKey, SignInScreen.usernameKey, SignInScreen.passwordKey, SignInScreen.submitKey, SignInScreen.registerKey].forEach(expectFits);

      await act(tester, api, () async {
        await tester.enterText(find.byKey(SignInScreen.usernameKey), 'nawaf');
        await tester.enterText(find.byKey(SignInScreen.passwordKey), 'temporary');
        await tester.tap(find.byKey(SignInScreen.submitKey));
      });
      [ChangePasswordScreen.currentKey, ChangePasswordScreen.newKey, ChangePasswordScreen.confirmKey].forEach(expectFits);
      await tester.ensureVisible(find.byKey(ChangePasswordScreen.submitKey));
      expectFits(ChangePasswordScreen.submitKey);

      await act(tester, api, () async {
        await tester.enterText(find.byKey(ChangePasswordScreen.currentKey), 'temporary');
        await tester.enterText(find.byKey(ChangePasswordScreen.newKey), 'chosen-pass');
        await tester.enterText(find.byKey(ChangePasswordScreen.confirmKey), 'chosen-pass');
        await tester.tap(find.byKey(ChangePasswordScreen.submitKey));
      });
      final runningId = running['id'] as String;
      final finishedId = finished['id'] as String;
      [
        ProjectsScreen.titleKey,
        ProjectsScreen.hintKey,
        ProjectsScreen.settingsKey,
        ProjectsScreen.openDefaultKey,
        ProjectsScreen.newProjectKey,
        ProjectsScreen.nameKey(runningId),
        ProjectsScreen.detailsKey(runningId),
        ProjectsScreen.rolesKey(runningId),
        ProjectsScreen.statusKey(runningId),
        ProjectsScreen.starKey(runningId),
        ProjectsScreen.statusKey(finishedId),
        ProjectsScreen.detailsKey(finishedId),
      ].forEach(expectFits);

      await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.newProjectKey)));
      [NewProjectScreen.nameKey, NewProjectScreen.startDateKey, NewProjectScreen.unitNameKey, NewProjectScreen.addUnitKey, NewProjectScreen.submitKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey(runningId))));
      [
        HomeScreen.titleKey,
        HomeScreen.settingsKey,
        HomeScreen.rolesKey(runningId),
        HomeScreen.detailsKey(runningId),
        HomeScreen.statusKey(runningId),
        HomeScreen.usersKey(runningId),
        HomeScreen.addUnitKey(runningId),
        HomeScreen.closeKey(runningId),
      ].forEach(expectFits);

      await tester.ensureVisible(find.byKey(HomeScreen.closeKey(runningId)));
      await tester.pumpAndSettle();
      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.closeKey(runningId))));
      [HomeScreen.closeExplainKey, HomeScreen.confirmCloseKey, HomeScreen.cancelCloseKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.cancelCloseKey)));

      final bone = api.addCategory(runningId, 'العظم');
      final tiles = api.addItem(bone, 'بند الدرابزين والألمنيوم مع التركيب الكامل', subgroups: ['مواد']);
      final disabledItem = api.addItem(bone, 'بند الحديد', isActive: false);
      final boneId = bone['id'] as String;
      final tilesId = tiles['id'] as String;
      await tester.ensureVisible(find.byKey(HomeScreen.categoriesKey(runningId)));
      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.categoriesKey(runningId))));
      await act(tester, api, () => tester.tap(find.byKey(CategoriesScreen.categoryTileKey(boneId))));
      [
        CategoriesScreen.hintKey,
        CategoriesScreen.addCategoryKey,
        CategoriesScreen.categoryHandleKey(boneId),
        CategoriesScreen.categoryNameKey(boneId),
        CategoriesScreen.categoryDetailsKey(boneId),
        CategoriesScreen.addItemKey(boneId),
        CategoriesScreen.renameCategoryKey(boneId),
        CategoriesScreen.disableCategoryKey(boneId),
        CategoriesScreen.itemHandleKey(tilesId),
        CategoriesScreen.itemNameKey(tilesId),
        CategoriesScreen.itemDetailsKey(tilesId),
        CategoriesScreen.itemMenuKey(tilesId),
        CategoriesScreen.itemDetailsKey(disabledItem['id'] as String),
      ].forEach(expectFits);

      await act(tester, api, () => tester.tap(find.byKey(CategoriesScreen.addItemKey(boneId))));
      [CategoriesScreen.nameKey, for (final type in ItemType.values) CategoriesScreen.itemTypeKey(type), CategoriesScreen.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));

      final columnsPath = Columns.itemPath(runningId, tilesId);
      final dateColumn = api.addColumn(columnsPath, 'التاريخ', dataType: 'date', isCore: true, isRequired: true, showInReports: true)['id'] as String;
      final areaColumn = api.addColumn(columnsPath, 'المساحة بالمتر المربع في الطابق الأرضي', dataType: 'number', isCustom: true, isRequired: true, showInReports: true)['id'] as String;
      final templateDate = api.addColumn(Columns.templatePath(runningId, ItemType.both), 'التاريخ', dataType: 'date', isCore: true)['id'] as String;
      expectFits(CategoriesScreen.itemColumnsKey(tilesId));
      await tester.ensureVisible(find.byKey(CategoriesScreen.itemColumnsKey(tilesId)));
      await tester.pumpAndSettle();
      await act(tester, api, () => tester.tap(find.byKey(CategoriesScreen.itemColumnsKey(tilesId))));
      [
        ItemColumnsScreen.itemDetailsKey,
        ItemColumnsScreen.templateKey,
        ItemColumnsScreen.thisItemKey,
        ItemColumnsScreen.hintKey,
        ItemColumnsScreen.addKey,
        ItemColumnsScreen.handleKey(dateColumn),
        ItemColumnsScreen.nameKey(dateColumn),
        ItemColumnsScreen.detailsKey(dateColumn),
        ItemColumnsScreen.editKey(dateColumn),
        ItemColumnsScreen.lockKey(dateColumn),
        ItemColumnsScreen.nameKey(areaColumn),
        ItemColumnsScreen.detailsKey(areaColumn),
        ItemColumnsScreen.editKey(areaColumn),
        ItemColumnsScreen.deleteKey(areaColumn),
      ].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(ItemColumnsScreen.addKey)));
      [ItemColumnsScreen.columnNameKey, ItemColumnsScreen.dataTypeKey, ItemColumnsScreen.requiredKey, ItemColumnsScreen.showInReportsKey, ItemColumnsScreen.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));
      await tester.ensureVisible(find.byKey(ItemColumnsScreen.deleteKey(areaColumn)));
      await tester.pumpAndSettle();
      await act(tester, api, () => tester.tap(find.byKey(ItemColumnsScreen.deleteKey(areaColumn))));
      [ItemColumnsScreen.deleteExplainKey, ItemColumnsScreen.confirmDeleteKey, ItemColumnsScreen.cancelDeleteKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(ItemColumnsScreen.cancelDeleteKey)));
      await act(tester, api, () => tester.tap(find.byKey(ItemColumnsScreen.templateKey)));
      await tester.ensureVisible(find.byKey(ItemColumnsScreen.editKey(templateDate)));
      await tester.pumpAndSettle();
      await act(tester, api, () => tester.tap(find.byKey(ItemColumnsScreen.editKey(templateDate))));
      await act(tester, api, () => tester.tap(find.byKey(ItemColumnsScreen.saveKey)));
      [ApplyToAllDialog.explainKey, ApplyToAllDialog.applyKey, ApplyToAllDialog.templateOnlyKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(ApplyToAllDialog.templateOnlyKey)));
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      await tester.ensureVisible(find.byKey(CategoriesScreen.itemMenuKey(tilesId)));
      await tester.pumpAndSettle();
      await act(tester, api, () => tester.tap(find.byKey(CategoriesScreen.itemMenuKey(tilesId))));
      [CategoriesScreen.renameItemKey, CategoriesScreen.subgroupsKey, CategoriesScreen.disableItemKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(CategoriesScreen.subgroupsKey)));
      [SubgroupsScreen.hintKey, SubgroupsScreen.addKey, SubgroupsScreen.subgroupNameKey((tiles['subgroups']! as List<Map<String, Object>>).last['id'] as String)].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byType(BackButton)));
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      final cardMethod = api.addPaymentMethod(runningId, 'شبكة')['id'] as String;
      final longMethod = api.addPaymentMethod(runningId, 'تحويل بنكي عن طريق الحساب الجاري للمؤسسة', isActive: false)['id'] as String;
      await tester.ensureVisible(find.byKey(HomeScreen.paymentMethodsKey(runningId)));
      expectFits(HomeScreen.paymentMethodsKey(runningId));
      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.paymentMethodsKey(runningId))));
      [
        PaymentMethodsScreen.vatRateKey,
        PaymentMethodsScreen.vatHintKey,
        PaymentMethodsScreen.changeVatRateKey,
        PaymentMethodsScreen.addKey,
        PaymentMethodsScreen.nameKey(cardMethod),
        PaymentMethodsScreen.menuKey(cardMethod),
        PaymentMethodsScreen.nameKey(longMethod),
        PaymentMethodsScreen.disabledKey(longMethod),
        PaymentMethodsScreen.menuKey(longMethod),
      ].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(PaymentMethodsScreen.menuKey(cardMethod))));
      [PaymentMethodsScreen.renameKey, PaymentMethodsScreen.disableKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(PaymentMethodsScreen.renameKey)));
      [PaymentMethodsScreen.dialogNameKey, PaymentMethodsScreen.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));
      await act(tester, api, () => tester.tap(find.byKey(PaymentMethodsScreen.changeVatRateKey)));
      [PaymentMethodsScreen.vatPercentKey, PaymentMethodsScreen.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      api.addMember('user-nawaf', 'نواف بن عبدالله بن محمد العتيبي من قسم الإشراف الميداني بالمشروع');
      final bankAccount = api.addAccount(runningId, 'حساب جارٍ باسم طويل جداً في بنك من البنوك المحلية', openingBalance: 64250.75)['id'] as String;
      final custody = api.addAccount(runningId, 'كاش مع نواف', type: 'cashCustody', openingBalance: 2750.5, custodianId: 'user-nawaf', custodianName: 'نواف بن عبدالله', isMine: true)['id'] as String;
      final oldAccount = api.addAccount(runningId, 'حساب قديم', openingBalance: -120.40, isActive: false)['id'] as String;
      await tester.ensureVisible(find.byKey(HomeScreen.accountsKey(runningId)));
      expectFits(HomeScreen.accountsKey(runningId));
      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.accountsKey(runningId))));
      [
        AccountsScreen.addKey,
        AccountsScreen.nameKey(bankAccount),
        AccountsScreen.detailsKey(bankAccount),
        AccountsScreen.balanceKey(bankAccount),
        AccountsScreen.menuKey(bankAccount),
      ].forEach(expectFits);
      for (final id in [custody, oldAccount]) {
        await tester.scrollUntilVisible(find.byKey(AccountsScreen.balanceKey(id)), 100);
        [AccountsScreen.detailsKey(id), AccountsScreen.balanceKey(id)].forEach(expectFits);
      }
      await act(tester, api, () => tester.tap(find.byKey(AccountsScreen.addKey)));
      [
        for (final type in AccountType.values) AccountsScreen.typeKey(type),
        AccountsScreen.accountNameKey,
        AccountsScreen.custodianKey,
        AccountsScreen.openingBalanceKey,
        AccountsScreen.saveKey,
      ].forEach(expectFits);
      [MemberPicker.optionKey(''), MemberPicker.optionKey('user-nawaf')].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));
      await tester.ensureVisible(find.byKey(AccountsScreen.menuKey(custody)));
      await tester.pumpAndSettle();
      await act(tester, api, () => tester.tap(find.byKey(AccountsScreen.menuKey(custody))));
      [AccountsScreen.editKey, AccountsScreen.disableKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(AccountsScreen.editKey)));
      [AccountsScreen.accountNameKey, AccountsScreen.custodianKey, AccountsScreen.openingBalanceKey, AccountsScreen.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));
      await act(tester, api, () => tester.tap(find.byType(BackButton)));
      expectFits(HomeScreen.custodyKey(custody));
      expectFits(HomeScreen.custodyBalanceKey(custody));

      final partner = api.addPartner(runningId, 'متعب بن عبدالله بن محمد المغيري الشريك المؤسس في المشروع', userId: 'user-nawaf', userName: 'نواف بن عبدالله بن محمد العتيبي من قسم الإشراف الميداني')['id'] as String;
      final partnerWithNoLogin = api.addPartner(runningId, 'هيثم')['id'] as String;
      await tester.ensureVisible(find.byKey(HomeScreen.partnersKey(runningId)));
      expectFits(HomeScreen.partnersKey(runningId));
      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.partnersKey(runningId))));
      [
        PartnersScreen.addKey,
        PartnersScreen.nameKey(partner),
        PartnersScreen.detailsKey(partner),
        PartnersScreen.editKey(partner),
        PartnersScreen.nameKey(partnerWithNoLogin),
        PartnersScreen.detailsKey(partnerWithNoLogin),
        PartnersScreen.editKey(partnerWithNoLogin),
      ].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(PartnersScreen.editKey(partner))));
      [PartnersScreen.partnerNameKey, PartnersScreen.loginKey, PartnersScreen.loginHintKey, PartnersScreen.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      final supplier = api.addSupplier(runningId, 'شركة الأفق العالية للسيراميك والبورسلان والمواد الإنشائية', vatNumber: '322222222222223', defaultItemName: 'البلاط والرخام')['id'] as String;
      await tester.ensureVisible(find.byKey(HomeScreen.suppliersKey(runningId)));
      expectFits(HomeScreen.suppliersKey(runningId));
      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.suppliersKey(runningId))));
      [SuppliersScreen.addKey, SuppliersScreen.nameKey(supplier), SuppliersScreen.detailsKey(supplier), SuppliersScreen.menuKey(supplier)].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(SuppliersScreen.addKey)));
      [SuppliersScreen.supplierNameKey, SuppliersScreen.notVatRegisteredKey, SuppliersScreen.vatNumberKey, SuppliersScreen.mobileKey, SuppliersScreen.defaultItemKey, SuppliersScreen.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));
      final project = Project.fromJson(jsonDecode(jsonEncode(running)) as Map<String, dynamic>);
      await act(tester, api, () async => unawaited(SupplierPicker.show(tester.element(find.byType(SuppliersScreen)), project, Suppliers(session, runningId))));
      [SupplierPicker.searchKey, SupplierPicker.closeKey, SupplierPicker.rowKey(supplier), SupplierPicker.detailsKey(supplier), SupplierPicker.quickAddKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(SupplierPicker.quickAddKey)));
      [SuppliersScreen.supplierNameKey, SuppliersScreen.notVatRegisteredKey, SuppliersScreen.vatNumberKey, SuppliersScreen.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));
      await act(tester, api, () => tester.tap(find.byKey(SupplierPicker.closeKey)));
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      final overrun = api.addContract(runningId, 'شركة الأفق العالية للسيراميك والبورسلان والمواد الإنشائية', itemName: 'البلاط والرخام للواجهات الداخلية', unitName: 'الفلة الغربية الكبرى', value: 999999999.99, paid: 1099999999.99, unitPrice: 380, quantity: 50, notes: 'زيادة بملحق')['id'] as String;
      final open = api.addContract(runningId, 'دهان داخلي', isOpenValue: true, paid: 12000)['id'] as String;
      await tester.ensureVisible(find.byKey(HomeScreen.contractsKey(runningId)));
      expectFits(HomeScreen.contractsKey(runningId));
      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.contractsKey(runningId))));
      [
        ContractsScreen.addKey,
        for (final filter in ContractFilter.values) ContractsScreen.filterKey(filter),
        for (final id in [overrun, open]) ...[
          ContractsScreen.nameKey(id),
          ContractsScreen.termsKey(id),
          ContractsScreen.standingKey(id),
          ContractsScreen.valueOfKey(id),
          ContractsScreen.paidKey(id),
          ContractsScreen.remainingKey(id),
          ContractsScreen.progressKey(id),
          ContractsScreen.menuKey(id),
        ],
      ].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(ContractsScreen.addKey)));
      [ContractsScreen.contractorKey, ContractsScreen.itemKey, ContractsScreen.unitKey('$runningId-unit-0'), ContractsScreen.openValueKey, ContractsScreen.valueKey, ContractsScreen.unitPriceKey, ContractsScreen.quantityKey, ContractsScreen.notesKey, ContractsScreen.addDocumentKey, ContractsScreen.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));
      await act(tester, api, () => tester.tap(find.byKey(ContractsScreen.menuKey(overrun))));
      [ContractsScreen.editKey, ContractsScreen.disableKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(ContractsScreen.editKey)));
      [ContractsScreen.partiesKey, ContractsScreen.openValueKey, ContractsScreen.valueKey, ContractsScreen.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      await tester.ensureVisible(find.byKey(HomeScreen.addExpenseKey(runningId)));
      expectFits(HomeScreen.addExpenseKey(runningId));
      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addExpenseKey(runningId))));
      [
        AddExpenseScreen.titleKey,
        AddExpenseScreen.projectNameKey,
        AddExpenseScreen.cameraKey,
        AddExpenseScreen.filesKey,
        AddExpenseScreen.invoiceNameKey,
        AddExpenseScreen.itemKey,
        AddExpenseScreen.unitKey('$runningId-unit-0'),
        AddExpenseScreen.unitKey('$runningId-unit-shared'),
        AddExpenseScreen.supplierKey,
        AddExpenseScreen.invoiceNumberKey,
        AddExpenseScreen.invoiceDateKey,
        AddExpenseScreen.productKey,
        AddExpenseScreen.unitPriceKey,
        AddExpenseScreen.quantityKey,
        AddExpenseScreen.includingVatKey,
        AddExpenseScreen.beforeVatKey,
        AddExpenseScreen.amountKey,
        AddExpenseScreen.discountKey,
        AddExpenseScreen.notTaxableKey,
        AddExpenseScreen.afterDiscountKey,
        AddExpenseScreen.vatKey,
        AddExpenseScreen.totalKey,
        AddExpenseScreen.paymentDiffersKey,
        AddExpenseScreen.notesKey,
        AddExpenseScreen.sendKey,
        AddExpenseScreen.draftKey,
      ].forEach(expectFits);
      await tester.ensureVisible(find.byKey(AddExpenseScreen.paymentDiffersKey));
      await tester.pumpAndSettle();
      await act(tester, api, () => tester.tap(find.byKey(AddExpenseScreen.paymentDiffersKey)));
      [AddExpenseScreen.paymentDateKey, AddExpenseScreen.paymentAmountKey, AddExpenseScreen.bankFeesKey].forEach(expectFits);
      await tester.ensureVisible(find.byKey(AddExpenseScreen.withoutInvoiceKey));
      await tester.pumpAndSettle();
      await act(tester, api, () => tester.tap(find.byKey(AddExpenseScreen.withoutInvoiceKey)));
      [AddExpenseScreen.withoutInvoiceKey, AddExpenseScreen.withoutInvoiceReasonKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      await tester.ensureVisible(find.byKey(HomeScreen.usersKey(runningId)));
      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.usersKey(runningId))));
      [
        UsersScreen.newUserKey,
        UsersScreen.addExistingKey,
        UsersScreen.nameKey('user-0'),
        UsersScreen.menuKey('user-0'),
        UsersScreen.detailsKey('user-1'),
        UsersScreen.rolesLineKey('user-1'),
        UsersScreen.menuKey('user-1'),
        UsersScreen.statusKey('user-2'),
      ].forEach(expectFits);

      await act(tester, api, () => tester.tap(find.byKey(UsersScreen.menuKey('user-1'))));
      [UsersScreen.editKey, UsersScreen.rolesKey, UsersScreen.resetPasswordKey, UsersScreen.disableKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(UsersScreen.resetPasswordKey)));
      [UsersScreen.resetExplainKey, UsersScreen.resetPasswordFieldKey, UsersScreen.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));

      await act(tester, api, () => tester.tap(find.byKey(UsersScreen.menuKey('user-1'))));
      await act(tester, api, () => tester.tap(find.byKey(UsersScreen.rolesKey)));
      [
        UserRolesScreen.nameKey,
        UserRolesScreen.hintKey,
        UserRolesScreen.roleKey('role-manager'),
        UserRolesScreen.roleKey('role-finance'),
        UserRolesScreen.roleKey('role-field'),
        UserRolesScreen.roleKey('role-reader'),
      ].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      await act(tester, api, () => tester.tap(find.byKey(UsersScreen.addExistingKey)));
      [UsersScreen.existingUsernameKey, UsersScreen.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));

      await act(tester, api, () => tester.tap(find.byKey(UsersScreen.newUserKey)));
      [NewUserScreen.nameKey, NewUserScreen.usernameKey, NewUserScreen.mobileKey, NewUserScreen.passwordKey].forEach(expectFits);
      await tester.ensureVisible(find.byKey(NewUserScreen.submitKey));
      expectFits(NewUserScreen.submitKey);
      await act(tester, api, () => tester.tap(find.byType(BackButton)));
      await act(tester, api, () => tester.tap(find.byType(BackButton)));
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.settingsKey)));
      [SettingsScreen.switchProjectKey, SettingsScreen.registeredKey, SettingsScreen.myAccountKey].forEach(expectFits);
      api.addRegistered('غصون 8');
      await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.registeredKey)));
      [
        RegisteredProjectsScreen.detailsKey('registered-0'),
        RegisteredProjectsScreen.managerKey('registered-0'),
        RegisteredProjectsScreen.approveKey('registered-0'),
        RegisteredProjectsScreen.rejectKey('registered-0'),
      ].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(RegisteredProjectsScreen.rejectKey('registered-0'))));
      [RegisteredProjectsScreen.reasonKey, RegisteredProjectsScreen.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.myAccountKey)));
      [MyAccountScreen.arabicKey, MyAccountScreen.englishKey, MyAccountScreen.changePasswordKey, MyAccountScreen.signOutKey].forEach(expectFits);
    });
  }
}
