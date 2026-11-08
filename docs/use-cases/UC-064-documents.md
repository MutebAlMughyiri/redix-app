[Documentation](../README.md) › UC-064

# UC-064: Keep a project's documents, any file, in optional groups

**What it is for:** keeping a project's papers with it: drawings, permits, quantities, anything under 25 MB, each under a name, and in a group when one is given (redix-api #92, in place of المخططات).
**Who uses it:** everyone in the project reads and downloads them; whoever manages the project (`manageProject`) keeps and removes them, while the project is open.
**Issue:** redix-app #77; the API side is redix-api #81 and #92.

## Screen

`DocumentsScreen` at `/projects/:projectId/documents`, opened from **Documents** on the project's card ([guide](../guide/documents.md)):

| Element | `Key` | Does |
| --- | --- | --- |
| Add a document | `DocumentsScreen.addKey` | Opens the form; gray without `manageProject` or on a closed project |
| Its name, its group, its file | `DocumentsScreen.nameKey`, `groupKey`, `fileKey` | The form; the group offers the groups already used |
| A document | `DocumentsScreen.documentKey(id)` | Opens it: a picture to zoom into, any other file handed to the phone by its own name |
| A group's heading | `DocumentsScreen.groupHeadingKey(group)` | Documents in no group come first, with no heading |
| Download | `DocumentsScreen.downloadKey(id)` | Keeps the file in the phone's Download folder |
| The red bar | `DocumentsScreen.documentKey(id).bar` | Inside a document's card, for whoever may remove it (redix-app #88) |

## API calls

| Call | When |
| --- | --- |
| `GET /projects/{projectId}/documents` | Opening Documents, and after every answer |
| `POST /projects/{projectId}/documents` | Keeping the document: its file, with its name and group beside it in one request |
| `POST /projects/{projectId}/documents/{documentId}/delete` | A swipe |
| `GET /projects/{projectId}/attachments/{attachmentId}` | Opening or downloading a document |

## Rules and where they live

| Rule | Code | Test |
| --- | --- | --- |
| Everyone opens the documents, those in no group first with no heading, then each group under its name | `DocumentsScreen` | `documents_test.dart`: UC-064: everyone opens the documents |
| A file that is not a picture is handed to the phone by its own name, a PDF included (findings row 158) | `AttachmentScreen`, `FileKind`, `InvoiceCapture.shareFile` | `documents_test.dart`: UC-064: a file that is neither a picture nor a PDF; UC-064: a PDF is handed to the phone by its own name too |
| Any file is kept under a name and a group, sent together; no group is sent empty | `Documents.add` | `documents_test.dart`: UC-064: the manager keeps any file; UC-064: a document with no group |
| A document needs its file | `DocumentsScreen` | `documents_test.dart`: a document with no file is not kept |
| A swipe removes a document with no question, and the list says how; a short swipe springs back (redix-api #102) | `SwipeToRemove` | `documents_test.dart`: redix-api #102 R1, R4; redix-api #102 R5 |
| A closed project shows its documents with no Add and no Remove (AC-04.1) | `Project.mayManageProject` | `documents_test.dart`: AC-04.1: a closed project shows its documents |
