import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/part_keys.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'reconcile_screen.dart';
import 'reconciliation.dart';
import 'reconciliation_card.dart';

/// الأرصدة الفعلية, on its own from the home (Muteb, 9 Nov 2026): the project's accounts against its books, as last entered, and the way to enter them again, تحديث, for
/// whoever moves money (FR-24).
class ActualBalancesScreen extends StatefulWidget {
  /// The [reconciliations] of [project].
  const ActualBalancesScreen({super.key, required this.project, required this.reconciliations});

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

  @override
  State<ActualBalancesScreen> createState() => _ActualBalancesScreenState();
}

class _ActualBalancesScreenState extends State<ActualBalancesScreen> {
  @override
  void initState() {
    super.initState();
    widget.reconciliations.loadOnOpen();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final project = widget.project;
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.reconciliationsEnterTitle, subject: project.name)),
      body: RefreshIndicator(
        onRefresh: widget.reconciliations.load,
        child: ListView(
          padding: ApiListBody.padding,
          physics: ApiListBody.physics,
          children: [
            ReconciliationCard(reconciliations: widget.reconciliations),
            if (project.mayMoveMoney)
              FilledButton(
                key: ActualBalancesScreen.updateKey,
                onPressed: () => context.push(ReconcileScreen.pathOf(project.id), extra: project),
                child: Text(words.accountsReconcile, key: ActualBalancesScreen.updateKey.label),
              ),
          ],
        ),
      ),
    );
  }
}
