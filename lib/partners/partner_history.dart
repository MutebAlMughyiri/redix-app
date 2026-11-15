import 'package:flutter/material.dart';

import '../auth/session.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../format/parts_line.dart';
import '../history/history_list.dart';
import '../words/word_fill.dart';
import '../words/words.dart';

/// What a line of the partner history says was done, each knowing its word, its icon and what fills the word (redix-app #101).
enum PartnerHistoryKind {
  /// A partner was added.
  partnerCreated('history.partnerCreated', Icons.add, _partner),

  /// A partner's name changed.
  partnerChanged('history.partnerChanged', Icons.edit_outlined, _change),

  /// A partner was given an account, another one, or none.
  partnerAccount('history.partnerAccount', Icons.person_outline, _account),

  /// A partner was deleted, softly.
  partnerDeleted('history.partnerDeleted', Icons.delete_outline, _partner),

  /// Capital came in from a partner, approved.
  capitalIn('history.capitalIn', Icons.done_all, _movement),

  /// Capital went out to a partner, approved.
  capitalOut('history.capitalOut', Icons.done_all, _movement);

  const PartnerHistoryKind(this.wordKey, this.icon, this._values);

  /// The key of the word that says it.
  final String wordKey;

  /// What shows beside it.
  final IconData icon;

  final List<String> Function(PartnerHistoryLine line, Words words) _values;

  /// True for an approved movement's line, which says who approved it.
  bool get isApproval => this == capitalIn || this == capitalOut;

  static List<String> _partner(PartnerHistoryLine line, Words words) => [line.partner];

  static List<String> _change(PartnerHistoryLine line, Words words) => [line.partner, line.nameWas.isEmpty ? '' : words.historyNameWas.fill([line.nameWas])];

  static List<String> _account(PartnerHistoryLine line, Words words) => [line.partner, line.login.isEmpty ? words.partnersNoLogin : line.login];

  static List<String> _movement(PartnerHistoryLine line, Words words) => [formatMoney(line.amount), line.partner, line.account];
}

/// One line of the partner history, as the API answers it.
class PartnerHistoryLine implements HistoryLine {
  /// The line the API describes in [json].
  PartnerHistoryLine.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      at = momentOf(json['at'] as String),
      by = json['by'] as String,
      kind = PartnerHistoryKind.values.byName(json['kind'] as String),
      partner = json['partner'] as String,
      account = json['account'] as String,
      amount = (json['amount'] as num).toDouble(),
      nameWas = json['nameWas'] as String,
      login = json['login'] as String;

  /// Its History row, which the next page starts after.
  @override
  final int id;

  /// When it was done, in the phone's time.
  final DateTime at;

  /// Who did it.
  final String by;

  /// What was done.
  final PartnerHistoryKind kind;

  /// The partner it names, by their name now.
  final String partner;

  /// A movement's account; empty otherwise.
  final String account;

  /// How much moved; zero for a partner's own action.
  final double amount;

  /// A partner's name before it changed; empty otherwise.
  final String nameWas;

  /// The account a partner was given; empty for none.
  final String login;

  @override
  IconData get icon => kind.icon;

  /// What it says, in [words].
  @override
  String textIn(Words words) => words.text(kind.wordKey).fill(kind._values(this, words));

  /// Who did it and when, in [words]: an approval says who approved it.
  @override
  String whoAndWhenIn(Words words) => partsLine([kind.isApproval ? words.historyApprovedBy.fill([by]) : by, '${formatDate(at)} ${formatTime(at)}']);
}

/// A project's partner history, newest first, a page at a time (redix-app #101): every partner the user sees, or one, and everyone's lines, or the signed-in user's own.
class PartnerHistory extends HistoryList<PartnerHistoryLine> {
  /// The history of the partners of the project [projectId], seen through [session].
  PartnerHistory(Session session, String projectId) : super(session, '/projects/$projectId/partners/history', 'partner', PartnerHistoryLine.fromJson);
}
