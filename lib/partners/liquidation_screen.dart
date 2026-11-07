import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../accounts/account.dart';
import '../accounts/accounts.dart';
import '../attachments/attachment_screen.dart';
import '../attachments/invoice_capture.dart';
import '../expenses/entry_date.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../projects/projects.dart';
import '../structure/category.dart';
import '../structure/item_picker.dart';
import '../structure/offered_items.dart';
import '../ui/api_object_body.dart';
import '../ui/change_dialog.dart';
import '../ui/confirm_dialog.dart';
import '../ui/entry_field.dart';
import '../ui/labelled_chips.dart';
import '../ui/part_keys.dart';
import '../ui/picker_field.dart';
import '../ui/refusal_snack_bar.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'liquidation.dart';
import 'partner.dart';
import 'partners.dart';

/// Liquidating a project (UC-061, FR-51, BR-27): each partner's part of the final surplus, paid out or carried to a later project, or of a deficit, paid in; then the project closes. Once
/// closed, it shows what each partner was given, takes each payout's receipt, and records a late expense or revenue.
class LiquidationScreen extends StatefulWidget {
  /// The liquidation of [project] through [liquidation], paying through its [accounts], carrying to one of [projects] whose partners and accounts come from [partnersOf] and [accountsOf]; a late
  /// expense picks from [items], and a receipt comes from what [capture] picks.
  const LiquidationScreen({super.key, required this.project, required this.liquidation, required this.projects, required this.accounts, required this.partnersOf, required this.accountsOf, required this.items, required this.revenueItems, required this.capture});

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

  /// The button that records a late expense or revenue, in a closed project.
  static const lateKey = Key('liquidation.late');

  /// The late expense choice.
  static const lateExpenseKey = Key('liquidation.lateExpense');

  /// The late revenue choice.
  static const lateRevenueKey = Key('liquidation.lateRevenue');

  /// The late expense's item.
  static const lateItemKey = Key('liquidation.lateItem');

  /// The late entry's day.
  static const lateDateKey = Key('liquidation.lateDate');

  /// The late entry's amount.
  static const lateAmountKey = Key('liquidation.lateAmount');

  /// The late entry's description.
  static const lateDescriptionKey = Key('liquidation.lateDescription');

  /// The choice of the account [id] for the late entry.
  static Key lateAccountKey(String id) => Key('liquidation.lateAccount.$id');

  /// The button that attaches the receipt of the part [entryId].
  static Key attachReceiptKey(String entryId) => Key('liquidation.attachReceipt.$entryId');

  /// The receipt of the part [entryId].
  static Key receiptKey(String entryId) => Key('liquidation.receipt.$entryId');

  /// The choice of the account paying the partner [partnerId].
  static Key accountChoiceKey(String partnerId) => Key('liquidation.accountChoice.$partnerId');

  /// The choice of the project the partner [partnerId]'s share moves to.
  static Key targetProjectChoiceKey(String partnerId) => Key('liquidation.targetProjectChoice.$partnerId');

  /// The choice of the partner it reaches there.
  static Key targetPartnerChoiceKey(String partnerId) => Key('liquidation.targetPartnerChoice.$partnerId');

  /// The choice of the account it reaches there.
  static Key targetAccountChoiceKey(String partnerId) => Key('liquidation.targetAccountChoice.$partnerId');

  /// The choice of the account of a late entry.
  static const lateAccountChoiceKey = Key('liquidation.lateAccountChoice');

  /// What liquidating does, or what a deficit means.
  static const explainKey = Key('liquidation.explain');

  /// The heading over what was distributed.
  static const distributedHeadingKey = Key('liquidation.distributedHeading');

  /// What recording a late entry does.
  static const lateExplainKey = Key('liquidation.lateExplain');

  /// The choice of paying the partner [partnerId] out or carrying the share to another project.
  static Key wayKey(String partnerId) => Key('liquidation.way.$partnerId');

  /// The choice of what a late entry is: an expense or revenue.
  static const lateKindKey = Key('liquidation.lateKind');

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

  /// The items a late expense may go to.
  final OfferedItems items;

  /// The revenue items late revenue may go to.
  final OfferedItems revenueItems;

  /// The phone's camera and files.
  final InvoiceCapture capture;

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
      showMessage(messenger, words, 'liquidation.done');
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

  Widget _chips<T>(Key key, String label, List<T> choices, Key Function(T) keyOf, String Function(T) nameOf, bool Function(T) isChosen, ValueChanged<T> onChosen) =>
      LabelledChips<T>(key: key, label: label, choices: choices, keyOf: keyOf, nameOf: nameOf, isChosen: isChosen, onChosen: (choice) => setState(() => onChosen(choice)));

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
                key: LiquidationScreen.partKey(id).body,
                contentPadding: EdgeInsets.zero,
                title: Text(part.name, key: LiquidationScreen.partKey(id).title),
                subtitle: Text('${words.capitalShare}: ${formatShare(part.sharePercent)}%', key: LiquidationScreen.partKey(id).subtitle),
                trailing: Text(formatMoney(part.amount), key: LiquidationScreen.partKey(id).trailing, style: Theme.of(context).textTheme.titleMedium),
              ),
              SegmentedButton<bool>(
                key: LiquidationScreen.wayKey(id),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: false, label: Text(words.liquidationPayOut, key: LiquidationScreen.payOutKey(id))),
                  ButtonSegment(value: true, label: Text(words.liquidationCarry, key: LiquidationScreen.carryKey(id))),
                ],
                selected: {line.isCarry},
                onSelectionChanged: (selected) => setState(() => line.isCarry = selected.single),
              ),
              _chips<Account>(LiquidationScreen.accountChoiceKey(id), words.capitalAccount, widget.accounts.bankAndCash, (account) => LiquidationScreen.accountKey(id, account.id), (account) => account.name, (account) => account.id == line.accountId, (account) => line.accountId = account.id),
              if (line.isCarry) ...[
                _chips<Project>(LiquidationScreen.targetProjectChoiceKey(id), words.capitalTargetProject, _laterProjects, (project) => LiquidationScreen.targetProjectKey(id, project.id), (project) => project.name, (project) => project.id == line.targetProjectId, (project) => _chooseTarget(line, project)),
                if (line.targetProjectId.isNotEmpty) ...[
                  _chips<Partner>(LiquidationScreen.targetPartnerChoiceKey(id), words.capitalTargetPartner, widget.partnersOf(line.targetProjectId).all, (partner) => LiquidationScreen.targetPartnerKey(id, partner.id), (partner) => partner.name, (partner) => partner.id == line.targetPartnerId, (partner) => line.targetPartnerId = partner.id),
                  _chips<Account>(LiquidationScreen.targetAccountChoiceKey(id), words.capitalTargetAccount, widget.accountsOf(line.targetProjectId).bankAndCash, (account) => LiquidationScreen.targetAccountKey(id, account.id), (account) => account.name, (account) => account.id == line.targetAccountId, (account) => line.targetAccountId = account.id),
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
      Text(isDeficit ? words.liquidationDeficit : words.liquidationSurplus, key: LiquidationScreen.surplusKey.label, style: theme.textTheme.bodySmall),
      Text(formatMoney(figures.surplus.abs()), key: LiquidationScreen.surplusKey, style: theme.textTheme.headlineMedium),
      Text(isDeficit ? words.liquidationDeficitExplain : words.liquidationExplain, key: LiquidationScreen.explainKey),
      if (figures.pendingCount > 0) Text(words.liquidationPending.replaceFirst('{0}', '${figures.pendingCount}'), key: LiquidationScreen.pendingKey, style: TextStyle(color: theme.colorScheme.error)),
      PickerField(key: LiquidationScreen.dateKey, label: words.liquidationDate, value: formatDate(_date), onTap: _chooseDate),
      for (final part in figures.parts) _part(part, words),
      if (_message.isNotEmpty) Text(words.text(_message), key: LiquidationScreen.messageKey, style: TextStyle(color: theme.colorScheme.error)),
      FilledButton(
        key: LiquidationScreen.confirmKey,
        style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
        onPressed: ready && !_saving ? () => _askToLiquidate(figures.parts) : null,
        child: Text(words.liquidationConfirm, key: LiquidationScreen.confirmKey.label),
      ),
    ];
  }

  Future<void> _attachReceipt(LiquidationShare share) async {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final file = await widget.capture.fromFiles();
    if (file.isNone || !mounted) {
      return;
    }
    final refusal = await widget.liquidation.attachReceipt(share.entryId, file);
    showMessage(messenger, words, refusal.isEmpty ? 'liquidation.receiptAttached' : refusal);
  }

  void _askLate() => showDialog<void>(
    context: context,
    builder: (_) => _LateDialog(project: widget.project, liquidation: widget.liquidation, items: widget.items, revenueItems: widget.revenueItems, accounts: widget.accounts),
  );

  List<Widget> _distributed(LiquidationFigures figures, Words words) => [
    OutlinedButton.icon(key: LiquidationScreen.lateKey, icon: Icon(Icons.add, key: LiquidationScreen.lateKey.icon), label: Text(words.liquidationLate, key: LiquidationScreen.lateKey.label), onPressed: _askLate),
    if (figures.distributed.isEmpty) Text(words.liquidationNothing, key: LiquidationScreen.nothingKey),
    if (figures.distributed.isNotEmpty) Text(words.liquidationDistributed, key: LiquidationScreen.distributedHeadingKey, style: Theme.of(context).textTheme.titleMedium),
    for (final share in figures.distributed)
      ListTile(
        key: LiquidationScreen.distributedKey(share.entryId),
        contentPadding: EdgeInsets.zero,
        title: Text(share.partnerName, key: LiquidationScreen.distributedKey(share.entryId).title),
        subtitle: Text('${share.description} · ${formatDate(share.date)} · ${share.accountName}', key: LiquidationScreen.distributedKey(share.entryId).subtitle),
        leading: share.receiptId.isEmpty
            ? IconButton(key: LiquidationScreen.attachReceiptKey(share.entryId), tooltip: words.liquidationAttachReceipt, icon: Icon(Icons.attach_file, key: LiquidationScreen.attachReceiptKey(share.entryId).icon, color: Theme.of(context).colorScheme.error), onPressed: () => _attachReceipt(share))
            : IconButton(
                key: LiquidationScreen.receiptKey(share.entryId),
                icon: Icon(Icons.receipt_long_outlined, key: LiquidationScreen.receiptKey(share.entryId).icon),
                onPressed: () => context.push(AttachmentScreen.pathOf(widget.project.id, share.receiptId), extra: share.receiptType),
              ),
        trailing: Text(formatMoney(share.amount), key: LiquidationScreen.distributedKey(share.entryId).trailing),
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

/// The form of a late expense or revenue in a closed project (FR-51): what it was, for an expense its item, the day, the amount and the account, shared among the partners by their shares.
class _LateDialog extends StatefulWidget {
  const _LateDialog({required this.project, required this.liquidation, required this.items, required this.revenueItems, required this.accounts});

  final Project project;

  final Liquidation liquidation;

  final OfferedItems items;

  /// The revenue items late revenue may go to.
  final OfferedItems revenueItems;

  final Accounts accounts;

  @override
  State<_LateDialog> createState() => _LateDialogState();
}

class _LateDialogState extends State<_LateDialog> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  var _isExpense = true;
  var _item = Item.none();
  var _accountId = '';
  var _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    widget.items.loadOnOpen();
    widget.revenueItems.loadOnOpen();
    widget.accounts.loadOnOpen();
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final chosen = await pickEntryDate(context, widget.project, _date);
    if (mounted) {
      setState(() => _date = chosen);
    }
  }

  Future<String> _save() async {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final amount = parseNumber(_amount.text);
    if (amount.isNaN) {
      return 'capital.invalidAmount';
    }
    final refusal = await widget.liquidation.recordLate(itemId: _item.id, date: _date, amount: amount, accountId: _accountId, description: _description.text);
    if (refusal.isEmpty) {
      showMessage(messenger, words, 'liquidation.lateRecorded');
    }
    return refusal;
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ChangeDialog(
      title: words.liquidationLate,
      saveLabel: words.liquidationRecord,
      onSave: _save,
      children: [
        Text(words.liquidationLateExplain, key: LiquidationScreen.lateExplainKey, style: Theme.of(context).textTheme.bodySmall),
        SegmentedButton<bool>(
          key: LiquidationScreen.lateKindKey,
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: true, label: Text(words.liquidationLateExpense, key: LiquidationScreen.lateExpenseKey)),
            ButtonSegment(value: false, label: Text(words.liquidationLateRevenue, key: LiquidationScreen.lateRevenueKey)),
          ],
          selected: {_isExpense},
          onSelectionChanged: (selected) => setState(() {
            _isExpense = selected.single;
            _item = Item.none();
          }),
        ),
        ItemPicker(key: LiquidationScreen.lateItemKey, items: _isExpense ? widget.items : widget.revenueItems, label: words.liquidationItem, itemName: _item.name, onChanged: (item) => setState(() => _item = item)),
        PickerField(key: LiquidationScreen.lateDateKey, label: words.liquidationDate, value: formatDate(_date), onTap: _chooseDate),
        entryField(key: LiquidationScreen.lateAmountKey, controller: _amount, label: words.liquidationAmount, isNumber: true, onChanged: (_) {}),
        ListenableBuilder(
          listenable: widget.accounts,
          builder: (context, _) => LabelledChips<Account>(
            key: LiquidationScreen.lateAccountChoiceKey,
            label: words.capitalAccount,
            choices: widget.accounts.bankAndCash,
            keyOf: (account) => LiquidationScreen.lateAccountKey(account.id),
            nameOf: (account) => account.name,
            isChosen: (account) => account.id == _accountId,
            onChosen: (account) => setState(() => _accountId = account.id),
          ),
        ),
        entryField(key: LiquidationScreen.lateDescriptionKey, controller: _description, label: words.liquidationDescription, onChanged: (_) {}),
      ],
    );
  }
}
