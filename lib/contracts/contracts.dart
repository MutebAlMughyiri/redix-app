import '../api_list.dart';
import '../auth/session.dart';
import 'contract.dart';

/// What can change on a contract: its [value], or that it [isOpenValue], its [unitPrice] and [quantity], 0 when not used, its [notes], and the ids of the [attachmentIds] it is to carry besides those it does.
typedef ContractTerms = ({double value, bool isOpenValue, double unitPrice, double quantity, String notes, List<String> attachmentIds});

/// A project's contracts (UC-020), and the one way to change them. Each change returns an empty string once made, otherwise the word key of the refusal.
class Contracts extends ApiList<Contract> {
  /// The contracts of the project [projectId], seen through [session].
  Contracts(Session session, this.projectId) : super(session, '/projects/$projectId/contracts', 'contracts', Contract.fromJson);

  /// The project these contracts belong to.
  final String projectId;

  Map<String, Object> _bodyOf(ContractTerms terms) => {
    'value': terms.value,
    'isOpenValue': terms.isOpenValue,
    'unitPrice': terms.unitPrice,
    'quantity': terms.quantity,
    'notes': terms.notes,
    if (terms.attachmentIds.isNotEmpty) 'attachmentIds': terms.attachmentIds,
  };

  /// Adds a contract with the contractor [supplierId], for [itemId] and [unitId], on [terms]. Any of the three still empty is left for the API to refuse.
  Future<String> add(String supplierId, String itemId, String unitId, ContractTerms terms) => change('/projects/$projectId/contracts', {
    if (supplierId.isNotEmpty) 'supplierId': supplierId,
    if (itemId.isNotEmpty) 'itemId': itemId,
    if (unitId.isNotEmpty) 'unitId': unitId,
    ..._bodyOf(terms),
  });

  /// Amends [contract] to [terms]; its contractor, item and unit never change.
  Future<String> amend(Contract contract, ContractTerms terms) => change('/projects/$projectId/contracts/${contract.id}', _bodyOf(terms));

  /// Disables [contract]; it stays in the reports.
  Future<String> disable(Contract contract) => change('/projects/$projectId/contracts/${contract.id}/disable', {});

  /// Brings the disabled [contract] back.
  Future<String> enable(Contract contract) => change('/projects/$projectId/contracts/${contract.id}/enable', {});
}
