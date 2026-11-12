import 'package:flutter/material.dart';

import '../auth/session.dart';
import '../entries/entry_kind.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../format/parts_line.dart';
import '../history/history_list.dart';
import '../words/word_fill.dart';
import '../words/words.dart';

/// What a line of the account history says was done, each knowing its word, its icon and what fills the word (redix-app #89).
enum AccountHistoryKind {
  /// An account was added.
  accountCreated('history.accountCreated', Icons.add, _account),

  /// An account's name changed.
  accountChanged('history.accountChanged', Icons.edit_outlined, _change),

  /// An account was disabled.
  accountDisabled('history.accountDisabled', Icons.block, _account),

  /// A disabled account was enabled.
  accountEnabled('history.accountEnabled', Icons.check_circle_outline, _account),

  /// An account nothing named was deleted.
  accountDeleted('history.accountDeleted', Icons.delete_outline, _account),

  /// Someone else now holds an account, or nobody does.
  custodianChanged('history.custodianChanged', Icons.person_outline, _custodian),

  /// Money moved between two accounts.
  transfer('history.transfer', Icons.sync_alt, _transfer),

  /// An approved entry brought money into an account.
  entryIn('history.entryIn', Icons.done_all, _entry),

  /// An approved entry took money out of an account.
  entryOut('history.entryOut', Icons.done_all, _entry),

  /// The actual balances were counted.
  check('history.check', Icons.balance_outlined, _check);

  const AccountHistoryKind(this.wordKey, this.icon, this._values);

  /// The key of the word that says it.
  final String wordKey;

  /// What shows beside it.
  final IconData icon;

  final List<String> Function(AccountHistoryLine line, Words words) _values;

  /// True for an approved entry's line, which says who approved it.
  bool get isApproval => this == entryIn || this == entryOut;

  static List<String> _account(AccountHistoryLine line, Words words) => [line.account];

  static List<String> _change(AccountHistoryLine line, Words words) => [line.account, line.nameWas.isEmpty ? '' : words.historyNameWas.fill([line.nameWas])];

  static List<String> _custodian(AccountHistoryLine line, Words words) => [line.account, line.custodian.isEmpty ? words.accountsNoCustodian : line.custodian];

  static List<String> _transfer(AccountHistoryLine line, Words words) => [formatMoney(line.amount), line.account, line.otherAccount];

  static List<String> _entry(AccountHistoryLine line, Words words) => [words.text(line.entryKind.wordKey), formatMoney(line.amount), line.account];

  static List<String> _check(AccountHistoryLine line, Words words) => [formatMoney(line.amount)];
}

/// One line of the account history, as the API answers it.
class AccountHistoryLine implements HistoryLine {
  /// The line the API describes in [json].
  AccountHistoryLine.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      at = DateTime.parse(json['at'] as String).toLocal(),
      by = json['by'] as String,
      kind = AccountHistoryKind.values.byName(json['kind'] as String),
      account = json['account'] as String,
      otherAccount = json['otherAccount'] as String,
      amount = (json['amount'] as num).toDouble(),
      entryKind = EntryKind.values.byName(json['entryKind'] as String),
      nameWas = json['nameWas'] as String,
      custodian = json['custodian'] as String;

  /// Its History row, which the next page starts after.
  @override
  final int id;

  /// When it was done, in the phone's time.
  final DateTime at;

  /// Who did it.
  final String by;

  /// What was done.
  final AccountHistoryKind kind;

  /// The account it names.
  final String account;

  /// A transfer's second account; empty otherwise.
  final String otherAccount;

  /// How much moved, or a check's counted total.
  final double amount;

  /// An entry's kind, for an entry's line.
  final EntryKind entryKind;

  /// An account's name before it changed; empty otherwise.
  final String nameWas;

  /// Who holds an account now, for a custodian's change; empty when nobody does.
  final String custodian;

  @override
  IconData get icon => kind.icon;

  /// What it says, in [words].
  @override
  String textIn(Words words) => words.text(kind.wordKey).fill(kind._values(this, words));

  /// Who did it and when, in [words]: an approval says who approved it.
  @override
  String whoAndWhenIn(Words words) => partsLine([kind.isApproval ? words.historyApprovedBy.fill([by]) : by, '${formatDate(at)} ${formatTime(at)}']);
}

/// A project's account history, newest first, a page at a time (redix-app #89, R22): every account, or one, and everyone's lines, or the signed-in user's own.
class AccountHistory extends HistoryList<AccountHistoryLine> {
  /// The history of the accounts of the project [projectId], seen through [session].
  AccountHistory(Session session, String projectId) : super(session, '/projects/$projectId/accounts/history', 'account', AccountHistoryLine.fromJson);
}
