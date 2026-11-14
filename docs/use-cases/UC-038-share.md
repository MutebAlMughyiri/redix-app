[Documentation](../README.md) › [Use cases](../README.md) › UC-038, UC-039, UC-046

# UC-038, UC-039, UC-046: A file shared from another app

**Purpose:** share an invoice from WhatsApp, the gallery or email, and put it on any entry the person may handle, found in القيود's list and its search, an approved one too, beside the files it has (redix-app #115); or start a new entry with it. Attaching puts only the file on the entry: its figures and its status stay, an approved one included (redix-api #96, D15).

**Who uses it:** whoever may enter expenses.

Android receives the share through an intent filter on the app's activity. **iPhone needs a Share Extension target, which is not added yet**, findings row 115 "UC-038, a share on an iPhone and on a real phone" says what is missing. No real WhatsApp share has run: the phone's share reaches the app through `InvoiceCapture.shared`, and the tests stand in for it there.

The first screen after signing in continues with the file. The capital movement receipt of AC-49.4 comes with UC-042 "Record a capital movement".

| Rule | Code | Test |
| --- | --- | --- |
| AC-49.1, AC-46.10b: a shared file opens the share screen with the file and the project | `_RedixAppState._openShared` | `AC-49.1, AC-46.10b, AC-46.10c, D3: a shared file opens the share screen` |
| AC-49.1: not signed in, sign in comes first and continues with the file | `_RedixAppState._redirect` | `AC-49.1: not signed in, sign in comes first and the share screen continues with the file` |
| Without a project to enter in, the screen says so | `ShareScreen` | `without a project to enter in, the screen says so` |
| With more than one project, the person chooses, and the list is the project chosen | `ShareScreen._chooseProject` | `with more than one project, the person chooses, and the list is the project chosen` |
| Leaving lets go of the file | `_RedixAppState._letGoOfShared` | `leaving lets go of the file` |
| AC-46.10c, D3, D6 (redix-app #115): the middle is القيود's own list with its search, asking the API only the entries a file can go on (`attachable`); the table step is gone | `ShareScreen._body`, `SearchedEntries.open(attachable:)`, `EntryFilter.attachable` | `AC-49.1, AC-46.10b, AC-46.10c, D3`; `R3, D3: what is typed in the search is asked of the API` |
| AC-49.2, D4: the entry the QR code matches is pinned over the list, saying «يطابق الفاتورة», and chosen; the list does not hold it twice; without a code nothing is asked or chosen | `ShareScreen._pinned`, `_findMatches`, `AttachableEntries.findFor` | `AC-49.2, D4: the entry the QR code matches is pinned`; `without a QR code nothing is pinned or chosen` |
| AC-49.3: choosing shows what differs from the QR code, its amount or its supplier's VAT number | `ShareScreen._differences`, `EntryRow.supplierVatNumber` | `AC-49.3: choosing an entry from the list shows what differs from the QR code` |
| AC-46.10a, D15: attaching keeps the file, puts it on the entry, an approved one too, names the entry in the bar (`share.attached`), and lets go of the file | `ShareScreen._attach`, `AttachableEntries.attach` | `AC-46.10a, D15: attaching to an approved entry` |
| BR-22, G1: a file already on another entry is refused, and the person stays | `ShareScreen._attach` | `BR-22, G1: a file already on another entry is refused` |
| UC-046: a new entry opens with the shared file and its QR code | `AddEntryScreen._start` | `UC-046: a new expense opens with the shared file and its QR code, not the camera` |

Who may attach, which entries take a file, and that an entry with files takes another beside them (AC-46.10e, AC-46.10f) are the API's: `InvoiceAttachEndpoints.AttachableBy` and `EntryChanges.MayHandle`, proved by redix-api's `InvoiceAttachTests`. `patrol_test/sharing/shared_file_test.dart` shares a made-up invoice into the app on the HUAWEI (written for redix-app #115, not yet run).

**Not built yet:** AC-46.10g, the entry's page showing every file it holds (R9, D7): the page shows its first file, as before; see redix-app #115's decisions.
