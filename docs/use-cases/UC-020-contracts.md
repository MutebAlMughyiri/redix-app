[Documentation](../README.md) › UC-020

# UC-020: Manage contracts

**What it is for:** recording what each contractor was promised, and following each contract's value, paid and remaining.
**Who uses it:** whoever holds `manageSettings` changes them, which is Finance. Everyone with access reads them.
**Issue:** redix-app #39; the API side is redix-api #38.

## Screens

Built from the canvas (`Contracts.dc.html`): the filters with their counts, and each contract's card. What was paid comes from the API, since UC-027 "Record a contractor payment".

The project's home, `HomeScreen`:

| Element | `Key` | Does |
| --- | --- | --- |
| Contracts | `HomeScreen.contractsKey(id)` | Opens the screen below, for everyone with access |

[Contracts](../guide/contracts.md), `ContractsScreen` at `/projects/:projectId/contracts`:

| Element | `Key` | Does |
| --- | --- | --- |
| Add contract | `ContractsScreen.addKey` | Opens the dialog; shown with `manageSettings` while the project runs |
| A filter, with its count | `ContractsScreen.filterKey(filter)` | Keeps all contracts, those overrun, or those of open value |
| The contractor | `ContractsScreen.nameKey(id)` | |
| The item, unit, and unit price and quantity | `ContractsScreen.termsKey(id)` | |
| The notes | `ContractsScreen.contractNotesKey(id)` | Shown when there are any |
| How it stands | `ContractsScreen.standingKey(id)` | Disabled, contract overrun, open value, not started, or in progress |
| Value, Paid, Remaining | `ContractsScreen.valueOfKey(id)`, `paidKey(id)`, `remainingKey(id)` | An overrun shows in brackets, in red; an open value shows no remaining |
| The bar of how much is paid | `ContractsScreen.progressKey(id)` | |
| A contract's menu | `ContractsScreen.menuKey(id)` | Shown with `manageSettings` while the project runs |
| Amend, Disable, Enable, in the menu | `ContractsScreen.editKey`, `disableKey`, `enableKey` | |
| The contractor, in the dialog that adds | `ContractsScreen.contractorKey` | Opens `SupplierPicker` (UC-018), with its quick add (UC-019) |
| The item, in the dialog that adds | `ContractsScreen.itemKey` | An `ItemPicker` of what takes contractor payments |
| A unit, in the dialog that adds | `ContractsScreen.unitKey(id)` | The project's units, and the shared one last |
| The contractor, item and unit, in the dialog that amends | `ContractsScreen.contractorKey`, `itemKey`, `unitKey(id)` while no payment names the contract, starting from what it has; `partiesKey`, read only, once one does | |
| Open-value contract, in the dialog | `ContractsScreen.openValueKey` | Hides the value |
| The value, unit price, quantity and notes, in the dialog | `ContractsScreen.valueKey`, `unitPriceKey`, `quantityKey`, `notesKey` | |
| Save, in the dialog | `ContractsScreen.saveKey` | |
| Why refused, in the dialog | `ContractsScreen.dialogMessageKey` | |
| The list's states | `ContractsScreen.messageKey`, `emptyKey` | Could not read; no contracts |

## API calls

| Call | When |
| --- | --- |
| `GET /projects/{id}/contracts` | Opening the screen, and after every change |
| `GET /projects/{id}/categories/offered?itemType=contractorPayments` | Opening the screen with `manageSettings` |
| `GET /projects/{id}/suppliers/search`, `POST /projects/{id}/suppliers` | Choosing the contractor |
| `POST /projects/{id}/contracts`, `.../{contractId}`, `.../{contractId}/disable`, `.../enable` | Adding, amending, disabling and enabling |

## Rules and where they live

| Rule | Code | Test in `test/contracts/contracts_test.dart` |
| --- | --- | --- |
| Each contract shows its contractor, item and figures (FR-07); a contract belongs to the project, not a unit (redix-api #96) | `ContractCard` | `each contract shows its contractor, item and figures` |
| It shows what remains, and how it stands (AC-07.1) | `ContractCard`, `Contract.standingWordKey` | `AC-07.1: a contract shows what remains of it, and how it stands` |
| An overrun shows in brackets, with an alert (AC-07.1) | `ContractCard`, `formatMoney` | `AC-07.1: an overrun shows its remaining in brackets, with an alert` |
| An open-value contract has no remaining and no alert (AC-07.2) | `ContractCard` | `AC-07.2: an open-value contract adds up, with no remaining and no alert` |
| Nothing paid is not started | `Contract.standingWordKey` | `a contract with nothing paid has not started` |
| The filters count their contracts and keep only those | `ContractFilter`, `ContractsScreen` | `the filters count their contracts and keep only those` |
| A filter that keeps no contract says there are none rather than showing a blank page | `ApiListBody.keeps` | `a filter that keeps no contract says there are none rather than showing a blank page` |
| Adding sends the contractor, item and terms | `ContractDialog`, `Contracts.add` | `adding sends the contractor, item and terms` |
| A missing contractor is added from the picker | `SupplierPicker` | `a contractor missing from the register is added from the picker and goes on` |
| Nothing chosen is left for the API to refuse | `Contracts.add` | `nothing chosen is left for the API to refuse, and stays in the dialog` |
| An open-value contract asks no value | `ContractDialog` | `an open-value contract asks no value and sends the mark` |
| Figures that are not numbers are refused before sending | `ContractDialog` | `figures that are not numbers are refused before anything is sent` |
| A contract with no payments offers its contractor, item and unit, starting from what it has, and sends them; a refusal stays in the dialog | `ContractDialog`, `Contracts.amend`, `Contract.hasPayments` | `a contract with no payments offers its contractor, item and unit, starting from what it has, and sends them`, `another unit chosen is what is sent`, `a refused change of contractor stays in the dialog and says why` |
| Amending a contract with payments starts from it, whose contractor and item stay and are not sent | `ContractDialog`, `Contracts.amend` | `amending a contract with payments starts from it, whose contractor and item stay` |
| Saving with the keyboard up closes it with the dialog | `ChangeDialog` | `saving with the keyboard up closes it with the dialog` |
| Disabled, it stays on the list, marked, and can be enabled | `ContractCard` | `a disabled contract stays on the list, marked, and can be enabled` |
| A project with no contracts says so | `ApiListBody` | `a project with no contracts says so` |
| Without keeping the settings there is nothing to change | `Project.mayManageSettings` | `without keeping the settings the contracts show with nothing to change` |
| A finished project shows them with nothing to change (AC-04.1) | `Project.mayManageSettings` | `a finished project shows its contracts with nothing to change` |
| A list that cannot be read says so | `ApiListBody` | `a list that cannot be read says so` |
| It fits 360 points wide in both languages (AC-N03) | `ContractsScreen`, `ContractDialog` | `AC-N03` in `test/account/settings/account_test.dart` |

The real app is run on an emulator by the journey in `patrol_test/app_test.dart`, which opens the supplier picker, adds a contractor with the quick add, and adds a contract.

## Left to later use cases

| What | Use case |
| --- | --- |
| The contract's document | UC-021 "Store an invoice or receipt attachment" |
| The contracts report | UC-051 "Contracts report" |
