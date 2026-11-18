// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

/// What the API says a user may do, named as the API names it. The app shows a control from these, and a project manager ticks them for each person in a project.
enum Permission {
  /// See the registered projects, and approve or reject them: the admin's, never ticked in a project.
  approveProjects,

  /// See a project and everything in it: being in the project.
  readProject,

  /// Add people to a project and tick their permissions.
  manageUsers,

  /// See every partner in a project and their capital; holding it takes [seeChosenCapital].
  seeAllCapital,

  /// See only the partners chosen for one in a project, and their capital (redix-api #106); holding it takes [seeAllCapital].
  seeChosenCapital,

  /// Rename a project, add and delete its units, keep its documents and close it.
  manageProject,

  /// Shape a project's expense structure: its categories, items, subgroups and columns.
  manageStructure,

  /// Keep a project's payment methods, accounts, partners, suppliers and contracts.
  manageSettings,

  /// Add a supplier to a project's register; without [manageSettings] it waits for approval.
  addSupplier,

  /// Spend from any account of a project; without it, only from the accounts in one's custody.
  chargeAnyAccount,

  /// Record a purchase or a contractor payment in a project's ledger.
  recordEntries,

  /// Change or send an entry someone else sent, or one waiting, before it is approved; never someone else's draft (BR-42).
  manageAnyEntry,

  /// Delete an entry not yet approved: one's own, or with [manageAnyEntry] anyone's once sent.
  deleteEntries,

  /// Remove an approved entry softly (redix-api #119): it leaves every list and figure, and its history stays. Nobody holds it until it is ticked.
  removeApprovedEntries,

  /// Keep a picture or a file in a project, for an entry, a receipt or a contract.
  attachFiles,

  /// See the entries waiting in a project, and approve or reject them.
  approveEntries,

  /// Enter what counts at once in a project: capital movements, revenue and reconciling.
  moveMoney,

  /// «يرى التقارير»: open a project's reports, the periodic report, an item's, a contract's and the VAT statement (redix-api #131).
  seeReports,

  /// «يُصدر التقارير»: issue a project's periodic report and take every report's Excel and PDF, whose capital shows only the partners one sees (redix-api #131).
  generateReports;

  /// What can be ticked in a project, in this order: every permission but the system's own.
  static List<Permission> get inAProject => values.where((permission) => permission != approveProjects).toList();

  /// The two capital ticks, which exclude each other (redix-api #106).
  static const capitalTicks = {seeAllCapital, seeChosenCapital};

  /// The key of the word naming it.
  String get wordKey => 'permissions.$name';

  /// The key of the word explaining it.
  String get hintKey => 'permissions.${name}Hint';

  /// The key of the word heading the group of ticks it sits in: «رأس المال» over the capital ticks, «التقارير» over the report ticks (redix-api #131); empty for a tick under none.
  String get groupWordKey => switch (this) {
    seeAllCapital || seeChosenCapital => 'permissions.capitalGroup',
    seeReports || generateReports => 'permissions.reportsGroup',
    _ => '',
  };
}
