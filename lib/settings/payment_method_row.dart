import 'package:flutter/material.dart';

import '../ui/name_dialog.dart';
import '../ui/refusal_snack_bar.dart';
import '../ui/swipe_to_remove.dart';
import '../words/words.dart';
import 'payment_method.dart';
import 'payment_methods.dart';
import 'payment_methods_screen.dart';
import '../ui/app_color.dart';
import '../ui/row_menu.dart';

/// One payment method: its name, whether it is disabled and, for whoever keeps the settings, a menu of what can be done to it.
class PaymentMethodRow extends StatelessWidget {
  /// The row of [method], changed through [paymentMethods] while [mayChange].
  const PaymentMethodRow({super.key, required this.method, required this.paymentMethods, required this.mayChange});

  /// The payment method this row shows.
  final PaymentMethod method;

  /// The way to change it.
  final PaymentMethods paymentMethods;

  /// Whether the signed-in user may change it now.
  final bool mayChange;

  void _askForName(BuildContext context) {
    final words = Words.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => NameDialog(
        title: words.paymentMethodsRename,
        label: words.paymentMethodsName,
        saveLabel: words.paymentMethodsSave,
        name: method.name,
        onSave: (name) => paymentMethods.rename(method, name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return SwipeToRemove(
      rowKey: PaymentMethodsScreen.rowKey(method.id),
      mayRemove: mayChange,
      onRemove: () => paymentMethods.delete(method),
      child: ListTile(
        key: PaymentMethodsScreen.rowKey(method.id),
        contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 4, 0),
        title: Text(
          method.name,
          key: PaymentMethodsScreen.nameKey(method.id),
          style: AppColor.quiet.textUnless(context, method.isActive),
        ),
        subtitle: method.isActive ? null : Text(words.paymentMethodsDisabled, key: PaymentMethodsScreen.disabledKey(method.id)),
        trailing: mayChange
            ? rowMenu(PaymentMethodsScreen.menuKey(method.id), [
                  rowMenuItem(PaymentMethodsScreen.renameKey, words.paymentMethodsRename, () => _askForName(context)),
                  if (method.isActive)
                    rowMenuItem(PaymentMethodsScreen.disableKey, words.paymentMethodsDisable, () => showRefusalOf(context, paymentMethods.disable(method)))
                  else
                    rowMenuItem(PaymentMethodsScreen.enableKey, words.paymentMethodsEnable, () => showRefusalOf(context, paymentMethods.enable(method))),
                ])
            : null,
      ),
    );
  }
}
