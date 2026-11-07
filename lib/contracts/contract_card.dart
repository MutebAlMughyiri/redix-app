import 'package:flutter/material.dart';

import '../format/number_format.dart';
import '../ui/refusal_snack_bar.dart';
import '../words/words.dart';
import 'contract.dart';
import 'contracts.dart';
import 'contracts_screen.dart';

/// One contract: its contractor, item and unit, how it stands, its value, paid and remaining, with a bar of how much is paid and, for whoever keeps the settings, a menu of what can be done to it.
class ContractCard extends StatelessWidget {
  /// The card of [contract], changed through [contracts] while [mayChange], where [onAmend] opens its dialog.
  const ContractCard({super.key, required this.contract, required this.contracts, required this.mayChange, required this.onAmend});

  /// The contract this card shows.
  final Contract contract;

  /// The way to change it.
  final Contracts contracts;

  /// Whether the signed-in user may change it now.
  final bool mayChange;

  /// Opens the dialog that amends it.
  final VoidCallback onAmend;

  String _terms() => [
    contract.itemName,
    if (contract.unitPrice > 0 && contract.quantity > 0) '${formatPlain(contract.unitPrice)} × ${formatPlain(contract.quantity)}' else if (contract.unitPrice > 0) formatPlain(contract.unitPrice),
  ].join(' · ');

  Widget _figure(ThemeData theme, String label, String figure, Key key, Color color) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(figure, key: key, style: theme.textTheme.titleSmall?.copyWith(color: color)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 8),
      shape: contract.isOverrun ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: colors.error)) : null,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(16, 8, mayChange ? 4 : 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: OverflowBar(
                    alignment: MainAxisAlignment.spaceBetween,
                    overflowSpacing: 4,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(contract.supplierName, key: ContractsScreen.nameKey(contract.id), style: theme.textTheme.titleSmall),
                          Text(_terms(), key: ContractsScreen.termsKey(contract.id), style: theme.textTheme.bodySmall),
                          if (contract.notes.isNotEmpty) Text(contract.notes, key: ContractsScreen.contractNotesKey(contract.id), style: theme.textTheme.bodySmall),
                        ],
                      ),
                      Chip(
                        key: ContractsScreen.standingKey(contract.id),
                        label: Text(words.text(contract.standingWordKey)),
                        backgroundColor: contract.isOverrun ? colors.errorContainer : colors.surfaceContainerHighest,
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                if (mayChange)
                  PopupMenuButton<VoidCallback>(
                    key: ContractsScreen.menuKey(contract.id),
                    onSelected: (action) => action(),
                    itemBuilder: (_) => [
                      PopupMenuItem(key: ContractsScreen.editKey, value: onAmend, child: Text(words.contractsEdit)),
                      if (contract.isActive)
                        PopupMenuItem(key: ContractsScreen.disableKey, value: () => showRefusalOf(context, contracts.disable(contract)), child: Text(words.contractsDisable))
                      else
                        PopupMenuItem(key: ContractsScreen.enableKey, value: () => showRefusalOf(context, contracts.enable(contract)), child: Text(words.contractsEnable)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsetsDirectional.only(end: mayChange ? 12 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _figure(theme, words.contractsValue, contract.isOpenValue ? words.contractsOpen : formatMoney(contract.value), ContractsScreen.valueOfKey(contract.id), colors.onSurface),
                      _figure(theme, words.contractsPaid, formatMoney(contract.paid), ContractsScreen.paidKey(contract.id), colors.onSurface),
                      _figure(theme, words.contractsRemaining, contract.isOpenValue ? '—' : formatMoney(contract.remaining), ContractsScreen.remainingKey(contract.id), contract.isOverrun ? colors.error : colors.onSurface),
                    ],
                  ),
                  if (contract.pending != 0) Text('${words.contractsPending} ${formatMoney(contract.pending)}', key: ContractsScreen.pendingKey(contract.id), style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    key: ContractsScreen.progressKey(contract.id),
                    value: contract.progress,
                    color: contract.isOverrun ? colors.error : (contract.isOpenValue ? colors.outline : null),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
