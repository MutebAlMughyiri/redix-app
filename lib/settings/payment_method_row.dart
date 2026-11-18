// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../accounts/accounts.dart';
import '../ui/messages.dart';
import '../ui/swipe_to_remove.dart';
import '../words/words.dart';
import 'payment_method.dart';
import 'payment_method_dialog.dart';
import 'payment_methods.dart';
import 'payment_methods_screen.dart';
import '../ui/app_color.dart';
import '../ui/row_menu.dart';

/// One payment method: its name, whether it is disabled and, for whoever keeps the settings, a menu of what can be done to it.
class PaymentMethodRow extends StatelessWidget {
  /// The row of [method], changed through [paymentMethods] while [mayChange], naming which of [accounts] it pays from (redix-app #109).
  const PaymentMethodRow({super.key, required this.method, required this.paymentMethods, required this.accounts, required this.mayChange});

  /// The payment method this row shows.
  final PaymentMethod method;

  /// The way to change it.
  final PaymentMethods paymentMethods;

  /// The project's accounts, which it pays from some of.
  final Accounts accounts;

  /// Whether the signed-in user may change it now.
  final bool mayChange;

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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListenableBuilder(
              listenable: accounts,
              builder: (context, _) => Text(
                '${words.paymentMethodsPaysFrom}: ${accounts.all.where((account) => method.paysFrom(account.id)).map((account) => account.name).join('، ')}',
                key: PaymentMethodsScreen.paysFromKey(method.id),
              ),
            ),
            if (!method.isActive) Text(words.paymentMethodsDisabled, key: PaymentMethodsScreen.disabledKey(method.id)),
          ],
        ),
        trailing: mayChange
            ? rowMenu(PaymentMethodsScreen.menuKey(method.id), [
                  rowMenuItem(PaymentMethodsScreen.renameKey, words.paymentMethodsRename, () => askForPaymentMethod(context, paymentMethods: paymentMethods, accounts: accounts, method: method)),
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
