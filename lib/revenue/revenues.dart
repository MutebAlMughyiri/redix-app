import '../api_list.dart';
import '../auth/session.dart';
import 'revenue_row.dart';

/// A project's revenue, newest first (UC-047), and the ways to record it and its sales invoices (UC-048). Each change returns an empty string once made, otherwise the word key of the refusal.
class Revenues extends ApiList<RevenueRow> {
  /// The revenue of the project [projectId], seen through [session].
  Revenues(Session session, this.projectId) : super(session, '/projects/$projectId/revenue', 'revenue', RevenueRow.fromJson);

  /// The project.
  final String projectId;

  /// Records revenue.
  Future<String> record(Map<String, Object> body) => change('/projects/$projectId/revenue', body);

  /// Records a sales invoice.
  Future<String> recordSale(Map<String, Object> body) => change('/projects/$projectId/sales-invoices', body);

  /// Reverses [row], saying [reason].
  Future<String> reverse(RevenueRow row, String reason) => change('/projects/$projectId/entries/${row.id}/reverse', {'reason': reason}, wordPrefix: 'entries');
}
