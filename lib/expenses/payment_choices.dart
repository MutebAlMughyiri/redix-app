import 'package:flutter/material.dart';

import '../accounts/account.dart';
import '../accounts/offered_accounts.dart';
import '../api_list.dart';
import '../settings/payment_methods.dart';
import '../ui/labelled_chips.dart';
import '../words/words.dart';
import 'payment_choice.dart';

/// Where an entry is paid from and how, for any kind of expense: only what the signed-in user may pay from is on offer (BRS open question 4).
class PaymentChoices extends StatelessWidget {
  /// The choices kept in [choice], among [accounts] and [paymentMethods], calling [onChanged] after each and [onRetry] to read a list again.
  const PaymentChoices({super.key, required this.choice, required this.accounts, required this.paymentMethods, required this.onChanged, required this.onRetry});

  /// What was chosen.
  final PaymentChoice choice;

  /// What the signed-in user may pay from.
  final OfferedAccounts accounts;

  /// The project's payment methods.
  final PaymentMethods paymentMethods;

  /// Called after a choice changes.
  final VoidCallback onChanged;

  /// Reads the lists again.
  final VoidCallback onRetry;

  /// The line that says the user holds nothing to pay from.
  static const noAccountKey = Key('payment.noAccount');

  /// The line that says a list could not be read.
  static const listMessageKey = Key('payment.listMessage');

  /// The button that reads that list again.
  static const retryKey = Key('payment.retry');

  /// The choice of paying from an account of [type].
  static Key sourceKey(AccountType type) => Key('payment.source.${type.name}');

  /// The choice of the payment method [id].
  static Key paymentMethodKey(String id) => Key('payment.method.$id');

  /// The choice of the account [id].
  static Key accountKey(String id) => Key('payment.account.$id');

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([accounts, paymentMethods]),
      builder: (context, _) {
        final failed = <ApiList<Object?>>[accounts, paymentMethods].where((list) => list.message.isNotEmpty).firstOrNull;
        final sources = choice.sourcesIn(accounts.all);
        final offered = choice.accountsIn(accounts.all);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            if (failed != null) ...[
              Text(words.text(failed.message), key: listMessageKey),
              OutlinedButton(key: retryKey, onPressed: onRetry, child: Text(words.commonRetry)),
            ],
            if (failed == null && !accounts.isLoading && sources.isEmpty) Text(words.expensesNoAccount, key: noAccountKey),
            if (sources.isNotEmpty)
              LabelledChips<AccountType>(
                label: words.expensesPaymentSource,
                choices: sources,
                keyOf: sourceKey,
                nameOf: (type) => words.text(type.wordKey),
                isChosen: (type) => choice.sourceIn(accounts.all) == type,
                onChosen: (type) {
                  choice.source = type;
                  onChanged();
                },
              ),
            if (offered.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(words.expensesAccount, style: Theme.of(context).textTheme.titleSmall),
                  RadioGroup<String>(
                    groupValue: choice.chosenAccountIn(accounts.all),
                    onChanged: (accountId) {
                      choice.accountId = accountId ?? choice.accountId;
                      onChanged();
                    },
                    child: Column(
                      children: [
                        for (final account in offered) RadioListTile<String>(key: accountKey(account.id), contentPadding: EdgeInsets.zero, dense: true, value: account.id, title: Text(account.name)),
                      ],
                    ),
                  ),
                ],
              ),
            LabelledChips(
              label: words.expensesPaymentMethod,
              choices: paymentMethods.all.where((method) => method.isActive),
              keyOf: (method) => paymentMethodKey(method.id),
              nameOf: (method) => method.name,
              isChosen: (method) => choice.paymentMethodId == method.id,
              onChosen: (method) {
                choice.paymentMethodId = method.id;
                onChanged();
              },
            ),
          ],
        );
      },
    );
  }
}
