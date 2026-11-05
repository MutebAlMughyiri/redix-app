import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../accounts/account.dart';
import '../accounts/accounts.dart';
import '../expenses/entry_date.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../projects/projects.dart';
import '../ui/api_object_body.dart';
import '../ui/confirm_dialog.dart';
import '../ui/labelled_chips.dart';
import '../ui/picker_field.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'liquidation.dart';
import 'partner.dart';
import 'partners.dart';

/// Liquidating a project (UC-061, FR-51, BR-27): each partner's part of the final surplus, paid out or carried to a later project, or of a deficit, paid in; then the project closes.
class LiquidationScreen extends StatefulWidget {
  /// The liquidation of [project] through [liquidation], paying through its [accounts], carrying to one of [projects] whose partners and accounts come from [partnersOf] and [accountsOf].
  const LiquidationScreen({super.key, required this.project, required this.liquidation, required this.projects, required this.accounts, required this.partnersOf, required this.accountsOf});

  /// The screen's route.
  static const path = '/projects/:projectId/liquidation';

  /// The route of the project [projectId]'s liquidation.
  static String pathOf(String projectId) => '/projects/$projectId/liquidation';

  /// What is left to share out.
  static const surplusKey = Key('liquidation.surplus');

  /// The line saying entries wait for approval.
  static const pendingKey = Key('liquidation.pending');

  /// The line saying nothing is left to share out.
  static const nothingKey = Key('liquidation.nothing');

  /// The day.
  static const dateKey = Key('liquidation.date');

  /// The button that liquidates and closes.
  static const confirmKey = Key('liquidation.confirm');

  /// The line that says why it was refused.
  static const messageKey = Key('liquidation.message');

  /// The part of the partner [partnerId].
  static Key partKey(String partnerId) => Key('liquidation.part.$partnerId');

  /// The choice to pay the partner [partnerId]'s part.
  static Key payOutKey(String partnerId) => Key('liquidation.payOut.$partnerId');

  /// The choice to carry the partner [partnerId]'s part.
  static Key carryKey(String partnerId) => Key('liquidation.carry.$partnerId');

  /// The choice of the account [accountId] for the partner [partnerId].
  static Key accountKey(String partnerId, String accountId) => Key('liquidation.account.$partnerId.$accountId');

  /// The choice of the later project [projectId] for the partner [partnerId].
  static Key targetProjectKey(String partnerId, String projectId) => Key('liquidation.targetProject.$partnerId.$projectId');

  /// The choice of the partner [targetPartnerId] there for the partner [partnerId].
  static Key targetPartnerKey(String partnerId, String targetPartnerId) => Key('liquidation.targetPartner.$partnerId.$targetPartnerId');

  /// The choice of the account [accountId] there for the partner [partnerId].
  static Key targetAccountKey(String partnerId, String accountId) => Key('liquidation.targetAccount.$partnerId.$accountId');

  /// A part already shared out, by its entry [entryId].
  static Key distributedKey(String entryId) => Key('liquidation.distributed.$entryId');

  /// The project.
  final Project project;

  /// Its liquidation.
  final Liquidation liquidation;

  /// All the projects, for a carry.
  final Projects projects;

  /// The project's accounts.
  final Accounts accounts;

  /// Another project's partners.
  final Partners Function(String projectId) partnersOf;

  /// Another project's accounts.
  final Accounts Function(String projectId) accountsOf;

  @override
  State<LiquidationScreen> createState() => _LiquidationScreenState();
}

class _LiquidationScreenState extends State<LiquidationScreen> {
  final _lines = <String, LiquidationLine>{};
  var _date = DateTime.now();
  var _message = '';
  var _saving = false;

  @override
  void initState() {
    super.initState();
    widget.liquidation.loadOnOpen();
    widget.accounts.loadOnOpen();
    widget.projects.loadOnOpen();
  }

  LiquidationLine _lineOf(String partnerId) => _lines.putIfAbsent(partnerId, LiquidationLine.new);

  List<Project> get _laterProjects => widget.projects.all.where((project) => project.id != widget.project.id && project.mayMoveMoney).toList();

  void _chooseTarget(LiquidationLine line, Project project) {
    setState(() {
      line
        ..targetProjectId = project.id
        ..targetPartnerId = ''
        ..targetAccountId = '';
    });
    unawaited(widget.partnersOf(project.id).load());
    unawaited(widget.accountsOf(project.id).load());
  }

  Future<void> _chooseDate() async {
    final chosen = await pickEntryDate(context, widget.project, _date);
    if (mounted) {
      setState(() => _date = chosen);
    }
  }

  Future<void> _liquidate(List<LiquidationPart> parts) async {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    final refusal = await widget.liquidation.liquidate(_date, {for (final part in parts) part.partnerId: _lineOf(part.partnerId)});
    if (!mounted) {
      return;
    }
    if (refusal.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(words.liquidationDone)));
      await widget.projects.load();
      if (mounted) {
        context.pop(true);
      }
      return;
    }
    setState(() {
      _saving = false;
      _message = refusal;
    });
  }

  void _askToLiquidate(List<LiquidationPart> parts) {
    final words = Words.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: words.liquidationQuestion,
        subject: widget.project.name,
        explanation: words.liquidationQuestionExplain,
        confirmLabel: words.liquidationConfirm,
        onConfirm: () => _liquidate(parts),
      ),
    );
  }

  Widget _chips<T>(String label, List<T> choices, Key Function(T) keyOf, String Function(T) nameOf, bool Function(T) isChosen, ValueChanged<T> onChosen) =>
      LabelledChips<T>(label: label, choices: choices, keyOf: keyOf, nameOf: nameOf, isChosen: isChosen, onChosen: (choice) => setState(() => onChosen(choice)));

  Widget _part(LiquidationPart part, Words words) {
    final line = _lineOf(part.partnerId);
    final id = part.partnerId;
    return Card.outlined(
      key: LiquidationScreen.partKey(id),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ListenableBuilder(
          listenable: Listenable.merge([widget.accounts, widget.projects, if (line.targetProjectId.isNotEmpty) ...[widget.partnersOf(line.targetProjectId), widget.accountsOf(line.targetProjectId)]]),
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(part.name),
                subtitle: Text('${words.capitalShare}: ${formatShare(part.sharePercent)}%'),
                trailing: Text(formatMoney(part.amount), style: Theme.of(context).textTheme.titleMedium),
              ),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: false, label: Text(words.liquidationPayOut, key: LiquidationScreen.payOutKey(id))),
                  ButtonSegment(value: true, label: Text(words.liquidationCarry, key: LiquidationScreen.carryKey(id))),
                ],
                selected: {line.isCarry},
                onSelectionChanged: (selected) => setState(() => line.isCarry = selected.single),
              ),
              _chips<Account>(words.capitalAccount, widget.accounts.bankAndCash, (account) => LiquidationScreen.accountKey(id, account.id), (account) => account.name, (account) => account.id == line.accountId, (account) => line.accountId = account.id),
              if (line.isCarry) ...[
                _chips<Project>(words.capitalTargetProject, _laterProjects, (project) => LiquidationScreen.targetProjectKey(id, project.id), (project) => project.name, (project) => project.id == line.targetProjectId, (project) => _chooseTarget(line, project)),
                if (line.targetProjectId.isNotEmpty) ...[
                  _chips<Partner>(words.capitalTargetPartner, widget.partnersOf(line.targetProjectId).all, (partner) => LiquidationScreen.targetPartnerKey(id, partner.id), (partner) => partner.name, (partner) => partner.id == line.targetPartnerId, (partner) => line.targetPartnerId = partner.id),
                  _chips<Account>(words.capitalTargetAccount, widget.accountsOf(line.targetProjectId).bankAndCash, (account) => LiquidationScreen.targetAccountKey(id, account.id), (account) => account.name, (account) => account.id == line.targetAccountId, (account) => line.targetAccountId = account.id),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _toShare(LiquidationFigures figures, Words words) {
    final theme = Theme.of(context);
    final isDeficit = figures.surplus < 0;
    final ready = figures.pendingCount == 0 && figures.parts.every((part) => _lineOf(part.partnerId).isComplete);
    return [
      Text(isDeficit ? words.liquidationDeficit : words.liquidationSurplus, style: theme.textTheme.bodySmall),
      Text(formatMoney(figures.surplus.abs()), key: LiquidationScreen.surplusKey, style: theme.textTheme.headlineMedium),
      Text(isDeficit ? words.liquidationDeficitExplain : words.liquidationExplain),
      if (figures.pendingCount > 0) Text(words.liquidationPending.replaceFirst('{0}', '${figures.pendingCount}'), key: LiquidationScreen.pendingKey, style: TextStyle(color: theme.colorScheme.error)),
      PickerField(key: LiquidationScreen.dateKey, label: words.liquidationDate, value: formatDate(_date), onTap: _chooseDate),
      for (final part in figures.parts) _part(part, words),
      if (_message.isNotEmpty) Text(words.text(_message), key: LiquidationScreen.messageKey, style: TextStyle(color: theme.colorScheme.error)),
      FilledButton(
        key: LiquidationScreen.confirmKey,
        style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
        onPressed: ready && !_saving ? () => _askToLiquidate(figures.parts) : null,
        child: Text(words.liquidationConfirm),
      ),
    ];
  }

  List<Widget> _distributed(LiquidationFigures figures, Words words) => [
    if (figures.distributed.isEmpty) Text(words.liquidationNothing, key: LiquidationScreen.nothingKey),
    if (figures.distributed.isNotEmpty) Text(words.liquidationDistributed, style: Theme.of(context).textTheme.titleMedium),
    for (final share in figures.distributed)
      ListTile(
        key: LiquidationScreen.distributedKey(share.entryId),
        contentPadding: EdgeInsets.zero,
        title: Text(share.partnerName),
        subtitle: Text('${formatDate(share.date)} · ${share.accountName}'),
        trailing: Text(formatMoney(share.amount)),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.liquidationTitle, subject: widget.project.name)),
      body: ApiObjectBody(
        object: widget.liquidation,
        builder: (figures) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: widget.project.isFinished ? _distributed(figures, words) : _toShare(figures, words),
            ),
          ],
        ),
      ),
    );
  }
}
