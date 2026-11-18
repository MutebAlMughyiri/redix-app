// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../format/number_format.dart';
import '../format/parts_line.dart';
import '../reports/report_files.dart';
import '../ui/part_keys.dart';
import '../ui/messages.dart';
import '../words/words.dart';
import 'contract.dart';
import 'contracts.dart';
import 'contracts_screen.dart';
import '../ui/labelled_figure.dart';
import '../ui/app_color.dart';
import '../ui/row_menu.dart';

/// One contract: its contractor, item and unit, how it stands, its value, paid and remaining, with a bar of how much is paid. Tapped, it opens its own table (Muteb, 12 Nov
/// 2026) for whoever holds «يرى التقارير». Its ⋮ holds what can be done to it, for whoever keeps the settings, and its PDF and Excel, gray with the reason for whoever
/// does not hold «يُصدر التقارير» (redix-api #131: gray, never hidden).
class ContractCard extends StatelessWidget {
  /// The card of [contract], changed through [contracts] while [mayChange], where [onAmend] opens its dialog and [onOpen] its table while [mayOpen]; its files are at
  /// [address], got through [files] while [mayExport].
  const ContractCard({
    super.key,
    required this.contract,
    required this.contracts,
    required this.mayChange,
    required this.onAmend,
    required this.mayOpen,
    required this.onOpen,
    required this.mayExport,
    required this.files,
    required this.address,
  });

  /// The contract this card shows.
  final Contract contract;

  /// The way to change it.
  final Contracts contracts;

  /// Whether the signed-in user may change it now.
  final bool mayChange;

  /// Opens the dialog that amends it.
  final VoidCallback onAmend;

  /// Whether the signed-in user may open its own table, a contract's report (redix-api #131).
  final bool mayOpen;

  /// Opens its own table.
  final VoidCallback onOpen;

  /// Whether the signed-in user may take its files, holding «يُصدر التقارير» (redix-api #131).
  final bool mayExport;

  /// The way to its files.
  final ReportFiles files;

  /// Its report's address, which its files are named after.
  final String address;

  /// What waits for approval and, unless the value is open, what remains once it is approved: the figure Add entry works from.
  String _waitingLine(Words words) {
    final waiting = '${words.contractsPending} ${formatMoney(contract.pending)}';
    return contract.isOpenValue ? waiting : '$waiting · ${formatMoney(contract.remainingAfter(0))} ${words.contractsAfterApproval}';
  }

  String _terms() => partsLine([
    contract.itemName,
    if (contract.unitPrice > 0 && contract.quantity > 0) '${formatPlain(contract.unitPrice)} × ${formatPlain(contract.quantity)}' else if (contract.unitPrice > 0) formatPlain(contract.unitPrice),
  ]);

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    return Card.outlined(
      key: ContractsScreen.nameKey(contract.id).card,
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      shape: contract.isOverrun ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColor.refusal.of(context))) : null,
      child: InkWell(
        key: ContractsScreen.nameKey(contract.id).body,
        onTap: mayOpen ? onOpen : null,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 4, 16),
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
                  rowMenu(ContractsScreen.menuKey(contract.id), [
                    if (mayChange) ...[
                      rowMenuItem(ContractsScreen.editKey, words.contractsEdit, onAmend),
                      if (contract.isActive)
                        rowMenuItem(ContractsScreen.disableKey, words.contractsDisable, () => showRefusalOf(context, contracts.disable(contract)))
                      else
                        rowMenuItem(ContractsScreen.enableKey, words.contractsEnable, () => showRefusalOf(context, contracts.enable(contract))),
                    ],
                    for (final kind in const [ReportFileKind.pdf, ReportFileKind.excel])
                      rowMenuItem(
                        ContractsScreen.fileKey(kind),
                        words.text(kind.wordKey),
                        () => handReportFile(context, files, address, contract.supplierName, kind),
                        reason: mayExport ? '' : words.reportsNeedsGenerateReports,
                      ),
                  ]),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
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
      ),
    );
  }
}
