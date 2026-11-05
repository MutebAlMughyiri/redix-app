[Documentation](../README.md) › UC-022

# UC-022: Enter the expense details

**What it is for:** completing and sending a purchase expense.
**Who uses it:** whoever holds `recordEntries` in the project while it runs, which is Finance and Field.
**Issue:** redix-app #41; the API side is redix-api #40, with #41 for the duplicate.

## Screens

Built from the canvas (`AddExpense.dc.html`, `SupplierPicker.dc.html`). Left out for their own use cases: **Without invoice** (UC-025), **Credit note** (UC-026) and the source **From partner** (UC-045).

The app sends what was typed and never a figure. `InvoiceFigures` only shows what the API will compute, and `formatMoney` rounds half up from the four decimals the API keeps, because a `double` lies just below 2,955.385 and would show 2,955.38. The id is made here (`Uuid().v7()`), once per screen, so trying again cannot make a second entry. The invoice is kept once, on the first save, and again only if it was taken again.

[New purchase expense](../guide/add-expense.md), `AddExpenseScreen` at `/projects/:projectId/expenses/new`, besides the invoice's elements in UC-021:

| Element | `Key` | Does |
| --- | --- | --- |
| Item | `AddExpenseScreen.itemKey` | An `ItemPicker` of what takes purchases; its columns are read when chosen |
| A subgroup | `AddExpenseScreen.subgroupKey(id)` | Shown when the item has named ones |
| A unit | `AddExpenseScreen.unitKey(id)` | The project's units, and the shared one last |
| Supplier, and what is known of it | `AddExpenseScreen.supplierKey`, `supplierDetailsKey` | Opens `SupplierPicker`, with its quick add (UC-018, UC-019) |
| Invoice number, date | `AddExpenseScreen.invoiceNumberKey`, `invoiceDateKey` | The date starts at today and picks within the project's period |
| Product, unit price, quantity | `AddExpenseScreen.productKey`, `unitPriceKey`, `quantityKey` | Each follows its column: marked `*` when required, gone when deleted |
| Including VAT, Before VAT | `AddExpenseScreen.includingVatKey`, `beforeVatKey` | What the amount is |
| Amount, discount | `AddExpenseScreen.amountKey`, `discountKey` | |
| Not taxable | `AddExpenseScreen.notTaxableKey` | VAT is zero |
| Before VAT after discount, VAT, total | `AddExpenseScreen.afterDiscountKey`, `vatKey`, `totalKey` | Read-only, to two decimals |
| A custom column | `AddExpenseScreen.columnKey(key)` | `ColumnValueField`, by what it holds; marked `*` when required, and in red when refused |
| A source | `AddExpenseScreen.sourceKey(type)` | The kinds of account on offer |
| An account | `AddExpenseScreen.accountKey(id)` | The offered accounts of that source; the only one is already chosen |
| Holds nothing | `AddExpenseScreen.noAccountKey` | |
| A payment method | `AddExpenseScreen.paymentMethodKey(id)` | The active ones |
| Payment differs, its date, amount and bank fees | `AddExpenseScreen.paymentDiffersKey`, `paymentDateKey`, `paymentAmountKey`, `bankFeesKey` | |
| Notes | `AddExpenseScreen.notesKey` | Follows its column |
| Send for approval, Save draft | `AddExpenseScreen.sendKey`, `draftKey` | |
| Why refused, and what was saved | `AddExpenseScreen.messageKey`, `savedKey` | |
| A list not read, and try again | `AddExpenseScreen.listMessageKey`, `retryKey` | |
| In the question about a repeated invoice | `AddExpenseScreen.earlierKey`, `saveAnywayKey` | A `ConfirmDialog` |

The project's home has the way in, `HomeScreen.addExpenseKey(id)`. `SupplierPicker` gains its title, `SupplierPicker.mostUsedKey`, while nothing is typed and once something was used.

## API calls

| Call | When |
| --- | --- |
| `GET /projects/{id}/categories/offered?itemType=purchases`, `.../accounts/offered`, `.../payment-methods` | Opening the screen |
| `GET /projects/{id}/items/{itemId}/columns` | Choosing an item |
| `GET /projects/{id}/suppliers/search`, `POST /projects/{id}/suppliers` | Choosing the supplier |
| `POST /projects/{id}/attachments` | The first save with an invoice |
| `POST /projects/{id}/expenses` | Saving or sending; with `confirmDuplicate` once a repeat is confirmed |

## Rules

Tests are in `test/expenses/add_expense_test.dart` and `invoice_figures_test.dart`.

| Rule | Code | Test |
| --- | --- | --- |
| AC-08.1, AC-08.2, AC-08.3: the amounts show as the accountant's, to two decimals | `InvoiceFigures`, `formatMoney` | `invoice_figures_test`; AC-08.1, AC-08.2, AC-08.3 on the screen |
| NFR-04: an amount rounds half up | `formatMoney` | `invoice_figures_test`: the group on it |
| BR-14: no VAT for a supplier not registered or an invoice not taxable | `_hasNoVat` | a supplier not VAT-registered and an invoice not taxable show no VAT |
| BR-01: price times quantity includes VAT | `_figures` | BR-01 |
| Arabic digits count, and an invoice number is sent in Western ones | `parseNumber`, `westernDigits` | what a person types in Arabic digits counts; an invoice number in Arabic digits |
| What was typed is sent, never a figure, with an id made here | `_body` | saving a draft sends what was typed |
| FR-09: the invoice is kept first and named | `_record` | FR-09; a refusal stays on the screen; a picture taken again; a file the API refuses |
| AC-41.1, FR-41: custom columns are drawn, marked and sent | `ColumnValueField`, `ItemColumn.valueToSend` | AC-41.1; FR-41; choosing another item |
| A built-in column follows what Finance made of it | `_asks`, `_requires` | a built-in field Finance made required |
| Open question 3: the shared unit | `Project.entryUnits` | open question 3 |
| Open question 4: Field is offered only what they hold; Finance chooses any | `OfferedAccounts` | open question 4; ChargeAnyAccount; someone who holds nothing |
| AC-40.1: a disabled method is not offered | `_payment` | a disabled payment method |
| BR-24: a payment that differs | `_numbers`, `_body` | BR-24; a payment that does not differ |
| FR-44: Field reaches the sheet and its quick add from the expense (findings row 79) | `_pickSupplier` | findings row 79; Patrol |
| AC-17.1: a repeat shows the earlier entry, and saves only once confirmed | `_askAboutDuplicate` | AC-17.1; BR-33 |
| AC-43.1: the title over what was used most | `SupplierSearch.leadsWithMostUsed` | `supplier_picker_test`: AC-43.1 |
| AC-N03: it fits 360 points wide, in both languages | The screen | `my_account_test`: AC-N03 |

The Patrol journey follows Field from the home through the supplier's quick add to sending for approval.
