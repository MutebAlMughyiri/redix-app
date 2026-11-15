[Documentation](../README.md) › [Use cases](../README.md#use-cases) › UC-031, UC-032

# UC-031 and UC-032: Review what waits, and approve or reject it

**Purpose:** Finance sees what waits for a decision, oldest first, with its file, and approves one, approves many, or rejects saying why.

**Who uses it:** whoever holds `approveEntries`, from **Waiting for approval** on the project's home. A finished project shows what waits, with no decision.

| Element | Key |
| --- | --- |
| The way in, on the home | `HomeScreen.approvalsKey` |
| The filters | `ApprovalsScreen.allKey`, `purchasesKey`, `contractorPaymentsKey` |
| An entry's card, and its details line led by «قيد 312» (redix-api #128) | `ApprovalsScreen.cardKey`, `dateKey` |
| Its selection, Approve, Reject and file | `ApprovalsScreen.selectKey`, `approveKey`, `rejectKey`, `fileKey` |
| Why it could not be approved | `ApprovalsScreen.failedKey` |
| Show everything waiting, when a shared link opened one entry (redix-app #83) | `ApprovalsScreen.showAllKey` |
| Approve selected | `ApprovalsScreen.approveSelectedKey` |
| The rejection's quick reasons, reason, send and refusal | `ApprovalsScreen.quickReasonKey`, `reasonKey`, `rejectSendKey`, `rejectMessageKey` |
| A file: picture, any other file, or failure | `AttachmentScreen.pictureKey`, zoomed in `zoomKey`; `openFileKey`, `failedKey` |

| Rule | Code | Test |
| --- | --- | --- |
| Only whoever decides entries has a way in | `ProjectSettingsCard`, `project.may` | `approvals_test.dart`: only whoever decides |
| AC-18.1: what waits shows what Finance needs, in the API's order | `ApprovalsScreen._details` | `approvals_test.dart`: AC-18.1: what waits |
| AC-54.4 (redix-api #128): each row's details line starts with its entry's own «قيد 312», as the entry card's does, then an older bill's number and the date | `ApprovalsScreen._details`, `PendingApproval.numberIn`, `EntryRow.numberOf` | `approvals_test.dart`: redix-api #128, AC-54.4, two tests |
| AC-18.1: a picture opens to zoom into | `AttachmentScreen` | `approvals_test.dart`: AC-18.1: a picture |
| A PDF goes to the phone by its own name, and an unreadable file says so | `AttachmentScreen`, `PendingApproval.fileName` | `approvals_test.dart`: a PDF is handed to the phone by its own name |
| A file that is not a picture, a PDF included, goes to the phone through `InvoiceCapture.shareFile` by its own name; an entry's file, whose name the app is not given, goes as invoice.pdf | `AttachmentScreen`, the attachment route | `documents_test.dart`: UC-064: a PDF is handed to the phone by its own name too |
| A filter shows one kind | `_Filter.keeps`, `ApiListBody.keeps` | `approvals_test.dart`: a filter shows |
| Each filter counts what it keeps, and one that keeps nothing says nothing waits rather than showing a blank page | `_Filter.keeps`, `ApiListBody.keeps` | `approvals_test.dart`: each filter counts what it keeps |
| Approving one sends it, and it leaves | `Approvals.approve` | `approvals_test.dart`: approving one |
| Approve selected sends what was ticked | `_ApprovalsScreenState._approve` | `approvals_test.dart`: Approve selected |
| AC-19.2: what could not be approved stays, saying why | `Approvals.failed` | `approvals_test.dart`: AC-19.2 |
| AC-19.1: rejecting needs a reason | `RejectSheet` | `approvals_test.dart`: AC-19.1 |
| A quick reason fills the field, and rejecting closes | `RejectSheet` | `approvals_test.dart`: a quick reason |
| A finished project offers no decision | `ApprovalsScreen` | `approvals_test.dart`: a finished project |
| redix-app #83 R7, D7: for whoever decides entries, a shared link of one waiting opens Approvals on it alone, with Approve and Reject, everything waiting one tap away and the project's home behind | `EntryLinkScreen`, `ApprovalsScreen.focusEntryId` | `entry_share_test.dart`: R7, D7 |

A contract's document opens the same way, from its dialog.

## On a real phone

`patrol_test/approvals/what_waits_test.dart`, `approve_entries_test.dart` and `reject_entries_test.dart` run this screen on the HUAWEI against the real API. A PDF is handed to the phone's own share sheet by its name, and a double tap on Approve sends one approval.
