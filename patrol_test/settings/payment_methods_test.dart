import 'package:flutter_test/flutter_test.dart';
import 'package:redix/entries/add_entry_screen.dart';
import 'package:redix/entries/table_picker.dart';
import 'package:redix/expenses/payment_choices.dart';
import 'package:redix/home/home_screen.dart';
import 'package:redix/settings/payment_methods_screen.dart';
import 'package:redix/ui/change_dialog.dart';
import 'package:redix/ui/confirm_dialog.dart';
import 'package:redix/ui/one_field_dialog.dart';

import '../support/given.dart';
import '../support/phone_case.dart';
import '../support/steps.dart';

void main() {
  phoneClass('Payment methods (UC-014)', () {
    phoneCase('a method is added and shows', ($) async {
      final manager = await Given.manager();
      await $.fromTheHome(manager, HomeScreen.paymentMethodsKey(manager.projectId));
      await $.tapOn(PaymentMethodsScreen.addKey);
      await $.saveName('حوالة بنكية');
      await $.idOf('paymentMethods.name.', () => Given.paymentMethodNamed(manager, 'حوالة بنكية'));
    });

    phoneCase('disabled, it stays on the list and says so', ($) async {
      final manager = await Given.manager();
      await $.fromTheHome(manager, HomeScreen.paymentMethodsKey(manager.projectId));
      final id = await $.idOf('paymentMethods.name.', () async => (await Given.paymentMethods(manager)).first['id'] as String);
      await $.menuChoice(PaymentMethodsScreen.menuKey(id), PaymentMethodsScreen.disableKey);
      await $.says(PaymentMethodsScreen.disabledKey(id), $.words.paymentMethodsDisabled);
      await $.picture('payment-methods');
    });

    phoneCase('methods show in order', ($) async {
      final manager = await Given.manager();
      final methods = await Given.paymentMethods(manager);
      await $.fromTheHome(manager, HomeScreen.paymentMethodsKey(manager.projectId));
      await $.reach($(PaymentMethodsScreen.nameKey(methods[0]['id'] as String)));
      expect($.topOf(PaymentMethodsScreen.nameKey(methods[0]['id'] as String)), lessThan($.topOf(PaymentMethodsScreen.nameKey(methods[1]['id'] as String))));
    });

    phoneCase('renaming starts from the name', ($) async {
      final manager = await Given.manager();
      final method = (await Given.paymentMethods(manager)).first;
      await $.fromTheHome(manager, HomeScreen.paymentMethodsKey(manager.projectId));
      final id = method['id'] as String;
      await $.menuChoice(PaymentMethodsScreen.menuKey(id), PaymentMethodsScreen.renameKey);
      await $.reach($(OneFieldDialog.fieldKey));
      expect($.typed(OneFieldDialog.fieldKey), method['name']);
      await $.saveName('اسم جديد');
      await $.says(PaymentMethodsScreen.nameKey(id), 'اسم جديد');
    });

    phoneCase('AC-40.1: Enable brings it back', ($) async {
      final manager = await Given.manager();
      final id = (await Given.paymentMethods(manager)).first['id'] as String;
      await Given.paymentMethodDisabled(manager, id);
      await $.fromTheHome(manager, HomeScreen.paymentMethodsKey(manager.projectId));
      await $.reach($(PaymentMethodsScreen.disabledKey(id)));
      await $.menuChoice(PaymentMethodsScreen.menuKey(id), PaymentMethodsScreen.enableKey);
      await $.gone($(PaymentMethodsScreen.disabledKey(id)));
    });

    phoneCase('redix-api #119: a swipe deletes a method never used, once confirmed in its row', ($) async {
      final manager = await Given.manager();
      final id = (await Given.paymentMethods(manager)).last['id'] as String;
      await $.fromTheHome(manager, HomeScreen.paymentMethodsKey(manager.projectId));
      await $.swipeAway(PaymentMethodsScreen.rowKey(id));
      expect($(ConfirmDialog.dialogKey), findsNothing);
      await $.gone($(PaymentMethodsScreen.nameKey(id)));
    });

    phoneCase('a method an expense was paid with is not deleted, and the refusal says to disable it', ($) async {
      final manager = await Given.manager();
      await Given.entry(manager);
      final id = (await Given.paymentMethods(manager)).first['id'] as String;
      await $.fromTheHome(manager, HomeScreen.paymentMethodsKey(manager.projectId));
      await $.swipeAway(PaymentMethodsScreen.rowKey(id));
      await $.messageSays('paymentMethods.paymentMethodUsed', $.words.paymentMethodsPaymentMethodUsed);
      await $.reach($(PaymentMethodsScreen.nameKey(id)));
    });

    phoneCase('AC-40.1: a disabled method is not offered in Add entry', ($) async {
      final manager = await Given.manager();
      final methods = await Given.paymentMethods(manager);
      final disabled = methods.first['id'] as String;
      final offered = methods.last['id'] as String;
      await Given.paymentMethodDisabled(manager, disabled);
      final table = await Given.firstPurchaseTable(manager);
      await $.fromTheHome(manager, HomeScreen.addEntryKey(manager.projectId));
      await $.tapOn(AddEntryScreen.tableKey);
      await $.tapOn(TablePicker.optionKey(table.tableId));
      await $.goTo($(PaymentChoices.paymentMethodKey(offered)));
      expect($(PaymentChoices.paymentMethodKey(disabled)), findsNothing);
    });

    phoneCase('a refused name stays in the dialog with its reason', ($) async {
      final manager = await Given.manager();
      await $.fromTheHome(manager, HomeScreen.paymentMethodsKey(manager.projectId));
      await $.tapOn(PaymentMethodsScreen.addKey);
      await $.saveName(' ');
      await $.says(ChangeDialog.messageKey, $.words.paymentMethodsInvalidName);
      expect($(OneFieldDialog.fieldKey), findsOneWidget);
    });
  });
}
