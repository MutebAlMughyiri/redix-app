import 'package:flutter/material.dart';

import '../contracts/contract.dart';
import '../format/number_format.dart';
import '../words/words.dart';
import '../entries/add_entry_screen.dart';
import '../ui/part_keys.dart';

/// What the chosen contract stands at with this payment, before it is saved (AC-12.1): its value, what was paid, what waits, what remains after it, and the alert of an overrun.
class ContractFigures extends StatelessWidget {
  /// The figures of [contract] with [counted] on top of what it holds: this payment, or nothing when it is outside the contract.
  const ContractFigures({super.key, required this.contract, required this.counted});

  /// The contract.
  final Contract contract;

  /// What this payment adds inside the contract.
  final double counted;

  Widget _figure(ThemeData theme, String label, String figure, Key key, Color? color) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, key: key.label, style: theme.textTheme.bodySmall),
        Text(figure, key: key, style: theme.textTheme.titleSmall?.copyWith(color: color)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;
    final isOverrun = contract.isOverrunBy(counted);
    final reached = contract.paid + contract.pending + counted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            _figure(theme, words.contractsValue, contract.isOpenValue ? words.contractsOpen : formatMoney(contract.value), AddEntryScreen.valueKey, null),
            _figure(theme, words.contractsPaid, formatMoney(contract.paid), AddEntryScreen.paidKey, null),
            _figure(theme, words.contractorPaymentsRemainingAfter, contract.isOpenValue ? '—' : formatMoney(contract.remainingAfter(counted)), AddEntryScreen.remainingKey, isOverrun ? error : null),
          ],
        ),
        if (contract.pending != 0) Text('${words.contractsPending} ${formatMoney(contract.pending)}', key: AddEntryScreen.pendingKey, style: theme.textTheme.bodySmall),
        if (!contract.isOpenValue) LinearProgressIndicator(key: AddEntryScreen.progressKey, value: contract.value == 0 ? 1 : (reached / contract.value).clamp(0, 1), color: isOverrun ? error : null),
        if (isOverrun) Text(words.contractorPaymentsOverrun, key: AddEntryScreen.overrunKey, style: TextStyle(color: error)),
      ],
    );
  }
}
