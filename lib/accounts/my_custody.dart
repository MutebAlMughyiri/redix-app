import 'package:flutter/material.dart';

import '../format/number_format.dart';
import '../home/home_screen.dart';
import '../ui/part_keys.dart';
import '../words/words.dart';
import 'accounts.dart';

/// What the signed-in user holds, on the project's home (AC-22.1): one card per account, and nothing for someone who holds none.
class MyCustody extends StatelessWidget {
  /// The cards of the signed-in user's own accounts among [accounts].
  const MyCustody({super.key, required this.accounts});

  /// The project's accounts.
  final Accounts accounts;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: accounts,
    builder: (context, _) {
      final words = Words.of(context);
      final theme = Theme.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final account in accounts.mine)
            Card.filled(
              key: HomeScreen.custodyKey(account.id),
              margin: const EdgeInsets.only(bottom: 12),
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${words.accountsMyCustody} · ${account.name}', key: HomeScreen.custodyKey(account.id).title, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text('${formatMoney(account.balance)} ${words.accountsRiyal}', key: HomeScreen.custodyBalanceKey(account.id), style: theme.textTheme.headlineSmall),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}
