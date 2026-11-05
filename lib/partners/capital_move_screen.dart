import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../accounts/account.dart';
import '../accounts/accounts.dart';
import '../attachments/attachments.dart';
import '../attachments/invoice_capture.dart';
import '../attachments/picked_file.dart';
import '../expenses/entry_date.dart';
import '../expenses/invoice_section.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../projects/projects.dart';
import '../ui/entry_field.dart';
import '../ui/labelled_chips.dart';
import '../ui/picker_field.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'capital.dart';
import 'partner.dart';
import 'partners.dart';

/// What a capital movement can be, as the API names it, each knowing what it asks for.
enum MoveType {
  /// A partner put money in.
  contribution,

  /// A partner took money out.
  withdrawal,

  /// A partner took all they had and withdrew.
  settlementAndExit,

  /// A balance arrives from another project.
  carryIn,

  /// A balance leaves for another project.
  carryOut,

  /// A partner gave something other than money.
  inKind,

  /// A partner took money that comes back.
  refundableAdvance;

  /// True for a carry between projects, which asks for no receipt (BR-23).
  bool get isCarry => this == carryIn || this == carryOut;

  /// True when a reason takes the place of a receipt.
  bool get asksReasonOnly => this == inKind;
}

/// A capital movement (UC-042), or a balance carried between projects (UC-043). It counts at once (BR-30).
class CapitalMoveScreen extends StatefulWidget {
  /// The screen entering a movement in [project], starting with [sharedFile] when it was shared from another app (UC-046).
  const CapitalMoveScreen({super.key, required this.project, required this.projects, required this.capital, required this.partners, required this.accounts, required this.partnersOf, required this.accountsOf, required this.attachments, required this.capture, required this.sharedFile});

  /// The address of the screen.
  static const path = '/projects/:projectId/capital/new';

  /// The address of the screen for the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/capital/new';

  /// The address of the screen starting with the shared file.
  static String sharedPathOf(String projectId) => '/projects/$projectId/capital/new?shared=1';

  /// The amount.
  static const amountKey = Key('capitalMove.amount');

  /// The date.
  static const dateKey = Key('capitalMove.date');

  /// What was said about it.
  static const descriptionKey = Key('capitalMove.description');

  /// The switch saying it was paid in cash.
  static const cashKey = Key('capitalMove.cash');

  /// Why there is no receipt.
  static const reasonKey = Key('capitalMove.reason');

  /// The amount on the receipt.
  static const receiptAmountKey = Key('capitalMove.receiptAmount');

  /// The warning that the receipt says another amount (BR-23).
  static const receiptDiffersKey = Key('capitalMove.receiptDiffers');

  /// The line saying there is no project to carry to.
  static const noTargetKey = Key('capitalMove.noTarget');

  /// The button saving it.
  static const saveKey = Key('capitalMove.save');

  /// The line saying why it was refused.
  static const messageKey = Key('capitalMove.message');

  /// The choice of the partner [id].
  static Key partnerKey(String id) => Key('capitalMove.partner.$id');

  /// The choice of [type].
  static Key typeKey(MoveType type) => Key('capitalMove.type.${type.name}');

  /// The choice of the account [id].
  static Key accountKey(String id) => Key('capitalMove.account.$id');

  /// The choice of the other project [id].
  static Key targetProjectKey(String id) => Key('capitalMove.targetProject.$id');

  /// The choice of the partner [id] in the other project.
  static Key targetPartnerKey(String id) => Key('capitalMove.targetPartner.$id');

  /// The choice of the account [id] in the other project.
  static Key targetAccountKey(String id) => Key('capitalMove.targetAccount.$id');

  /// The project.
  final Project project;

  /// All the projects, for a carry.
  final Projects projects;

  /// The way to enter it.
  final Capital capital;

  /// The project's partners.
  final Partners partners;

  /// The project's accounts.
  final Accounts accounts;

  /// Another project's partners.
  final Partners Function(String projectId) partnersOf;

  /// Another project's accounts.
  final Accounts Function(String projectId) accountsOf;

  /// The way to keep the receipt.
  final Attachments attachments;

  /// The phone's camera and files.
  final InvoiceCapture capture;

  /// The file it starts with; none otherwise.
  final PickedFile sharedFile;

  @override
  State<CapitalMoveScreen> createState() => _CapitalMoveScreenState();
}

class _CapitalMoveScreenState extends State<CapitalMoveScreen> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _reason = TextEditingController();
  final _receiptAmount = TextEditingController();
  var _partnerId = '';
  var _type = MoveType.contribution;
  var _accountId = '';
  var _date = DateTime.now();
  late var _file = widget.sharedFile;
  var _fileMessage = '';
  var _attachmentId = '';
  var _isCash = false;
  var _targetProjectId = '';
  var _targetPartnerId = '';
  var _targetAccountId = '';
  var _message = '';
  var _saving = false;

  @override
  void initState() {
    super.initState();
    widget.partners.loadOnOpen();
    widget.accounts.loadOnOpen();
    widget.capital.loadOnOpen();
    widget.projects.loadOnOpen();
  }

  @override
  void dispose() {
    for (final field in [_amount, _description, _reason, _receiptAmount]) {
      field.dispose();
    }
    super.dispose();
  }

  List<Project> get _otherProjects => widget.projects.all.where((project) => project.id != widget.project.id && project.mayMoveMoney).toList();

  List<Account> _realAccounts(Accounts accounts) => accounts.all.where((account) => account.isActive && account.type != AccountType.partnerPocket).toList();

  void _chooseType(MoveType type) {
    setState(() {
      _type = type;
      if (type == MoveType.settlementAndExit && _partnerId.isNotEmpty) {
        _amount.text = formatPlain(widget.capital.value.of(_partnerId).balance);
      }
    });
  }

  void _choosePartner(Partner partner) {
    setState(() => _partnerId = partner.id);
    _chooseType(_type);
  }

  void _chooseTarget(Project project) {
    setState(() {
      _targetProjectId = project.id;
      _targetPartnerId = '';
      _targetAccountId = '';
    });
    unawaited(widget.partnersOf(project.id).load());
    unawaited(widget.accountsOf(project.id).load());
  }

  Future<void> _takeFrom(Future<PickedFile> Function() source) async {
    final file = await source();
    if (mounted) {
      setState(() {
        _fileMessage = file.failure;
        _file = file.isNone ? _file : file;
        _attachmentId = file.isNone ? _attachmentId : '';
      });
    }
  }

  Future<void> _chooseDate() async {
    final chosen = await pickEntryDate(context, widget.project, _date);
    if (mounted) {
      setState(() => _date = chosen);
    }
  }

  String _isoOf(DateTime date) => date.toIso8601String().substring(0, 10);

  Future<String> _carry(double amount) {
    final here = widget.project.id;
    final out = _type == MoveType.carryOut;
    return widget.capital.carry(out ? here : _targetProjectId, {
      'partnerId': out ? _partnerId : _targetPartnerId,
      'accountId': out ? _accountId : _targetAccountId,
      'targetProjectId': out ? _targetProjectId : here,
      'targetPartnerId': out ? _targetPartnerId : _partnerId,
      'targetAccountId': out ? _targetAccountId : _accountId,
      'date': _isoOf(_date),
      'amount': amount,
      'description': _description.text,
    });
  }

  Future<String> _send() async {
    final amount = parseNumber(_amount.text);
    if (amount.isNaN) {
      return 'capital.invalidAmount';
    }
    if (_partnerId.isEmpty) {
      return 'capital.unknownPartner';
    }
    if (_accountId.isEmpty) {
      return 'capital.unknownAccount';
    }
    if (_type.isCarry) {
      return _targetProjectId.isEmpty || _targetPartnerId.isEmpty || _targetAccountId.isEmpty ? 'capital.sameProject' : _carry(amount);
    }
    final usesReceipt = !_isCash && !_type.asksReasonOnly;
    if (usesReceipt && !_file.isNone && _attachmentId.isEmpty) {
      final refusal = await widget.attachments.keep(_file);
      if (refusal.isNotEmpty) {
        return refusal;
      }
      _attachmentId = widget.attachments.kept.id;
    }
    return widget.capital.record({
      'partnerId': _partnerId,
      'type': _type.name,
      'date': _isoOf(_date),
      'amount': amount,
      'accountId': _accountId,
      'description': _description.text,
      if (usesReceipt && _attachmentId.isNotEmpty) 'attachmentId': _attachmentId,
      if (!usesReceipt) 'cashReason': _reason.text,
    });
  }

  Future<void> _save() async {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    final refusal = await _send();
    if (!mounted) {
      return;
    }
    if (refusal.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(words.capitalSaved)));
      await Future.wait([widget.accounts.load(), widget.partners.load()]);
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

  bool get _receiptDiffers {
    final onReceipt = parseNumber(_receiptAmount.text);
    return !onReceipt.isNaN && onReceipt != parseNumber(_amount.text);
  }

  List<Widget> _carrySection(Words words) {
    final others = _otherProjects;
    if (others.isEmpty) {
      return [Text(words.capitalNoTargetProject, key: CapitalMoveScreen.noTargetKey)];
    }
    return [
      LabelledChips<Project>(
        label: words.capitalTargetProject,
        choices: others,
        keyOf: (project) => CapitalMoveScreen.targetProjectKey(project.id),
        nameOf: (project) => project.name,
        isChosen: (project) => project.id == _targetProjectId,
        onChosen: _chooseTarget,
      ),
      if (_targetProjectId.isNotEmpty)
        ListenableBuilder(
          listenable: Listenable.merge([widget.partnersOf(_targetProjectId), widget.accountsOf(_targetProjectId)]),
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              LabelledChips<Partner>(
                label: words.capitalTargetPartner,
                choices: widget.partnersOf(_targetProjectId).all,
                keyOf: (partner) => CapitalMoveScreen.targetPartnerKey(partner.id),
                nameOf: (partner) => partner.name,
                isChosen: (partner) => partner.id == _targetPartnerId,
                onChosen: (partner) => setState(() => _targetPartnerId = partner.id),
              ),
              LabelledChips<Account>(
                label: words.capitalTargetAccount,
                choices: _realAccounts(widget.accountsOf(_targetProjectId)),
                keyOf: (account) => CapitalMoveScreen.targetAccountKey(account.id),
                nameOf: (account) => account.name,
                isChosen: (account) => account.id == _targetAccountId,
                onChosen: (account) => setState(() => _targetAccountId = account.id),
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _receiptSection(Words words) {
    final theme = Theme.of(context);
    return [
      if (!_type.asksReasonOnly) ...[
        SwitchListTile(key: CapitalMoveScreen.cashKey, contentPadding: EdgeInsets.zero, title: Text(words.capitalPaidInCash), value: _isCash, onChanged: (isCash) => setState(() => _isCash = isCash)),
        if (!_isCash) ...[
          Text('${words.capitalReceipt} · ${words.capitalReceiptRequiredWord}', style: theme.textTheme.titleSmall),
          InvoiceSection(file: _file, emptyLabel: words.capitalReceiptHint, message: _fileMessage, onCamera: () => _takeFrom(widget.capture.fromCamera), onFiles: () => _takeFrom(widget.capture.fromFiles)),
          entryField(key: CapitalMoveScreen.receiptAmountKey, controller: _receiptAmount, label: words.capitalReceiptAmount, isNumber: true, onChanged: (_) => setState(() {})),
          if (_receiptDiffers) Text(words.capitalReceiptDiffers, key: CapitalMoveScreen.receiptDiffersKey, style: TextStyle(color: theme.colorScheme.error)),
        ],
      ],
      if (_isCash || _type.asksReasonOnly) entryField(key: CapitalMoveScreen.reasonKey, controller: _reason, label: words.capitalCashReason, onChanged: (_) {}),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.capitalMoveTitle, subject: widget.project.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ListenableBuilder(
          listenable: Listenable.merge([widget.partners, widget.accounts, widget.projects]),
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              LabelledChips<Partner>(
                label: words.capitalPartner,
                choices: widget.partners.all,
                keyOf: (partner) => CapitalMoveScreen.partnerKey(partner.id),
                nameOf: (partner) => partner.name,
                isChosen: (partner) => partner.id == _partnerId,
                onChosen: _choosePartner,
              ),
              LabelledChips<MoveType>(
                label: words.capitalType,
                choices: MoveType.values,
                keyOf: CapitalMoveScreen.typeKey,
                nameOf: (type) => words.text('capital.${type.name}'),
                isChosen: (type) => type == _type,
                onChosen: _chooseType,
              ),
              entryField(key: CapitalMoveScreen.amountKey, controller: _amount, label: words.capitalAmount, isNumber: true, onChanged: (_) => setState(() {})),
              PickerField(key: CapitalMoveScreen.dateKey, label: words.capitalDate, value: formatDate(_date), onTap: _chooseDate),
              LabelledChips<Account>(
                label: words.capitalAccount,
                choices: _realAccounts(widget.accounts),
                keyOf: (account) => CapitalMoveScreen.accountKey(account.id),
                nameOf: (account) => account.name,
                isChosen: (account) => account.id == _accountId,
                onChosen: (account) => setState(() => _accountId = account.id),
              ),
              entryField(key: CapitalMoveScreen.descriptionKey, controller: _description, label: words.capitalDescription, onChanged: (_) {}),
              if (_type.isCarry) ..._carrySection(words) else ..._receiptSection(words),
              if (_message.isNotEmpty) Text(words.text(_message), key: CapitalMoveScreen.messageKey, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              FilledButton(key: CapitalMoveScreen.saveKey, onPressed: _saving ? null : _save, child: Text(words.capitalSave)),
            ],
          ),
        ),
      ),
    );
  }
}
