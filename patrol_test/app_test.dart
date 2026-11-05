import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:patrol/patrol.dart';
import 'package:qr/qr.dart';
import 'package:redix/account/my_account_screen.dart';
import 'package:redix/auth/change_password_screen.dart';
import 'package:redix/auth/session.dart';
import 'package:redix/auth/sign_in_screen.dart';
import 'package:redix/contracts/contracts_screen.dart';
import 'package:redix/accounts/account.dart';
import 'package:redix/accounts/accounts_screen.dart';
import 'package:redix/attachments/invoice_capture.dart';
import 'package:redix/attachments/picked_file.dart';
import 'package:redix/expenses/add_expense_screen.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/partners/partners_screen.dart';
import 'package:redix/main.dart';
import 'package:redix/projects/new_project_screen.dart';
import 'package:redix/projects/projects_screen.dart';
import 'package:redix/projects/registered_projects_screen.dart';
import 'package:redix/settings/settings_screen.dart';
import 'package:redix/settings/payment_methods_screen.dart';
import 'package:redix/structure/categories_screen.dart';
import 'package:redix/structure/apply_to_all_dialog.dart';
import 'package:redix/structure/item_columns_screen.dart';
import 'package:redix/structure/subgroups_screen.dart';
import 'package:redix/suppliers/supplier_picker.dart';
import 'package:redix/suppliers/suppliers_screen.dart';
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
  final code = QrImage(QrCode(payload: QrPayload.fromString(text)));
  final size = (code.moduleCount + border * 2) * cell;
  final picture = img.fill(img.Image(width: size, height: size), color: img.ColorRgb8(255, 255, 255));
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
    final bytes = pictureOfQr(madeUpInvoiceQr);
    final file = await File('${Directory.systemTemp.path}/made-up-invoice.png').writeAsBytes(bytes);
    return PickedFile('made-up-invoice.png', file.path, bytes);
  }
}

/// The QR code of a made-up invoice from شركة النخيل, whose VAT is what 7.5% makes.
String get madeUpInvoiceQr {
  List<int> field(int tag, String text) => [tag, utf8.encode(text).length, ...utf8.encode(text)];
  return base64.encode([
    ...field(1, 'شركة النخيل'),
    ...field(2, '300000000000003'),
    ...field(3, '${DateTime.now().toIso8601String().substring(0, 10)}T10:30:00Z'),
    ...field(4, '1075.00'),
    ...field(5, '75.00'),
  ]);
}

void main() {
  patrolTest('a project is registered, approved and managed; a new user sees it by role', ($) async {
    final session = Session();
    final language = AppLanguage();
    await session.restore();
    await language.restore();
    await $.pumpWidgetAndSettle(RedixApp(session: session, language: language, capture: const CameraWithAPicture()));
    await $(SignInScreen.usernameKey).waitUntilVisible();
    final logo = find.byKey(SignInScreen.logoKey);
    await precacheImage($.tester.widget<Image>(logo).image, $.tester.element(logo));
    await $.pumpAndSettle();
    expect($.tester.widget<RawImage>(find.descendant(of: logo, matching: find.byType(RawImage))).image, isNotNull);
    await $.takeNativeScreenshot('sign-in');

    Finder keyStartingWith(String start) => find.byWidgetPredicate((widget) => widget.key is ValueKey<String> && (widget.key! as ValueKey<String>).value.startsWith(start));

    Future<void> showInDialog(Finder finder) async {
      await $.tester.ensureVisible(finder);
      await $.pumpAndSettle();
    }

    Finder rowShowing(String name) => find.descendant(of: find.byType(ListTile), matching: find.text(name));

    await $(SignInScreen.registerKey).scrollTo().tap();
    await $(NewProjectScreen.nameKey).enterText('غصون 7');
    await $(NewProjectScreen.unitNameKey).enterText('الفلة الشرقية');
    await $(NewProjectScreen.addUnitKey).tap();
    await $(NewProjectScreen.unitNameKey).enterText('الفلة الشمالية');
    await $(NewProjectScreen.addUnitKey).tap();
    await $(NewProjectScreen.managerNameKey).scrollTo().enterText('ريم');
    await $(NewProjectScreen.usernameKey).scrollTo().enterText('patrol-reem');
    await $(NewProjectScreen.mobileKey).scrollTo().enterText('0511111111');
    await $(NewProjectScreen.passwordKey).scrollTo().enterText('Reem-chosen-1');
    await $.takeNativeScreenshot('register-project');
    await $(NewProjectScreen.submitKey).scrollTo().tap();

    await $(SignInScreen.usernameKey).waitUntilVisible();
    await $(SignInScreen.usernameKey).enterText('patrol-reem');
    await $(SignInScreen.passwordKey).enterText('Reem-chosen-1');
    await $(SignInScreen.submitKey).scrollTo().tap();
    await $(keyStartingWith('projects.status.')).waitUntilVisible();
    expect($(keyStartingWith('projects.star.')), findsNothing);
    await $.takeNativeScreenshot('project-waiting');
    await $(keyStartingWith('projects.card.')).tap();
    expect($(ProjectsScreen.titleKey), findsOneWidget);
    await $(ProjectsScreen.settingsKey).tap();
    expect($(SettingsScreen.registeredKey), findsNothing);
    await $(SettingsScreen.myAccountKey).tap();
    await $(MyAccountScreen.signOutKey).tap();
    await $(MyAccountScreen.confirmSignOutKey).tap();

    await $(SignInScreen.usernameKey).waitUntilVisible();
    await $(SignInScreen.usernameKey).enterText(username);
    await $(SignInScreen.passwordKey).enterText(temporaryPassword);
    await $(SignInScreen.submitKey).scrollTo().tap();
    await $(ChangePasswordScreen.currentKey).waitUntilVisible();
    await $.takeNativeScreenshot('change-password');

    await $(ChangePasswordScreen.currentKey).enterText(temporaryPassword);
    await $(ChangePasswordScreen.newKey).enterText(newPassword);
    await $(ChangePasswordScreen.confirmKey).enterText(newPassword);
    await $(ChangePasswordScreen.submitKey).scrollTo().tap();
    await $(ProjectsScreen.titleKey).waitUntilVisible();

    await $(ProjectsScreen.settingsKey).tap();
    await $(SettingsScreen.registeredKey).waitUntilVisible();
    await $.takeNativeScreenshot('settings');
    await $(SettingsScreen.registeredKey).tap();
    await $(keyStartingWith('registered.approve.')).waitUntilVisible();
    await $.takeNativeScreenshot('registered-projects');
    await $(keyStartingWith('registered.approve.')).tap();
    await $(RegisteredProjectsScreen.emptyKey).waitUntilVisible();
    await $(BackButton).tap();
    await $(SettingsScreen.myAccountKey).tap();
    await $(MyAccountScreen.signOutKey).tap();
    await $(MyAccountScreen.confirmSignOutKey).tap();

    await $(SignInScreen.usernameKey).waitUntilVisible();
    await $(SignInScreen.usernameKey).enterText('patrol-reem');
    await $(SignInScreen.passwordKey).enterText('Reem-chosen-1');
    await $(SignInScreen.submitKey).scrollTo().tap();
    await $(keyStartingWith('projects.card.')).waitUntilVisible();
    expect($(keyStartingWith('home.users.')), findsNothing);
    await $(keyStartingWith('projects.card.')).tap();

    final projectUsers = $(keyStartingWith('home.users.'));
    await projectUsers.waitUntilVisible();
    expect($(keyStartingWith('home.addUnit.')), findsNothing);
    await projectUsers.scrollTo().tap();
    await $(keyStartingWith('users.menu.')).waitUntilVisible();
    await $(keyStartingWith('users.menu.')).tap();
    await $(UsersScreen.rolesKey).tap();
    await $(keyStartingWith('userRoles.role.')).at(1).waitUntilVisible();
    await $(keyStartingWith('userRoles.role.')).at(1).tap();
    await $.pumpAndSettle();
    await $.takeNativeScreenshot('user-roles');
    await $(BackButton).tap();
    await $(BackButton).tap();

    final addUnit = $(keyStartingWith('home.addUnit.'));
    await addUnit.waitUntilVisible();
    expect($(find.text('الفلة الشرقية')), findsOneWidget);
    expect($(find.text('الفلة الشمالية')), findsOneWidget);
    await addUnit.tap();
    await $(HomeScreen.unitNameKey).enterText('الفلة الغربية');
    await $(HomeScreen.saveUnitKey).tap();
    await $(keyStartingWith('home.unit.')).at(2).waitUntilVisible();
    await $.takeNativeScreenshot('home');

    await $(keyStartingWith('home.categories.')).scrollTo().tap();
    await $(keyStartingWith('categories.tile.')).at(4).waitUntilVisible();
    String firstCategory() => $.tester.widget<Text>(keyStartingWith('categories.name.').first).data!;
    expect(firstCategory(), 'تكلفة الأراضي');
    await $.tester.timedDrag(keyStartingWith('categories.handle.').first, const Offset(0, 160), const Duration(milliseconds: 600));
    await $.pumpAndSettle();
    expect(firstCategory(), isNot('تكلفة الأراضي'));

    await $(CategoriesScreen.addCategoryKey).tap();
    await $(CategoriesScreen.nameKey).enterText('الملاحق');
    await $(CategoriesScreen.saveKey).tap();
    await $(CategoriesScreen.addCategoryKey).waitUntilVisible();
    await $(find.text('الملاحق')).scrollTo();

    await $(keyStartingWith('categories.tile.')).at(5).tap();
    await $(keyStartingWith('categories.addItem.')).scrollTo().tap();
    await $(CategoriesScreen.nameKey).enterText('المظلة');
    await $(CategoriesScreen.saveKey).tap();
    await $(keyStartingWith('categories.itemMenu.')).waitUntilVisible();
    await $.pumpAndSettle();
    await $.takeNativeScreenshot('categories');

    await $(keyStartingWith('categories.itemMenu.')).tap();
    await $(CategoriesScreen.subgroupsKey).tap();
    await $(SubgroupsScreen.addKey).tap();
    await $(SubgroupsScreen.nameKey).enterText('مواد');
    await $(SubgroupsScreen.saveKey).tap();
    await $(find.text('مواد')).waitUntilVisible();
    await $.takeNativeScreenshot('subgroups');
    await $(BackButton).tap();

    await $(keyStartingWith('categories.itemColumns.')).tap();
    await $(keyStartingWith('columns.lock.')).first.waitUntilVisible();
    await $(ItemColumnsScreen.addKey).tap();
    await $(ItemColumnsScreen.columnNameKey).enterText('المساحة م²');
    await $(ItemColumnsScreen.requiredKey).tap();
    await $(ItemColumnsScreen.saveKey).tap();
    await $(ItemColumnsScreen.addKey).waitUntilVisible();
    await $(find.text('المساحة م²')).scrollTo();
    await $.takeNativeScreenshot('item-columns');
    await $(keyStartingWith('columns.delete.')).last.scrollTo().tap();
    await $(ItemColumnsScreen.confirmDeleteKey).tap();
    await $.pumpAndSettle();
    expect($(find.text('المساحة م²')), findsNothing);

    await $(ItemColumnsScreen.templateKey).tap();
    await $(keyStartingWith('columns.lock.')).first.waitUntilVisible();
    await $(ItemColumnsScreen.addKey).tap();
    await $(ItemColumnsScreen.columnNameKey).enterText('رقم أمر الشراء');
    await $(ItemColumnsScreen.saveKey).tap();
    await $(ApplyToAllDialog.applyKey).waitUntilVisible();
    await $.takeNativeScreenshot('apply-to-all');
    await $(ApplyToAllDialog.applyKey).tap();
    await $(find.text('رقم أمر الشراء')).scrollTo();
    await $(ItemColumnsScreen.thisItemKey).tap();
    await $(find.text('رقم أمر الشراء')).scrollTo();
    await $(BackButton).tap();

    await $(keyStartingWith('categories.itemMenu.')).tap();
    await $(CategoriesScreen.disableItemKey).tap();
    await $(keyStartingWith('categories.itemMenu.')).waitUntilVisible();
    await $.pumpAndSettle();
    await $(BackButton).tap();

    await $(keyStartingWith('home.paymentMethods.')).scrollTo().tap();
    await $(find.text('شبكة')).waitUntilVisible();
    await $(PaymentMethodsScreen.addKey).tap();
    await $(PaymentMethodsScreen.dialogNameKey).enterText('مدى');
    await $(PaymentMethodsScreen.saveKey).tap();
    await $(find.text('مدى')).waitUntilVisible();
    await $(keyStartingWith('paymentMethods.menu.')).last.tap();
    await $(PaymentMethodsScreen.disableKey).tap();
    await $(keyStartingWith('paymentMethods.disabled.')).waitUntilVisible();
    await $(PaymentMethodsScreen.changeVatRateKey).tap();
    await $(PaymentMethodsScreen.vatPercentKey).enterText('7.5');
    await $(PaymentMethodsScreen.saveKey).tap();
    await $(find.text('7.5%')).waitUntilVisible();
    await $.takeNativeScreenshot('payment-methods');
    await $(BackButton).tap();

    await $(keyStartingWith('home.accounts.')).scrollTo().tap();
    await $(AccountsScreen.addKey).waitUntilVisible();
    await $(AccountsScreen.addKey).tap();
    await $(AccountsScreen.accountNameKey).enterText('حساب المؤسسة');
    await $(AccountsScreen.openingBalanceKey).enterText('64250.75');
    await $(AccountsScreen.saveKey).tap();
    await $(find.text('64,250.75')).waitUntilVisible();
    await $(AccountsScreen.addKey).tap();
    await $(AccountsScreen.typeKey(AccountType.cashCustody)).tap();
    await $(AccountsScreen.accountNameKey).enterText('كاش مع مدير المشروع');
    await $(AccountsScreen.openingBalanceKey).enterText('2750');
    await $.tester.ensureVisible(keyStartingWith('memberPicker.option.').last);
    await $.pumpAndSettle();
    await $(keyStartingWith('memberPicker.option.')).last.tap();
    await $.pumpAndSettle();
    await $.takeNativeScreenshot('account-dialog');
    await $(AccountsScreen.saveKey).tap();
    await $(find.text('2,750.00')).waitUntilVisible();
    await $.takeNativeScreenshot('accounts');
    await $(BackButton).tap();
    await $(keyStartingWith('home.custody.')).waitUntilVisible();
    await $.takeNativeScreenshot('my-custody');

    await $(keyStartingWith('home.partners.')).scrollTo().tap();
    await $(PartnersScreen.addKey).waitUntilVisible();
    await $(PartnersScreen.addKey).tap();
    await $(PartnersScreen.partnerNameKey).enterText('هيثم');
    await $(PartnersScreen.saveKey).tap();
    await $(find.text('هيثم')).waitUntilVisible();
    await $(PartnersScreen.addKey).tap();
    await $(PartnersScreen.partnerNameKey).enterText('مدير المشروع');
    await $.tester.ensureVisible(keyStartingWith('memberPicker.option.').last);
    await $.pumpAndSettle();
    await $(keyStartingWith('memberPicker.option.')).last.tap();
    await $.pumpAndSettle();
    await $.takeNativeScreenshot('partner-dialog');
    await $(PartnersScreen.saveKey).tap();
    await $(rowShowing('مدير المشروع')).waitUntilVisible();
    await $.pumpAndSettle();
    await $.takeNativeScreenshot('partners');
    await $(BackButton).tap();

    await $(keyStartingWith('home.suppliers.')).scrollTo().tap();
    await $(SuppliersScreen.addKey).waitUntilVisible();
    await $(SuppliersScreen.addKey).tap();
    await $(SuppliersScreen.supplierNameKey).enterText('شركة النخيل');
    await $(SuppliersScreen.vatNumberKey).enterText('300000000000003');
    await showInDialog(find.byKey(SuppliersScreen.defaultItemKey));
    await $(SuppliersScreen.defaultItemKey).tap();
    await $(keyStartingWith('itemPicker.option.')).at(1).tap();
    await $.pumpAndSettle();
    await $.takeNativeScreenshot('supplier-dialog');
    await $(SuppliersScreen.saveKey).tap();
    await $(rowShowing('شركة النخيل')).waitUntilVisible();
    await $.pumpAndSettle();
    await $.takeNativeScreenshot('suppliers');
    await $(BackButton).tap();

    await $(keyStartingWith('home.contracts.')).scrollTo().tap();
    await $(ContractsScreen.addKey).waitUntilVisible();
    await $(ContractsScreen.addKey).tap();
    await $(ContractsScreen.contractorKey).tap();
    await $(keyStartingWith('supplierPicker.row.')).waitUntilVisible();
    await $.takeNativeScreenshot('supplier-picker');
    await $(SupplierPicker.searchKey).enterText('مبلط الغربية');
    await $(SupplierPicker.quickAddKey).tap();
    await $(SuppliersScreen.vatNumberKey).enterText('311111111111113');
    await $.pumpAndSettle();
    await $.takeNativeScreenshot('quick-add-supplier');
    await $(SuppliersScreen.saveKey).last.tap();
    await $(find.text('مبلط الغربية')).waitUntilVisible();
    await $(ContractsScreen.itemKey).tap();
    await $(keyStartingWith('itemPicker.option.')).first.tap();
    await $.pumpAndSettle();
    await showInDialog(keyStartingWith('contracts.unit.').first);
    await $(keyStartingWith('contracts.unit.')).first.tap();
    await $.pumpAndSettle();
    await showInDialog(find.byKey(ContractsScreen.valueKey));
    await $(ContractsScreen.valueKey).enterText('34000');
    await showInDialog(find.byKey(ContractsScreen.contractorKey));
    await $.takeNativeScreenshot('contract-dialog');
    await $(ContractsScreen.saveKey).tap();
    await $(find.text('34,000.00')).waitUntilVisible();
    await $.pumpAndSettle();
    await $.takeNativeScreenshot('contracts');
    await $(BackButton).tap();

    await projectUsers.scrollTo().tap();
    await $(keyStartingWith('users.menu.')).waitUntilVisible();

    await $(UsersScreen.newUserKey).tap();
    await $(NewUserScreen.nameKey).enterText('نواف');
    await $(NewUserScreen.usernameKey).enterText('patrol-nawaf');
    await $(NewUserScreen.mobileKey).enterText('0500000000');
    await $(NewUserScreen.passwordKey).enterText('Temporary-1');
    await $.takeNativeScreenshot('new-user');
    await $(NewUserScreen.submitKey).scrollTo().tap();
    await $(find.text('نواف')).waitUntilVisible();
    await $.takeNativeScreenshot('users');

    final newUserMenu = $(keyStartingWith('users.menu.')).last;
    await newUserMenu.tap();
    await $(UsersScreen.editKey).tap();
    await $(UsersScreen.editNameKey).enterText('نواف الأول');
    await $(UsersScreen.saveKey).tap();
    await $(find.text('نواف الأول')).waitUntilVisible();

    await newUserMenu.tap();
    await $(UsersScreen.resetPasswordKey).tap();
    await $(UsersScreen.resetPasswordFieldKey).enterText('Temporary-2');
    await $(UsersScreen.saveKey).tap();
    await $.pumpAndSettle();

    await newUserMenu.tap();
    await $(UsersScreen.disableKey).tap();
    await $(UsersScreen.confirmDisableKey).tap();
    await $(keyStartingWith('users.status.')).last.waitUntilVisible();
    await newUserMenu.tap();
    await $(UsersScreen.enableKey).tap();
    await $.pumpAndSettle();

    await newUserMenu.tap();
    await $(UsersScreen.rolesKey).tap();
    await $(keyStartingWith('userRoles.role.')).at(2).waitUntilVisible();
    await $(keyStartingWith('userRoles.role.')).at(2).tap();
    await $.pumpAndSettle();
    await $(keyStartingWith('userRoles.role.')).at(3).tap();
    await $.pumpAndSettle();
    await $(BackButton).tap();
    await $.pumpAndSettle();

    await $(BackButton).tap();
    await projectUsers.waitUntilVisible();
    await $(BackButton).tap();
    await $(keyStartingWith('projects.star.')).tap();
    await $(Icons.star).waitUntilVisible();
    await $(ProjectsScreen.openDefaultKey).tap();
    await $(find.byWidgetPredicate((widget) => widget is SwitchListTile && widget.value)).waitUntilVisible();
    await $.takeNativeScreenshot('projects');

    await $(ProjectsScreen.settingsKey).tap();
    await $(SettingsScreen.myAccountKey).tap();
    await $(MyAccountScreen.arabicKey).waitUntilVisible();
    await $.takeNativeScreenshot('my-account');

    await $(MyAccountScreen.arabicKey).tap();
    await $.pumpAndSettle();
    expect(Directionality.of($.tester.element(find.byKey(MyAccountScreen.arabicKey))), TextDirection.rtl);
    await $.takeNativeScreenshot('my-account-arabic');

    await $(BackButton).tap();
    await $(SettingsScreen.switchProjectKey).tap();
    await $(keyStartingWith('projects.status.')).waitUntilVisible();
    expect(Directionality.of($.tester.element(keyStartingWith('projects.status.'))), TextDirection.rtl);
    await $.takeNativeScreenshot('projects-arabic');
    await $(keyStartingWith('projects.card.')).tap();
    await projectUsers.scrollTo().tap();
    await $(keyStartingWith('users.menu.')).waitUntilVisible();
    await $.takeNativeScreenshot('users-arabic');
    await $(BackButton).tap();
    await projectUsers.waitUntilVisible();

    await $(keyStartingWith('home.accounts.')).scrollTo().tap();
    await $(AccountsScreen.addKey).waitUntilVisible();
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
    await $(find.text('عهدة الميدان')).waitUntilVisible();
    await $(BackButton).tap();
    await projectUsers.waitUntilVisible();
    await $(BackButton).tap();
    await $(ProjectsScreen.settingsKey).tap();
    await $(SettingsScreen.myAccountKey).tap();
    await $(MyAccountScreen.englishKey).waitUntilVisible();

    await $(MyAccountScreen.englishKey).tap();
    await $.pumpAndSettle();
    expect(Directionality.of($.tester.element(find.byKey(MyAccountScreen.englishKey))), TextDirection.ltr);

    await $(MyAccountScreen.biometricsKey).scrollTo().tap();
    await $(MyAccountScreen.biometricsMessageKey).waitUntilVisible();
    expect($.tester.widget<SwitchListTile>(find.byKey(MyAccountScreen.biometricsKey)).value, isFalse);

    await $(MyAccountScreen.signOutKey).tap();
    await $(MyAccountScreen.cancelSignOutKey).tap();
    expect($(MyAccountScreen.signOutKey), findsOneWidget);
    await $(MyAccountScreen.signOutKey).tap();
    await $(MyAccountScreen.confirmSignOutKey).tap();

    await $(SignInScreen.usernameKey).waitUntilVisible();
    await $(SignInScreen.usernameKey).enterText('patrol-nawaf');
    await $(SignInScreen.passwordKey).enterText('Temporary-2');
    await $(SignInScreen.submitKey).scrollTo().tap();
    await $(ChangePasswordScreen.currentKey).enterText('Temporary-2');
    await $(ChangePasswordScreen.newKey).enterText('Nawaf-chosen-1');
    await $(ChangePasswordScreen.confirmKey).enterText('Nawaf-chosen-1');
    await $(ChangePasswordScreen.submitKey).scrollTo().tap();

    await $(ProjectsScreen.settingsKey).tap();
    await $(SettingsScreen.myAccountKey).waitUntilVisible();
    expect($(SettingsScreen.registeredKey), findsNothing);
    await $(SettingsScreen.switchProjectKey).tap();
    await $(keyStartingWith('projects.card.')).waitUntilVisible();
    expect($(ProjectsScreen.newProjectKey), findsOneWidget);
    await $(keyStartingWith('projects.card.')).tap();
    await $(keyStartingWith('home.roles.')).waitUntilVisible();
    expect($(keyStartingWith('home.users.')), findsNothing);
    expect($(keyStartingWith('home.addUnit.')), findsNothing);
    expect($(keyStartingWith('home.close.')), findsNothing);

    await $(keyStartingWith('home.addExpense.')).tap();
    await $(AddExpenseScreen.qrReadKey).waitUntilVisible();
    await $(AddExpenseScreen.supplierDetailsKey).waitUntilVisible();
    expect($.tester.widget<TextField>(find.byKey(AddExpenseScreen.amountKey)).controller!.text, '1075');

    await $(AddExpenseScreen.supplierKey).scrollTo().tap();
    await $(SupplierPicker.searchKey).enterText('مورد الميدان');
    await $(SupplierPicker.quickAddKey).tap();
    await $(SuppliersScreen.vatNumberKey).enterText('322222222222223');
    await $(SupplierPicker.pendingHintKey).waitUntilVisible();
    await $(SuppliersScreen.saveKey).last.tap();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    await $(find.text('مورد الميدان')).scrollTo();

    await $(AddExpenseScreen.itemKey).scrollTo().tap();
    await $(keyStartingWith('itemPicker.option.')).first.tap();
    await $.pumpAndSettle();
    await $(keyStartingWith('addExpense.unit.')).first.scrollTo().tap();
    await $(AddExpenseScreen.invoiceNumberKey).scrollTo().enterText('2617');
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    await $.pumpAndSettle();
    await $.tester.ensureVisible(find.byKey(AddExpenseScreen.cameraKey));
    await $.pumpAndSettle();
    await $.takeNativeScreenshot('add-expense');

    await $(keyStartingWith('addExpense.paymentMethod.')).first.scrollTo().tap();
    await $(AddExpenseScreen.paymentDiffersKey).scrollTo().tap();
    await $.pumpAndSettle();
    await $.takeNativeScreenshot('add-expense-payment');
    await $(AddExpenseScreen.paymentDiffersKey).scrollTo().tap();
    await $.pumpAndSettle();

    await $(AddExpenseScreen.sendKey).scrollTo();
    await $.takeNativeScreenshot('add-expense-send');
    await $(AddExpenseScreen.sendKey).tap();
    await $(AddExpenseScreen.savedKey).waitUntilVisible();
    await $(keyStartingWith('home.addExpense.')).waitUntilVisible();

    await $(HomeScreen.settingsKey).tap();
    await $(SettingsScreen.myAccountKey).tap();
    await $(MyAccountScreen.signOutKey).tap();
    await $(MyAccountScreen.confirmSignOutKey).tap();

    await $(SignInScreen.usernameKey).waitUntilVisible();
    await $(SignInScreen.usernameKey).enterText('patrol-reem');
    await $(SignInScreen.passwordKey).enterText('Reem-chosen-1');
    await $(SignInScreen.submitKey).scrollTo().tap();
    await $(HomeScreen.titleKey).waitUntilVisible();
    await $(find.text('غصون 7')).waitUntilVisible();
    expect($(BackButton), findsNothing);

    await $(keyStartingWith('home.close.')).scrollTo().tap();
    await $(HomeScreen.confirmCloseKey).waitUntilVisible();
    await $.takeNativeScreenshot('close-project');
    await $(HomeScreen.cancelCloseKey).tap();
    expect($(keyStartingWith('home.close.')), findsOneWidget);

    await $(keyStartingWith('home.close.')).scrollTo().tap();
    await $(HomeScreen.confirmCloseKey).tap();
    await $.pumpAndSettle();
    expect($(keyStartingWith('home.close.')), findsNothing);
    expect($(keyStartingWith('home.addUnit.')), findsNothing);

    await $(HomeScreen.settingsKey).tap();
    await $(SettingsScreen.switchProjectKey).tap();
    await $(ProjectsScreen.titleKey).waitUntilVisible();
    await $(ProjectsScreen.settingsKey).tap();
    await $(SettingsScreen.myAccountKey).tap();
    await $(MyAccountScreen.signOutKey).tap();
    await $(MyAccountScreen.confirmSignOutKey).tap();
  });
}
