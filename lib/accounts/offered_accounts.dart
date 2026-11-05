import '../api_list.dart';
import '../auth/session.dart';
import 'account.dart';

/// What the signed-in user's entry may be paid from (BRS open question 4). The API decides, and refuses anything else.
class OfferedAccounts extends ApiList<Account> {
  /// The accounts of the project [projectId] on offer, seen through [session].
  OfferedAccounts(Session session, String projectId) : super(session, '/projects/$projectId/accounts/offered', 'accounts', Account.fromJson);
}
