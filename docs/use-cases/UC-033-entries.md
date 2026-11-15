[Documentation](../README.md) › [Use cases](../README.md#use-cases) › UC-033, UC-034, UC-035, UC-037

# UC-033, UC-034, UC-035, UC-037: See entries, fix them, and remove an approved one

**Purpose:** everyone in a project sees its entries, and each person what they entered. An entry is fixed before approval; after it, an approved one is removed softly by its own permission (redix-api #119). Nothing is reversed.

**Who uses it:** everyone in the project reads. Who entered an entry changes it while it is a draft or rejected; whoever holds `manageAnyEntry` changes anything before approval; whoever holds `removeApprovedEntries`, which nobody holds until it is ticked, removes an approved one.

| Element | Key |
| --- | --- |
| On the home, under القيود: the search, the way to all | `HomeScreen.searchEntriesKey`, `entriesKey` |
| The search, and the filters: whose, kind, status, period, «رقم القيد», clearing them, how many show | `EntriesScreen.searchKey`, `mineKey`, `allKey`, `kindKey(kind)`, `statusFilterKey(wordKey)`, `periodKey`, `numberKey` (its dialog `NameDialog.nameKey`, `ChangeDialog.saveKey`), `clearKey`, `foundKey` |
| A row's details line, led by «قيد 312» (redix-api #128) | `EntriesScreen.detailsKey(id)` |
| A row, where it stands by its frame's color alone: teal a draft, orange waiting, red rejected, plain once approved (redix-app #90; Muteb, 9 Nov 2026) | `EntriesScreen.rowKey`, `rowKey(id).card` |
| An entry read only (redix-app #90): where it stands, and what can be done to it | `AddEntryScreen.statusKey`, `changeKey`, `cannotChangeKey`, `sendDraftKey`, `removeKey`; a draft, waiting or rejected entry is deleted by swiping its row, `rowKey(id).swipe`, on القيود and on the home alike (redix-api #102) |
| Every file an entry read only holds, each opening it (redix-app #115, AC-46.10g) | `AddEntryScreen.fileKey(attachmentId)`, its `.icon` and `.title` |
| The reason at the top of the form | `AddEntryScreen.rejectionKey` |
| Share, in an entry's title bar read only and in the message once it is saved or sent (redix-app #83) | `AddEntryScreen.shareKey`; the message's action, `messageKeyOf(wordKey).icon` |
| Where a shared link lands: looking for the entry, and saying it cannot be found | `EntryLinkScreen.loadingKey`, `notFoundKey` |

| Rule | Code | Test |
| --- | --- | --- |
| AC-22.1, R1, R2, R3, R15: the home lists the project's latest five by anyone under القيود, someone else's saying who entered it; it counts none of mine waiting or rejected (Muteb, 7 Nov 2026) | `LatestEntries`, `EntryCard` | `entries_test.dart`: AC-22.1, R1, R2, R3, R15 |
| A row says where it stands by its frame's color alone, with no status words and no reason: teal a draft, orange waiting, red rejected, plain once approved; the entry's page says the status and the reason (Muteb, 9 Nov 2026) | `EntryStatus.color`, `SwipeToRemove.side` | `entries_test.dart`: Muteb, 9 Nov 2026: a row says where it stands by its frame alone |
| While the entries are first read, the home shows a spinner under القيود, and the rows once they come | `LatestEntries`, `HomeScreen.entriesLoadingKey` | `entries_test.dart`: the home shows a spinner under القيود |
| R3, R14: with none of mine the home still lists the project's; with none at all it keeps its heading, search and the way to all | `LatestEntries` | `entries_test.dart`: R3, R14; R14 |
| R4: the search beside القيود opens the list ready to type | `LatestEntries`, `EntriesScreen.startsSearching` | `entries_test.dart`: search, R4 |
| R8, R16: the text finds the item, supplier and amount, Arabic spelling read as one and digits in either script | `EntryFilter.keeps`, `EntryRow.searchText` | `entries_test.dart`: search, R8, R16 |
| R8: a kind and a status keep what holds both; mine keeps mine; clearing shows all | `EntryFilter` | `entries_test.dart`: search, R8: a kind and a status |
| R8: a period keeps the entries dated inside it, both ends included | `EntryFilter.keeps` | `entries_test.dart`: search, R8: a period |
| Everyone sees all entries, and starts on their own | `EntriesScreen` | `entries_test.dart`: everyone sees |
| Tapping an entry opens it read only, its photo and every value as it was filled, with no way to type or take another file; تعديل turns it into the form, keeping the photo, and saving sends the file it holds no second time (redix-app #90) | `AddEntryScreen` (`isReading`), `Attachments.read`, `EntryFile.showKept`, `InvoiceSection.isReading` | `entries_test.dart`: redix-app #90: a tap opens the entry read only; the reason shows at the top; saving goes to that entry |
| AC-46.10g, R9, D7 (redix-app #115): an entry read only lists every file it holds, the oldest first, each its role's word and the day it was sent, «فاتورة · 15/11/2026»; a tap opens it in `AttachmentScreen`, as a file opens anywhere in the app; an entry being changed lists none, as Add entry shows its own file alone | `AddEntryScreen._files`, `SavedEntry.attachments`, `EntryAttachment`, `EntryAttachmentRole` | `entries_test.dart`: redix-app #115 AC-46.10g, three tests |
| Whoever approves finds اعتماد beside تعديل on a waiting entry read only; approving there approves it as Approvals does and goes back, a refusal for that entry says why and keeps it open; it shows grayed for whoever may not approve, and no draft or approved entry offers it. Approvals and its card stay as they are (Muteb, 9 Nov 2026) | `AddEntryScreen._approve`, `Approvals.approve` | `entries_test.dart`: Muteb, 9 Nov 2026, four tests |
| A draft of their own can be changed, sent or deleted | `AddEntryScreen._readingActions` | `entries_test.dart`: a draft of their own |
| What waits offers the field تعديل grayed, saying why, and someone else's too (redix-app #90, D4) | `EntryRow.allows`, `AddEntryScreen._readingActions` | `entries_test.dart`: redix-app #90 D4, two tests |
| Finance can change what waits, and what someone else entered | `EntryRow.allows` | `entries_test.dart`: Finance can change |
| What is approved does not change: its تعديل is grayed, saying so; حذف removes it softly, shown only to whoever holds the removal, approving entries or not, and a removal being sent cannot be sent again (redix-api #119) | `AddEntryScreen._readingActions`, `OpenedEntry.remove` | `entries_test.dart`: redix-api #119, five tests |
| AC-50.1: an approved entry swipes away for whoever holds the removal, and shows no red bar to anyone else | `EntryRow.mayRemoveIn`, `SwipeableEntryCard` | `entries_test.dart`: redix-api #119: an approved entry swipes away |
| القيود lists every kind of entry: expenses, revenue and partners' money, each named by its item or partner and saying what it is; any of them opens in Add entry to change or fix, for whoever may enter its table (redix-api #110) | `EntryRow.title`, `kindWordKey`, `EntryKind.recordedWith` | `one_entry_test.dart`: No Revenue screen; R14, two tests |
| A swipe deletes an entry once confirmed in its row (redix-api #119), where `EntryRow.allows` lets the user delete it | `SwipeableEntryCard`, `SwipeToRemove` | `entries_test.dart`: redix-api #102: a swipe deletes a draft once confirmed in its row (redix-api #119); without Delete entries a bill does not swipe |
| AC-19.1: a rejected entry opens with its reason, and holds what it held | `AddEntryScreen._openEntry` | `entries_test.dart`: the reason shows at the top |
| R12, D10: a contractor payment opens in its contract's table under the title تعديل, and goes back to its own route | `AddEntryScreen._openEntry`, `EntryTables.tableOf` | `entries_test.dart`: R12, D10 |
| Saving goes to that entry, with its id, file and figures | `EntryRecording.record` | `entries_test.dart`: saving goes to that entry |
| AC-16.2: an offline change arriving after approval says it was not applied | `Outbox`, `WaitingScreen` | `entries_test.dart`: AC-16.2 |
| redix-app #83 R2, R4, R5, R6, R10: an entry's sheet shares it as text alone, in the app's language, each on its own line: what it is · the project; its item, or its partner; the supplier or contractor; the amount; the date; the status; the account; the payment method; who entered it; the notes; and its link last | `EntryShare.textOf`, `linkOf`, `InvoiceCapture.shareText` | `entry_share_test.dart`: R2, R4, R5, R6, R10, in en and in ar |
| R3, R4: every kind shares the same way, a contractor named as the contractor, and a line it has nothing for is left out | `EntryShare.textOf` | `entry_share_test.dart`: R3, R4, for a contractor payment, revenue, a contribution and a withdrawal |
| A row that a swipe would remove shows a red bar inside its frame, along the edge the swipe starts from; a row that would not move shows none, and every removable row has the same frame (redix-app #88) | `SwipeToRemove` | `swipe_to_remove_test`: the bar shows only where it may be removed, inside the card, on the side the language puts it; `entries_test`: a draft has the bar, a finished project none |
| R1: once the API keeps an entry, its message offers Share, which shares the entry as the list now holds it; one kept on the phone offers nothing | `AddEntryScreen._offerShare`, `EntryShare.shareSaved`, `showMessage` | `add_entry_test.dart`: redix-app #83 R1, and without a network; `one_entry_test.dart`: redix-app #83 R1 |
| R8: the link of an entry the reader cannot decide, or one no longer waiting, opens it read only, saying where it stands | `EntryLinkScreen` | `entry_share_test.dart`: the link, R8, two tests |
| R8: the link grants nothing by itself: signed out, it asks to sign in first and then opens the entry | `RedixApp._redirect`, `EntryLinkScreen.isLink` | `entry_share_test.dart`: R8: the link grants nothing by itself |
| R9: the link of an entry no longer listed, or of a project the reader is not in, says it cannot be found and opens nothing | `EntryLinkScreen` | `entry_share_test.dart`: R9, two tests |
| R9: a link that cannot be read says why and offers to try again, never that the entry is gone | `EntryLinkScreen`, `LoadFailure` | `entry_share_test.dart`: R9: a link that cannot be read |
| R8: signed out with a temporary password, the link opens once the password is changed, since the change returns to sign-in, which decides where a person lands | `ChangePasswordScreen._save`, `RedixApp._redirect` | `entry_share_test.dart`: R8: signed out with a temporary password |
| A finished project says nothing about swiping an entry away | `Project.mayDeleteEntries` | `entries_test.dart`: a finished project says nothing about swiping |
| AC-54.4, D5 (redix-api #128): every card's details line, on the home and on القيود, starts with «قيد 312», its «رقم القيد»; the entry's page is titled «قيد 312», «قيد» until it answers | `EntryRow.numberIn`, `EntryCard`, `AddEntryScreen._title` | `entries_test.dart`: redix-api #128, AC-54.4, two tests; `one_entry_test.dart`: No Revenue screen |
| AC-54.5, D4: the «رقم القيد» chip asks the number in the one-field dialog on a number keyboard, digits in either script; set, it says «رقم القيد: 312», keeps that entry alone with every other filter, and clearing, or saving it empty, keeps every number; a number no entry the person may see has lists nothing | `EntriesScreen._askNumber`, `EntryFilter.number`, `SearchedEntries.query`, `NameDialog.keyboardType` | `entries_test.dart`: search, redix-api #128, three tests |
| AC-54.7: an entry waiting on the phone shows no number; it shows the one the API gave once it is kept there | `WaitingScreen`, `EntryRow.number` | `entries_test.dart`: redix-api #128, AC-54.7 |

## On a real phone

`patrol_test/entries/entries_list_test.dart` finds an entry by its «رقم القيد», reads it on its card and in its page's title, and finds nothing by the number of another's draft (redix-api #128; written, not yet run). `patrol_test/entries/open_and_change_test.dart` opens every kind of entry on the HUAWEI, the contractor payment's included, and `patrol_test/money/contract_figures_test.dart` opens saved payments to check their contract's figures. `patrol_test/entries/share_entry_test.dart` shares an entry to the phone's Notepad and reads the text back.

A link tapped in WhatsApp reaches REDIX through the Android manifest's `https` intent filter for `LINK_HOST`, which no widget test runs. It was checked on the HUAWEI on 8 Nov 2026: a link to a made-up entry, opened as a browser opens it, reached REDIX, which said the entry cannot be found. On a phone without REDIX the link opens nothing until go-live (redix-app #83, D6).
