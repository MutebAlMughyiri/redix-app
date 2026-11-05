[Documentation](../README.md) › UC-024

# UC-024: Fill the expense from the e-invoice QR

**What it is for:** avoiding typing what the invoice already carries.
**Who uses it:** whoever enters an expense, each time they take or pick the invoice's picture.
**Issue:** redix-app #42. It has no API issue; the words came with the API's UC-022 and UC-023.

## Screens

No screen of its own, as the canvas draws it: the code is read from the invoice's picture, and what was read shows under it. `InvoiceCapture.qrTextOf` asks the phone's own barcode reader (`mobile_scanner`, reading a file rather than the camera). `InvoiceQr.parse` is plain code: it decodes the base64, walks tag, length and value, and keeps tags 1 to 5, so a newer code's longer tags are not looked at.

The date stays as the invoice wrote it. A code's time usually ends in `Z` whether or not it is truly UTC, and the day a person checks is the one printed.

On `AddExpenseScreen` (the rest is in UC-021 and UC-022):

| Element | `Key` | Does |
| --- | --- | --- |
| QR code read | `AddExpenseScreen.qrReadKey` | A title over the five fields |
| Seller, VAT number | `AddExpenseScreen.qrSellerKey`, `qrVatNumberKey` | |
| Date and time | `AddExpenseScreen.qrTimeKey` | Also fills the invoice's date |
| Total and VAT | `AddExpenseScreen.qrAmountsKey` | The total also fills the amount, as including VAT |
| No supplier holds the number | `AddExpenseScreen.qrSupplierMissingKey` | |
| Add this supplier | `AddExpenseScreen.qrAddSupplierKey` | Opens the quick add with the seller and its number filled; for whoever holds `addSupplier` |
| No QR code could be read | `AddExpenseScreen.qrMessageKey` | The fields stay open |
| VAT differs | `AddExpenseScreen.qrVatDiffersKey` | Under the amounts, following them as they change; saving still works |

A picture is read; a PDF is not, because the phone's reader takes only pictures.

## API calls

`GET /projects/{id}/suppliers/search` with the VAT number, which answers its one holder. Nothing is sent about the QR code itself: the API computes the figures from what the fields hold.

## Rules

Tests are in `test/expenses/invoice_qr_test.dart` and `add_expense_qr_test.dart`.

| Rule | Code | Test |
| --- | --- | --- |
| AC-11.1: a code gives the five fields | `InvoiceQr.parse` | `invoice_qr_test`: AC-11.1; a newer code; a code with no padding; the day stays |
| AC-11.1: they fill, and the supplier with that number is chosen | `_readQr`, `QrSummary` | `add_expense_qr_test`: AC-11.1; a QR code sets the amount as including VAT |
| AC-11.2: anything else is no code; the message shows and the fields stay open | `InvoiceQr.parse`, `_readQr` | `invoice_qr_test`: AC-11.2, twice; `add_expense_qr_test`: AC-11.2 |
| A supplier not in the register is offered a quick add | `_addSupplierFromQr` | `add_expense_qr_test`: supplier not in the register; who cannot add a supplier |
| AC-11.3: a VAT more than 0.01 away warns, and saving still works | `InvoiceQr.vatTolerance` | `add_expense_qr_test`: AC-11.3, three times |
| A picture is read, from the camera or the files; a PDF is not | `_takeFrom` | a PDF is not looked at; a picture from the files is read too; a picture taken again |
| The phone's real barcode reader reads a picture of a made-up invoice's QR code, and it reaches the API | `InvoiceCapture.qrTextOf` | `patrol_test/app_test.dart`: the journey hands the screen a picture, and the real reader reads it |

## Not run

The emulator's camera is virtual, so a QR code has never gone from a real invoice through the camera. The journey proves everything from the picture inward, with the phone's real reader on a sharp picture made for the test. A photo at an angle, in poor light or with a small code is not proved; whether a whole page's photo reads well enough is what a real phone must show. It is in the findings.
