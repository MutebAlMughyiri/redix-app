import 'package:flutter/material.dart';

import '../format/number_format.dart';
import '../ui/part_keys.dart';
import '../ui/refusal_snack_bar.dart';
import '../words/words.dart';
import 'contract.dart';
import 'contracts.dart';
import 'contracts_screen.dart';
import '../ui/labelled_figure.dart';

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

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card.outlined(
      key: ContractsScreen.nameKey(contract.id).card,
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
                        label: Text(words.text(contract.standingWordKey), key: ContractsScreen.standingKey(contract.id).label),
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
                      PopupMenuItem(key: ContractsScreen.editKey, value: onAmend, child: Text(words.contractsEdit, key: ContractsScreen.editKey.label)),
                      if (contract.isActive)
                        PopupMenuItem(key: ContractsScreen.disableKey, value: () => showRefusalOf(context, contracts.disable(contract)), child: Text(words.contractsDisable, key: ContractsScreen.disableKey.label))
                      else
                        PopupMenuItem(key: ContractsScreen.enableKey, value: () => showRefusalOf(context, contracts.enable(contract)), child: Text(words.contractsEnable, key: ContractsScreen.enableKey.label)),
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
                      LabelledFigure(label: words.contractsValue, figure: contract.isOpenValue ? words.contractsOpen : formatMoney(contract.value), figureKey: ContractsScreen.valueOfKey(contract.id)),
                      LabelledFigure(label: words.contractsPaid, figure: formatMoney(contract.paid), figureKey: ContractsScreen.paidKey(contract.id)),
                      LabelledFigure(label: words.contractsRemaining, figure: contract.isOpenValue ? '—' : formatMoney(contract.remaining), figureKey: ContractsScreen.remainingKey(contract.id), color: contract.isOverrun ? colors.error : null),
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
