// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import '../api_list.dart';
import '../auth/session.dart';
import '../format/date_format.dart';
import 'account.dart';

/// A project's accounts and cash custodies (UC-015), and the one way to change them and move money between them (redix-app #89). Each change returns an empty string
/// once made, otherwise the word key of the refusal.
class Accounts extends ApiList<Account> {
  /// The accounts of the project [projectId], seen through [session].
  Accounts(Session session, this.projectId) : super(session, '/projects/$projectId/accounts', 'accounts', Account.fromJson);

  /// The project these accounts belong to.
  final String projectId;

  /// The active accounts: what money is paid from or into.
  List<Account> get bankAndCash => all.where((account) => account.isActive).toList();

  /// The active accounts the signed-in user holds, which their home shows (AC-22.1).
  List<Account> get mine => all.where((account) => account.isMine && account.isActive).toList();

  /// Adds an account of [type] named [name], held by the user [custodianId], or by nobody when that is empty. It holds nothing until money moves into it.
  Future<String> add(AccountType type, String name, String custodianId) =>
      change('/projects/$projectId/accounts', {'type': type.name, 'name': name, if (custodianId.isNotEmpty) 'custodianId': custodianId});

  /// Changes the name of [account] and who holds it: the user [custodianId], or nobody when that is empty.
  Future<String> edit(Account account, String name, String custodianId) =>
      put('/projects/$projectId/accounts/${account.id}', {'name': name, if (custodianId.isNotEmpty) 'custodianId': custodianId});

  /// Takes [account] out of entry; it stays in the reports.
  Future<String> disable(Account account) => change('/projects/$projectId/accounts/${account.id}/disable', {});

  /// Brings the disabled [account] back into entry.
  Future<String> enable(Account account) => change('/projects/$projectId/accounts/${account.id}/enable', {});

  /// Deletes [account], which nothing names yet (BR-15).
  Future<String> delete(Account account) => deleteAt('/projects/$projectId/accounts/${account.id}');

  /// Moves [amount] from [from] to [to] on [date], with [notes]: it counts in both balances at once (FR-23), and its refusals are the transfer's words.
  Future<String> transfer(Account from, Account to, double amount, DateTime date, String notes) => change(
    '/projects/$projectId/transfers',
    {'fromAccountId': from.id, 'toAccountId': to.id, 'amount': amount, 'date': apiDate(date), 'notes': notes},
    wordPrefix: 'transfers',
  );
}
