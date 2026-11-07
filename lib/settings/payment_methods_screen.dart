import 'package:flutter/material.dart';

import '../format/number_format.dart';
import '../projects/project.dart';
import '../projects/projects.dart';
import '../ui/screen_title.dart';
import '../ui/api_list_body.dart';
import '../ui/change_dialog.dart';
import '../ui/confirm_dialog.dart';
import '../ui/name_dialog.dart';
import '../ui/refresh_button.dart';
import '../words/words.dart';
import 'payment_method_row.dart';
import 'payment_methods.dart';
import 'vat_rate_dialog.dart';

/// A project's VAT rate and payment methods (UC-014): whoever keeps its settings changes the rate, and adds, renames, disables and deletes methods; one an expense was paid with is only disabled.
class PaymentMethodsScreen extends StatefulWidget {
  /// The screen of [project], whose rate changes through [projects] and whose methods change through [paymentMethods].
  const PaymentMethodsScreen({super.key, required this.project, required this.projects, required this.paymentMethods});

  /// The project, as it was opened.
  final Project project;

  /// The projects, which hold its VAT rate as it is now.
  final Projects projects;

  /// The payment methods this screen shows and changes.
  final PaymentMethods paymentMethods;

  /// The screen's route.
  static const path = '/projects/:projectId/payment-methods';

  /// The route of the payment methods of the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/payment-methods';

  /// The VAT rate.
  static const vatRateKey = Key('paymentMethods.vatRate');

  /// The line that says what the rate applies to.
  static const vatHintKey = Key('paymentMethods.vatHint');

  /// The button that changes the rate.
  static const changeVatRateKey = Key('paymentMethods.changeVatRate');

  /// The rate, in its dialog.
  static const vatPercentKey = Key('paymentMethods.vatPercent');

  /// The button that adds a payment method.
  static const addKey = Key('paymentMethods.add');

  /// Rename, in a method's menu.
  static const renameKey = Key('paymentMethods.rename');

  /// Disable, in a method's menu.
  static const disableKey = Key('paymentMethods.disable');

  /// Enable, in a method's menu.
  static const enableKey = Key('paymentMethods.enable');

  /// Delete, in a method's menu.
  static const deleteKey = Key('paymentMethods.delete');

  /// The button that deletes, in the dialog that asks first.
  static const deleteConfirmKey = ConfirmDialog.confirmKey;

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

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  @override
  void initState() {
    super.initState();
    widget.paymentMethods.load();
  }

  Widget _vatRate(BuildContext context) => ListenableBuilder(
    listenable: widget.projects,
    builder: (context, _) {
      final words = Words.of(context);
      final project = widget.projects.all.firstWhere((project) => project.id == widget.project.id, orElse: () => widget.project);
      return Card.outlined(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: ListTile(
          contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 4, 0),
          title: Text(words.paymentMethodsVatRate),
          subtitle: Text(words.paymentMethodsVatHint, key: PaymentMethodsScreen.vatHintKey),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${formatPlain(project.vatPercent)}%', key: PaymentMethodsScreen.vatRateKey, style: Theme.of(context).textTheme.titleMedium),
              if (project.mayManageSettings)
                IconButton(
                  key: PaymentMethodsScreen.changeVatRateKey,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: words.paymentMethodsChangeVatRate,
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => VatRateDialog(project: project, projects: widget.projects),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final project = widget.project;
    final paymentMethods = widget.paymentMethods;
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.paymentMethodsTitle, subject: widget.project.name), actions: [RefreshButton(onRefresh: paymentMethods.load)]),
      floatingActionButton: project.mayManageSettings
          ? FloatingActionButton.extended(
              key: PaymentMethodsScreen.addKey,
              icon: const Icon(Icons.add),
              tooltip: words.paymentMethodsNew,
              label: Text(words.commonAdd),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => NameDialog(title: words.paymentMethodsNew, label: words.paymentMethodsName, saveLabel: words.paymentMethodsNew, onSave: paymentMethods.add),
              ),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _vatRate(context),
          Expanded(
            child: ApiListBody(
              list: paymentMethods,
              emptyText: words.paymentMethodsEmpty,
              itemBuilder: (method) => PaymentMethodRow(method: method, paymentMethods: paymentMethods, mayChange: project.mayManageSettings),
            ),
          ),
        ],
      ),
    );
  }
}
