import '../api_list.dart';
import '../auth/session.dart';
import 'creditable_invoice.dart';

/// What a credit note may return (BR-18): one supplier's invoices, as the API finds them.
class CreditableInvoices extends ApiList<CreditableInvoice> {
  /// The invoices of the project [projectId], seen through [session].
  CreditableInvoices(Session session, this.projectId) : super(session, _pathOf(projectId, ''), 'expenses', CreditableInvoice.fromJson);

  /// The project they belong to.
  final String projectId;

  static String _pathOf(String projectId, String supplierId) => '/projects/$projectId/expenses/creditable?supplierId=$supplierId';

  /// Reads the invoices of the supplier [supplierId].
  Future<void> ofSupplier(String supplierId) {
    pointAt(_pathOf(projectId, supplierId));
    return load();
  }
}
