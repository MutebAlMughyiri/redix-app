// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../accounts/accounts.dart';
import '../ui/one_field_dialog.dart';
import '../words/words.dart';
import 'account_ticks.dart';
import 'payment_method.dart';
import 'payment_methods.dart';

/// Opens the dialog of [method]: its name and a check box per account it pays from (redix-app #109, D1). A new method, [PaymentMethod.none], starts
/// with every account ticked (D1b); saving sends both through [paymentMethods], and a refusal shows in the dialog.
void askForPaymentMethod(BuildContext context, {required PaymentMethods paymentMethods, required Accounts accounts, required PaymentMethod method}) {
  final words = Words.of(context);
  final isNew = method.id.isEmpty;
  final ticked = ValueNotifier<Set<String>>(isNew ? {for (final account in accounts.all.where((account) => account.isActive)) account.id} : {...method.accountIds});
  showDialog<void>(
    context: context,
    builder: (_) => OneFieldDialog(
      title: isNew ? words.paymentMethodsNew : words.paymentMethodsRename,
      label: words.paymentMethodsName,
      saveLabel: isNew ? words.paymentMethodsNew : words.paymentMethodsSave,
      name: method.name,
      below: [AccountTicks(accounts: accounts, ticked: ticked)],
      onSave: (name) => isNew ? paymentMethods.add(name, ticked.value) : paymentMethods.rename(method, name, ticked.value),
    ),
  ).whenComplete(ticked.dispose);
}
