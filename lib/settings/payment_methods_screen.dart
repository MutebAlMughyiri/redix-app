import 'package:flutter/material.dart';

import '../projects/project.dart';
import '../ui/bottom_button.dart';
import '../ui/screen_title.dart';
import '../ui/swipe_to_remove.dart';
import '../ui/api_list_body.dart';
import '../ui/change_dialog.dart';
import '../ui/name_dialog.dart';
import '../words/words.dart';
import 'payment_method_row.dart';
import 'payment_methods.dart';

/// A project's payment methods (UC-014): whoever keeps its settings adds, renames, disables and deletes them; one an expense was paid with is only disabled.
class PaymentMethodsScreen extends StatefulWidget {
  /// The screen of [project], whose methods change through [paymentMethods].
  const PaymentMethodsScreen({super.key, required this.project, required this.paymentMethods});

  /// The project, as it was opened.
  final Project project;

  /// The payment methods this screen shows and changes.
  final PaymentMethods paymentMethods;

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

  /// The line saying a method is removed by a swipe (redix-api #102).
  static const swipeHintKey = Key('paymentMethods.swipeHint');

  /// The name, in the dialogs that add and rename.
  static const dialogNameKey = NameDialog.nameKey;

  /// The button that saves, in a dialog.
  static const saveKey = ChangeDialog.saveKey;

  /// The line that says why a change was refused, in a dialog.
  static const dialogMessageKey = ChangeDialog.messageKey;

  /// The line that says the list could not be read.
  static const messageKey = ApiListBody.messageKey;

  /// The line shown while the project has no payment methods.
  static const emptyKey = ApiListBody.emptyKey;

  /// The name of the payment method [id].
  static Key nameKey(String id) => Key('paymentMethods.name.$id');

  /// The line that says the payment method [id] is disabled.
  static Key disabledKey(String id) => Key('paymentMethods.disabled.$id');

  /// The menu of the payment method [id].
  static Key menuKey(String id) => Key('paymentMethods.menu.$id');

  /// The row of the payment method [id].
  static Key rowKey(String id) => Key('paymentMethods.row.$id');

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  @override
  void initState() {
    super.initState();
    widget.paymentMethods.loadOnOpen();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final project = widget.project;
    final paymentMethods = widget.paymentMethods;
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.paymentMethodsTitle, subject: widget.project.name)),
      bottomNavigationBar: BottomButton(
        buttonKey: PaymentMethodsScreen.addKey,
        label: words.paymentMethodsNew,
        onPressed: project.mayManageSettings
            ? () => showDialog<void>(
                context: context,
                builder: (_) => NameDialog(title: words.paymentMethodsNew, label: words.paymentMethodsName, saveLabel: words.paymentMethodsNew, onSave: paymentMethods.add),
              )
            : null,
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
                children: [if (project.mayManageSettings) const SwipeHint(key: PaymentMethodsScreen.swipeHintKey), ...rows],
              ),
              itemBuilder: (method) => PaymentMethodRow(method: method, paymentMethods: paymentMethods, mayChange: project.mayManageSettings),
            ),
          ),
        ],
      ),
    );
  }
}
