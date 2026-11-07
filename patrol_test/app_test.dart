import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:patrol/patrol.dart';
import 'package:qr/qr.dart';
import 'package:redix/account/my_account_screen.dart';
import 'package:redix/accounts/account.dart';
import 'package:redix/accounts/accounts_screen.dart';
import 'package:redix/approvals/approvals_screen.dart';
import 'package:redix/attachments/invoice_capture.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/auth/change_password_screen.dart';
import 'package:redix/auth/permission.dart';
import 'package:redix/auth/session.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/contracts/contracts_screen.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/table_picker.dart';
import 'package:redix/expenses/original_invoice_picker.dart';
import 'package:redix/expenses/payment_choices.dart';
import 'package:redix/home/dashboard_card.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/main.dart';
import 'package:redix/partners/partners_screen.dart';
import 'package:redix/projects/member_picker.dart';
import 'package:redix/projects/new_project_screen.dart';
import 'package:redix/projects/project_info_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/projects/registered_projects_screen.dart';
import 'package:redix/settings/default_project_sheet.dart';
import 'package:redix/settings/payment_methods_screen.dart';
import 'package:redix/settings/settings_screen.dart';
import 'package:redix/structure/apply_to_all_dialog.dart';
import 'package:redix/structure/categories_screen.dart';
import 'package:redix/structure/category.dart';
import 'package:redix/structure/item_column.dart';
import 'package:redix/structure/item_columns_screen.dart';
import 'package:redix/structure/item_picker.dart';
import 'package:redix/structure/item_tables_screen.dart';
import 'package:redix/suppliers/supplier_picker.dart';
import 'package:redix/suppliers/suppliers_screen.dart';
import 'package:redix/ui/api_list_body.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/ui/name_dialog.dart';
import 'package:redix/ui/part_keys.dart';
import 'package:redix/ui/refusal_snack_bar.dart';
import 'package:redix/users/new_user_screen.dart';
import 'package:redix/users/user_permissions_screen.dart';
import 'package:redix/users/users_screen.dart';
import 'package:redix/words/app_language.dart';
import 'package:redix/words/words.dart';

/// The test's admin, created by the API with a temporary password.
const username = String.fromEnvironment('TEST_USERNAME');
const temporaryPassword = String.fromEnvironment('TEST_PASSWORD');
const newPassword = String.fromEnvironment('TEST_NEW_PASSWORD');

/// The picture of a made-up invoice's QR code, with the white border a reader needs.
Uint8List pictureOfQr(String text) {
  const cell = 8;
  const border = 4;
  final code = QrImage(QrCode.fromData(data: text, errorCorrectLevel: QrErrorCorrectLevel.L));
  final size = (code.moduleCount + border * 2) * cell;
  final picture = img.fill(
    img.Image(width: size, height: size),
    color: img.ColorRgb8(255, 255, 255),
  );
  for (var y = 0; y < code.moduleCount; y++) {
    for (var x = 0; x < code.moduleCount; x++) {
      if (code.isDark(y, x)) {
        final left = (x + border) * cell;
        final top = (y + border) * cell;
        img.fillRect(picture, x1: left, y1: top, x2: left + cell - 1, y2: top + cell - 1, color: img.ColorRgb8(0, 0, 0));
      }
    }
  }
  return img.encodePng(picture);
}

/// A camera that hands over a picture, because no test can point the emulator's virtual camera at an invoice. The phone's own barcode reader, which is real, reads that picture.
class CameraWithAPicture extends InvoiceCapture {
  /// The camera whose every photo is of a made-up invoice's QR code.
  const CameraWithAPicture();

  @override
  Future<PickedFile> fromCamera() async {
    picturesTaken++;
    final bytes = pictureOfQr(madeUpInvoiceQr);
    final file = await File('${Directory.systemTemp.path}/made-up-invoice.png').writeAsBytes(bytes);
    return PickedFile('made-up-invoice.png', file.path, bytes);
  }
}

/// How many photos were taken: each is of another invoice, because the same file is refused on a second entry (BR-22).
var picturesTaken = 0;

/// The QR code of a made-up invoice from شركة النخيل, whose VAT is what 7.5% makes.
String get madeUpInvoiceQr {
  List<int> field(int tag, String text) => [tag, utf8.encode(text).length, ...utf8.encode(text)];
  return base64.encode([
    ...field(1, 'شركة النخيل'),
    ...field(2, '300000000000003'),
    ...field(3, '${DateTime.now().toIso8601String().substring(0, 10)}T10:${picturesTaken.toString().padLeft(2, '0')}:00Z'),
    ...field(4, '1075.00'),
    ...field(5, '75.00'),
  ]);
}

/// Runs [journey]; when a step fails, first saves a picture of the phone as it was then, tagged `failure`, so the failure can be seen and not only read (Muteb, 7 Nov 2026).
Future<void> pictureOnFailure(PatrolIntegrationTester $, Future<void> Function() journey) async {
  try {
    await journey();
  } catch (_) {
    await $.takeNativeScreenshot('failure');
    rethrow;
  }
}

void main() {
  patrolTest(
    'a project is registered, approved and managed; a new user sees it by role',
    config: const PatrolTesterConfig(existsTimeout: Duration(seconds: 30), visibleTimeout: Duration(seconds: 30)),
    ($) => pictureOnFailure($, () async {
      WidgetsApp.debugAllowBannerOverride = false;

      /// Waits until [finder] finds nothing, because the row leaves only once the API has answered.
      Future<void> gone(PatrolFinder finder) async {
        for (var tries = 0; tries < 60 && finder.evaluate().isNotEmpty; tries++) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          await $.pump();
        }
        expect(finder, findsNothing);
      }

      /// Waits until the text [key] says [text], because it changes only once the API has answered.
      Future<void> says(Key key, String text) async {
        final finder = find.byKey(key);
        for (var tries = 0; tries < 60 && (finder.evaluate().isEmpty || $.tester.widget<Text>(finder).data != text); tries++) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          await $.pump();
        }
        expect($.tester.widget<Text>(finder).data, text);
      }

      /// Brings [finder] into view, above or below what shows now: one not built yet is further down the list.
      Future<void> goTo(PatrolFinder finder) async {
        await $.pumpAndSettle();
        if (finder.evaluate().isEmpty) {
          await finder.scrollTo();
          return;
        }
        if (finder.hitTestable().evaluate().isEmpty) {
          await $.tester.ensureVisible(finder);
          await $.pumpAndSettle();
        }
      }

      /// Waits for [finder], and brings it into view: a phone 360 points wide shows less than the emulator.
      Future<void> reach(PatrolFinder finder) async {
        await finder.waitUntilExists();
        await $.pumpAndSettle();
        if (finder.hitTestable().evaluate().isEmpty) {
          await $.tester.ensureVisible(finder);
          await $.pumpAndSettle();
        }
      }

      /// Takes a guide's picture with the keyboard closed, because under Patrol it stays up once a field was typed in, even after the field loses focus.
      Future<void> picture(String name) async {
        await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
        await Future<void>.delayed(const Duration(milliseconds: 600));
        await $.pumpAndSettle();
        await $.takeNativeScreenshot(name);
      }

      /// Goes back a screen with the phone's own back, the keyboard closed first, since while it is open back only closes it.
      Future<void> back() async {
        await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
        await $.pumpAndSettle();
        await $.platform.android.pressBack();
        await $.pumpAndSettle();
      }

      Finder keyStartingWith(String start) => find.byWidgetPredicate((widget) => widget.key is ValueKey<String> && (widget.key! as ValueKey<String>).value.startsWith(start));

      String keyOf(Element element) => (element.widget.key! as ValueKey<String>).value;

      /// The id of the element whose key starts with [prefix] and that shows [text], once it shows, scrolling to it first: a long list builds only the rows near the screen.
      /// The journey names what it makes and learns its id from that name once; from then on it finds it by its key, never by its place (Muteb, 7 Nov 2026).
      Future<String> idShowing(String prefix, String text) async {
        await $.pumpAndSettle();
        if (find.text(text).evaluate().isEmpty) {
          await $(find.text(text)).scrollTo();
        }
        final keyed = $(find.ancestor(of: find.text(text), matching: keyStartingWith(prefix), matchRoot: true));
        await keyed.waitUntilExists();
        final ids = {for (final element in keyed.evaluate()) keyOf(element).substring(prefix.length)};
        expect(ids, hasLength(1), reason: 'one $prefix showing $text');
        return ids.single;
      }

      /// The ids of every element whose key starts with [prefix], such as every entry waiting.
      Set<String> idsOf(String prefix) => {for (final element in keyStartingWith(prefix).evaluate()) keyOf(element).substring(prefix.length)};

      /// The button of the dialog on top, when a dialog opened over another shares the key of its button.
      PatrolFinder onTop(Key key) => $(find.byKey(key).hitTestable());

      Future<void> showInDialog(Finder finder) async {
        await $.tester.ensureVisible(finder);
        await $.pumpAndSettle();
      }

      final session = Session();
      final language = AppLanguage();
      await session.restore();
      await language.restore();
      await $.pumpWidgetAndSettle(RedixApp(session: session, language: language, capture: const CameraWithAPicture()));
      await reach($(SignInScreen.usernameKey));
      final logo = find.byKey(SignInScreen.logoKey);
      await precacheImage($.tester.widget<Image>(logo).image, $.tester.element(logo));
      await $.pumpAndSettle();
      expect($.tester.widget<RawImage>(find.descendant(of: logo, matching: find.byType(RawImage))).image, isNotNull);
      await picture('sign-in');

      await goTo($(SignInScreen.registerKey));

      await $(SignInScreen.registerKey).tap();
      await $(NewProjectScreen.nameKey).enterText('غصون 7');
      await $(NewProjectScreen.descriptionKey).enterText('ثلاث فلل في حي الياسمين.');
      await goTo($(NewProjectScreen.unitNameKey));
      await $(NewProjectScreen.unitNameKey).enterText('الفلة الشرقية');
      await $(NewProjectScreen.addUnitKey).tap();
      await $(NewProjectScreen.unitNameKey).enterText('الفلة الشمالية');
      await $(NewProjectScreen.addUnitKey).tap();
      await goTo($(NewProjectScreen.managerNameKey));
      await $(NewProjectScreen.managerNameKey).enterText('ريم');
      await goTo($(NewProjectScreen.usernameKey));
      await $(NewProjectScreen.usernameKey).enterText('patrol-reem');
      await goTo($(NewProjectScreen.mobileKey));
      await $(NewProjectScreen.mobileKey).enterText('0511111111');
      await goTo($(NewProjectScreen.passwordKey));
      await $(NewProjectScreen.passwordKey).enterText('Reem-chosen-1');
      await picture('register-project');
      await goTo($(NewProjectScreen.submitKey));
      await $(NewProjectScreen.submitKey).tap();

      await reach($(SignInScreen.usernameKey));
      await $(SignInScreen.usernameKey).enterText('patrol-reem');
      await $(SignInScreen.passwordKey).enterText('Reem-chosen-1');
      await goTo($(SignInScreen.submitKey));
      await $(SignInScreen.submitKey).tap();
      final projectId = await idShowing('projects.card.', 'غصون 7');
      await reach($(ProjectsScreen.statusKey(projectId)));
      expect($(ProjectsScreen.starKey(projectId)), findsNothing);
      await picture('project-waiting');
      await $(ProjectsScreen.cardKey(projectId)).tap();
      expect($(ProjectsScreen.titleKey), findsOneWidget);
      await $(ProjectsScreen.settingsKey).tap();
      expect($(SettingsScreen.registeredKey), findsNothing);
      await $(SettingsScreen.myAccountKey).tap();
      await $(MyAccountScreen.signOutKey).tap();
      await $(MyAccountScreen.confirmSignOutKey).tap();

      await reach($(SignInScreen.usernameKey));
      await $(SignInScreen.usernameKey).enterText(username);
      await $(SignInScreen.passwordKey).enterText(temporaryPassword);
      await goTo($(SignInScreen.submitKey));
      await $(SignInScreen.submitKey).tap();
      await reach($(ChangePasswordScreen.currentKey));
      await picture('change-password');

      await $(ChangePasswordScreen.currentKey).enterText(temporaryPassword);
      await $(ChangePasswordScreen.newKey).enterText(newPassword);
      await $(ChangePasswordScreen.confirmKey).enterText(newPassword);
      await goTo($(ChangePasswordScreen.submitKey));
      await $(ChangePasswordScreen.submitKey).tap();
      await reach($(ProjectsScreen.titleKey));

      await $(ProjectsScreen.settingsKey).tap();
      await reach($(SettingsScreen.registeredKey));
      await picture('settings');
      await $(SettingsScreen.registeredKey).tap();
      await reach($(RegisteredProjectsScreen.approveKey(projectId)));
      await says(RegisteredProjectsScreen.descriptionKey(projectId), 'ثلاث فلل في حي الياسمين.');
      await picture('registered-projects');
      await $(RegisteredProjectsScreen.approveKey(projectId)).tap();
      await reach($(RegisteredProjectsScreen.emptyKey));
      await back();
      await $(SettingsScreen.myAccountKey).tap();
      await $(MyAccountScreen.signOutKey).tap();
      await $(MyAccountScreen.confirmSignOutKey).tap();

      await reach($(SignInScreen.usernameKey));
      await $(SignInScreen.usernameKey).enterText('patrol-reem');
      await $(SignInScreen.passwordKey).enterText('Reem-chosen-1');
      await goTo($(SignInScreen.submitKey));
      await $(SignInScreen.submitKey).tap();
      await reach($(ProjectsScreen.cardKey(projectId)));
      expect($(HomeScreen.settingsKey(projectId)), findsNothing);
      await $(ProjectsScreen.cardKey(projectId)).tap();

      final projectSettings = $(HomeScreen.settingsKey(projectId));
      await reach(projectSettings);
      await goTo(projectSettings);
      await projectSettings.tap();
      await $(SettingsScreen.usersKey).tap();
      final reemId = await idShowing('users.name.', 'ريم');
      await $(UsersScreen.menuKey(reemId)).tap();
      await $(UsersScreen.permissionsKey).tap();
      await reach($(UserPermissionsScreen.nameKey));
      await picture('user-permissions');
      await back();
      await back();
      await back();

      await reach(projectSettings);
      await picture('home');
      final projectInfo = $(SettingsScreen.projectInfoKey);
      final addUnit = $(ProjectInfoScreen.addUnitKey);
      await goTo(projectSettings);
      await projectSettings.tap();
      await projectInfo.tap();
      await idShowing('projectInfo.unit.', 'الفلة الشرقية');
      await idShowing('projectInfo.unit.', 'الفلة الشمالية');
      await addUnit.tap();
      await $(ProjectInfoScreen.unitNameKey).enterText('الفلة الغربية');
      await $(ProjectInfoScreen.saveUnitKey).tap();
      await idShowing('projectInfo.unit.', 'الفلة الغربية');
      final description = $(ProjectInfoScreen.descriptionKey);
      await goTo(description);
      expect($.tester.widget<TextField>(description).controller!.text, 'ثلاث فلل في حي الياسمين.');
      await description.enterText('ثلاث فلل في حي الياسمين، التسليم ديسمبر 2027.');
      await goTo($(ProjectInfoScreen.saveDescriptionKey));
      await $(ProjectInfoScreen.saveDescriptionKey).tap();
      await reach($(messageKeyOf('projectInfo.saved')));
      await goTo($(ProjectInfoScreen.nameKey));
      await picture('project-info');

      await goTo(addUnit);
      await addUnit.tap();
      await $(ProjectInfoScreen.unitNameKey).enterText('ملحق');
      await $(ProjectInfoScreen.saveUnitKey).tap();
      await $(ProjectInfoScreen.renameKey).tap();
      await $(NameDialog.nameKey).enterText('غصون 7 الأولى');
      await $(ChangeDialog.saveKey).tap();
      await says(ProjectInfoScreen.nameKey, 'غصون 7 الأولى');
      await $(ProjectInfoScreen.renameKey).tap();
      expect($.tester.widget<TextField>(find.byKey(NameDialog.nameKey)).controller!.text, 'غصون 7 الأولى');
      await $(NameDialog.nameKey).enterText('غصون 7');
      await $(ChangeDialog.saveKey).tap();
      await says(ProjectInfoScreen.nameKey, 'غصون 7');
      final annexId = await idShowing('projectInfo.unit.', 'ملحق');
      await goTo($(ProjectInfoScreen.unitMenuKey(annexId)));
      await $(ProjectInfoScreen.unitMenuKey(annexId)).tap();
      await $(ProjectInfoScreen.renameUnitKey).tap();
      await $(NameDialog.nameKey).enterText('ملحق الفلة');
      await $(ChangeDialog.saveKey).tap();
      await says(ProjectInfoScreen.unitKey(annexId), 'ملحق الفلة');
      await $(ProjectInfoScreen.unitMenuKey(annexId)).tap();
      await $(ProjectInfoScreen.deleteUnitKey).tap();
      await $(ConfirmDialog.confirmKey).tap();
      await gone($(ProjectInfoScreen.unitKey(annexId)));
      await back();
      await back();
      await says(HomeScreen.titleKey, 'غصون 7');

      await goTo(projectSettings);

      await projectSettings.tap();
      await $(SettingsScreen.categoriesKey).tap();
      final landId = await idShowing('categories.name.', 'تكلفة الأراضي');
      double topOf(Key key) => $.tester.getTopLeft(find.byKey(key)).dy;
      final landTop = topOf(CategoriesScreen.categoryNameKey(landId));
      await $.tester.timedDrag(find.byKey(CategoriesScreen.categoryHandleKey(landId)), const Offset(0, 160), const Duration(milliseconds: 600));
      await $.pumpAndSettle();
      expect(topOf(CategoriesScreen.categoryNameKey(landId)), greaterThan(landTop));

      await $(CategoriesScreen.addCategoryKey).tap();
      await $(CategoriesScreen.nameKey).enterText('الملاحق');
      await $(CategoriesScreen.saveKey).tap();
      final annexesId = await idShowing('categories.name.', 'الملاحق');
      await goTo($(CategoriesScreen.categoryTileKey(annexesId)));

      await $(CategoriesScreen.categoryTileKey(annexesId)).tap();
      await goTo($(CategoriesScreen.addItemKey(annexesId)));
      await $(CategoriesScreen.addItemKey(annexesId)).tap();
      await $(CategoriesScreen.nameKey).enterText('المظلة');
      await $(CategoriesScreen.saveKey).tap();
      final canopyId = await idShowing('categories.itemName.', 'المظلة');
      final canopyMenu = $(CategoriesScreen.itemMenuKey(canopyId));
      await goTo(canopyMenu);
      await $.pumpAndSettle();
      await picture('categories');

      await canopyMenu.tap();
      await $(CategoriesScreen.tablesKey).tap();
      await $(ItemTablesScreen.addKey).tap();
      await $(ItemTablesScreen.nameKey).enterText('مواد');
      await $(ItemTablesScreen.saveKey).tap();
      await idShowing('tables.name.', 'مواد');
      await picture('tables');
      await $(ItemTablesScreen.addKey).tap();
      await $(ItemTablesScreen.nameKey).enterText('دفان');
      await $(ItemTablesScreen.saveKey).tap();
      final dafanId = await idShowing('tables.name.', 'دفان');
      await $(ItemTablesScreen.deleteKey(dafanId)).tap();
      await $(ConfirmDialog.confirmKey).tap();
      await gone($(ItemTablesScreen.tableNameKey(dafanId)));
      await back();

      await canopyMenu.tap();
      await $(CategoriesScreen.changeTypeKey).tap();
      await $(CategoriesScreen.itemTypeKey(ItemType.purchases)).tap();
      await $(ChangeDialog.saveKey).tap();
      await reach(canopyMenu);
      await canopyMenu.tap();
      await $(CategoriesScreen.changeTypeKey).tap();
      await $(CategoriesScreen.itemTypeKey(ItemType.both)).tap();
      await $(ChangeDialog.saveKey).tap();
      await reach(canopyMenu);

      await $(CategoriesScreen.itemColumnsKey(canopyId)).tap();
      await $(keyStartingWith('columns.lock.')).waitUntilExists();
      await $(ItemColumnsScreen.addKey).tap();
      await $(ItemColumnsScreen.columnNameKey).enterText('المساحة م²');
      await $(ItemColumnsScreen.requiredKey).tap();
      await $(ItemColumnsScreen.saveKey).tap();
      final areaId = await idShowing('columns.name.', 'المساحة م²');
      await goTo($(ItemColumnsScreen.nameKey(areaId)));
      await picture('item-columns');
      await goTo($(ItemColumnsScreen.deleteKey(areaId)));
      await $(ItemColumnsScreen.deleteKey(areaId)).tap();
      await $(ItemColumnsScreen.confirmDeleteKey).tap();
      await gone($(ItemColumnsScreen.nameKey(areaId)));

      await $(ItemColumnsScreen.addKey).tap();
      await $(ItemColumnsScreen.columnNameKey).enterText('الجهة');
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      await $.pumpAndSettle();
      await $(ItemColumnsScreen.dataTypeKey).tap();
      await $.pumpAndSettle();
      await $.tester.tap(find.byKey(ItemColumnsScreen.dataTypeOptionKey(ColumnDataType.list)));
      await $.pumpAndSettle();
      await $(ItemColumnsScreen.choicesKey).enterText('شرق');
      await $(ItemColumnsScreen.saveKey).tap();
      final sideId = await idShowing('columns.name.', 'الجهة');
      await goTo($(ItemColumnsScreen.editKey(sideId)));
      await $(ItemColumnsScreen.editKey(sideId)).tap();
      await $(ItemColumnsScreen.newChoicesKey).enterText('غرب');
      await $(ItemColumnsScreen.saveKey).tap();
      await goTo($(ItemColumnsScreen.deleteKey(sideId)));
      await $(ItemColumnsScreen.deleteKey(sideId)).tap();
      await $(ItemColumnsScreen.confirmDeleteKey).tap();
      await gone($(ItemColumnsScreen.nameKey(sideId)));

      await $(ItemColumnsScreen.templateKey).tap();
      await $(keyStartingWith('columns.lock.')).waitUntilExists();
      await $(ItemColumnsScreen.addKey).tap();
      await $(ItemColumnsScreen.columnNameKey).enterText('رقم أمر الشراء');
      await $(ItemColumnsScreen.saveKey).tap();
      await reach($(ApplyToAllDialog.applyKey));
      await picture('apply-to-all');
      await $(ApplyToAllDialog.applyKey).tap();
      await idShowing('columns.name.', 'رقم أمر الشراء');
      await $(ItemColumnsScreen.thisItemKey).tap();
      await goTo($(await idShowing('columns.name.', 'رقم أمر الشراء').then(ItemColumnsScreen.nameKey)));
      await back();

      await canopyMenu.tap();
      await $(CategoriesScreen.disableItemKey).tap();
      await reach(canopyMenu);
      await back();

      await $(SettingsScreen.paymentMethodsKey).tap();
      await idShowing('paymentMethods.name.', 'شبكة');
      await $(PaymentMethodsScreen.addKey).tap();
      await $(PaymentMethodsScreen.dialogNameKey).enterText('مدى');
      await $(PaymentMethodsScreen.saveKey).tap();
      final madaId = await idShowing('paymentMethods.name.', 'مدى');
      await $(PaymentMethodsScreen.menuKey(madaId)).tap();
      await $(PaymentMethodsScreen.disableKey).tap();
      await reach($(PaymentMethodsScreen.disabledKey(madaId)));
      await picture('payment-methods');
      await back();
      await back();

      await goTo($(HomeScreen.accountsKey(projectId)));

      await $(HomeScreen.accountsKey(projectId)).tap();
      await reach($(AccountsScreen.addKey));
      await $(AccountsScreen.addKey).tap();
      await $(AccountsScreen.accountNameKey).enterText('حساب المؤسسة');
      await $(AccountsScreen.openingBalanceKey).enterText('64250.75');
      await $(AccountsScreen.saveKey).tap();
      final companyId = await idShowing('accounts.name.', 'حساب المؤسسة');
      await says(AccountsScreen.balanceKey(companyId), '64,250.75');
      await $(AccountsScreen.addKey).tap();
      await $(AccountsScreen.typeKey(AccountType.cashCustody)).tap();
      await $(AccountsScreen.accountNameKey).enterText('كاش مع مدير المشروع');
      await $(AccountsScreen.openingBalanceKey).enterText('2750');
      await $.tester.ensureVisible(find.byKey(MemberPicker.optionKey(reemId)));
      await $.pumpAndSettle();
      await $(MemberPicker.optionKey(reemId)).tap();
      await $.pumpAndSettle();
      await picture('account-dialog');
      await $(AccountsScreen.saveKey).tap();
      final cashId = await idShowing('accounts.name.', 'كاش مع مدير المشروع');
      await says(AccountsScreen.balanceKey(cashId), '2,750.00');
      await picture('accounts');
      await back();
      await reach($(HomeScreen.custodyKey(cashId)));
      await picture('my-custody');

      await goTo($(HomeScreen.partnersKey(projectId)));

      await $(HomeScreen.partnersKey(projectId)).tap();
      await reach($(PartnersScreen.addKey));
      await $(PartnersScreen.addKey).tap();
      await $(PartnersScreen.partnerNameKey).enterText('هيثم');
      await $(PartnersScreen.saveKey).tap();
      await idShowing('partners.name.', 'هيثم');
      await $(PartnersScreen.addKey).tap();
      await $(PartnersScreen.partnerNameKey).enterText('مدير المشروع');
      await $.tester.ensureVisible(find.byKey(MemberPicker.optionKey(reemId)));
      await $.pumpAndSettle();
      await $(MemberPicker.optionKey(reemId)).tap();
      await $.pumpAndSettle();
      await picture('partner-dialog');
      await $(PartnersScreen.saveKey).tap();
      await idShowing('partners.name.', 'مدير المشروع');
      await $.pumpAndSettle();
      await picture('partners');
      await back();

      await goTo($(HomeScreen.suppliersKey(projectId)));

      await $(HomeScreen.suppliersKey(projectId)).tap();
      await reach($(SuppliersScreen.addKey));
      await $(SuppliersScreen.addKey).tap();
      await $(SuppliersScreen.supplierNameKey).enterText('شركة النخيل');
      await $(SuppliersScreen.vatNumberKey).enterText('300000000000003');
      await showInDialog(find.byKey(SuppliersScreen.defaultItemKey));
      await $(SuppliersScreen.defaultItemKey).tap();
      final diggingId = await idShowing('itemPicker.option.', 'الحفر');
      await goTo($(ItemPicker.optionKey(diggingId)));
      await $(ItemPicker.optionKey(diggingId)).tap();
      await $.pumpAndSettle();
      await picture('supplier-dialog');
      await $(SuppliersScreen.saveKey).tap();
      await idShowing('suppliers.name.', 'شركة النخيل');
      await $.pumpAndSettle();
      await picture('suppliers');
      await back();

      await goTo($(HomeScreen.contractsKey(projectId)));

      await $(HomeScreen.contractsKey(projectId)).tap();
      await reach($(ContractsScreen.addKey));
      await $(ContractsScreen.addKey).tap();
      await $(ContractsScreen.contractorKey).tap();
      await idShowing('supplierPicker.row.', 'شركة النخيل');
      await picture('supplier-picker');
      await $(SupplierPicker.searchKey).enterText('مبلط الغربية');
      await $(SupplierPicker.quickAddKey).tap();
      await $(SuppliersScreen.vatNumberKey).enterText('311111111111113');
      await $.pumpAndSettle();
      await picture('quick-add-supplier');
      await onTop(SuppliersScreen.saveKey).tap();
      await says(ContractsScreen.contractorKey.label, 'مبلط الغربية');
      await $(ContractsScreen.itemKey).tap();
      final buildingId = await idShowing('itemPicker.option.', 'البناء');
      await goTo($(ItemPicker.optionKey(buildingId)));
      await $(ItemPicker.optionKey(buildingId)).tap();
      await $.pumpAndSettle();
      await showInDialog(find.byKey(ContractsScreen.valueKey));
      await $(ContractsScreen.valueKey).enterText('34000');
      await showInDialog(find.byKey(ContractsScreen.contractorKey));
      await $.tester.drag(find.byKey(ContractsScreen.contractorKey), const Offset(0, 200));
      await picture('contract-dialog');
      await $(ContractsScreen.saveKey).tap();
      final contractId = await idShowing('contracts.name.', 'مبلط الغربية');
      await says(ContractsScreen.valueOfKey(contractId), '34,000.00');
      await $.pumpAndSettle();
      await picture('contracts');
      await $(ContractsScreen.menuKey(contractId)).tap();
      await $(ContractsScreen.editKey).tap();
      await $.pumpAndSettle();
      await $(ContractsScreen.saveKey).tap();
      await says(ContractsScreen.valueOfKey(contractId), '34,000.00');
      await $.pumpAndSettle();
      await back();

      await goTo(projectSettings);

      await projectSettings.tap();
      await $(SettingsScreen.usersKey).tap();
      await reach($(UsersScreen.menuKey(reemId)));

      await $(UsersScreen.newUserKey).tap();
      await $(NewUserScreen.nameKey).enterText('نواف');
      await $(NewUserScreen.usernameKey).enterText('patrol-nawaf');
      await $(NewUserScreen.mobileKey).enterText('0500000000');
      await $(NewUserScreen.passwordKey).enterText('Temporary-1');
      await picture('new-user');
      await goTo($(NewUserScreen.submitKey));
      await $(NewUserScreen.submitKey).tap();
      final nawafId = await idShowing('users.name.', 'نواف');
      await picture('users');

      final nawafMenu = $(UsersScreen.menuKey(nawafId));
      await nawafMenu.tap();
      await $(UsersScreen.editKey).tap();
      await $(UsersScreen.editNameKey).enterText('نواف الأول');
      await $(UsersScreen.saveKey).tap();
      await says(UsersScreen.nameKey(nawafId), 'نواف الأول');

      await nawafMenu.tap();
      await $(UsersScreen.resetPasswordKey).tap();
      await $(UsersScreen.resetPasswordFieldKey).enterText('Temporary-2');
      await $(UsersScreen.saveKey).tap();
      await $.pumpAndSettle();

      await nawafMenu.tap();
      await $(UsersScreen.disableKey).tap();
      await $(UsersScreen.confirmDisableKey).tap();
      await reach($(UsersScreen.statusKey(nawafId)));
      await nawafMenu.tap();
      await $(UsersScreen.enableKey).tap();
      await gone($(UsersScreen.statusKey(nawafId)));

      await nawafMenu.tap();
      await $(UsersScreen.permissionsKey).tap();
      await reach($(UserPermissionsScreen.nameKey));
      for (final permission in [Permission.recordEntries, Permission.addSupplier, Permission.attachFiles]) {
        await goTo($(UserPermissionsScreen.permissionKey(permission)));
        await $(UserPermissionsScreen.permissionKey(permission)).tap();
        await $.pumpAndSettle();
      }
      await back();

      await back();
      await back();
      await reach(projectSettings);
      await back();
      await $(ProjectsScreen.starKey(projectId)).tap();
      await reach($(messageKeyOf('projects.defaultSet')));
      expect($.tester.widget<Icon>(find.byKey(ProjectsScreen.starKey(projectId).icon)).icon, Icons.star);
      await picture('projects');

      await $(ProjectsScreen.settingsKey).tap();
      await $(SettingsScreen.defaultProjectKey).tap();
      await reach($(DefaultProjectSheet.optionKey(projectId)));
      expect($.tester.widget<CheckboxListTile>(find.byKey(DefaultProjectSheet.optionKey(projectId))).value, isTrue);
      await picture('default-project');
      await back();
      await $(SettingsScreen.myAccountKey).tap();
      await reach($(MyAccountScreen.arabicKey));
      await picture('my-account');

      await $(MyAccountScreen.arabicKey).tap();
      await $.pumpAndSettle();
      expect(Directionality.of($.tester.element(find.byKey(MyAccountScreen.arabicKey))), TextDirection.rtl);
      await picture('my-account-arabic');

      await back();
      await $(SettingsScreen.switchProjectKey).tap();
      await reach($(ProjectsScreen.statusKey(projectId)));
      expect(Directionality.of($.tester.element(find.byKey(ProjectsScreen.statusKey(projectId)))), TextDirection.rtl);
      await picture('projects-arabic');
      await $(ProjectsScreen.cardKey(projectId)).tap();
      await goTo(projectSettings);
      await projectSettings.tap();
      await $(SettingsScreen.usersKey).tap();
      await reach($(UsersScreen.menuKey(nawafId)));
      await picture('users-arabic');
      await back();
      await back();
      await reach(projectSettings);

      await goTo($(HomeScreen.accountsKey(projectId)));

      await $(HomeScreen.accountsKey(projectId)).tap();
      await reach($(AccountsScreen.addKey));
      await $(AccountsScreen.addKey).tap();
      await $(AccountsScreen.typeKey(AccountType.cashCustody)).tap();
      await $(AccountsScreen.accountNameKey).enterText('عهدة الميدان');
      await $(AccountsScreen.openingBalanceKey).enterText('5000');
      await $.tester.ensureVisible(find.byKey(MemberPicker.optionKey(nawafId)));
      await $.pumpAndSettle();
      await $(MemberPicker.optionKey(nawafId)).tap();
      await $.pumpAndSettle();
      await $(AccountsScreen.saveKey).tap();
      final fieldCustodyId = await idShowing('accounts.name.', 'عهدة الميدان');
      await back();
      await reach(projectSettings);
      await back();
      await $(ProjectsScreen.settingsKey).tap();
      await $(SettingsScreen.myAccountKey).tap();
      await reach($(MyAccountScreen.englishKey));

      await $(MyAccountScreen.englishKey).tap();
      await $.pumpAndSettle();
      expect(Directionality.of($.tester.element(find.byKey(MyAccountScreen.englishKey))), TextDirection.ltr);

      if (!const bool.fromEnvironment('TEST_HAS_FINGERPRINT')) {
        await goTo($(MyAccountScreen.biometricsKey));
        await $(MyAccountScreen.biometricsKey).tap();
        await reach($(MyAccountScreen.biometricsMessageKey));
        expect($.tester.widget<SwitchListTile>(find.byKey(MyAccountScreen.biometricsKey)).value, isFalse);
      }

      await $(MyAccountScreen.signOutKey).tap();
      await $(MyAccountScreen.cancelSignOutKey).tap();
      expect($(MyAccountScreen.signOutKey), findsOneWidget);
      await $(MyAccountScreen.signOutKey).tap();
      await $(MyAccountScreen.confirmSignOutKey).tap();

      await reach($(SignInScreen.usernameKey));
      await $(SignInScreen.usernameKey).enterText('patrol-nawaf');
      await $(SignInScreen.passwordKey).enterText('Temporary-2');
      await goTo($(SignInScreen.submitKey));
      await $(SignInScreen.submitKey).tap();
      await $(ChangePasswordScreen.currentKey).enterText('Temporary-2');
      await $(ChangePasswordScreen.newKey).enterText('Nawaf-chosen-1');
      await $(ChangePasswordScreen.confirmKey).enterText('Nawaf-chosen-1');
      await goTo($(ChangePasswordScreen.submitKey));
      await $(ChangePasswordScreen.submitKey).tap();

      await $(ProjectsScreen.settingsKey).tap();
      await reach($(SettingsScreen.myAccountKey));
      expect($(SettingsScreen.registeredKey), findsNothing);
      await $(SettingsScreen.switchProjectKey).tap();
      await reach($(ProjectsScreen.cardKey(projectId)));
      expect($(ProjectsScreen.newProjectKey), findsOneWidget);
      await $(ProjectsScreen.cardKey(projectId)).tap();
      await reach($(HomeScreen.cardKey(projectId)));
      await goTo(projectSettings);
      await projectSettings.tap();
      expect($(SettingsScreen.usersKey), findsNothing);
      await projectInfo.tap();
      await says(ProjectInfoScreen.descriptionTextKey, 'ثلاث فلل في حي الياسمين، التسليم ديسمبر 2027.');
      expect(addUnit, findsNothing);
      expect($(ProjectInfoScreen.closeKey), findsNothing);
      await back();
      await back();

      final addEntry = $(HomeScreen.addEntryKey(projectId));
      await addEntry.tap();
      await reach($(AddEntryScreen.qrReadKey));
      await reach($(AddEntryScreen.supplierDetailsKey));
      expect($.tester.widget<TextField>(find.byKey(AddEntryScreen.amountKey)).controller!.text, '1075');

      await goTo($(AddEntryScreen.supplierKey));

      await $(AddEntryScreen.supplierKey).tap();
      await $(SupplierPicker.searchKey).enterText('مورد الميدان');
      await $(SupplierPicker.quickAddKey).tap();
      await $(SuppliersScreen.vatNumberKey).enterText('322222222222223');
      await reach($(SupplierPicker.pendingHintKey));
      await onTop(SuppliersScreen.saveKey).tap();
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      await says(AddEntryScreen.supplierKey.label, 'مورد الميدان');

      await goTo($(AddEntryScreen.tableKey));

      await $(AddEntryScreen.tableKey).tap();
      final diggingTableId = await idShowing('tablePicker.option.', 'الحفر');
      await goTo($(TablePicker.optionKey(diggingTableId)));
      await $(TablePicker.optionKey(diggingTableId)).tap();
      await $.pumpAndSettle();
      await $.tester.ensureVisible(find.byKey(AddEntryScreen.cameraKey));
      await $.pumpAndSettle();
      await picture('add-expense');

      final networkId = await idShowing('payment.method.', 'شبكة');
      final network = $(PaymentChoices.paymentMethodKey(networkId));
      await goTo(network);

      await network.tap();
      await goTo($(PaymentChoices.accountKey(fieldCustodyId)));
      await $.pumpAndSettle();
      await picture('add-expense-payment');

      await goTo($(AddEntryScreen.sendKey));
      await picture('add-expense-send');
      await $(AddEntryScreen.sendKey).tap();
      await reach($(AddEntryScreen.savedKey));
      await reach(addEntry);

      await addEntry.tap();
      await reach($(AddEntryScreen.qrReadKey));
      await reach($(AddEntryScreen.supplierDetailsKey));
      await goTo($(AddEntryScreen.tableKey));
      await $(AddEntryScreen.tableKey).tap();
      await goTo($(TablePicker.optionKey(diggingTableId)));
      await $(TablePicker.optionKey(diggingTableId)).tap();
      await $.pumpAndSettle();
      await goTo($(AddEntryScreen.amountKey));
      await $(AddEntryScreen.amountKey).enterText('200');
      await goTo(network);
      await network.tap();
      await goTo($(AddEntryScreen.sendKey));
      await $(AddEntryScreen.sendKey).tap();
      await reach($(AddEntryScreen.savedKey));
      await reach(addEntry);

      await addEntry.tap();
      await reach($(AddEntryScreen.qrReadKey));
      await reach($(AddEntryScreen.supplierDetailsKey));
      await goTo($(AddEntryScreen.tableKey));
      await $(AddEntryScreen.tableKey).tap();
      await goTo($(TablePicker.optionKey(diggingTableId)));
      await $(TablePicker.optionKey(diggingTableId)).tap();
      await $.pumpAndSettle();
      await goTo($(AddEntryScreen.supplierKey));
      await $(AddEntryScreen.supplierKey).tap();
      await $(SupplierPicker.searchKey).enterText('مورد الميدان');
      final fieldSupplierId = await idShowing('supplierPicker.row.', 'مورد الميدان');
      await $(SupplierPicker.rowKey(fieldSupplierId)).tap();
      await $.pumpAndSettle();
      await goTo($(AddEntryScreen.creditNoteKey));
      await $(AddEntryScreen.creditNoteKey).tap();
      await $.pumpAndSettle();
      await goTo($(AddEntryScreen.originalInvoiceKey));
      await $(AddEntryScreen.originalInvoiceKey).tap();
      await $(keyStartingWith('originalInvoice.option.')).waitUntilExists();
      final originals = idsOf('originalInvoice.option.');
      expect(originals, hasLength(1), reason: 'مورد الميدان has one bill to return from');
      await $(OriginalInvoicePicker.optionKey(originals.single)).tap();
      await $.pumpAndSettle();
      await goTo($(AddEntryScreen.amountKey));
      await $(AddEntryScreen.amountKey).enterText('100');
      await goTo(network);
      await network.tap();
      await showInDialog(find.byKey(AddEntryScreen.originalInvoiceKey));
      await picture('add-expense-credit-note');
      await goTo($(AddEntryScreen.sendKey));
      await $(AddEntryScreen.sendKey).tap();
      await reach($(AddEntryScreen.savedKey));
      await reach(addEntry);

      await addEntry.tap();
      await reach($(AddEntryScreen.qrReadKey));
      await goTo($(AddEntryScreen.tableKey));
      await $(AddEntryScreen.tableKey).tap();
      final contractTable = $(TablePicker.optionKey(contractId));
      await goTo(contractTable);
      await contractTable.tap();
      await $.pumpAndSettle();
      await goTo($(AddEntryScreen.amountKey));
      await $(AddEntryScreen.amountKey).enterText('35000');
      await reach($(AddEntryScreen.overrunKey));
      await picture('contractor-payment');
      await goTo(network);
      await network.tap();
      await goTo($(AddEntryScreen.sendKey));
      await picture('contractor-payment-send');
      await $(AddEntryScreen.sendKey).tap();
      await reach($(AddEntryScreen.savedKey));
      await reach(addEntry);

      await goTo(projectSettings);
      await projectSettings.tap();
      await $(SettingsScreen.myAccountKey).tap();
      await $(MyAccountScreen.signOutKey).tap();
      await $(MyAccountScreen.confirmSignOutKey).tap();

      await reach($(SignInScreen.usernameKey));
      await $(SignInScreen.usernameKey).enterText('patrol-reem');
      await $(SignInScreen.passwordKey).enterText('Reem-chosen-1');
      await goTo($(SignInScreen.submitKey));
      await $(SignInScreen.submitKey).tap();
      await says(HomeScreen.titleKey, 'غصون 7');
      expect(GoRouter.of($.tester.element(find.byKey(HomeScreen.titleKey))).canPop(), isFalse);

      final close = $(ProjectInfoScreen.closeKey);
      await goTo(projectSettings);
      await projectSettings.tap();
      await projectInfo.tap();

      await goTo(close);
      await close.tap();
      await reach($(ProjectInfoScreen.confirmCloseKey));
      await picture('close-project');
      await $(ProjectInfoScreen.cancelCloseKey).tap();
      expect(close, findsOneWidget);

      await close.tap();
      await $(ProjectInfoScreen.confirmCloseKey).tap();
      await reach($(messageKeyOf('projects.pendingEntries')));
      expect(close, findsOneWidget, reason: 'BR-35: a project stays active while entries wait for approval');
      await back();
      await back();

      final words = Words.of($.tester.element(find.byKey(HomeScreen.titleKey)));
      await goTo($(DashboardCard.pendingKey.title));
      await says(DashboardCard.pendingKey.title, words.dashboardPending.replaceFirst('{0}', '4'));

      await goTo($(HomeScreen.approvalsKey(projectId)));
      await $(HomeScreen.approvalsKey(projectId)).tap();
      await $(keyStartingWith('approvals.card.')).waitUntilExists();
      for (var round = 0; round < 4 && keyStartingWith('approvals.card.').evaluate().isNotEmpty; round++) {
        await $.pumpAndSettle();
        final shown = idsOf('approvals.card.');
        for (final entryId in shown) {
          await goTo($(ApprovalsScreen.selectKey(entryId)));
          await $(ApprovalsScreen.selectKey(entryId)).tap();
          await $.pumpAndSettle();
        }
        await $(ApprovalsScreen.approveSelectedKey).tap();
        for (final entryId in shown) {
          await gone($(ApprovalsScreen.cardKey(entryId)));
        }
      }
      await reach($(ApiListBody.emptyKey));
      await back();
      await gone($(DashboardCard.pendingKey));

      await goTo(projectSettings);
      await projectSettings.tap();
      await projectInfo.tap();
      await goTo(close);
      await close.tap();
      await $(ProjectInfoScreen.confirmCloseKey).tap();
      await gone(close);
      expect(addUnit, findsNothing);
      await says(ProjectInfoScreen.statusKey.label, Words.of($.tester.element(find.byKey(ProjectInfoScreen.nameKey))).projectsFinished);
      await back();

      await $(SettingsScreen.switchProjectKey).tap();
      await reach($(ProjectsScreen.titleKey));
      await $(ProjectsScreen.settingsKey).tap();
      await $(SettingsScreen.myAccountKey).tap();
      await $(MyAccountScreen.signOutKey).tap();
      await $(MyAccountScreen.confirmSignOutKey).tap();
    }),
  );
}
