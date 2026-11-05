[Documentation](../README.md) › UC-026

# UC-026: Record a credit note or a deduction

**What it is for:** recording money coming back.
**Who uses it:** whoever enters an expense, which is Finance and Field.
**Issue:** redix-app #44; the API side is redix-api #43.

## Screens

No screen of its own. On `AddExpenseScreen`, the canvas's **مرتجع** switch under the invoice's number and date. Turned on, every computed figure shows negative, in brackets. The amount is typed as a plain amount, and the API keeps it negative. Once a supplier is chosen, the original invoice can be picked from a sheet that says what each has left to return, or left unlinked. The invoice's rate is then the one shown, and choosing another supplier takes the link away.

A deduction needs no switch of its own: it is a negative amount, under **Without an invoice** with the reason. The amount's keyboard offers the minus sign, and `parseNumber` reads it with either digits. A negative amount with an invoice number is refused, saying what to do.

| Element | `Key` | Does |
| --- | --- | --- |
| Credit note | `AddExpenseScreen.creditNoteKey` | The switch, gone without an invoice |
| Original invoice | `AddExpenseScreen.originalInvoiceKey` | Opens the sheet |
| An invoice, or none | `OriginalInvoicePicker.optionKey` | Each row of the sheet |

## API calls

`GET /projects/{id}/expenses/creditable?supplierId=` through `CreditableInvoices`, read each time the sheet opens. `POST /projects/{id}/expenses` with `isCreditNote` and `originalEntryId`, or a negative `amount`.

## Rules

Tests are in `test/expenses/add_expense_test.dart` and `invoice_figures_test.dart`.

| Rule | Code | Test |
| --- | --- | --- |
| AC-14.2: its own number and date, its figures negative, a plain amount sent | `_figures`, `InvoiceFigures.negated` | AC-14.2; BR-18: a credit note shows every figure negative |
| BR-18: linking is optional, and says what is left | `OriginalInvoicePicker` | BR-18: linking is optional; BR-18: choosing no invoice |
| The rate shown is the invoice's | `_vatPercent` | BR-18: linking is optional |
| Another supplier takes the link away | `_useSupplier` | another supplier takes the link away |
| BR-18: above what is left is blocked with a message | The API's `creditNoteAboveOriginal` | BR-18: a credit note above what is left |
| It cannot be both | `_setCreditNote` | turning on Without an invoice ends the credit note |
| AC-14.1: a deduction is a negative amount, with no VAT | `_figures`, `_hasNoVat` | AC-14.1: a deduction is a negative amount |
| FR-14: with an invoice number it is refused | The API's `deductionNeedsReason` | FR-14: a negative amount with an invoice number |
| Fits 360 points wide, in both languages | The screen | `test/account/my_account_test.dart`: AC-N03 |
