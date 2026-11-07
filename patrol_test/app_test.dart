import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:patrol/patrol.dart';
import 'package:qr/qr.dart';
import 'package:redix/account/my_account_screen.dart';
import 'package:redix/accounts/account.dart';
import 'package:redix/accounts/accounts_screen.dart';
import 'package:redix/attachments/invoice_capture.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/auth/change_password_screen.dart';
import 'package:redix/auth/session.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/contracts/contracts_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/main.dart';
import 'package:redix/partners/partners_screen.dart';
import 'package:redix/projects/new_project_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/projects/registered_projects_screen.dart';
import 'package:redix/settings/payment_methods_screen.dart';
import 'package:redix/settings/settings_screen.dart';
import 'package:redix/structure/apply_to_all_dialog.dart';
import 'package:redix/structure/categories_screen.dart';
import 'package:redix/structure/category.dart';
import 'package:redix/structure/item_columns_screen.dart';
import 'package:redix/structure/item_tables_screen.dart';
import 'package:redix/suppliers/supplier_picker.dart';
import 'package:redix/suppliers/suppliers_screen.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/ui/name_dialog.dart';
import 'package:redix/users/new_user_screen.dart';
import 'package:redix/users/users_screen.dart';
import 'package:redix/words/app_language.dart';

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

void main() {
  patrolTest(
    'a project is registered, approved and managed; a new user sees it by role',
    config: const PatrolTesterConfig(existsTimeout: Duration(seconds: 30), visibleTimeout: Duration(seconds: 30)),
    ($) async {
      WidgetsApp.debugAllowBannerOverride = false;

      /// Waits until [finder] finds nothing, because the row leaves only once the API has answered.
      Future<void> gone(PatrolFinder finder) async {
        for (var tries = 0; tries < 60 && finder.evaluate().isNotEmpty; tries++) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          await $.pump();
        }
        expect(finder, findsNothing);
      }

      /// Brings [finder] into view, above or below what shows now: one not built yet is further down the list.
      Future<void> goTo(PatrolFinder finder) async {
        await $.pumpAndSettle();
        if (finder.evaluate().isEmpty) {
          await finder.scrollTo();
          return;
        }
        if (finder.hitTestable().evaluate().isEmpty) {
          await $.tester.ensureVisible(finder.first);
          await $.pumpAndSettle();
        }
      }

      /// Waits for [finder], and brings it into view: a phone 360 points wide shows less than the emulator.
      Future<void> reach(PatrolFinder finder) async {
        await finder.waitUntilExists();
        await $.pumpAndSettle();
        if (finder.hitTestable().evaluate().isEmpty) {
          await $.tester.ensureVisible(finder.first);
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

      Finder keyStartingWith(String start) => find.byWidgetPredicate((widget) => widget.key is ValueKey<String> && (widget.key! as ValueKey<String>).value.startsWith(start));

      Future<void> showInDialog(Finder finder) async {
        await $.tester.ensureVisible(finder);
        await $.pumpAndSettle();
      }

      Finder rowShowing(String name) => find.descendant(of: find.byType(ListTile), matching: find.text(name));

      await goTo($(SignInScreen.registerKey));

      await $(SignInScreen.registerKey).tap();
      await $(NewProjectScreen.nameKey).enterText('غصون 7');
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
      await reach($(keyStartingWith('projects.status.')));
      expect($(keyStartingWith('projects.star.')), findsNothing);
      await picture('project-waiting');
      await $(keyStartingWith('projects.card.')).tap();
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
      await reach($(keyStartingWith('registered.approve.')));
      await picture('registered-projects');
      await $(keyStartingWith('registered.approve.')).tap();
      await reach($(RegisteredProjectsScreen.emptyKey));
      await $(BackButton).tap();
      await $(SettingsScreen.myAccountKey).tap();
      await $(MyAccountScreen.signOutKey).tap();
      await $(MyAccountScreen.confirmSignOutKey).tap();

      await reach($(SignInScreen.usernameKey));
      await $(SignInScreen.usernameKey).enterText('patrol-reem');
      await $(SignInScreen.passwordKey).enterText('Reem-chosen-1');
      await goTo($(SignInScreen.submitKey));
      await $(SignInScreen.submitKey).tap();
      await reach($(keyStartingWith('projects.card.')));
      expect($(keyStartingWith('home.settings.')), findsNothing);
      await $(keyStartingWith('projects.card.')).tap();

      final projectSettings = $(keyStartingWith('home.settings.'));
      await reach(projectSettings);
      await goTo(projectSettings);
      await projectSettings.tap();
      await $(SettingsScreen.usersKey).tap();
      await reach($(keyStartingWith('users.menu.')));
      await $(keyStartingWith('users.menu.')).tap();
      await $(UsersScreen.permissionsKey).tap();
      await reach($(keyStartingWith('userPermissions.')).at(1));
      await $(keyStartingWith('userPermissions.')).at(1).tap();
      await $.pumpAndSettle();
      await picture('user-permissions');
      await $(BackButton).tap();
      await $(BackButton).tap();
      await $(BackButton).tap();

      final addUnit = $(keyStartingWith('home.addUnit.'));
      await reach(addUnit);
      expect($(find.text('الفلة الشرقية')), findsOneWidget);
      expect($(find.text('الفلة الشمالية')), findsOneWidget);
      await addUnit.tap();
      await $(HomeScreen.unitNameKey).enterText('الفلة الغربية');
      await $(HomeScreen.saveUnitKey).tap();
      await reach($(keyStartingWith('home.unit.')).at(2));
      await picture('home');

      await addUnit.tap();
      await $(HomeScreen.unitNameKey).enterText('ملحق');
      await $(HomeScreen.saveUnitKey).tap();
      await reach($(keyStartingWith('home.unit.')).at(3));
      await $(keyStartingWith('home.unitMenu.')).at(3).tap();
      await $(HomeScreen.renameUnitKey).tap();
      await $(NameDialog.nameKey).enterText('ملحق الفلة');
      await $(ChangeDialog.saveKey).tap();
      await reach($(find.text('ملحق الفلة')));
      await $(keyStartingWith('home.unitMenu.')).at(3).tap();
      await $(HomeScreen.deleteUnitKey).tap();
      await $(ConfirmDialog.confirmKey).tap();
      await gone($(find.text('ملحق الفلة')));
      await goTo($(keyStartingWith('home.rename.')));
      await $(keyStartingWith('home.rename.')).tap();
      await $(NameDialog.nameKey).enterText('غصون 7 الأولى');
      await $(ChangeDialog.saveKey).tap();
      await reach($(find.text('غصون 7 الأولى')));
      await goTo($(keyStartingWith('home.rename.')));
      await $(keyStartingWith('home.rename.')).tap();
      await $(NameDialog.nameKey).enterText('غصون 7');
      await $(ChangeDialog.saveKey).tap();
      await reach($(find.text('غصون 7')));

      await goTo($(keyStartingWith('home.settings.')));

      await $(keyStartingWith('home.settings.')).tap();
      await $(SettingsScreen.categoriesKey).tap();
      await reach($(keyStartingWith('categories.tile.')).at(4));
      String firstCategory() => $.tester.widget<Text>(keyStartingWith('categories.name.').first).data!;
      expect(firstCategory(), 'تكلفة الأراضي');
      await $.tester.timedDrag(keyStartingWith('categories.handle.').first, const Offset(0, 160), const Duration(milliseconds: 600));
      await $.pumpAndSettle();
      expect(firstCategory(), isNot('تكلفة الأراضي'));

      await $(CategoriesScreen.addCategoryKey).tap();
      await $(CategoriesScreen.nameKey).enterText('الملاحق');
      await $(CategoriesScreen.saveKey).tap();
      await reach($(CategoriesScreen.addCategoryKey));
      await goTo($(find.text('الملاحق')));

      await $(find.text('الملاحق')).tap();
      await goTo($(keyStartingWith('categories.addItem.')));
      await $(keyStartingWith('categories.addItem.')).tap();
      await $(CategoriesScreen.nameKey).enterText('المظلة');
      await $(CategoriesScreen.saveKey).tap();
      await goTo($(keyStartingWith('categories.itemMenu.')));
      await $.pumpAndSettle();
      await picture('categories');

      await $(keyStartingWith('categories.itemMenu.')).tap();
      await $(CategoriesScreen.tablesKey).tap();
      await $(ItemTablesScreen.addKey).tap();
      await $(ItemTablesScreen.nameKey).enterText('مواد');
      await $(ItemTablesScreen.saveKey).tap();
      await reach($(find.text('مواد')));
      await picture('tables');
      await $(ItemTablesScreen.addKey).tap();
      await $(ItemTablesScreen.nameKey).enterText('دفان');
      await $(ItemTablesScreen.saveKey).tap();
      await reach($(find.text('دفان')));
      await $(keyStartingWith('tables.delete.')).last.tap();
      await $(ConfirmDialog.confirmKey).tap();
      await gone($(find.text('دفان')));
      await $(BackButton).tap();

      await $(keyStartingWith('categories.itemMenu.')).tap();
      await $(CategoriesScreen.changeTypeKey).tap();
      await $(CategoriesScreen.itemTypeKey(ItemType.purchases)).tap();
      await $(ChangeDialog.saveKey).tap();
      await reach($(keyStartingWith('categories.itemMenu.')));
      await $.pumpAndSettle();
      await $(keyStartingWith('categories.itemMenu.')).tap();
      await $(CategoriesScreen.changeTypeKey).tap();
      await $(CategoriesScreen.itemTypeKey(ItemType.both)).tap();
      await $(ChangeDialog.saveKey).tap();
      await reach($(keyStartingWith('categories.itemMenu.')));
      await $.pumpAndSettle();

      await $(keyStartingWith('categories.itemColumns.')).tap();
      await reach($(keyStartingWith('columns.lock.')).first);
      await $(ItemColumnsScreen.addKey).tap();
      await $(ItemColumnsScreen.columnNameKey).enterText('المساحة م²');
      await $(ItemColumnsScreen.requiredKey).tap();
      await $(ItemColumnsScreen.saveKey).tap();
      await reach($(ItemColumnsScreen.addKey));
      await goTo($(find.text('المساحة م²')));
      await picture('item-columns');
      await goTo($(keyStartingWith('columns.delete.')).last);
      await $(keyStartingWith('columns.delete.')).last.tap();
      await $(ItemColumnsScreen.confirmDeleteKey).tap();
      await gone($(find.text('المساحة م²')));

      await $(ItemColumnsScreen.addKey).tap();
      await $(ItemColumnsScreen.columnNameKey).enterText('الجهة');
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      await $.pumpAndSettle();
      await $(ItemColumnsScreen.dataTypeKey).tap();
      await $(find.text('Pick list')).last.tap();
      await $.pumpAndSettle();
      await $(ItemColumnsScreen.choicesKey).enterText('شرق');
      await $(ItemColumnsScreen.saveKey).tap();
      await goTo($(find.text('الجهة')));
      await goTo($(keyStartingWith('columns.edit.')).last);
      await $(keyStartingWith('columns.edit.')).last.tap();
      await $(ItemColumnsScreen.newChoicesKey).enterText('غرب');
      await $(ItemColumnsScreen.saveKey).tap();
      await goTo($(find.text('الجهة')));
      await goTo($(keyStartingWith('columns.delete.')).last);
      await $(keyStartingWith('columns.delete.')).last.tap();
      await $(ItemColumnsScreen.confirmDeleteKey).tap();
      await gone($(find.text('الجهة')));

      await $(ItemColumnsScreen.templateKey).tap();
      await reach($(keyStartingWith('columns.lock.')).first);
      await $(ItemColumnsScreen.addKey).tap();
      await $(ItemColumnsScreen.columnNameKey).enterText('رقم أمر الشراء');
      await $(ItemColumnsScreen.saveKey).tap();
      await reach($(ApplyToAllDialog.applyKey));
      await picture('apply-to-all');
      await $(ApplyToAllDialog.applyKey).tap();
      await goTo($(find.text('رقم أمر الشراء')));
      await $(ItemColumnsScreen.thisItemKey).tap();
      await goTo($(find.text('رقم أمر الشراء')));
      await $(BackButton).tap();

      await $(keyStartingWith('categories.itemMenu.')).tap();
      await $(CategoriesScreen.disableItemKey).tap();
      await reach($(keyStartingWith('categories.itemMenu.')));
      await $.pumpAndSettle();
      await $(BackButton).tap();

      await $(SettingsScreen.paymentMethodsKey).tap();
      await reach($(find.text('شبكة')));
      await $(PaymentMethodsScreen.addKey).tap();
      await $(PaymentMethodsScreen.dialogNameKey).enterText('مدى');
      await $(PaymentMethodsScreen.saveKey).tap();
      await reach($(find.text('مدى')));
      await $(keyStartingWith('paymentMethods.menu.')).last.tap();
      await $(PaymentMethodsScreen.disableKey).tap();
      await reach($(keyStartingWith('paymentMethods.disabled.')));
      await picture('payment-methods');
      await $(BackButton).tap();
      await $(BackButton).tap();

      await goTo($(keyStartingWith('home.accounts.')));

      await $(keyStartingWith('home.accounts.')).tap();
      await reach($(AccountsScreen.addKey));
      await $(AccountsScreen.addKey).tap();
      await $(AccountsScreen.accountNameKey).enterText('حساب المؤسسة');
      await $(AccountsScreen.openingBalanceKey).enterText('64250.75');
      await $(AccountsScreen.saveKey).tap();
      await reach($(find.text('64,250.75')));
      await $(AccountsScreen.addKey).tap();
      await $(AccountsScreen.typeKey(AccountType.cashCustody)).tap();
      await $(AccountsScreen.accountNameKey).enterText('كاش مع مدير المشروع');
      await $(AccountsScreen.openingBalanceKey).enterText('2750');
      await $.tester.ensureVisible(keyStartingWith('memberPicker.option.').last);
      await $.pumpAndSettle();
      await $(keyStartingWith('memberPicker.option.')).last.tap();
      await $.pumpAndSettle();
      await picture('account-dialog');
      await $(AccountsScreen.saveKey).tap();
      await reach($(find.text('2,750.00')));
      await picture('accounts');
      await $(BackButton).tap();
      await reach($(keyStartingWith('home.custody.')));
      await picture('my-custody');

      await goTo($(keyStartingWith('home.partners.')));

      await $(keyStartingWith('home.partners.')).tap();
      await reach($(PartnersScreen.addKey));
      await $(PartnersScreen.addKey).tap();
      await $(PartnersScreen.partnerNameKey).enterText('هيثم');
      await $(PartnersScreen.saveKey).tap();
      await reach($(find.text('هيثم')));
      await $(PartnersScreen.addKey).tap();
      await $(PartnersScreen.partnerNameKey).enterText('مدير المشروع');
      await $.tester.ensureVisible(keyStartingWith('memberPicker.option.').last);
      await $.pumpAndSettle();
      await $(keyStartingWith('memberPicker.option.')).last.tap();
      await $.pumpAndSettle();
      await picture('partner-dialog');
      await $(PartnersScreen.saveKey).tap();
      await reach($(rowShowing('مدير المشروع')));
      await $.pumpAndSettle();
      await picture('partners');
      await $(BackButton).tap();

      await goTo($(keyStartingWith('home.suppliers.')));

      await $(keyStartingWith('home.suppliers.')).tap();
      await reach($(SuppliersScreen.addKey));
      await $(SuppliersScreen.addKey).tap();
      await $(SuppliersScreen.supplierNameKey).enterText('شركة النخيل');
      await $(SuppliersScreen.vatNumberKey).enterText('300000000000003');
      await showInDialog(find.byKey(SuppliersScreen.defaultItemKey));
      await $(SuppliersScreen.defaultItemKey).tap();
      await $(keyStartingWith('itemPicker.option.')).at(1).tap();
      await $.pumpAndSettle();
      await picture('supplier-dialog');
      await $(SuppliersScreen.saveKey).tap();
      await reach($(rowShowing('شركة النخيل')));
      await $.pumpAndSettle();
      await picture('suppliers');
      await $(BackButton).tap();

      await goTo($(keyStartingWith('home.contracts.')));

      await $(keyStartingWith('home.contracts.')).tap();
      await reach($(ContractsScreen.addKey));
      await $(ContractsScreen.addKey).tap();
      await $(ContractsScreen.contractorKey).tap();
      await reach($(keyStartingWith('supplierPicker.row.')));
      await picture('supplier-picker');
      await $(SupplierPicker.searchKey).enterText('مبلط الغربية');
      await $(SupplierPicker.quickAddKey).tap();
      await $(SuppliersScreen.vatNumberKey).enterText('311111111111113');
      await $.pumpAndSettle();
      await picture('quick-add-supplier');
      await $(SuppliersScreen.saveKey).last.tap();
      await reach($(find.text('مبلط الغربية')));
      await $(ContractsScreen.itemKey).tap();
      await $(keyStartingWith('itemPicker.option.')).first.tap();
      await $.pumpAndSettle();
      await $.pumpAndSettle();
      await showInDialog(find.byKey(ContractsScreen.valueKey));
      await $(ContractsScreen.valueKey).enterText('34000');
      await showInDialog(find.byKey(ContractsScreen.contractorKey));
      await $.tester.drag(find.byKey(ContractsScreen.contractorKey), const Offset(0, 200));
      await picture('contract-dialog');
      await $(ContractsScreen.saveKey).tap();
      await reach($(find.text('34,000.00')));
      await $.pumpAndSettle();
      await picture('contracts');
      await $(keyStartingWith('contracts.menu.')).tap();
      await $(ContractsScreen.editKey).tap();
      await $.pumpAndSettle();
      await $(ContractsScreen.saveKey).tap();
      await reach($(find.text('34,000.00')));
      await $.pumpAndSettle();
      await $(BackButton).tap();

      await goTo(projectSettings);

      await projectSettings.tap();
      await $(SettingsScreen.usersKey).tap();
      await reach($(keyStartingWith('users.menu.')));

      await $(UsersScreen.newUserKey).tap();
      await $(NewUserScreen.nameKey).enterText('نواف');
      await $(NewUserScreen.usernameKey).enterText('patrol-nawaf');
      await $(NewUserScreen.mobileKey).enterText('0500000000');
      await $(NewUserScreen.passwordKey).enterText('Temporary-1');
      await picture('new-user');
      await goTo($(NewUserScreen.submitKey));
      await $(NewUserScreen.submitKey).tap();
      await reach($(find.text('نواف')));
      await picture('users');

      final newUserMenu = $(keyStartingWith('users.menu.')).last;
      await newUserMenu.tap();
      await $(UsersScreen.editKey).tap();
      await $(UsersScreen.editNameKey).enterText('نواف الأول');
      await $(UsersScreen.saveKey).tap();
      await reach($(find.text('نواف الأول')));

      await newUserMenu.tap();
      await $(UsersScreen.resetPasswordKey).tap();
      await $(UsersScreen.resetPasswordFieldKey).enterText('Temporary-2');
      await $(UsersScreen.saveKey).tap();
      await $.pumpAndSettle();

      await newUserMenu.tap();
      await $(UsersScreen.disableKey).tap();
      await $(UsersScreen.confirmDisableKey).tap();
      await reach($(keyStartingWith('users.status.')).last);
      await newUserMenu.tap();
      await $(UsersScreen.enableKey).tap();
      await $.pumpAndSettle();

      await newUserMenu.tap();
      await $(UsersScreen.permissionsKey).tap();
      await reach($(keyStartingWith('userPermissions.')).at(2));
      await $(keyStartingWith('userPermissions.')).at(2).tap();
      await $.pumpAndSettle();
      await $(keyStartingWith('userPermissions.')).at(3).tap();
      await $.pumpAndSettle();
      await $(BackButton).tap();
      await $.pumpAndSettle();

      await $(BackButton).tap();
      await $(BackButton).tap();
      await reach(projectSettings);
      await $(BackButton).tap();
      await $(keyStartingWith('projects.star.')).tap();
      await reach($(Icons.star));
      await $(ProjectsScreen.openDefaultKey).tap();
      await reach($(find.byWidgetPredicate((widget) => widget is SwitchListTile && widget.value)));
      await picture('projects');

      await $(ProjectsScreen.settingsKey).tap();
      await $(SettingsScreen.myAccountKey).tap();
      await reach($(MyAccountScreen.arabicKey));
      await picture('my-account');

      await $(MyAccountScreen.arabicKey).tap();
      await $.pumpAndSettle();
      expect(Directionality.of($.tester.element(find.byKey(MyAccountScreen.arabicKey))), TextDirection.rtl);
      await picture('my-account-arabic');

      await $(BackButton).tap();
      await $(SettingsScreen.switchProjectKey).tap();
      await reach($(keyStartingWith('projects.status.')));
      expect(Directionality.of($.tester.element(keyStartingWith('projects.status.'))), TextDirection.rtl);
      await picture('projects-arabic');
      await $(keyStartingWith('projects.card.')).tap();
      await goTo(projectSettings);
      await projectSettings.tap();
      await $(SettingsScreen.usersKey).tap();
      await reach($(keyStartingWith('users.menu.')));
      await picture('users-arabic');
      await $(BackButton).tap();
      await $(BackButton).tap();
      await reach(projectSettings);

      await goTo($(keyStartingWith('home.accounts.')));

      await $(keyStartingWith('home.accounts.')).tap();
      await reach($(AccountsScreen.addKey));
      await $(AccountsScreen.addKey).tap();
      await $(AccountsScreen.typeKey(AccountType.cashCustody)).tap();
      await $(AccountsScreen.accountNameKey).enterText('عهدة الميدان');
      await $(AccountsScreen.openingBalanceKey).enterText('5000');
      final nawaf = find.descendant(of: keyStartingWith('memberPicker.option.'), matching: find.text('نواف الأول'));
      await $.tester.ensureVisible(nawaf);
      await $.pumpAndSettle();
      await $(nawaf).tap();
      await $.pumpAndSettle();
      await $(AccountsScreen.saveKey).tap();
      await reach($(find.text('عهدة الميدان')));
      await $(BackButton).tap();
      await reach(projectSettings);
      await $(BackButton).tap();
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
      await reach($(keyStartingWith('projects.card.')));
      expect($(ProjectsScreen.newProjectKey), findsOneWidget);
      await $(keyStartingWith('projects.card.')).tap();
      await reach($(keyStartingWith('home.card.')));
      await goTo($(keyStartingWith('home.settings.')));
      await $(keyStartingWith('home.settings.')).tap();
      expect($(SettingsScreen.usersKey), findsNothing);
      await $(BackButton).tap();
      expect($(keyStartingWith('home.addUnit.')), findsNothing);
      expect($(keyStartingWith('home.close.')), findsNothing);

      await $(keyStartingWith('home.addEntry.')).tap();
      await reach($(AddEntryScreen.qrReadKey));
      await reach($(AddEntryScreen.supplierDetailsKey));
      expect($.tester.widget<TextField>(find.byKey(AddEntryScreen.amountKey)).controller!.text, '1075');

      await goTo($(AddEntryScreen.supplierKey));

      await $(AddEntryScreen.supplierKey).tap();
      await $(SupplierPicker.searchKey).enterText('مورد الميدان');
      await $(SupplierPicker.quickAddKey).tap();
      await $(SuppliersScreen.vatNumberKey).enterText('322222222222223');
      await reach($(SupplierPicker.pendingHintKey));
      await $(SuppliersScreen.saveKey).last.tap();
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      await goTo($(find.text('مورد الميدان')));

      await goTo($(AddEntryScreen.tableKey));

      await $(AddEntryScreen.tableKey).tap();
      await $(keyStartingWith('tablePicker.option.')).first.tap();
      await $.pumpAndSettle();
      await $.tester.ensureVisible(find.byKey(AddEntryScreen.cameraKey));
      await $.pumpAndSettle();
      await picture('add-expense');

      await goTo($(keyStartingWith('payment.method.')).first);

      await $(keyStartingWith('payment.method.')).first.tap();
      await goTo($(keyStartingWith('payment.account.')).first);
      await $.pumpAndSettle();
      await picture('add-expense-payment');

      await goTo($(AddEntryScreen.sendKey));
      await picture('add-expense-send');
      await $(AddEntryScreen.sendKey).tap();
      await reach($(AddEntryScreen.savedKey));
      await reach($(keyStartingWith('home.addEntry.')));

      await $(keyStartingWith('home.addEntry.')).tap();
      await reach($(AddEntryScreen.qrReadKey));
      await reach($(AddEntryScreen.supplierDetailsKey));
      await goTo($(AddEntryScreen.tableKey));
      await $(AddEntryScreen.tableKey).tap();
      await $(keyStartingWith('tablePicker.option.')).first.tap();
      await $.pumpAndSettle();
      await goTo($(AddEntryScreen.amountKey));
      await $(AddEntryScreen.amountKey).enterText('200');
      await goTo($(keyStartingWith('payment.method.')).first);
      await $(keyStartingWith('payment.method.')).first.tap();
      await goTo($(AddEntryScreen.sendKey));
      await $(AddEntryScreen.sendKey).tap();
      await reach($(AddEntryScreen.savedKey));
      await reach($(keyStartingWith('home.addEntry.')));

      await $(keyStartingWith('home.addEntry.')).tap();
      await reach($(AddEntryScreen.qrReadKey));
      await reach($(AddEntryScreen.supplierDetailsKey));
      await goTo($(AddEntryScreen.tableKey));
      await $(AddEntryScreen.tableKey).tap();
      await $(keyStartingWith('tablePicker.option.')).first.tap();
      await $.pumpAndSettle();
      await goTo($(AddEntryScreen.supplierKey));
      await $(AddEntryScreen.supplierKey).tap();
      await $(SupplierPicker.searchKey).enterText('مورد الميدان');
      await $(find.descendant(of: keyStartingWith('supplierPicker.row.'), matching: find.text('مورد الميدان'))).tap();
      await $.pumpAndSettle();
      await goTo($(AddEntryScreen.creditNoteKey));
      await $(AddEntryScreen.creditNoteKey).tap();
      await $.pumpAndSettle();
      await goTo($(AddEntryScreen.originalInvoiceKey));
      await $(AddEntryScreen.originalInvoiceKey).tap();
      await $(keyStartingWith('originalInvoice.option.')).first.tap();
      await $.pumpAndSettle();
      await goTo($(AddEntryScreen.amountKey));
      await $(AddEntryScreen.amountKey).enterText('100');
      await goTo($(keyStartingWith('payment.method.')).first);
      await $(keyStartingWith('payment.method.')).first.tap();
      await showInDialog(find.byKey(AddEntryScreen.originalInvoiceKey));
      await picture('add-expense-credit-note');
      await goTo($(AddEntryScreen.sendKey));
      await $(AddEntryScreen.sendKey).tap();
      await reach($(AddEntryScreen.savedKey));
      await reach($(keyStartingWith('home.addEntry.')));

      await $(keyStartingWith('home.addEntry.')).tap();
      await reach($(AddEntryScreen.qrReadKey));
      await goTo($(AddEntryScreen.tableKey));
      await $(AddEntryScreen.tableKey).tap();
      await goTo($('مبلط الغربية'));
      await $('مبلط الغربية').tap();
      await $.pumpAndSettle();
      await goTo($(AddEntryScreen.amountKey));
      await $(AddEntryScreen.amountKey).enterText('35000');
      await reach($(AddEntryScreen.overrunKey));
      await picture('contractor-payment');
      await goTo($(keyStartingWith('payment.method.')).first);
      await $(keyStartingWith('payment.method.')).first.tap();
      await goTo($(AddEntryScreen.sendKey));
      await picture('contractor-payment-send');
      await $(AddEntryScreen.sendKey).tap();
      await reach($(AddEntryScreen.savedKey));
      await reach($(keyStartingWith('home.addEntry.')));

      await goTo($(keyStartingWith('home.settings.')));
      await $(keyStartingWith('home.settings.')).tap();
      await $(SettingsScreen.myAccountKey).tap();
      await $(MyAccountScreen.signOutKey).tap();
      await $(MyAccountScreen.confirmSignOutKey).tap();

      await reach($(SignInScreen.usernameKey));
      await $(SignInScreen.usernameKey).enterText('patrol-reem');
      await $(SignInScreen.passwordKey).enterText('Reem-chosen-1');
      await goTo($(SignInScreen.submitKey));
      await $(SignInScreen.submitKey).tap();
      await reach($(HomeScreen.titleKey));
      await reach($(find.text('غصون 7')));
      expect($(BackButton), findsNothing);

      await goTo($(keyStartingWith('home.close.')));

      await $(keyStartingWith('home.close.')).tap();
      await reach($(HomeScreen.confirmCloseKey));
      await picture('close-project');
      await $(HomeScreen.cancelCloseKey).tap();
      expect($(keyStartingWith('home.close.')), findsOneWidget);

      await goTo($(keyStartingWith('home.close.')));

      await $(keyStartingWith('home.close.')).tap();
      await $(HomeScreen.confirmCloseKey).tap();
      await $.pumpAndSettle();
      expect($(keyStartingWith('home.close.')), findsNothing);
      expect($(keyStartingWith('home.addUnit.')), findsNothing);

      await goTo($(keyStartingWith('home.settings.')));
      await $(keyStartingWith('home.settings.')).tap();
      await $(SettingsScreen.switchProjectKey).tap();
      await reach($(ProjectsScreen.titleKey));
      await $(ProjectsScreen.settingsKey).tap();
      await $(SettingsScreen.myAccountKey).tap();
      await $(MyAccountScreen.signOutKey).tap();
      await $(MyAccountScreen.confirmSignOutKey).tap();
    },
  );
}
