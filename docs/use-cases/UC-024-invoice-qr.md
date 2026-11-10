[Documentation](../README.md) › UC-024

# UC-024: Fill the expense from the e-invoice QR

**What it is for:** avoiding typing what the invoice already carries.
**Who uses it:** whoever enters an expense, each time they take or pick the invoice's picture.
**Issue:** redix-app #42. It has no API issue; the words came with the API's UC-022 and UC-023.

## Screens

No screen of its own, as the canvas draws it: the code is read from the invoice's picture, and what was read shows under it. `InvoiceCapture.qrTextOf` asks the phone's own barcode reader (`mobile_scanner`, reading a file rather than the camera). `InvoiceQr.parse` is plain code: it decodes the base64, walks tag, length and value, and keeps tags 1 to 5, so a newer code's longer tags are not looked at.

The date stays as the invoice wrote it. A code's time usually ends in `Z` whether or not it is truly UTC, and the day a person checks is the one printed.

On `AddEntryScreen` (the rest is in UC-021 and UC-022):

| Element | `Key` | Does |
| --- | --- | --- |
| QR code read | `AddEntryScreen.qrReadKey` | A title over what was read |
| Seller, VAT number | `AddEntryScreen.qrSellerKey`, `qrVatNumberKey` | |
| Date and time | `AddEntryScreen.qrTimeKey` | Also fills the expense's date |
| Total | `AddEntryScreen.qrAmountsKey` | Also fills the total |
| No supplier holds the number | `AddEntryScreen.qrSupplierMissingKey` | |
| Add this supplier | `AddEntryScreen.qrAddSupplierKey` | Opens the quick add with the seller and its number filled; for whoever holds `addSupplier` |
| No QR code could be read | `AddEntryScreen.qrMessageKey` | The fields stay open |

A picture is read; a PDF is not, because the phone's reader takes only pictures.

## API calls

`GET /projects/{id}/suppliers/search` with the VAT number, which answers its one holder. Nothing is sent about the QR code itself. The QR code fills the date, the total and the supplier (redix-api #96, D21); its VAT is read only to tell a real e-invoice's code from any other, and is never shown or sent (D4).

## Rules

Tests are in `test/expenses/invoice_qr_test.dart` and `test/entries/add_entry_qr_test.dart`.

| Rule | Code | Test |
| --- | --- | --- |
| AC-11.1: a code gives the five fields | `InvoiceQr.parse` | `invoice_qr_test`: AC-11.1; a newer code; a code with no padding; the day stays |
| AC-11.1, D21: the date, the total and the supplier fill, and the supplier with that number is chosen | `_readQr`, `QrSummary` | `add_entry_qr_test`: AC-11.1, D21 |
| AC-11.2: anything else is no code; the message shows and the fields stay open | `InvoiceQr.parse`, `_readQr` | `invoice_qr_test`: AC-11.2, twice; `add_entry_qr_test`: AC-11.2 |
| A supplier not in the register is offered a quick add | `_addSupplierFromQr` | `add_entry_qr_test`: supplier not in the register; who cannot add a supplier |
| A picture is read, from the camera or the files; a PDF is not | `_takeFrom` | a PDF is not looked at; a picture from the files is read too; a picture taken again |
| The phone's real barcode reader reads a picture of a made-up invoice's QR code, and it reaches the API | `InvoiceCapture.qrTextOf` | `patrol_test/entries/invoice_capture_test.dart`: the camera hands the screen a picture, and the phone's real reader reads it |

## Not run

The camera is the one part of the phone a test cannot drive, so a QR code has never gone from a real invoice through it. `patrol_test/entries/invoice_capture_test.dart` hands the screen a sharp picture made for the test in its place and proves everything from the picture inward, with the phone's real reader; a picture picked from the phone's own files goes the real way. A photo at an angle, in poor light or with a small code is not proved; whether a whole page's photo reads well enough is what a real phone must show. It is in the findings.
