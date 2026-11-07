import 'package:flutter/material.dart';

import '../contracts/contract.dart';
import '../contracts/contracts.dart';
import '../ui/api_list_body.dart';
import '../ui/picker_field.dart';
import '../words/words.dart';

/// The field that chooses the contract a payment is against, opening a sheet of the project's active contracts.
class ContractPicker extends StatelessWidget {
  /// The field showing [chosen], choosing among [contracts] and answering [onChanged].
  const ContractPicker({super.key, required this.contracts, required this.chosen, required this.onChanged});

  /// What can be chosen, the disabled ones left out.
  final Contracts contracts;

  /// The contract chosen; none yet when its id is empty.
  final Contract chosen;

  /// Called with the contract chosen.
  final ValueChanged<Contract> onChanged;

  /// The choice of the contract [id].
  static Key optionKey(String id) => Key('contractPicker.option.$id');

  Future<void> _choose(BuildContext context) async {
    final picked = await showModalBottomSheet<Contract>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheet) => FractionallySizedBox(
        heightFactor: 0.9,
        child: ApiListBody(
          list: contracts,
          emptyText: Words.of(sheet).contractsEmpty,
          itemBuilder: (contract) => contract.isActive
              ? ListTile(key: optionKey(contract.id), title: Text(contract.supplierName), subtitle: Text(contract.itemName), onTap: () => Navigator.of(sheet).pop(contract))
              : const SizedBox.shrink(),
        ),
      ),
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) => PickerField(label: Words.of(context).contractorPaymentsContract, value: chosen.supplierName, onTap: () => _choose(context));
}
