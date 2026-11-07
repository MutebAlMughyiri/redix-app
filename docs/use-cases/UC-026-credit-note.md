[Documentation](../README.md) › UC-026

# UC-026: Record a credit note or a deduction

**What it is for:** recording money coming back.
**Who uses it:** whoever enters an expense, which is Finance and Field.
**Issue:** redix-app #44; the API side is redix-api #43. Simplified by redix-api #96 "Simple expense".

## Screens

No screen of its own. On `AddExpenseScreen`, the canvas's **مرتجع** switch. A credit note is typed as a plain amount, and the API keeps it negative. It always names the bill it returns (D13): once a supplier is chosen, the bill is picked from a sheet that says what each has left to return, an older bill by its number and a newer one by its date. Choosing another supplier takes the link away.

A deduction needs no switch of its own: it is a negative amount, and it says why in its notes (D14). The amount's keyboard offers the minus sign, and `parseNumber` reads it with either digits.

| Element | `Key` | Does |
| --- | --- | --- |
| Credit note | `AddExpenseScreen.creditNoteKey` | The switch |
| Original invoice | `AddExpenseScreen.originalInvoiceKey` | Opens the sheet; required for a credit note |
| A bill | `OriginalInvoicePicker.optionKey(entryId)` | Each row of the sheet |

## API calls

`GET /projects/{id}/expenses/creditable?supplierId=` through `CreditableInvoices`, read each time the sheet opens. `POST /projects/{id}/expenses` with `isCreditNote` and `originalEntryId`, or a negative `amount`.

## Rules

Tests are in `test/expenses/add_expense_test.dart`.

| Rule | Code | Test |
| --- | --- | --- |
| AC-14.2, D13: a credit note names the bill it returns and sends a plain amount | `OriginalInvoicePicker`, `_body` | AC-14.2, D13: a credit note names the bill it returns |
| An older bill shows its number, and a new one its date | `CreditableInvoice.label` | an older bill shows its number, and a new one its date |
| Another supplier takes the link away | `_useSupplier` | another supplier takes the link away |
| BR-18: above what is left is blocked with a message | The API's `creditNoteAboveOriginal` | BR-18: a credit note above what is left |
| AC-14.1, D14: a deduction is a negative amount, sent with why in its notes | `parseNumber`, `_body` | AC-14.1, D14: a deduction is a negative amount |
| D14: a deduction with no notes is refused with the API's reason | The API's `deductionNeedsNotes` | D14: a deduction with no notes is refused |
| Fits 360 points wide, in both languages | The screen | `test/account/my_account_test.dart`: AC-N03 |
