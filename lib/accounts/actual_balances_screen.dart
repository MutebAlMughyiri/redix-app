import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../format/number_format.dart';
import '../projects/members.dart';
import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/part_keys.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'account_row.dart';
import 'accounts.dart';
import 'reconcile_screen.dart';
import 'reconciliation.dart';
import 'reconciliation_card.dart';

/// الأرصدة الفعلية, on its own from the home (Muteb, 9 Nov 2026): the project's accounts against its books, as last entered, and the way to enter them again, تحديث, for
/// whoever moves money (FR-24). Under them, each account as Accounts draws it, without its menu, with what it really held at the latest check, or a dash before the first.
class ActualBalancesScreen extends StatefulWidget {
  /// The [reconciliations] of [project], and its [accounts], drawn with [members].
  const ActualBalancesScreen({super.key, required this.project, required this.reconciliations, required this.accounts, required this.members});

  /// The screen's route.
  static const path = '/projects/:projectId/actual-balances';

  /// The route of the actual balances of the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/actual-balances';

  /// The button entering the actual balances again.
  static const updateKey = Key('actualBalances.update');

  /// The project.
  final Project project;

  /// Its accounts against its books.
  final Reconciliations reconciliations;

  /// Its accounts, each with what it really held.
  final Accounts accounts;

  /// The people who can hold an account, which its row is drawn with.
  final Members members;

  @override
  State<ActualBalancesScreen> createState() => _ActualBalancesScreenState();
}

class _ActualBalancesScreenState extends State<ActualBalancesScreen> {
  @override
  void initState() {
    super.initState();
    widget.reconciliations.loadOnOpen();
    widget.accounts.loadOnOpen();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final project = widget.project;
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.reconciliationsEnterTitle, subject: project.name)),
      body: ListenableBuilder(
        listenable: widget.reconciliations,
        builder: (context, _) {
          final figures = widget.reconciliations.value;
          final actual = {if (figures.wasChecked) for (final row in figures.balances) row.accountId: formatMoney(row.actualBalance)};
          return ApiListBody(
            list: widget.accounts,
            emptyText: words.accountsEmpty,
            alsoRefresh: widget.reconciliations.load,
            itemBuilder: (account) => AccountRow(account: account, amount: actual[account.id] ?? '—', accounts: widget.accounts, members: widget.members, mayChange: false),
            listOf: (items) => ListView(
              padding: ApiListBody.padding,
              physics: ApiListBody.physics,
              children: [
                ReconciliationCard(reconciliations: widget.reconciliations),
                if (project.mayMoveMoney)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FilledButton(
                      key: ActualBalancesScreen.updateKey,
                      onPressed: () => context.push(ReconcileScreen.pathOf(project.id), extra: project),
                      child: Text(words.accountsReconcile, key: ActualBalancesScreen.updateKey.label),
                    ),
                  ),
                ...items,
              ],
            ),
          );
        },
      ),
    );
  }
}
