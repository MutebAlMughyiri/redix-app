// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../auth/session.dart';
import '../format/date_format.dart';
import '../format/parts_line.dart';
import '../words/words.dart';
import 'history_list.dart';

/// What a line of «سجلي» says happened to one's login, each knowing its word and its icon (redix-api #86, R9).
enum LoginHistoryKind {
  /// Signed in.
  signIn(Icons.login),

  /// Signed out.
  signOut(Icons.logout),

  /// A wrong password was typed.
  signInFailed(Icons.error_outline),

  /// Too many wrong passwords locked the login.
  locked(Icons.lock_clock_outlined),

  /// The password was changed.
  passwordChanged(Icons.password),

  /// The password was reset, by a manager or by a code.
  passwordReset(Icons.lock_reset),

  /// Fingerprint or face sign-in was turned on.
  biometricsOn(Icons.fingerprint),

  /// Fingerprint or face sign-in was turned off.
  biometricsOff(Icons.fingerprint),

  /// The login was made.
  created(Icons.person_add_alt_outlined),

  /// The name, username, mobile or email changed.
  changed(Icons.manage_accounts_outlined);

  const LoginHistoryKind(this.icon);

  /// What shows beside its line.
  final IconData icon;

  /// The key of the word saying it.
  String get wordKey => 'history.login.$name';
}

/// One line of «سجلي», as the API answers it.
class MyHistoryLine implements HistoryLine {
  /// The line the API describes in [json].
  MyHistoryLine.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      at = momentOf(json['at'] as String),
      by = json['by'] as String,
      kind = LoginHistoryKind.values.byName(json['kind'] as String),
      about = json['about'] as String;

  /// Its History row, which the next page starts after.
  @override
  final int id;

  /// When it happened, in the phone's time.
  final DateTime at;

  /// Who did it: the person, or a manager.
  final String by;

  /// What happened.
  final LoginHistoryKind kind;

  /// The name, username, mobile and email a change gave; empty for none.
  final String about;

  @override
  IconData get icon => kind.icon;

  /// What it says, in [words].
  @override
  String textIn(Words words) => partsLine([words.text(kind.wordKey), about]);

  /// Who did it and when, in [words].
  @override
  String whoAndWhenIn(Words words) => partsLine([by, '${formatDate(at)} ${formatTime(at)}']);
}

/// «سجلي»: every line of the signed-in user's own login, newest first, a page at a time (redix-api #86, R9).
class MyHistory extends HistoryList<MyHistoryLine> {
  /// The history of the login signed in through [session].
  MyHistory(Session session) : super(session, '/me/history', 'area', MyHistoryLine.fromJson);
}
