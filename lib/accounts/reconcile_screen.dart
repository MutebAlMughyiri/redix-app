import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../format/number_format.dart';
import '../projects/project.dart';
import '../ui/entry_field.dart';
import '../ui/part_keys.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'reconciliation.dart';
import '../ui/refusal_text.dart';
import '../ui/act_once.dart';
import '../ui/section.dart';

/// What each account and custody really holds (UC-041), with the total and the difference as they are typed.
class ReconcileScreen extends StatefulWidget {
  /// The screen entering through [reconciliations] in [project].
  const ReconcileScreen({super.key, required this.project, required this.reconciliations});

  /// The address of the screen.
  static const path = '/projects/:projectId/reconcile';

  /// The address of the screen for the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/reconcile';

  /// The total as typed.
  static const totalKey = Key('reconcile.total');

  /// The section holding each account's actual balance, their total and the difference (redix-app #96).
  static const balancesKey = Key('reconcile.balances');

  /// The difference as typed.
  static const differenceKey = Key('reconcile.difference');

  /// The button saving it.
  static const saveKey = Key('reconcile.save');

  /// The line saying why it was refused.
  static const messageKey = Key('reconcile.message');

  /// The field of the account [id].
  static Key balanceKey(String id) => Key('reconcile.balance.$id');

  /// The books' balance of the account [id].
  static Key booksKey(String id) => Key('reconcile.books.$id');

  /// The project.
  final Project project;

  /// The way to enter it.
  final Reconciliations reconciliations;

  @override
  State<ReconcileScreen> createState() => _ReconcileScreenState();
}

class _ReconcileScreenState extends State<ReconcileScreen> {
  late final _fields = {
    for (final row in widget.reconciliations.value.balances) row.accountId: TextEditingController(text: row.wasChecked ? formatPlain(row.actualBalance) : ''),
  };
  var _message = '';

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  double get _total => _fields.values.map((field) => parseNumber(field.text)).where((number) => !number.isNaN).fold(0, (sum, number) => sum + number);

  Future<void> _save() async {
    final balances = _fields.map((accountId, field) => MapEntry(accountId, parseNumber(field.text)));
    if (balances.values.any((balance) => balance.isNaN)) {
      setState(() => _message = 'reconciliations.accountMissing');
      return;
    }
    final refusal = await widget.reconciliations.enter(balances);
    if (!mounted) {
      return;
    }
    if (refusal.isEmpty) {
      context.pop();
      return;
    }
    setState(() => _message = refusal);
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final theme = Theme.of(context);
    final figures = widget.reconciliations.value;
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.reconciliationsEnterTitle, subject: widget.project.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Section(key: ReconcileScreen.balancesKey, [
              for (final row in figures.balances)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    entryField(key: ReconcileScreen.balanceKey(row.accountId), controller: _fields[row.accountId]!, label: row.accountName, isNumber: true, isSigned: true, onChanged: (_) => setState(() {})),
                    Text('${words.reconciliationsBooks}: ${formatMoney(row.booksBalance)}', key: ReconcileScreen.booksKey(row.accountId), style: theme.textTheme.bodySmall),
                  ],
                ),
              Text('${words.reconciliationsActualTotal}: ${formatMoney(_total)}', key: ReconcileScreen.totalKey),
              Text('${words.reconciliationsDifference}: ${formatMoney(_total - figures.surplus)}', key: ReconcileScreen.differenceKey, style: theme.textTheme.titleMedium),
            ]),
            if (_message.isNotEmpty) refusalText(context, words.text(_message), ReconcileScreen.messageKey),
            ActOnce(builder: (once) => FilledButton(key: ReconcileScreen.saveKey, onPressed: once(_save), child: Text(words.reconciliationsSave, key: ReconcileScreen.saveKey.label))),
          ],
        ),
      ),
    );
  }
}
