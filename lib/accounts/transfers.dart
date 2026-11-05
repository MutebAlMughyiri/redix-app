import '../api_list.dart';
import '../auth/session.dart';
import 'transfer.dart';

/// A project's latest transfers (UC-040), and the way to enter one. Each change returns an empty string once made, otherwise the word key of the refusal.
class Transfers extends ApiList<Transfer> {
  /// The transfers of the project [projectId], seen through [session].
  Transfers(Session session, this.projectId) : super(session, '/projects/$projectId/transfers', 'transfers', Transfer.fromJson);

  /// The project.
  final String projectId;

  /// Moves [amount] from the account [fromAccountId] to [toAccountId] on [date], saying [description], shown by the file [attachmentId] when that is not empty.
  Future<String> add(DateTime date, String fromAccountId, String toAccountId, double amount, String description, String attachmentId) => change('/projects/$projectId/transfers', {
    'date': date.toIso8601String().substring(0, 10),
    'fromAccountId': fromAccountId,
    'toAccountId': toAccountId,
    'amount': amount,
    'description': description,
    if (attachmentId.isNotEmpty) 'attachmentId': attachmentId,
  });

  /// Reverses [transfer], both its sides, saying [reason].
  Future<String> reverse(Transfer transfer, String reason) => change('/projects/$projectId/entries/${transfer.id}/reverse', {'reason': reason}, wordPrefix: 'entries');
}
