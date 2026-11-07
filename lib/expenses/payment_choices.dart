import 'package:flutter/material.dart';

import '../accounts/offered_accounts.dart';
import '../settings/payment_methods.dart';
import '../ui/labelled_chips.dart';
import '../ui/part_keys.dart';
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

  /// The choice of the payment method [id].
  static Key paymentMethodKey(String id) => Key('payment.method.$id');

  /// The choice of the account [id].
  static Key accountKey(String id) => Key('payment.account.$id');

  /// The choice of the payment method.
  static const methodChoiceKey = Key('payment.methodChoice');

  /// The heading over the accounts.
  static const accountHeadingKey = Key('payment.accountHeading');

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([accounts, paymentMethods]),
      builder: (context, _) {
        final failure = [accounts.message, paymentMethods.message].firstWhere((message) => message.isNotEmpty, orElse: () => '');
        final offered = accounts.all;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            if (failure.isNotEmpty) ...[
              Text(words.text(failure), key: listMessageKey),
              OutlinedButton(key: retryKey, onPressed: onRetry, child: Text(words.commonRetry, key: retryKey.label)),
            ],
            if (failure.isEmpty && !accounts.isLoading && offered.isEmpty) Text(words.expensesNoAccount, key: noAccountKey),
            if (offered.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(words.expensesAccount, key: PaymentChoices.accountHeadingKey, style: Theme.of(context).textTheme.titleSmall),
                  RadioGroup<String>(
                    groupValue: choice.chosenAccountIn(accounts.all),
                    onChanged: (accountId) {
                      choice.accountId = accountId ?? choice.accountId;
                      onChanged();
                    },
                    child: Column(
                      children: [
                        for (final account in offered) RadioListTile<String>(key: accountKey(account.id), contentPadding: EdgeInsets.zero, dense: true, value: account.id, title: Text(account.name, key: accountKey(account.id).title)),
                      ],
                    ),
                  ),
                ],
              ),
            LabelledChips(
              key: PaymentChoices.methodChoiceKey,
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
