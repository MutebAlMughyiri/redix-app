import '../api_list.dart';
import '../auth/session.dart';
import 'contract.dart';

/// What can change on a contract: its [value], or that it [isOpenValue], its [unitPrice] and [quantity], 0 when not used, its [notes], and the ids of the [attachmentIds] it is to carry besides those it does.
typedef ContractTerms = ({double value, bool isOpenValue, double unitPrice, double quantity, String notes, List<String> attachmentIds});

/// The id the API reads as nothing chosen. A choice left empty is sent as it, because the API refuses a request that misses a field before it can say which choice is missing.
const _nothingChosen = '00000000-0000-0000-0000-000000000000';

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

  /// Adds a contract with the contractor [supplierId], for [itemId], on [terms]. Either still empty goes as nothing chosen, for the API to refuse by name.
  Future<String> add(String supplierId, String itemId, ContractTerms terms) => change('/projects/$projectId/contracts', {
    'supplierId': supplierId.isEmpty ? _nothingChosen : supplierId,
    'itemId': itemId.isEmpty ? _nothingChosen : itemId,
    ..._bodyOf(terms),
  });

  /// Amends [contract] to [terms], with the contractor [supplierId], for [itemId] while no payment names it.
  Future<String> amend(Contract contract, ContractTerms terms, String supplierId, String itemId) => put('/projects/$projectId/contracts/${contract.id}', {
    if (!contract.hasPayments) ...{'supplierId': supplierId, 'itemId': itemId},
    ..._bodyOf(terms),
  });

  /// Disables [contract]; it stays in the reports.
  Future<String> disable(Contract contract) => change('/projects/$projectId/contracts/${contract.id}/disable', {});

  /// Brings the disabled [contract] back.
  Future<String> enable(Contract contract) => change('/projects/$projectId/contracts/${contract.id}/enable', {});
}
