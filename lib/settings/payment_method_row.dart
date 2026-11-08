import 'package:flutter/material.dart';

import '../ui/name_dialog.dart';
import '../ui/part_keys.dart';
import '../ui/refusal_snack_bar.dart';
import '../ui/swipe_to_remove.dart';
import '../words/words.dart';
import 'payment_method.dart';
import 'payment_methods.dart';
import 'payment_methods_screen.dart';

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
      child: Card.outlined(
      key: PaymentMethodsScreen.rowKey(method.id),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        key: PaymentMethodsScreen.rowKey(method.id).body,
        contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 4, 0),
        title: Text(
          method.name,
          key: PaymentMethodsScreen.nameKey(method.id),
          style: method.isActive ? null : TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        subtitle: method.isActive ? null : Text(words.paymentMethodsDisabled, key: PaymentMethodsScreen.disabledKey(method.id)),
        trailing: mayChange
            ? PopupMenuButton<VoidCallback>(
                key: PaymentMethodsScreen.menuKey(method.id),
                onSelected: (action) => action(),
                itemBuilder: (_) => [
                  PopupMenuItem(key: PaymentMethodsScreen.renameKey, value: () => _askForName(context), child: Text(words.paymentMethodsRename, key: PaymentMethodsScreen.renameKey.label)),
                  if (method.isActive)
                    PopupMenuItem(
                      key: PaymentMethodsScreen.disableKey,
                      value: () => showRefusalOf(context, paymentMethods.disable(method)),
                      child: Text(words.paymentMethodsDisable, key: PaymentMethodsScreen.disableKey.label),
                    )
                  else
                    PopupMenuItem(
                      key: PaymentMethodsScreen.enableKey,
                      value: () => showRefusalOf(context, paymentMethods.enable(method)),
                      child: Text(words.paymentMethodsEnable, key: PaymentMethodsScreen.enableKey.label),
                    ),
                ],
              )
            : null,
      ),
      ),
    );
  }
}
