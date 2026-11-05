import 'package:flutter/material.dart';

import '../projects/project.dart';
import '../structure/offered_items.dart';
import '../suppliers/suppliers.dart';
import '../ui/api_list_body.dart';
import '../ui/change_dialog.dart';
import '../words/words.dart';
import 'contract.dart';
import 'contract_card.dart';
import 'contract_dialog.dart';
import 'contracts.dart';

/// A project's contracts (UC-020): everyone with access follows each one's value, paid and remaining, and whoever keeps the settings adds, amends and disables them. Nothing is deleted.
class ContractsScreen extends StatefulWidget {
  /// The screen, showing and changing the [contracts] of [project], picking a contractor from [suppliers] and an item from [items].
  const ContractsScreen({super.key, required this.project, required this.contracts, required this.suppliers, required this.items});

  /// The project they belong to.
  final Project project;

  /// The contracts this screen shows and changes.
  final Contracts contracts;

  /// The register a contractor comes from.
  final Suppliers suppliers;

  /// The items that take contractor payments.
  final OfferedItems items;

  /// The screen's route.
  static const path = '/projects/:projectId/contracts';

  /// The route of the contracts of the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/contracts';

  /// The button that adds a contract.
  static const addKey = Key('contracts.add');

  /// Amend, in a contract's menu.
  static const editKey = Key('contracts.edit');

  /// Disable, in a contract's menu.
  static const disableKey = Key('contracts.disable');

  /// Enable, in a contract's menu.
  static const enableKey = Key('contracts.enable');

  /// The contractor, in the dialog that adds.
  static const contractorKey = Key('contracts.contractor');

  /// The item, in the dialog that adds.
  static const itemKey = Key('contracts.item');

  /// The contractor, item and unit, in the dialog that amends.
  static const partiesKey = Key('contracts.parties');

  /// The switch that makes it open-value, in the dialog.
  static const openValueKey = Key('contracts.openValue');

  /// The value, in the dialog.
  static const valueKey = Key('contracts.value');

  /// The unit price, in the dialog.
  static const unitPriceKey = Key('contracts.unitPrice');

  /// The quantity, in the dialog.
  static const quantityKey = Key('contracts.quantity');

  /// The notes, in the dialog.
  static const notesKey = Key('contracts.notes');

  /// The button that saves, in the dialog.
  static const saveKey = ChangeDialog.saveKey;

  /// The line that says why a change was refused, in the dialog.
  static const dialogMessageKey = ChangeDialog.messageKey;

  /// The line that says the list could not be read.
  static const messageKey = ApiListBody.messageKey;

  /// The line shown while the project has no contracts.
  static const emptyKey = ApiListBody.emptyKey;

  /// The choice of the filter [filter].
  static Key filterKey(ContractFilter filter) => Key('contracts.filter.${filter.name}');

  /// The choice of the unit [id], in the dialog that adds.
  static Key unitKey(String id) => Key('contracts.unit.$id');

  /// The contractor of the contract [id].
  static Key nameKey(String id) => Key('contracts.name.$id');

  /// The item, unit, and unit price and quantity of the contract [id].
  static Key termsKey(String id) => Key('contracts.terms.$id');

  /// The notes of the contract [id].
  static Key contractNotesKey(String id) => Key('contracts.notes.$id');

  /// How the contract [id] stands.
  static Key standingKey(String id) => Key('contracts.standing.$id');

  /// The value of the contract [id].
  static Key valueOfKey(String id) => Key('contracts.valueOf.$id');

  /// What was paid inside the contract [id].
  static Key paidKey(String id) => Key('contracts.paid.$id');

  /// What remains of the contract [id].
  static Key remainingKey(String id) => Key('contracts.remaining.$id');

  /// The bar of how much of the contract [id] is paid.
  static Key progressKey(String id) => Key('contracts.progress.$id');

  /// The menu of the contract [id].
  static Key menuKey(String id) => Key('contracts.menu.$id');

  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen> {
  var _filter = ContractFilter.all;

  @override
  void initState() {
    super.initState();
    widget.contracts.loadOnOpen();
    if (widget.project.mayManageSettings) {
      widget.items.loadOnOpen();
    }
  }

  void _ask(Contract contract) {
    showDialog<void>(
      context: context,
      builder: (_) => ContractDialog(contract: contract, project: widget.project, contracts: widget.contracts, suppliers: widget.suppliers, items: widget.items),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final project = widget.project;
    final contracts = widget.contracts;
    return Scaffold(
      appBar: AppBar(title: Text('${words.contractsTitle} · ${project.name}')),
      floatingActionButton: project.mayManageSettings
          ? FloatingActionButton.extended(key: ContractsScreen.addKey, icon: const Icon(Icons.add), label: Text(words.contractsNew), onPressed: () => _ask(Contract.none()))
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListenableBuilder(
            listenable: contracts,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final filter in ContractFilter.values)
                    ChoiceChip(
                      key: ContractsScreen.filterKey(filter),
                      label: Text('${words.text(filter.wordKey)} · ${contracts.all.where(filter.keeps).length}'),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ApiListBody(
              list: contracts,
              emptyText: words.contractsEmpty,
              itemBuilder: (contract) => _filter.keeps(contract)
                  ? ContractCard(contract: contract, contracts: contracts, mayChange: project.mayManageSettings, onAmend: () => _ask(contract))
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
