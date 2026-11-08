[Documentation](../README.md) › UC-021

# UC-021: Capture the invoice with the camera

**What it is for:** photographing a paper invoice so it is readable and small, and keeping a contract's document.
**Who uses it:** whoever may enter an expense, from the project's home. Whoever holds `manageSettings` adds a contract's document.
**Issue:** redix-app #40; the API side is redix-api #39.

## Screens

The picture sits at the top of every new entry, whatever its table, as the canvas's `AddExpense.dc.html` draws it, and stays there when a table is picked. The camera opens only when asked (Muteb, 8 Nov 2026). The phone's own document scanner (`cunning_document_scanner`) finds the invoice's edges and crops it, so the app draws no camera and no crop of its own. A picture of 1 MB or more is made smaller in `compressedPicture`, and one already smaller stays as it is. The rest of the screen is UC-022 "Enter the expense details".

The project's home, `HomeScreen`:

| Element | `Key` | Does |
| --- | --- | --- |
| إضافة قيد | `HomeScreen.addEntryKey(id)` | Opens the screen below, while the project runs, for whoever may enter (UC-022) |

`AddEntryScreen` at `/projects/:projectId/entries/new`:

| Element | `Key` | Does |
| --- | --- | --- |
| Take a picture, or Take again | `AddEntryScreen.cameraKey` | Opens the camera, which also opens by itself when the screen does |
| Pick from files | `AddEntryScreen.filesKey` | Opens the phone's files for a JPEG, a PNG or a PDF |
| The picture | `AddEntryScreen.invoicePictureKey` | |
| The name of a PDF, or what goes here | `AddEntryScreen.invoiceNameKey` | |
| Why the last try gave no file | `AddEntryScreen.invoiceMessageKey` | |

The contract's dialog, `ContractDialog` (UC-020):

| Element | `Key` | Does |
| --- | --- | --- |
| A document | `ContractsScreen.documentKey(id)` | Its name; a document stays once attached |
| Add a document | `ContractsScreen.addDocumentKey` | Picks a file and keeps it at once; the contract names it on save |
| Why a document was not kept | `ContractsScreen.documentMessageKey` | |

`InvoiceCapture` is the one place that touches the camera and the files. `RedixApp` takes it, so tests stand in for hardware they do not have.

## API calls

| Call | When |
| --- | --- |
| `POST /projects/{id}/attachments` | Keeping a contract's document, and from UC-022 the invoice |
| `POST /projects/{id}/contracts`, `.../{contractId}` with `attachmentIds` | Saving a contract with new documents |

## Rules

| Rule | Code | Test |
| --- | --- | --- |
| FR-10: the camera opens only when asked, and its picture stays on the screen (Muteb, 8 Nov 2026) | `AddEntryScreen`, `EntryFile` | `add_entry_invoice_test`: FR-10 (Muteb, 8 Nov 2026); `one_entry_test`: Add entry never opens the camera by itself, and the photo stays where it was when a table is picked |
| FR-10: the scanner finds and crops the invoice | `InvoiceCapture.fromCamera`, by the phone's scanner | Not run: see below |
| NFR-06, AC-10.1: the file is under 1 MB | `compressedPicture` | `picture_compression_test`: a photo comes back under 1 MB |
| A picture at most 2000 pixels long stays readable | `compressedPicture` | `picture_compression_test`; the reading itself is not run: see below |
| A picture already under 1 MB is untouched | `compressedPicture` | `picture_compression_test` |
| No camera permission: the message says so, and the files stay offered | `InvoiceCapture.fromCamera`, `InvoiceSection` | `add_entry_invoice_test`: no camera permission |
| Going back keeps what was there | `AddEntryScreen` | `add_entry_invoice_test`: going back |
| A contract's dialog shows its documents; a picked one is kept and named on save, and a refused one says why | `ContractDialog` | `contracts_test`: the dialog shows a contract's documents; a document the API refuses |

## Not run

The emulator's camera is virtual and its scanner is a Google Play service, so a real invoice has never gone through the camera, the crop or the compression. AC-10.1's visual check on 10 sample invoices needs Muteb's invoices and eyes. Both are in the findings.
