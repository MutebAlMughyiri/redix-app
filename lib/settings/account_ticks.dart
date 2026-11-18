// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../accounts/account.dart';
import '../accounts/accounts.dart';
import '../ui/part_keys.dart';
import '../words/words.dart';
import 'payment_methods_screen.dart';

/// The accounts a payment method pays from, a check box each (redix-app #109, D1): what is ticked is kept in [ticked], which the dialog sends.
class AccountTicks extends StatelessWidget {
  /// The active ones of [accounts], ticked as [ticked] holds them.
  const AccountTicks({super.key, required this.accounts, required this.ticked});

  /// The project's accounts.
  final Accounts accounts;

  /// The ids ticked.
  final ValueNotifier<Set<String>> ticked;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([accounts, ticked]),
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(words.paymentMethodsPaysFrom, key: PaymentMethodsScreen.paysFromHeadingKey, style: Theme.of(context).textTheme.titleSmall),
          ),
          for (final Account account in accounts.all.where((account) => account.isActive))
            CheckboxListTile(
              key: PaymentMethodsScreen.accountTickKey(account.id),
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: ticked.value.contains(account.id),
              title: Text(account.name, key: PaymentMethodsScreen.accountTickKey(account.id).title),
              onChanged: (isTicked) => ticked.value = isTicked ?? false ? {...ticked.value, account.id} : ({...ticked.value}..remove(account.id)),
            ),
        ],
      ),
    );
  }
}
