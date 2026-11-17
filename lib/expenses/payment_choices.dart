import 'package:flutter/material.dart';

import '../accounts/account.dart';
import '../api_list.dart';
import '../settings/payment_methods.dart';
import '../ui/labelled_chips.dart';
import '../ui/part_keys.dart';
import '../words/words.dart';
import 'payment_choice.dart';

/// The account an entry moves money through, for any table, and how an expense was paid (redix-api #110, D10). The accounts on offer are the table's to say: for an expense
/// only what the signed-in user may pay from (BRS open question 4), and of those only what its payment method, asked first, pays from (redix-app #109): one is named
/// on a line of its own (D2), none says so.
class PaymentChoices extends StatelessWidget {
  /// The choices kept in [choice], among the active ones of [accounts] and, when [asksPaymentMethod], [paymentMethods], calling [onChanged] after each and [onRetry] to read a
  /// list again.
  const PaymentChoices({super.key, required this.choice, required this.accounts, required this.asksPaymentMethod, required this.paymentMethods, required this.onChanged, required this.onRetry});

  /// What was chosen.
  final PaymentChoice choice;

  /// The accounts the entry may use.
  final ApiList<Account> accounts;

  /// True when the entry says how it was paid: an expense.
  final bool asksPaymentMethod;

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

  /// The line naming the one account the payment method pays from (D2).
  static const paidFromKey = Key('payment.paidFrom');

  /// The line that says the payment method pays from no account the user may use (R8).
  static const noAccountForMethodKey = Key('payment.noAccountForMethod');

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([accounts, paymentMethods]),
      builder: (context, _) {
        final failure = [accounts.message, paymentMethods.message].firstWhere((message) => message.isNotEmpty, orElse: () => '');
        final held = accounts.all.where((account) => account.isActive);
        final offered = choice.offeredIn(accounts.all, asksPaymentMethod: asksPaymentMethod, methods: paymentMethods.all);
        final methodChosen = !asksPaymentMethod || choice.paymentMethodId.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            if (failure.isNotEmpty) ...[
              Text(words.text(failure), key: listMessageKey),
              OutlinedButton(key: retryKey, onPressed: onRetry, child: Text(words.commonRetry, key: retryKey.label)),
            ],
            if (asksPaymentMethod)
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
            if (failure.isEmpty && !accounts.isLoading && held.isEmpty) Text(words.expensesNoAccount, key: noAccountKey),
            if (failure.isEmpty && held.isNotEmpty && methodChosen && offered.isEmpty) Text(words.expensesNoAccountForMethod, key: noAccountForMethodKey),
            if (asksPaymentMethod && offered.length == 1) Text('${words.expensesPaidFrom}: ${offered.single.name}', key: paidFromKey),
            if (offered.length > 1 || (!asksPaymentMethod && offered.isNotEmpty))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(words.expensesAccount, key: PaymentChoices.accountHeadingKey, style: Theme.of(context).textTheme.titleSmall),
                  RadioGroup<String>(
                    groupValue: choice.chosenAccountIn(offered),
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
          ],
        );
      },
    );
  }
}
