import 'package:flutter/material.dart';

import '../accounts/accounts.dart';
import '../projects/project.dart';
import '../ui/title_bar_add.dart';
import '../ui/screen_title.dart';
import '../ui/api_list_body.dart';
import '../words/words.dart';
import 'payment_method.dart';
import 'payment_method_dialog.dart';
import 'payment_method_row.dart';
import 'payment_methods.dart';

/// A project's payment methods (UC-014): whoever keeps its settings adds, renames, disables and deletes them; one an expense was paid with is only disabled.
class PaymentMethodsScreen extends StatefulWidget {
  /// The screen of [project], whose methods change through [paymentMethods], each paying from some of [accounts] (redix-app #109).
  const PaymentMethodsScreen({super.key, required this.project, required this.paymentMethods, required this.accounts});

  /// The project, as it was opened.
  final Project project;

  /// The payment methods this screen shows and changes.
  final PaymentMethods paymentMethods;

  /// The project's accounts, which a method is ticked to pay from.
  final Accounts accounts;

  /// The screen's route.
  static const path = '/projects/:projectId/payment-methods';

  /// The route of the payment methods of the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/payment-methods';

  /// The button that adds a payment method.
  static const addKey = Key('paymentMethods.add');

  /// Rename, in a method's menu.
  static const renameKey = Key('paymentMethods.rename');

  /// Disable, in a method's menu.
  static const disableKey = Key('paymentMethods.disable');

  /// Enable, in a method's menu.
  static const enableKey = Key('paymentMethods.enable');

  /// The name of the payment method [id].
  static Key nameKey(String id) => Key('paymentMethods.name.$id');

  /// The line that says the payment method [id] is disabled.
  static Key disabledKey(String id) => Key('paymentMethods.disabled.$id');

  /// The menu of the payment method [id].
  static Key menuKey(String id) => Key('paymentMethods.menu.$id');

  /// The row of the payment method [id].
  static Key rowKey(String id) => Key('paymentMethods.row.$id');

  /// The line under the payment method [id] naming the accounts it pays from.
  static Key paysFromKey(String id) => Key('paymentMethods.paysFrom.$id');

  /// The heading over a dialog's accounts.
  static const paysFromHeadingKey = Key('paymentMethods.paysFromHeading');

  /// The check box of the account [id] in a method's dialog.
  static Key accountTickKey(String id) => Key('paymentMethods.accountTick.$id');

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  @override
  void initState() {
    super.initState();
    widget.paymentMethods.loadOnOpen();
    widget.accounts.loadOnOpen();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final project = widget.project;
    final paymentMethods = widget.paymentMethods;
    return Scaffold(
      appBar: AppBar(
        title: ScreenTitle(words.paymentMethodsTitle, subject: widget.project.name),
        actions: [
          TitleBarAdd(
            buttonKey: PaymentMethodsScreen.addKey,
            tooltip: words.paymentMethodsNew,
            onPressed: project.mayManageSettings ? () => askForPaymentMethod(context, paymentMethods: paymentMethods, accounts: widget.accounts, method: PaymentMethod.none()) : null,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ApiListBody(
              list: paymentMethods,
              emptyText: words.paymentMethodsEmpty,
              listOf: (rows) => ListView(
                padding: ApiListBody.padding,
                physics: ApiListBody.physics,
                children: rows,
              ),
              itemBuilder: (method) => PaymentMethodRow(method: method, paymentMethods: paymentMethods, accounts: widget.accounts, mayChange: project.mayManageSettings),
            ),
          ),
        ],
      ),
    );
  }
}
