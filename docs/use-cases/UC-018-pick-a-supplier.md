[Documentation](../README.md) › UC-018

# UC-018: Search and pick a supplier

**What it is for:** finding a supplier quickly and picking it, with its VAT number, so a supplier is always one from the register and never free text (BR-19).
**Who uses it:** whoever enters an expense or a contract.
**Issue:** redix-app #37; the API side is redix-api #36.

## Screens

[Choosing a supplier](../guide/supplier-picker.md), `SupplierPicker`, a sheet opened by `SupplierPicker.show`, which answers the supplier picked, or no supplier when closed:

| Element | `Key` | Does |
| --- | --- | --- |
| Search | `SupplierPicker.searchKey` | Asks the API at every change; Arabic digits are sent as Western ones |
| Close | `SupplierPicker.closeKey` | Closes without picking |
| A supplier | `SupplierPicker.rowKey(id)` | Picks it |
| That it is pending approval, its VAT number or that it has none, and its default item | `SupplierPicker.detailsKey(id)` | |
| The list's states | `SupplierPicker.messageKey`, `emptyKey` | Could not read; nothing matches |

The canvas (`SupplierPicker.dc.html`) heads the list "most used"; the API cannot say that until the ledger exists, so the sheet does not claim it. The canvas's new-supplier form is UC-019.

Nothing opens the sheet in this use case: UC-020 opens it from the contract's dialog, and UC-022 from the expense.

## API calls

| Call | When |
| --- | --- |
| `GET /projects/{id}/suppliers/search?text=...` | Opening the sheet, and at every change of the search field |

## Rules and where they live

| Rule | Code | Test in `test/suppliers/supplier_picker_test.dart` |
| --- | --- | --- |
| Opening shows what is on offer, each with its VAT number and default item | `SupplierPicker`, `Supplier.detailsIn` | `opening shows what is on offer, each with its VAT number and default item` |
| Typing shows what the API finds (AC-43.1) | `SupplierSearch.find` | `typing shows what the API finds` |
| Arabic digits are asked in Western ones | `SupplierSearch`, `westernDigits` | `part of a VAT number typed in Arabic digits is asked in Western ones` |
| Picking closes the sheet and answers the supplier, with its VAT number (FR-43) | `SupplierPicker` | `picking closes the sheet and answers the supplier, with its VAT number` |
| Closing answers no supplier | `SupplierPicker.show` | `closing answers no supplier` |
| A search that finds nothing says so | `ApiListBody` | `a search that finds nothing says so` |
| An answer to an older search never replaces a newer one | `ApiList.load` | `an answer to an older search never replaces a newer one` |
| Opening again starts with nothing typed | `SupplierSearch.openAnew` | `opening again starts with nothing typed` |
| It fits 360 points wide in both languages (AC-N03) | `SupplierPicker` | `AC-N03` in `test/account/my_account_test.dart` |

## Left to later use cases

| What | Use case |
| --- | --- |
| A quick add when the supplier is not found | UC-019 "Quick-add a supplier without leaving the expense" |
| The caller's most used suppliers first, and the title that says so | UC-022 "Record a purchase expense", once entries name suppliers |
| Filling the VAT number from a QR code | UC-024 "Fill the expense from the e-invoice QR" |
