import 'package:flutter/material.dart';

import '../auth/session.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../format/parts_line.dart';
import '../history/history_list.dart';
import '../words/word_fill.dart';
import '../words/words.dart';

/// What a line of the approval history says was decided, each knowing its word and its icon (Muteb, 12 Nov 2026).
enum ApprovalHistoryKind {
  /// An entry was approved.
  approved('history.entryApproved', Icons.done_all),

  /// An entry was rejected, with a reason.
  rejected('history.entryRejected', Icons.close);

  const ApprovalHistoryKind(this.wordKey, this.icon);

  /// The key of the word that says it.
  final String wordKey;

  /// What shows beside it.
  final IconData icon;
}

/// One line of the approval history, as the API answers it.
class ApprovalHistoryLine implements HistoryLine {
  /// The line the API describes in [json].
  ApprovalHistoryLine.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      at = momentOf(json['at'] as String),
      by = json['by'] as String,
      kind = ApprovalHistoryKind.values.byName(json['kind'] as String),
      item = json['item'] as String,
      party = json['party'] as String,
      amount = (json['amount'] as num).toDouble(),
      reason = json['reason'] as String;

  /// Its History row, which the next page starts after.
  @override
  final int id;

  /// When it was decided, in the phone's time.
  final DateTime at;

  /// Who decided it.
  final String by;

  /// What was decided.
  final ApprovalHistoryKind kind;

  /// The entry's item, or for a partner's money the partner.
  final String item;

  /// The entry's supplier or contractor; empty for none.
  final String party;

  /// The entry's amount.
  final double amount;

  /// A rejection's reason; empty for an approval.
  final String reason;

  @override
  IconData get icon => kind.icon;

  /// What it says, in [words]: what was decided on which entry, and a rejection's reason.
  @override
  String textIn(Words words) => words.text(kind.wordKey).fill([partsLine([item, party, formatMoney(amount)]), reason]);

  /// Who decided it and when, in [words]: an approval says who approved it.
  @override
  String whoAndWhenIn(Words words) => partsLine([kind == ApprovalHistoryKind.approved ? words.historyApprovedBy.fill([by]) : by, '${formatDate(at)} ${formatTime(at)}']);
}

/// A project's approval history, newest first, a page at a time (Muteb, 12 Nov 2026): every decision or those on one kind of entry, everyone's or the signed-in user's own.
class ApprovalHistory extends HistoryList<ApprovalHistoryLine> {
  /// The approval history of the project [projectId], read through [session].
  ApprovalHistory(Session session, String projectId) : super(session, '/projects/$projectId/approvals/history', 'kind', ApprovalHistoryLine.fromJson);
}
