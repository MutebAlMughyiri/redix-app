[Documentation](../README.md) › UC-022

# UC-022, UC-027: Add an entry · إضافة قيد

**What it is for:** adding a purchase or a contractor payment to any table of an item's sheet, from one screen.
**Who uses it:** whoever holds `recordEntries` in the project while it runs, which is Finance and Field.
**Issue:** redix-app #84 "Add entry: one screen for every table, and the home's entries with search"; before it redix-app #41 and #45. Simplified by redix-api #96 "Simple expense".

## Screens

One button, **إضافة قيد**, sits at the bottom of the project's home where **New purchase expense** and **Contractor payment** were (`HomeScreen.addEntryKey(id)`). It opens `AddEntryScreen` at `/projects/:projectId/entries/new`. The rule: **an entry goes into one table of an item's sheet, and the table says what the entry is.** An item's general or named table takes a purchase; a contract's table takes a contractor payment (UC-027). `EntryTable` answers everything the two differ in: the route, the amount's column and word, and the file's word.

A purchase is a total on one date, with an optional file (redix-api #96, D3, D10, D11). The app sends what was typed: the amount, or price and quantity, which the API multiplies when no amount is typed (BR-01). It shows and sends no VAT, discount or bill number (D2, D4, D12). The id is made here (`Uuid().v7()`), once per screen, so trying again cannot make a second entry. The file is kept once, on the first save, and again only if it was taken again. The camera opens first for whoever may attach files, and its QR code fills the date, the total and the supplier (UC-024).

| Element | `Key` | Does |
| --- | --- | --- |
| The title, and the project's name under it | `AddEntryScreen.titleKey`, `projectNameKey` | إضافة قيد, or تعديل when an entry opens to change |
| The file | `AddEntryScreen.cameraKey`, `filesKey`, `invoiceNameKey` | UC-021: the bill's picture for a purchase, the receipt for a payment |
| Table | `AddEntryScreen.tableKey`, `TablePicker.optionKey(id)` | A sheet of every table on offer, by category: each item's general table, and its named tables and contracts under it. The field shows the general table as its item's name, and any other as the table and then its item in brackets, الجلاي (دفعات العظم) (Muteb, 7 Nov 2026). Its item's columns are read when the item changes |
| Searching the tables, and nothing matching | `TablePicker.searchKey`, `noMatchKey` | Keeps every table of an item whose name holds what was typed, and any table whose own name does, in one spelling |
| Date | `AddEntryScreen.dateKey` | Starts at today and picks within the project's period; sent as `paymentDate` |
| Supplier, and what is known of it | `AddEntryScreen.supplierKey`, `supplierDetailsKey` | A purchase's: opens `SupplierPicker`, with its quick add (UC-018, UC-019) |
| Credit note | `AddEntryScreen.creditNoteKey` | A purchase's (UC-026) |
| Product, unit price, quantity | `AddEntryScreen.productKey`, `unitPriceKey`, `quantityKey` | A purchase's; each follows its column: marked `*` when required, gone when deleted |
| The contract's figures, inside or outside | `AddEntryScreen.valueKey`, `paidKey`, `remainingKey`, `insideKey`, `outsideKey` | A payment's (UC-027) |
| Amount | `AddEntryScreen.amountKey` | A purchase's total or a payment's amount, labelled by its column; a negative one is a deduction |
| A custom column | `AddEntryScreen.columnKey(key)` | `ColumnValueField`, by what it holds; marked `*` when required, and in red when refused |
| A column list not read | `AddEntryScreen.columnsMessageKey` | |
| An account | `PaymentChoices.accountKey(id)` | The offered accounts; the only one is already chosen |
| Holds nothing | `AddEntryScreen.noAccountKey` | |
| A payment method | `PaymentChoices.paymentMethodKey(id)` | The active ones |
| Notes | `AddEntryScreen.notesKey` | Follows its column; a deduction says why here |
| Send for approval, Save draft | `AddEntryScreen.sendKey`, `draftKey` | |
| Why refused, and what was saved | `AddEntryScreen.messageKey`, `savedKey` | |
| A list not read, and try again | `AddEntryScreen.listMessageKey`, `retryKey` | |

`SupplierPicker` gains its title, `SupplierPicker.mostUsedKey`, while nothing is typed and once something was used.

## API calls

| Call | When |
| --- | --- |
| `GET /projects/{id}/entry-tables`, `.../contracts`, `.../accounts/offered`, `.../payment-methods` | Opening the screen |
| `GET /projects/{id}/items/{itemId}/columns` | Choosing a table of another item |
| `GET /projects/{id}/suppliers/search`, `POST /projects/{id}/suppliers` | Choosing the supplier |
| `POST /projects/{id}/attachments` | The first save with a file |
| `POST /projects/{id}/entries`, or `.../entries/{entryId}` for a change | Saving or sending, whatever the table (redix-api #110) |

## Rules

Tests are in `test/entries/add_entry_test.dart`, with the payment's in `add_entry_contract_test.dart` (UC-027).

| Rule | Code | Test |
| --- | --- | --- |
| R5: one إضافة قيد button at the bottom of the home opens the screen | `HomeScreen` | `entries_test`: R5 |
| R10: the table decides the kind: an item's named table takes the purchase into that subgroup, and the field names it as the table and then its item, مواد (البلاط) | `TablePicker`, `_purchasePart`, `EntryTable.label` | R10: an item's named table |
| R10, R11: a contract's table takes a contractor payment, sent with its contract and no item or subgroup | `_body`, `EntryTable.route` | `add_entry_contract_test`: R10, R11 |
| R7: only tables taking a purchase or a contractor payment are offered | `GET /entry-tables` | API `CategoriesTests`: R7, R10 |
| The table sheet searches the items' and the tables' names, Arabic spelling read as one, and says when nothing matches | `TablePicker._keptOf` | the table sheet searches the items' and the tables' names |
| R12, D10: an entry opens to change in its own table, under the title تعديل | `_openEntry` | `entries_test`: R12, D10; the reason shows at the top |
| Choosing a supplier fills its usual item's general table while none is chosen | `AddEntryScreen._useSupplier`, `EntryTables.generalTableOf` | choosing a supplier fills its usual item; an item already chosen stays; a usual item no longer on offer |
| D10: an entry has one date, sent as its payment date | `_body` | D10: an expense has one date |
| D3: an entry with no file is sent, with no reason asked | `_record` | D3: an expense with no file is sent |
| Arabic digits count | `parseNumber` | what a person types in Arabic digits counts |
| What was typed is sent, never a figure, with an id made here | `_body` | saving a draft sends what was typed and chosen, never a figure |
| What is not a number is refused here | `_numbers` | what is not a number is refused here |
| D14: a deduction, on either kind, is refused here until its notes say why | `_whatIsWrong` | `add_entry_test.dart`: AC-14.1, D14: a deduction is a negative amount, typed in either digits; `add_entry_contract_test.dart`: AC-14.1, D14: a deduction is a negative amount, which raises what remains |
| FR-09: a file is kept first and named | `_record` | FR-09; a refusal stays on the screen; a picture taken again; a file the API refuses |
| AC-41.1, FR-41: custom columns are drawn, marked and sent | `ColumnValueField`, `ItemColumn.valueToSend` | AC-41.1; FR-41; choosing another item |
| A built-in column follows what Finance made of it | `_asks`, `_requires` | a built-in field Finance made required |
| Open question 4: Field is offered only what they hold; Finance chooses any | `OfferedAccounts` | open question 4; ChargeAnyAccount; someone who holds nothing |
| AC-40.1: a disabled method is not offered | `PaymentChoices` | a disabled payment method |
| FR-44: Field reaches the sheet and its quick add from the entry (findings row 79) | `_pickSupplier` | findings row 79; Patrol |
| AC-43.1: the title over what was used most | `SupplierSearch.leadsWithMostUsed` | `supplier_picker_test`: AC-43.1 |
| Who may | `Project.mayEnterExpenses` | who holds no recordEntries; a finished project; `permission_gates_test` |
| AC-N03: it fits 360 points wide, in both languages | The screen | `settings/account_test`: AC-N03 |

On a real phone, `patrol_test/entries/add_purchase_test.dart` and `patrol_test/suppliers/quick_add_supplier_test.dart` follow Field from the home through the supplier's quick add to sending for approval, and `patrol_test/entries/add_contractor_payment_test.dart` pays a contractor from the same screen.
