// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../history/history_view.dart';
import '../projects/members.dart';
import '../projects/project.dart';
import '../ui/screen_title.dart';
import '../ui/search_scope.dart';
import '../words/words.dart';
import 'approval_history.dart';

/// السجل, from the title bar of بانتظار الاعتماد (the owner, 12 Nov 2026): what was approved and rejected, by whom and when, newest first, a page at a time; every kind of entry or
/// one, as Approvals' filter offers them, and everyone's decisions or one person's. Every history looks the same (redix-app #101).
class ApprovalHistoryScreen extends StatefulWidget {
  /// The approval [history] of [project], filtered by its [members].
  const ApprovalHistoryScreen({super.key, required this.project, required this.history, required this.members});

  /// The project.
  final Project project;

  /// Its approval history.
  final ApprovalHistory history;

  /// Its people, one filter each.
  final Members members;

  /// The screen's route.
  static const path = '/projects/:projectId/approvals/history';

  /// The route of the approval history of the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/approvals/history';

  /// The chip opening the list of kinds, under the search line.
  static const kindChoiceKey = Key('approvalHistory.kindChoice');

  /// Every kind, in that list.
  static const allKey = Key('approvalHistory.all');

  /// The kind [id] alone, in that list.
  static Key kindKey(String id) => Key('approvalHistory.kind.$id');

  /// The chip opening the list of people, under the search line.
  static const personChoiceKey = Key('approvalHistory.personChoice');

  /// The person [id] alone in that list; everyone for empty.
  static Key personKey(String id) => Key('approvalHistory.person.$id');

  /// The line [id].
  static Key lineKey(int id) => Key('approvalHistory.line.$id');

  /// The button reading the next page.
  static const moreKey = Key('approvalHistory.more');

  @override
  State<ApprovalHistoryScreen> createState() => _ApprovalHistoryScreenState();
}

class _ApprovalHistoryScreenState extends State<ApprovalHistoryScreen> {
  @override
  void initState() {
    super.initState();
    widget.history.open();
    widget.members.loadOnOpen();
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final history = widget.history;
    return SearchScope(
      onTyped: history.search,
      child: Scaffold(
        appBar: AppBar(
          title: ScreenTitle(words.approvalsHistory, subject: widget.project.name),
          actions: [ListenableBuilder(listenable: history, builder: (context, _) => SearchIcons.andFilters(filtersInUse: history.isFiltered))],
        ),
        body: ListenableBuilder(
          listenable: Listenable.merge([history, widget.members]),
          builder: (context, _) => HistoryView(
            history: history,
            title: words.approvalsHistory,
            choiceLabel: words.entriesKind,
            choices: [('purchase', words.approvalsPurchases), ('contractorPayment', words.approvalsContractorPayments)],
            people: [for (final member in widget.members.all) (member.id, member.displayName)],
            choiceChipKey: ApprovalHistoryScreen.kindChoiceKey,
            allKey: ApprovalHistoryScreen.allKey,
            choiceKey: ApprovalHistoryScreen.kindKey,
            personChipKey: ApprovalHistoryScreen.personChoiceKey,
            personKey: ApprovalHistoryScreen.personKey,
            lineKey: ApprovalHistoryScreen.lineKey,
            moreKey: ApprovalHistoryScreen.moreKey,
          ),
        ),
      ),
    );
  }
}
