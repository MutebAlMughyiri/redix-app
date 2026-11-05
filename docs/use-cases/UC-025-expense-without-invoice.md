[Documentation](../README.md) › UC-025

# UC-025: Save an expense without an invoice

**What it is for:** sending an expense that has no invoice, with the reason.
**Who uses it:** whoever enters an expense, which is Finance and Field.
**Issue:** redix-app #43; the API side is redix-api #42.

## Screens

No screen of its own. A switch on `AddExpenseScreen` under the invoice's place, as the canvas's **بدون فاتورة**. Turned on, the reason takes the invoice's place, and what only an invoice has leaves the form: the camera and files, the number and date, the choice of including VAT, and "not taxable". The payment date shows instead, with no "the payment differs" switch, because there is no invoice for it to differ from. A picture already taken stays in memory, is not sent, and comes back if the switch is turned off.

| Element | `Key` | Does |
| --- | --- | --- |
| Without an invoice | `AddExpenseScreen.withoutInvoiceKey` | The switch |
| Why there is no invoice | `AddExpenseScreen.withoutInvoiceReasonKey` | Required to send or to save |
| Payment date | `AddExpenseScreen.paymentDateKey` | Now also shows without an invoice |

## API calls

`POST /projects/{id}/expenses` with `withoutInvoiceReason` and `paymentDate`, and no `invoiceNumber`, `invoiceDate` or `attachmentId`.

## Rules

Tests are in `test/expenses/add_expense_test.dart`.

| Rule | Code | Test |
| --- | --- | --- |
| AC-09.1: the reason takes the invoice's place, and it is sent with no file | `_withoutInvoice`, `_body` | AC-09.1: without an invoice, the reason takes the place of the invoice |
| AC-09.1: with the reason empty nothing is sent | `_record` | AC-09.1: with the reason empty nothing is sent |
| A picture already taken is not sent | `_record`, `_body` | a picture taken before turning it on is not sent |
| Fits 360 points wide, in both languages | The screen | `test/account/my_account_test.dart`: AC-N03 |
