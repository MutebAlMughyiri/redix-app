[Documentation](../README.md) › [Use cases](../README.md) › UC-038, UC-039, UC-046

# UC-038, UC-039, UC-046: A file shared from another app

**Purpose:** share an invoice from WhatsApp, the gallery or email, and put it on an expense entered without one, or start a new expense with it.

**Who uses it:** whoever may enter expenses.

Android receives the share through an intent filter on the app's activity. **iPhone needs a Share Extension target, which is not added yet**, findings row 115 "UC-038, a share on an iPhone and on a real phone" says what is missing. No real WhatsApp share has run: the phone's share reaches the app through `InvoiceCapture.shared`, and the tests stand in for it there.

The first screen after signing in continues with the file. The capital movement receipt of AC-49.4 comes with UC-042 "Record a capital movement".

| Rule | Code | Test |
| --- | --- | --- |
| AC-49.1: a shared file opens the attach screen | `_RedixAppState._openShared` | `AC-49.1: a shared file opens the attach screen` |
| AC-49.1: not signed in, sign in comes first and continues with the file | `_RedixAppState._redirect` | `AC-49.1: not signed in, sign in comes first and the attach screen continues with the file` |
| Without a project to enter in, the screen says so | `ShareScreen` | `without a project to enter in, the screen says so` |
| With more than one project, the person chooses | `ShareScreen` | `with more than one project, the person chooses` |
| Leaving lets go of the file | `_RedixAppState._letGoOfShared` | `leaving lets go of the file` |
| AC-49.2: the expense matching the QR code is marked and chosen | `ShareScreen._chooseItem` | `AC-49.2: the expense matching the QR code is marked and chosen` |
| AC-49.3: choosing shows what differs, and that approved goes back | `ShareScreen._differences` | `AC-49.3: choosing shows what differs and that approved goes back` |
| Attaching keeps the file and puts it on the expense | `ShareScreen._attach`, `AttachableEntries.attach` | `attaching keeps the file, puts it on the expense, and lets go of it` |
| AC-49.3: the same invoice on another expense is refused | `ShareScreen._attach` | `AC-49.3: the same invoice on another expense is refused, and the person stays` |
| UC-046: a new expense opens with the shared file and its QR code | `AddExpenseScreen._start` | `UC-046: a new expense opens with the shared file and its QR code, not the camera` |
| AC-49.3: Finance sees the invoice's total and another seller | `ApprovalsScreen._details` | `AC-49.3: the inbox shows what an attached invoice says differently` |
