import '../api_list.dart';
import '../auth/session.dart';
import 'account.dart';

/// A project's accounts and cash custodies (UC-015), and the one way to change them. Each change returns an empty string once made, otherwise the word key of the refusal.
class Accounts extends ApiList<Account> {
  /// The accounts of the project [projectId], seen through [session].
  Accounts(Session session, this.projectId) : super(session, '/projects/$projectId/accounts', 'accounts', Account.fromJson);

  /// The project these accounts belong to.
  final String projectId;

  /// The active accounts: what money is paid from or into.
  List<Account> get bankAndCash => all.where((account) => account.isActive).toList();

  /// The active accounts the signed-in user holds, which their home shows (AC-22.1).
  List<Account> get mine => all.where((account) => account.isMine && account.isActive).toList();

  /// Adds an account of [type] named [name] with [openingBalance], held by the user [custodianId], or by nobody when that is empty.
  Future<String> add(AccountType type, String name, double openingBalance, String custodianId) =>
      change('/projects/$projectId/accounts', {'type': type.name, 'name': name, 'openingBalance': openingBalance, if (custodianId.isNotEmpty) 'custodianId': custodianId});

  /// Changes the name of [account], its [openingBalance] and who holds it: the user [custodianId], or nobody when that is empty.
  Future<String> edit(Account account, String name, double openingBalance, String custodianId) =>
      change('/projects/$projectId/accounts/${account.id}', {'name': name, 'openingBalance': openingBalance, if (custodianId.isNotEmpty) 'custodianId': custodianId});

  /// Takes [account] out of entry; it stays in the reports.
  Future<String> disable(Account account) => change('/projects/$projectId/accounts/${account.id}/disable', {});

  /// Brings the disabled [account] back into entry.
  Future<String> enable(Account account) => change('/projects/$projectId/accounts/${account.id}/enable', {});
}
