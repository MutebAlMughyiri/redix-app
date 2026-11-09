import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/accounts/account.dart';
import 'package:redix/accounts/accounts_screen.dart';
import 'package:redix/auth/change_password_screen.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/entries/table_picker.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/contracts/contract.dart';
import 'package:redix/contracts/contracts_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/partners/partners_screen.dart';
import 'package:redix/projects/member_picker.dart';
import 'package:redix/projects/new_project_screen.dart';
import 'package:redix/projects/project.dart';
import 'package:redix/projects/project_info_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/projects/registered_projects_screen.dart';
import 'package:redix/settings/payment_methods_screen.dart';
import 'package:redix/settings/settings_screen.dart';
import 'package:redix/structure/apply_to_all_dialog.dart';
import 'package:redix/structure/categories_screen.dart';
import 'package:redix/structure/category.dart';
import 'package:redix/structure/columns.dart';
import 'package:redix/structure/item_columns_screen.dart';
import 'package:redix/structure/item_tables_screen.dart';
import 'package:redix/suppliers/supplier_picker.dart';
import 'package:redix/suppliers/suppliers.dart';
import 'package:redix/suppliers/suppliers_screen.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/users/new_user_screen.dart';
import 'package:redix/users/user_permissions_screen.dart';
import 'package:redix/users/users_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_harness.dart';
import 'package:redix/words/language_switch.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/name_dialog.dart';
import 'package:redix/ui/screen_title.dart';
import 'package:redix/ui/reason_sheet.dart';

void main() {
  String text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

  TextDirection direction(WidgetTester tester, Key key) => Directionality.of(tester.element(find.byKey(key)));

  Future<void> openSettingsFromList(WidgetTester tester, FakeApi api) => act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.settingsKey)));

  SwitchListTile biometricsSwitch(WidgetTester tester) => tester.widget<SwitchListTile>(find.byKey(SettingsScreen.biometricsKey));

  testWidgets('Muteb, 9 Nov 2026: Settings shows who is signed in at its top, their name over the name they sign in with', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await openSettingsFromList(tester, api);

    expect(text(tester, SettingsScreen.whoKey.title), 'متعب المغيري');
    expect(text(tester, SettingsScreen.whoKey.subtitle), 'muteb');
  });

  testWidgets('turning on fingerprint or face asks first, then tells the server', (tester) async {
    final api = FakeApi();
    final prompt = FakePrompt();
    await pumpRedix(tester, api, stored: {'session': keptSession}, prompt: prompt);
    await openSettingsFromList(tester, api);
    expect(biometricsSwitch(tester).value, isFalse);

    await scrollAndTap(tester, api, SettingsScreen.biometricsKey);

    expect(prompt.shown, 1);
    expect(api.sentBiometrics, [true]);
    expect(biometricsSwitch(tester).value, isTrue);
    expect(find.byKey(SettingsScreen.biometricsMessageKey), findsNothing);
  });

  testWidgets('a phone with no fingerprint or face stays off, tells the server nothing, and says what to do', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, stored: {'session': keptSession}, prompt: FakePrompt()..fails = true);
    await openSettingsFromList(tester, api);

    await scrollAndTap(tester, api, SettingsScreen.biometricsKey);

    expect(api.sentBiometrics, isEmpty);
    expect(biometricsSwitch(tester).value, isFalse);
    expect(text(tester, SettingsScreen.biometricsMessageKey), 'en biometrics.notAvailable');
  });

  testWidgets('a prompt with no answer leaves the switch off, and it can be tapped again', (tester) async {
    final api = FakeApi();
    final prompt = FakePrompt()..neverAnswers = true;
    await pumpRedix(tester, api, stored: {'session': keptSession}, prompt: prompt);
    await openSettingsFromList(tester, api);

    await scrollAndTap(tester, api, SettingsScreen.biometricsKey);
    expect(biometricsSwitch(tester).value, isFalse);

    prompt.neverAnswers = false;
    await scrollAndTap(tester, api, SettingsScreen.biometricsKey);
    expect(biometricsSwitch(tester).value, isTrue);
  });

  testWidgets('without a network it stays off and says so', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, stored: {'session': keptSession}, prompt: FakePrompt());
    await openSettingsFromList(tester, api);

    api.online = false;
    await scrollAndTap(tester, api, SettingsScreen.biometricsKey);

    expect(biometricsSwitch(tester).value, isFalse);
    expect(text(tester, SettingsScreen.biometricsMessageKey), 'en biometrics.notChanged');
  });

  testWidgets('a refused change stays as it was and says so', (tester) async {
    final api = FakeApi()..biometricsStatus = 403;
    await pumpRedix(tester, api, stored: {'session': keptSession}, prompt: FakePrompt());
    await openSettingsFromList(tester, api);

    await scrollAndTap(tester, api, SettingsScreen.biometricsKey);

    expect(biometricsSwitch(tester).value, isFalse);
    expect(text(tester, SettingsScreen.biometricsMessageKey), 'en biometrics.notChanged');
  });

  testWidgets('turning it off asks nothing', (tester) async {
    final api = FakeApi()..usesBiometrics = true;
    final prompt = FakePrompt();
    await pumpRedix(tester, api, stored: {'session': keptBiometricSession}, prompt: prompt);
    expect(prompt.shown, 1);
    await openSettingsFromList(tester, api);

    await scrollAndTap(tester, api, SettingsScreen.biometricsKey);

    expect(prompt.shown, 1);
    expect(api.sentBiometrics, [false]);
    expect(biometricsSwitch(tester).value, isFalse);
  });

  /// Chooses [language] through the language switch in Settings, from the project list.
  Future<void> choose(WidgetTester tester, FakeApi api, String language) async {
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.settingsKey)));
    await act(tester, api, () => tester.tap(find.byKey(language == 'ar' ? LanguageSwitch.arabicKey : LanguageSwitch.englishKey)));
  }

  testWidgets('UC-004 (Muteb, 9 Nov 2026): Settings shows the Arabic and English choice itself, the language in use chosen, with no row to open first', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, locale: const Locale('ar'), stored: {'session': keptSession});
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.settingsKey)));

    expect(text(tester, SettingsScreen.languageKey.title), 'ar myAccount.language');
    expect(text(tester, LanguageSwitch.arabicKey), 'ar myAccount.arabic');
    expect(text(tester, LanguageSwitch.englishKey), 'ar myAccount.english');
    expect(tester.widget<SegmentedButton<String>>(find.byKey(LanguageSwitch.choiceKey)).selected, {'ar'});
  });

  testWidgets('choosing English on an Arabic phone switches every screen to English, left to right', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, locale: const Locale('ar'), stored: {'session': keptSession});

    await choose(tester, api, 'en');

    expect(tester.widget<SegmentedButton<String>>(find.byKey(LanguageSwitch.choiceKey)).selected, {'en'});
    expect(direction(tester, SettingsScreen.languageKey.title), TextDirection.ltr);
    await act(tester, api, tester.pageBack);
    expect(text(tester, ProjectsScreen.titleKey), 'en projects.choose');
    expect(direction(tester, ProjectsScreen.titleKey), TextDirection.ltr);
  });

  testWidgets('the chosen language is kept on the phone and used at the next start', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, locale: const Locale('ar'), stored: {'session': keptSession});
    await choose(tester, api, 'en');
    final preferences = await SharedPreferences.getInstance();
    final kept = {for (final key in preferences.getKeys()) key: preferences.get(key) ?? ''};

    await tester.pumpWidget(const SizedBox());
    await pumpRedix(tester, FakeApi(), locale: const Locale('ar'), stored: {'session': keptSession}, preferences: kept);

    expect(text(tester, ProjectsScreen.titleKey), 'en projects.choose');
  });

  testWidgets('without a network the language stays and the app says switching needs a network', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, locale: const Locale('ar'), stored: {'session': keptSession});

    api.online = false;
    await choose(tester, api, 'en');

    expect(text(tester, LanguageSwitch.messageKey), 'ar myAccount.languageNeedsNetwork');
    expect(direction(tester, LanguageSwitch.messageKey), TextDirection.rtl);
    expect(tester.widget<SegmentedButton<String>>(find.byKey(LanguageSwitch.choiceKey)).selected, {'ar'});
    expect((await SharedPreferences.getInstance()).containsKey('language'), isFalse);
  });

  testWidgets('the password change opens from Settings and goes back to it', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, stored: {'session': keptSession});
    await openSettingsFromList(tester, api);

    await scrollAndTap(tester, api, SettingsScreen.changePasswordKey);
    expect(find.byKey(ChangePasswordScreen.currentKey), findsOneWidget);

    await act(tester, api, tester.pageBack);
    expect(find.byKey(SettingsScreen.changePasswordKey), findsOneWidget);
  });

  Future<void> signOut(WidgetTester tester, FakeApi api) async {
    await scrollAndTap(tester, api, SettingsScreen.signOutKey);
    await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.confirmKey)));
  }

  testWidgets('signing out asks first, says what it means, and Cancel changes nothing', (tester) async {
    final api = FakeApi();
    final session = await pumpRedix(tester, api, stored: {'session': keptSession});
    await openSettingsFromList(tester, api);

    await scrollAndTap(tester, api, SettingsScreen.signOutKey);
    expect(text(tester, ConfirmDialog.explanationKey), 'en myAccount.signOutExplain');
    expect(find.byKey(ConfirmDialog.subjectKey), findsNothing);

    await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.cancelKey)));
    expect(api.signOuts, 0);
    expect(session.isOpen, isTrue);
    expect(find.byKey(SettingsScreen.signOutKey), findsOneWidget);
  });

  testWidgets('signing out tells the API, forgets the session, and leads to sign-in with no message', (tester) async {
    final api = FakeApi();
    final session = await pumpRedix(tester, api, stored: {'session': keptSession});
    await openSettingsFromList(tester, api);

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
    await openSettingsFromList(tester, api);

    api.online = false;
    await signOut(tester, api);

    expect(session.isOpen, isFalse);
    expect(find.byKey(SignInScreen.usernameKey), findsOneWidget);
  });

  testWidgets('the chosen language stays after signing out', (tester) async {
    final api = FakeApi();
    await pumpRedix(tester, api, locale: const Locale('ar'), stored: {'session': keptSession});
    await choose(tester, api, 'en');

    await signOut(tester, api);

    expect(text(tester, SignInScreen.titleKey), 'en app.title');
    expect(direction(tester, SignInScreen.titleKey), TextDirection.ltr);
  });

  testWidgets("the next user on this phone never sees the last user's projects, even for a moment", (tester) async {
    final api = FakeApi()..addProject('غصون 6');
    await pumpRedix(tester, api, stored: {'session': keptSession});
    expect(find.byKey(ProjectsScreen.cardKey('project-0')), findsOneWidget);
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.settingsKey)));
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
    await openSettingsFromList(tester, api);
    await signOut(tester, api);

    api.permissions = [];
    await act(tester, api, () async {
      await tester.enterText(find.byKey(SignInScreen.usernameKey), 'nawaf');
      await tester.enterText(find.byKey(SignInScreen.passwordKey), 'secret');
      await tester.tap(find.byKey(SignInScreen.submitKey));
    });
    await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.settingsKey)));

    expect(find.byKey(SettingsScreen.registeredKey), findsNothing);
    expect(text(tester, SettingsScreen.whoKey.subtitle), 'muteb');
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
      final field_ = api.addUser('نواف', username: 'nawaf', mobile: '0500000000');
      final disabled = api.addUser('سالم', username: 'salem', isActive: false);
      for (final (user, permissions) in [(manager, managerAndFinance), (field_, field), (disabled, reader)]) {
        api.give(user, running['id'] as String, permissions);
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
        ProjectsScreen.newProjectKey,
        ProjectsScreen.nameKey(runningId),
        ProjectsScreen.detailsKey(runningId),
        ProjectsScreen.statusKey(runningId),
        ProjectsScreen.starKey(runningId),
        ProjectsScreen.statusKey(finishedId),
        ProjectsScreen.detailsKey(finishedId),
      ].forEach(expectFits);

      await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.newProjectKey)));
      [NewProjectScreen.nameKey, NewProjectScreen.descriptionKey, NewProjectScreen.startDateKey, NewProjectScreen.unitNameKey, NewProjectScreen.addUnitKey].forEach(expectFits);
      await tester.scrollUntilVisible(find.byKey(NewProjectScreen.submitKey), 200, scrollable: find.ancestor(of: find.byKey(NewProjectScreen.nameKey), matching: find.byType(Scrollable)).first);
      [NewProjectScreen.partnerNameKey, NewProjectScreen.addPartnerKey, NewProjectScreen.submitKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.cardKey(runningId))));
      [HomeScreen.titleKey, HomeScreen.settingsKey(runningId)].forEach(expectFits);

      await tester.ensureVisible(find.byKey(HomeScreen.projectInfoKey(runningId)));
      await tester.pumpAndSettle();
      expectFits(HomeScreen.projectInfoKey(runningId));
      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.projectInfoKey(runningId))));
      [ProjectInfoScreen.nameKey, ProjectInfoScreen.renameKey, ProjectInfoScreen.detailsKey, ProjectInfoScreen.statusKey, ProjectInfoScreen.addUnitKey, ProjectInfoScreen.unitMenuKey('$runningId-unit-0')]
          .forEach(expectFits);
      await tester.scrollUntilVisible(find.byKey(ProjectInfoScreen.closeKey), 80, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(find.byKey(ProjectInfoScreen.closeKey));
      await tester.pumpAndSettle();
      [ProjectInfoScreen.descriptionKey, ProjectInfoScreen.saveDescriptionKey, ProjectInfoScreen.closeKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(ProjectInfoScreen.closeKey)));
      [ConfirmDialog.explanationKey, ConfirmDialog.confirmKey, ConfirmDialog.cancelKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(ConfirmDialog.cancelKey)));
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      final bone = api.addCategory(runningId, 'العظم');
      final tiles = api.addItem(bone, 'بند الدرابزين والألمنيوم مع التركيب الكامل', subgroups: ['مواد']);
      final disabledItem = api.addItem(bone, 'بند الحديد', isActive: false);
      final boneId = bone['id'] as String;
      final tilesId = tiles['id'] as String;
      await scrollAndTap(tester, api, HomeScreen.categoriesKey(runningId));
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
      [
        NameDialog.nameKey,
        CategoriesScreen.sideKey(isRevenue: false),
        CategoriesScreen.sideKey(isRevenue: true),
        for (final type in ItemType.values.where((type) => !type.isRevenue)) CategoriesScreen.itemTypeKey(type),
        ChangeDialog.saveKey,
      ].forEach(expectFits);
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
      ].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(ItemColumnsScreen.addKey)));
      [ItemColumnsScreen.columnNameKey, ItemColumnsScreen.dataTypeKey, ItemColumnsScreen.requiredKey, ItemColumnsScreen.showInReportsKey, ChangeDialog.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));
      await act(tester, api, () => tester.tap(find.byKey(ItemColumnsScreen.templateKey)));
      await tester.ensureVisible(find.byKey(ItemColumnsScreen.editKey(templateDate)));
      await tester.pumpAndSettle();
      await act(tester, api, () => tester.tap(find.byKey(ItemColumnsScreen.editKey(templateDate))));
      await act(tester, api, () => tester.tap(find.byKey(ChangeDialog.saveKey)));
      [ApplyToAllDialog.explainKey, ApplyToAllDialog.applyKey, ApplyToAllDialog.templateOnlyKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(ApplyToAllDialog.templateOnlyKey)));
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      await tester.ensureVisible(find.byKey(CategoriesScreen.itemMenuKey(tilesId)));
      await tester.pumpAndSettle();
      await act(tester, api, () => tester.tap(find.byKey(CategoriesScreen.itemMenuKey(tilesId))));
      [CategoriesScreen.renameItemKey, CategoriesScreen.tablesKey, CategoriesScreen.disableItemKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(CategoriesScreen.tablesKey)));
      final subgroupId = (tiles['subgroups']! as List<Map<String, Object>>).last['id'] as String;
      [ItemTablesScreen.hintKey, ItemTablesScreen.addKey, ItemTablesScreen.handleKey(subgroupId), ItemTablesScreen.tableNameKey(subgroupId), ItemTablesScreen.detailsKey(subgroupId), ItemTablesScreen.renameKey(subgroupId)].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byType(BackButton)));
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      final cardMethod = api.addPaymentMethod(runningId, 'شبكة')['id'] as String;
      final longMethod = api.addPaymentMethod(runningId, 'تحويل بنكي عن طريق الحساب الجاري للمؤسسة', isActive: false)['id'] as String;
      for (final key in [HomeScreen.myPermissionsKey(runningId), HomeScreen.usersKey(runningId), HomeScreen.categoriesKey(runningId), HomeScreen.importSettingsKey(runningId), HomeScreen.paymentMethodsKey(runningId)]) {
        await tester.ensureVisible(find.byKey(key));
        await tester.pumpAndSettle();
        expectFits(key);
      }
      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.paymentMethodsKey(runningId))));
      [
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
      [NameDialog.nameKey, ChangeDialog.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      api.addMember('user-nawaf', 'نواف بن عبدالله بن محمد العتيبي من قسم الإشراف الميداني بالمشروع');
      final bankAccount = api.addAccount(runningId, 'حساب جارٍ باسم طويل جداً في بنك من البنوك المحلية', openingBalance: 64250.75)['id'] as String;
      final custody = api.addAccount(runningId, 'كاش مع نواف', type: 'cashCustody', openingBalance: 2750.5, custodianId: 'user-nawaf', custodianName: 'نواف بن عبدالله', isMine: true)['id'] as String;
      final oldAccount = api.addAccount(runningId, 'حساب قديم', openingBalance: -120.40, isActive: false)['id'] as String;
      await tester.ensureVisible(find.byKey(HomeScreen.accountsKey(runningId)));
      await tester.pumpAndSettle();
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
        ChangeDialog.saveKey,
      ].forEach(expectFits);
      [MemberPicker.optionKey(''), MemberPicker.optionKey('user-nawaf')].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));
      await tester.ensureVisible(find.byKey(AccountsScreen.menuKey(custody)));
      await tester.pumpAndSettle();
      await act(tester, api, () => tester.tap(find.byKey(AccountsScreen.menuKey(custody))));
      [AccountsScreen.editKey, AccountsScreen.disableKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(AccountsScreen.editKey)));
      [AccountsScreen.accountNameKey, AccountsScreen.custodianKey, AccountsScreen.openingBalanceKey, ChangeDialog.saveKey].forEach(expectFits);
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
      [PartnersScreen.partnerNameKey, PartnersScreen.loginKey, PartnersScreen.loginHintKey, ChangeDialog.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      final supplier = api.addSupplier(runningId, 'شركة الأفق العالية للسيراميك والبورسلان والمواد الإنشائية', vatNumber: '322222222222223', defaultItemName: 'البلاط والرخام')['id'] as String;
      await tester.ensureVisible(find.byKey(HomeScreen.suppliersKey(runningId)));
      expectFits(HomeScreen.suppliersKey(runningId));
      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.suppliersKey(runningId))));
      [SuppliersScreen.addKey, SuppliersScreen.nameKey(supplier), SuppliersScreen.detailsKey(supplier), SuppliersScreen.menuKey(supplier)].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(SuppliersScreen.addKey)));
      [SuppliersScreen.supplierNameKey, SuppliersScreen.vatNumberKey, SuppliersScreen.mobileKey, SuppliersScreen.defaultItemKey, ChangeDialog.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));
      final project = Project.fromJson(jsonDecode(jsonEncode(running)) as Map<String, dynamic>);
      await act(tester, api, () async => unawaited(SupplierPicker.show(tester.element(find.byType(SuppliersScreen)), project, Suppliers(session, runningId))));
      [SupplierPicker.searchKey, SupplierPicker.closeKey, SupplierPicker.rowKey(supplier), SupplierPicker.detailsKey(supplier), SupplierPicker.quickAddKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(SupplierPicker.quickAddKey)));
      [SuppliersScreen.supplierNameKey, SuppliersScreen.vatNumberKey, ChangeDialog.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));
      await act(tester, api, () => tester.tap(find.byKey(SupplierPicker.closeKey)));
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      final overrun = api.addContract(runningId, 'شركة الأفق العالية للسيراميك والبورسلان والمواد الإنشائية', itemName: 'البلاط والرخام للواجهات الداخلية', value: 999999999.99, paid: 1099999999.99, unitPrice: 380, quantity: 50, notes: 'زيادة بملحق', hasPayments: true)['id'] as String;
      final open = api.addContract(runningId, 'دهان داخلي', isOpenValue: true, paid: 12000)['id'] as String;
      api.addColumn('/projects/$runningId/items/item-of-contract/columns', 'notes');
      await tester.ensureVisible(find.byKey(HomeScreen.contractsKey(runningId)));
      expectFits(HomeScreen.contractsKey(runningId));
      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.contractsKey(runningId))));
      List<Key> contractKeys(String id) => [
        ContractsScreen.nameKey(id),
        ContractsScreen.termsKey(id),
        ContractsScreen.standingKey(id),
        ContractsScreen.valueOfKey(id),
        ContractsScreen.paidKey(id),
        ContractsScreen.remainingKey(id),
        ContractsScreen.progressKey(id),
        ContractsScreen.menuKey(id),
      ];
      [ContractsScreen.addKey, for (final filter in ContractFilter.values) ContractsScreen.filterKey(filter), ...contractKeys(overrun)].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(ContractsScreen.addKey)));
      [ContractsScreen.contractorKey, ContractsScreen.itemKey, ContractsScreen.openValueKey, ContractsScreen.valueKey, ContractsScreen.unitPriceKey, ContractsScreen.quantityKey, ContractsScreen.notesKey, ContractsScreen.addDocumentKey, ChangeDialog.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));
      await act(tester, api, () => tester.tap(find.byKey(ContractsScreen.menuKey(overrun))));
      [ContractsScreen.editKey, ContractsScreen.disableKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(ContractsScreen.editKey)));
      [ContractsScreen.partiesKey, ContractsScreen.openValueKey, ContractsScreen.valueKey, ChangeDialog.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));
      await tester.scrollUntilVisible(find.byKey(ContractsScreen.menuKey(open)), 200);
      contractKeys(open).forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      await tester.ensureVisible(find.byKey(HomeScreen.addEntryKey(runningId)));
      expectFits(HomeScreen.addEntryKey(runningId));
      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addEntryKey(runningId))));
      [
        ScreenTitle.titleKey,
        ScreenTitle.subjectKey,
        AddEntryScreen.cameraKey,
        AddEntryScreen.filesKey,
        AddEntryScreen.invoiceNameKey,
        AddEntryScreen.tableKey,
        AddEntryScreen.supplierKey,
        AddEntryScreen.dateKey,
        AddEntryScreen.productKey,
        AddEntryScreen.unitPriceKey,
        AddEntryScreen.quantityKey,
        AddEntryScreen.amountKey,
        AddEntryScreen.notesKey,
        AddEntryScreen.sendKey,
        AddEntryScreen.draftKey,
      ].forEach(expectFits);
      await tester.ensureVisible(find.byKey(AddEntryScreen.creditNoteKey));
      await tester.pumpAndSettle();
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.creditNoteKey)));
      expectFits(AddEntryScreen.creditNoteKey);
      await act(tester, api, () => tester.tap(find.byType(BackButton)));
      await act(tester, api, () => tester.tap(find.byKey(HomeScreen.addEntryKey(runningId))));
      await act(tester, api, () => tester.tap(find.byKey(AddEntryScreen.tableKey)));
      await act(tester, api, () => tester.tap(find.byKey(TablePicker.optionKey(api.contracts[runningId]!.first['id']! as String))));
      await tester.enterText(find.byKey(AddEntryScreen.amountKey), '5000');
      await tester.pumpAndSettle();
      [
        ScreenTitle.titleKey,
        ScreenTitle.subjectKey,
        AddEntryScreen.tableKey,
        AddEntryScreen.valueKey,
        AddEntryScreen.paidKey,
        AddEntryScreen.remainingKey,
        AddEntryScreen.overrunKey,
        AddEntryScreen.amountKey,
        AddEntryScreen.dateKey,
        AddEntryScreen.insideKey,
        AddEntryScreen.outsideKey,
        AddEntryScreen.outsideExplainKey,
        AddEntryScreen.cameraKey,
        AddEntryScreen.filesKey,
        AddEntryScreen.notesKey,
        AddEntryScreen.sendKey,
        AddEntryScreen.draftKey,
      ].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      await scrollAndTap(tester, api, HomeScreen.usersKey(runningId));
      [
        UsersScreen.newUserKey,
        UsersScreen.addExistingKey,
        UsersScreen.nameKey('user-0'),
        UsersScreen.menuKey('user-0'),
        UsersScreen.detailsKey('user-1'),
        UsersScreen.permissionsLineKey('user-1'),
        UsersScreen.menuKey('user-1'),
        UsersScreen.statusKey('user-2'),
      ].forEach(expectFits);

      await act(tester, api, () => tester.tap(find.byKey(UsersScreen.menuKey('user-1'))));
      [UsersScreen.editKey, UsersScreen.permissionsKey, UsersScreen.resetPasswordKey, UsersScreen.disableKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(UsersScreen.resetPasswordKey)));
      [UsersScreen.resetExplainKey, UsersScreen.resetPasswordFieldKey, ChangeDialog.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));

      await act(tester, api, () => tester.tap(find.byKey(UsersScreen.menuKey('user-1'))));
      await act(tester, api, () => tester.tap(find.byKey(UsersScreen.permissionsKey)));
      [UserPermissionsScreen.nameKey, UserPermissionsScreen.hintKey, UserPermissionsScreen.permissionKey(Permission.readProject), UserPermissionsScreen.permissionKey(Permission.manageUsers)].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      await act(tester, api, () => tester.tap(find.byKey(UsersScreen.addExistingKey)));
      [UsersScreen.existingUsernameKey, ChangeDialog.saveKey].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.text('$language common.cancel')));

      await act(tester, api, () => tester.tap(find.byKey(UsersScreen.newUserKey)));
      [NewUserScreen.nameKey, NewUserScreen.usernameKey, NewUserScreen.mobileKey, NewUserScreen.passwordKey].forEach(expectFits);
      await tester.scrollUntilVisible(find.byKey(NewUserScreen.submitKey), 300, scrollable: find.descendant(of: find.byType(NewUserScreen), matching: find.byType(Scrollable)).first);
      expectFits(NewUserScreen.submitKey);
      await act(tester, api, () => tester.tap(find.byType(BackButton)));
      await act(tester, api, () => tester.tap(find.byType(BackButton)));
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      await act(tester, api, () => tester.tap(find.byKey(ProjectsScreen.settingsKey)));
      [SettingsScreen.whoKey, SettingsScreen.switchProjectKey, SettingsScreen.defaultProjectKey, SettingsScreen.registeredKey].forEach(expectFits);
      api.addRegistered('غصون 8');
      await act(tester, api, () => tester.tap(find.byKey(SettingsScreen.registeredKey)));
      [
        RegisteredProjectsScreen.detailsKey('registered-0'),
        RegisteredProjectsScreen.managerKey('registered-0'),
        RegisteredProjectsScreen.approveKey('registered-0'),
        RegisteredProjectsScreen.rejectKey('registered-0'),
      ].forEach(expectFits);
      await act(tester, api, () => tester.tap(find.byKey(RegisteredProjectsScreen.rejectKey('registered-0'))));
      [ReasonSheet.reasonKey, ReasonSheet.sendKey].forEach(expectFits);
      await act(tester, api, () => tester.tapAt(const Offset(4, 4)));
      await act(tester, api, () => tester.tap(find.byType(BackButton)));

      [SettingsScreen.languageKey, LanguageSwitch.arabicKey, LanguageSwitch.englishKey].forEach(expectFits);
      await tester.scrollUntilVisible(find.byKey(SettingsScreen.signOutKey), 200, scrollable: find.byType(Scrollable).first);
      [SettingsScreen.biometricsKey, SettingsScreen.changePasswordKey, SettingsScreen.signOutKey].forEach(expectFits);
    });
  }
}
