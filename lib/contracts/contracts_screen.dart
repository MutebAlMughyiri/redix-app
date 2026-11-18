// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../reports/item_report_screen.dart';
import '../attachments/attachments.dart';
import '../attachments/invoice_capture.dart';
import '../projects/project.dart';
import '../structure/offered_items.dart';
import '../suppliers/suppliers.dart';
import '../ui/api_list_body.dart';
import '../ui/bottom_button.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'contract.dart';
import 'contract_card.dart';
import 'contract_dialog.dart';
import 'contracts.dart';
import '../reports/report_files.dart';
import '../ui/filter_line.dart';
import '../ui/list_search.dart';
import '../ui/search_scope.dart';
import '../words/word_fill.dart';
import '../format/parts_line.dart';
import '../format/number_format.dart';

/// A project's contracts (UC-020): everyone with access follows each one's value, paid and remaining, and whoever keeps the settings adds, amends and disables them. Nothing is deleted.
class ContractsScreen extends StatefulWidget {
  /// The screen, showing and changing the [contracts] of [project], picking a contractor from [suppliers] and an item from [items], and keeping a document through [attachments] from what [capture] picks.
  const ContractsScreen({super.key, required this.project, required this.contracts, required this.suppliers, required this.items, required this.attachments, required this.capture, required this.files});

  /// The project they belong to.
  final Project project;

  /// The contracts this screen shows and changes.
  final Contracts contracts;

  /// The register a contractor comes from.
  final Suppliers suppliers;

  /// The items that take contractor payments.
  final OfferedItems items;

  /// The way to keep a document.
  final Attachments attachments;

  /// The phone's files.
  final InvoiceCapture capture;

  /// The way to the contracts report's PDF and Excel, for whoever sees all capital (moved from Reports, Muteb, 9 Nov 2026).
  final ReportFiles files;

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

  /// The button that adds a document, in the dialog.
  static const addDocumentKey = Key('contracts.addDocument');

  /// The line that says why a document was not kept, in the dialog.
  static const documentMessageKey = Key('contracts.documentMessage');

  /// The document [id], in the dialog.
  static Key documentKey(String id) => Key('contracts.document.$id');

  /// The choice of the filter [filter].
  static Key filterKey(ContractFilter filter) => Key('contracts.filter.${filter.name}');

  /// The choice among the filters, folded under the search line (redix-app #104).
  static const filterChoiceKey = Key('contracts.filterChoice');

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

  /// What waits for approval on the contract [id], when anything does.
  static Key pendingKey(String id) => Key('contracts.pending.$id');

  /// The bar of how much of the contract [id] is paid.
  static Key progressKey(String id) => Key('contracts.progress.$id');

  /// The menu of the contract [id].
  static Key menuKey(String id) => Key('contracts.menu.$id');

  /// The file of [kind] of a contract, in its ⋮ (Muteb, 12 Nov 2026): its PDF or its Excel.
  static Key fileKey(ReportFileKind kind) => Key('contracts.file.${kind.name}');

  /// The heading over the documents, in the dialog.
  static const documentsHeadingKey = Key('contracts.documentsHeading');

  /// The button opening the document [id].
  static Key openDocumentKey(String id) => Key('contracts.openDocument.$id');

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
      builder: (_) => ContractDialog(contract: contract, project: widget.project, contracts: widget.contracts, suppliers: widget.suppliers, items: widget.items, attachments: widget.attachments, capture: widget.capture),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final project = widget.project;
    final contracts = widget.contracts;
    return SearchScope(
      child: Scaffold(
        appBar: AppBar(title: ScreenTitle(words.contractsTitle, subject: project.name), actions: [SearchIcons.andFilters(filtersInUse: _filter != ContractFilter.all)]),
        bottomNavigationBar: BottomButton(buttonKey: ContractsScreen.addKey, label: words.contractsNew, onPressed: project.mayManageSettings ? () => _ask(Contract.none()) : null),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListenableBuilder(
                listenable: contracts,
                builder: (context, _) => ApiListBody<Contract>(
                  list: contracts,
                  emptyText: words.contractsEmpty,
                  keeps: _filter.keeps,
                  search: ListSearch(
                    hint: words.commonSearchIn.fill([words.contractsTitle]),
                    textOf: (contract) => partsLine([contract.supplierName, contract.itemName, contract.notes, searchableAmount(contract.value)]),
                    filters: [
                      FilterLine.segmented(
                        key: ContractsScreen.filterChoiceKey,
                        values: ContractFilter.values,
                        selected: _filter,
                        labelOf: (filter) => '${words.text(filter.wordKey)} · ${contracts.all.where(filter.keeps).length}',
                        keyOf: ContractsScreen.filterKey,
                        onChanged: (filter) => setState(() => _filter = filter),
                      ),
                    ],
                  ),
                  itemBuilder: (contract) => ContractCard(
                    contract: contract,
                    contracts: contracts,
                    mayChange: project.mayManageSettings,
                    onAmend: () => _ask(contract),
                    mayOpen: project.maySeeReports,
                    onOpen: () => context.push(ItemReportScreen.contractPathOf(project.id, contract.id), extra: project),
                    mayExport: project.mayTakeReportFiles,
                    files: widget.files,
                    address: ItemReportScreen.contractPathOf(project.id, contract.id),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
