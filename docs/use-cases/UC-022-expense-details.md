[Documentation](../README.md) › UC-022

# UC-022: Enter the expense details

**What it is for:** completing and sending a purchase expense.
**Who uses it:** whoever holds `recordEntries` in the project while it runs, which is Finance and Field.
**Issue:** redix-app #41; the API side is redix-api #40. Simplified by redix-api #96 "Simple expense".

## Screens

Built from the canvas (`AddExpense.dc.html`, `SupplierPicker.dc.html`). The **Credit note** is UC-026.

An expense is a total on one date, with an optional file (redix-api #96, D3, D10, D11). The app sends what was typed: the amount, or price and quantity, which the API multiplies when no amount is typed (BR-01). It shows and sends no VAT, discount or bill number (D2, D4, D12). The id is made here (`Uuid().v7()`), once per screen, so trying again cannot make a second entry. The file is kept once, on the first save, and again only if it was taken again.

[New purchase expense](../guide/add-expense.md), `AddExpenseScreen` at `/projects/:projectId/expenses/new`, besides the file's elements in UC-021:

| Element | `Key` | Does |
| --- | --- | --- |
| The title, and the project's name under it | `AddExpenseScreen.titleKey`, `projectNameKey` | Two lines, so a long name cuts neither off |
| Item | `AddExpenseScreen.itemKey` | An `ItemPicker` of what takes purchases; its columns are read when chosen |
| A subgroup | `AddExpenseScreen.subgroupKey(id)` | Shown when the item has named ones |
| Supplier, and what is known of it | `AddExpenseScreen.supplierKey`, `supplierDetailsKey` | Opens `SupplierPicker`, with its quick add (UC-018, UC-019) |
| Date | `AddExpenseScreen.dateKey` | Starts at today and picks within the project's period; sent as `paymentDate` |
| Product, unit price, quantity | `AddExpenseScreen.productKey`, `unitPriceKey`, `quantityKey` | Each follows its column: marked `*` when required, gone when deleted |
| Total | `AddExpenseScreen.amountKey` | Labelled by the item's `total` column; a negative one is a deduction (UC-026) |
| A custom column | `AddExpenseScreen.columnKey(key)` | `ColumnValueField`, by what it holds; marked `*` when required, and in red when refused |
| An account | `PaymentChoices.accountKey(id)` | The offered accounts; the only one is already chosen |
| Holds nothing | `AddExpenseScreen.noAccountKey` | |
| A payment method | `PaymentChoices.paymentMethodKey(id)` | The active ones |
| Notes | `AddExpenseScreen.notesKey` | Follows its column; a deduction says why here |
| Send for approval, Save draft | `AddExpenseScreen.sendKey`, `draftKey` | |
| Why refused, and what was saved | `AddExpenseScreen.messageKey`, `savedKey` | |
| A list not read, and try again | `AddExpenseScreen.listMessageKey`, `retryKey` | |

The project's home has the way in, `HomeScreen.addExpenseKey(id)`. `SupplierPicker` gains its title, `SupplierPicker.mostUsedKey`, while nothing is typed and once something was used.

## API calls

| Call | When |
| --- | --- |
| `GET /projects/{id}/categories/offered?itemType=purchases`, `.../accounts/offered`, `.../payment-methods` | Opening the screen |
| `GET /projects/{id}/items/{itemId}/columns` | Choosing an item |
| `GET /projects/{id}/suppliers/search`, `POST /projects/{id}/suppliers` | Choosing the supplier |
| `POST /projects/{id}/attachments` | The first save with a file |
| `POST /projects/{id}/expenses` | Saving or sending |

## Rules

Tests are in `test/expenses/add_expense_test.dart`.

| Rule | Code | Test |
| --- | --- | --- |
| Choosing a supplier fills its usual item while none is chosen | `AddExpenseScreen._useSupplier` | choosing a supplier fills its usual item; an item already chosen stays; a usual item no longer on offer |
| D10: an expense has one date, sent as its payment date | `_body` | D10: an expense has one date |
| D3: an expense with no file is sent, with no reason asked | `_record` | D3: an expense with no file is sent |
| Arabic digits count | `parseNumber` | what a person types in Arabic digits counts |
| What was typed is sent, never a figure, with an id made here | `_body` | saving a draft sends what was typed and chosen, never a figure |
| What is not a number is refused here | `_numbers` | what is not a number is refused here |
| FR-09: a file is kept first and named | `_record` | FR-09; a refusal stays on the screen; a picture taken again; a file the API refuses |
| AC-41.1, FR-41: custom columns are drawn, marked and sent | `ColumnValueField`, `ItemColumn.valueToSend` | AC-41.1; FR-41; choosing another item |
| A built-in column follows what Finance made of it | `_asks`, `_requires` | a built-in field Finance made required |
| Named subgroups are offered, the general one first | `_subgroupChoice` | an item with named subgroups; an item with no named subgroup |
| Open question 4: Field is offered only what they hold; Finance chooses any | `OfferedAccounts` | open question 4; ChargeAnyAccount; someone who holds nothing |
| AC-40.1: a disabled method is not offered | `PaymentChoices` | a disabled payment method |
| FR-44: Field reaches the sheet and its quick add from the expense (findings row 79) | `_pickSupplier` | findings row 79; Patrol |
| AC-43.1: the title over what was used most | `SupplierSearch.leadsWithMostUsed` | `supplier_picker_test`: AC-43.1 |
| Who may | `Project.mayEnterExpenses` | who holds no recordEntries; a finished project |
| AC-N03: it fits 360 points wide, in both languages | The screen | `my_account_test`: AC-N03 |

The Patrol journey follows Field from the home through the supplier's quick add to sending for approval.
