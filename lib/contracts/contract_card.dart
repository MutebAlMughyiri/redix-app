import 'package:flutter/material.dart';

import '../format/number_format.dart';
import '../ui/part_keys.dart';
import '../ui/refusal_snack_bar.dart';
import '../words/words.dart';
import 'contract.dart';
import 'contracts.dart';
import 'contracts_screen.dart';
import '../ui/labelled_figure.dart';
import '../ui/app_color.dart';
import '../ui/row_menu.dart';

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

  /// What waits for approval and, unless the value is open, what remains once it is approved: the figure Add entry works from.
  String _waitingLine(Words words) {
    final waiting = '${words.contractsPending} ${formatMoney(contract.pending)}';
    return contract.isOpenValue ? waiting : '$waiting · ${formatMoney(contract.remainingAfter(0))} ${words.contractsAfterApproval}';
  }

  String _terms() => [
    contract.itemName,
    if (contract.unitPrice > 0 && contract.quantity > 0) '${formatPlain(contract.unitPrice)} × ${formatPlain(contract.quantity)}' else if (contract.unitPrice > 0) formatPlain(contract.unitPrice),
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    return Card.outlined(
      key: ContractsScreen.nameKey(contract.id).card,
      margin: const EdgeInsets.only(bottom: 8),
      shape: contract.isOverrun ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColor.refusal.of(context))) : null,
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
                        backgroundColor: contract.isOverrun ? AppColor.refusalSurface.of(context) : AppColor.mutedSurface.of(context),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                if (mayChange)
                  rowMenu(ContractsScreen.menuKey(contract.id), [
                      rowMenuItem(ContractsScreen.editKey, words.contractsEdit, onAmend),
                      if (contract.isActive)
                        rowMenuItem(ContractsScreen.disableKey, words.contractsDisable, () => showRefusalOf(context, contracts.disable(contract)))
                      else
                        rowMenuItem(ContractsScreen.enableKey, words.contractsEnable, () => showRefusalOf(context, contracts.enable(contract))),
                    ]),
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
                      LabelledFigure(label: words.contractsRemaining, figure: contract.isOpenValue ? '—' : formatMoney(contract.remaining), figureKey: ContractsScreen.remainingKey(contract.id), color: contract.isOverrun ? AppColor.refusal.of(context) : null),
                    ],
                  ),
                  if (contract.pending != 0) Text(_waitingLine(words), key: ContractsScreen.pendingKey(contract.id), style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    key: ContractsScreen.progressKey(contract.id),
                    value: contract.progress,
                    color: contract.isOverrun ? AppColor.refusal.of(context) : (contract.isOpenValue ? AppColor.outline.of(context) : null),
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
