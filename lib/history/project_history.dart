// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:flutter/material.dart';

import '../auth/session.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../format/parts_line.dart';
import '../words/word_fill.dart';
import '../words/words.dart';
import 'history_list.dart';

/// What a line of «سجل المشروع» or «سجلي» is filtered under, each knowing its word (redix-api #86).
enum HistoryArea {
  /// The entries, their details, invoices and files.
  entries,

  /// The accounts, custodies, transfers, balance checks and payment methods.
  accounts,

  /// The partners and their logins.
  partners,

  /// The suppliers and the contracts.
  suppliers,

  /// The categories, items, subgroups and columns.
  structure,

  /// The project itself: its name, units, time zone, documents and periodic reports.
  project,

  /// The people: their permissions, role names, partners in sight, and who is inactive.
  people,

  /// One's sign-ins and sign-outs, wrong passwords and lockouts.
  signIn,

  /// One's password changes and resets.
  password,

  /// One's fingerprint or face sign-in.
  biometrics,

  /// One's login and its details.
  details;

  /// The kinds of a project's history, as its kind chip offers them.
  static const inAProject = [entries, accounts, partners, suppliers, structure, project, people];

  /// The kinds of one's own history, as its kind chip offers them.
  static const ofALogin = [signIn, password, biometrics, details];

  /// The key of the word naming it.
  String get wordKey => 'history.area.$name';
}

/// What a line of «سجل المشروع» says was done, each knowing its word and its icon (redix-api #86, D5).
enum HistoryAction {
  /// A record was added.
  created(Icons.add_circle_outline),

  /// A record was changed.
  changed(Icons.edit_outlined),

  /// A record was deleted.
  deleted(Icons.delete_outline),

  /// A record was disabled.
  disabled(Icons.block),

  /// A record was enabled again.
  enabled(Icons.check_circle_outline),

  /// An entry was saved as a draft.
  drafted(Icons.edit_note),

  /// An entry was sent for approval.
  sent(Icons.send_outlined),

  /// An entry or a project was approved.
  approved(Icons.done_all),

  /// An entry or a project was rejected.
  rejected(Icons.close),

  /// A removed entry was brought back.
  restored(Icons.restore),

  /// A project was registered.
  registered(Icons.app_registration),

  /// A project was closed.
  closed(Icons.lock_outline),

  /// A file was attached.
  attached(Icons.attach_file),

  /// A permission or a partner's sight was given.
  given(Icons.key_outlined),

  /// A permission or a partner's sight was taken away.
  taken(Icons.key_off_outlined),

  /// A periodic report was issued.
  issued(Icons.summarize_outlined);

  const HistoryAction(this.icon);

  /// What shows beside its line.
  final IconData icon;

  /// The key of the word saying it.
  String get wordKey => 'history.action.$name';
}

/// What a line of «سجل المشروع» says it was done to, each knowing its word (redix-api #86, D5).
enum HistoryThing {
  /// An entry.
  entry,

  /// An entry's invoice number.
  invoice,

  /// A file attached to an entry.
  file,

  /// An account.
  account,

  /// Who holds an account in custody.
  custody,

  /// Money moved between two accounts.
  transfer,

  /// The accounts' actual balances, checked.
  reconciliation,

  /// A payment method.
  paymentMethod,

  /// A partner.
  partner,

  /// A partner's login in the app.
  partnerLogin,

  /// A supplier.
  supplier,

  /// A contract.
  contract,

  /// A document kept with a contract.
  contractDocument,

  /// A category.
  category,

  /// An item.
  item,

  /// A subgroup of an item.
  subgroup,

  /// A column of an item.
  column,

  /// A column every item of a type takes.
  defaultColumn,

  /// The project.
  project,

  /// A unit.
  unit,

  /// The project's time zone.
  timeZone,

  /// A document of the project.
  document,

  /// A periodic report.
  periodicReport,

  /// A permission of a person.
  permission,

  /// A person in the project.
  person,

  /// A person's role name.
  roleName,

  /// A partner a person sees.
  partnerSight;

  /// The key of the word naming it.
  String get wordKey => 'history.thing.$name';

  /// The record's [name] in [words]: a permission's is its word, every other's the name it has.
  String nameIn(Words words, String name) => this == permission ? words.text('permissions.$name') : name;
}

/// One line of «سجل المشروع», as the API answers it.
class ProjectHistoryLine implements HistoryLine {
  /// The line the API describes in [json].
  ProjectHistoryLine.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      at = momentOf(json['at'] as String),
      by = json['by'] as String,
      action = HistoryAction.values.byName(json['action'] as String),
      thing = HistoryThing.values.byName(json['thing'] as String),
      name = json['name'] as String,
      about = json['about'] as String,
      nameWas = json['nameWas'] as String,
      from = json['from'] as String,
      to = json['to'] as String,
      amount = (json['amount'] as num).toDouble();

  /// Its History row, which the next page starts after.
  @override
  final int id;

  /// When it was done, in the phone's time.
  final DateTime at;

  /// Who did it.
  final String by;

  /// What was done.
  final HistoryAction action;

  /// What it was done to.
  final HistoryThing thing;

  /// The record's name; empty for one that has none, such as a transfer.
  final String name;

  /// What else the line names: an entry's description, a rejection's reason, the person a permission was given to; empty for nothing.
  final String about;

  /// The name before a rename; empty for none.
  final String nameWas;

  /// The account money left; empty for none.
  final String from;

  /// The account money reached; empty for none.
  final String to;

  /// The amount it moved or holds; 0 for none.
  final double amount;

  @override
  IconData get icon => action.icon;

  /// What it says, in [words]: what was done to what, and what else it names.
  @override
  String textIn(Words words) => partsLine([
    [words.text(action.wordKey), words.text(thing.wordKey), thing.nameIn(words, name)].where((part) => part.isNotEmpty).join(' '),
    about,
    if (nameWas.isNotEmpty) words.historyNameWas.fill([nameWas]),
    if (from.isNotEmpty) words.historyFromTo.fill([from, to]),
    if (amount != 0) formatMoney(amount),
  ]);

  /// Who did it and when, in [words].
  @override
  String whoAndWhenIn(Words words) => partsLine([by, '${formatDate(at)} ${formatTime(at)}']);
}

/// «سجل المشروع» of one project, newest first, a page at a time (redix-api #86): every kind or one, everyone's lines or one person's.
class ProjectHistory extends HistoryList<ProjectHistoryLine> {
  /// The history of the project [projectId], read through [session].
  ProjectHistory(Session session, String projectId) : super(session, '/projects/$projectId/history', 'area', ProjectHistoryLine.fromJson);
}
