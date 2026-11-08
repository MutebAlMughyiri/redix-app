[Documentation](../README.md) › [Use cases](../README.md#use-cases) › UC-033, UC-034, UC-035, UC-037

# UC-033, UC-034, UC-035, UC-037: See entries, fix them, and reverse them

**Purpose:** everyone in a project sees its entries, and each person what they entered. An entry is fixed before approval, and reversed after it.

**Who uses it:** everyone in the project reads. Who entered an entry changes it while it is a draft or rejected; whoever holds `manageAnyEntry` changes anything before approval; whoever holds `approveEntries` reverses.

| Element | Key |
| --- | --- |
| On the home, under القيود: the search, the way to all | `HomeScreen.searchEntriesKey`, `entriesKey` |
| The search, and the filters: whose, kind, status, period, clearing them, how many show | `EntriesScreen.searchKey`, `mineKey`, `allKey`, `kindKey(kind)`, `statusFilterKey(wordKey)`, `periodKey`, `clearKey`, `foundKey` |
| A row, where it stands unless approved, and why it was rejected | `EntriesScreen.rowKey`, `statusKey`, `reasonKey` |
| What can be done to it | `EntriesScreen.editKey`, `sendKey`, `reverseKey`; a draft, waiting or rejected entry is deleted by swiping its row, `rowKey(id).swipe`, on القيود and on the home alike (redix-api #102) |
| Reversing | `EntriesScreen.reverseReasonKey`, `reverseSendKey` |
| The reason at the top of the form | `AddEntryScreen.rejectionKey` |
| Share, on an entry's sheet and in the message once it is saved or sent (redix-app #83) | `EntriesScreen.shareKey`; the message's action, `messageKeyOf(wordKey).icon` |
| Where a shared link lands: looking for the entry, and saying it cannot be found | `EntryLinkScreen.loadingKey`, `notFoundKey` |

| Rule | Code | Test |
| --- | --- | --- |
| AC-22.1, R1, R2, R3, R15: the home lists the project's latest five by anyone under القيود, someone else's saying who entered it; it counts none of mine waiting or rejected (Muteb, 7 Nov 2026) | `HomeEntries`, `EntryTile` | `entries_test.dart`: AC-22.1, R1, R2, R3, R15 |
| A row says whether it waits, was rejected, is a draft or was reversed; an approved one says nothing (Muteb, 7 Nov 2026) | `EntryRow.showsStatus`, `EntryTile` | `entries_test.dart`: a row says whether it waits or was rejected |
| While the entries are first read, the home shows a spinner under القيود, and the rows once they come | `HomeEntries`, `HomeScreen.entriesLoadingKey` | `entries_test.dart`: the home shows a spinner under القيود |
| R3, R14: with none of mine the home still lists the project's; with none at all it keeps its heading, search and the way to all | `HomeEntries` | `entries_test.dart`: R3, R14; R14 |
| R4: the search beside القيود opens the list ready to type | `HomeEntries`, `EntriesScreen.startsSearching` | `entries_test.dart`: search, R4 |
| R8, R16: the text finds the item, supplier and amount, Arabic spelling read as one and digits in either script | `EntryFilter.keeps`, `EntryRow.searchText` | `entries_test.dart`: search, R8, R16 |
| R8: a kind and a status keep what holds both; mine keeps mine; clearing shows all | `EntryFilter` | `entries_test.dart`: search, R8: a kind and a status |
| R8: a period keeps the entries dated inside it, both ends included | `EntryFilter.keeps` | `entries_test.dart`: search, R8: a period |
| Everyone sees all entries, and starts on their own | `EntriesScreen` | `entries_test.dart`: everyone sees |
| A draft of their own can be changed, sent or deleted | `_EntryActions` | `entries_test.dart`: a draft of their own |
| What waits offers the field nothing to change, and someone else's neither | `EntryRow.allows` | `entries_test.dart`: what waits for a decision offers the field nothing to change |
| Finance can change what waits, and what someone else entered | `EntryRow.allows` | `entries_test.dart`: Finance can change |
| What is approved is only reversed, and only by whoever decides | `_EntryActions` | `entries_test.dart`: what is approved |
| AC-50.1: reversing asks why, and the entry says it was reversed | `ReverseSheet`, `ProjectEntries.reverse` | `entries_test.dart`: AC-50.1 |
| القيود lists every kind of entry: expenses, revenue and partners' money, each named by its item or partner and saying what it is; only an expense opens in Add entry to change (Muteb, 8 Nov 2026) | `EntryRow.title`, `kindWordKey`, `isExpense` | `direct_entry_test.dart`: No Revenue screen, two tests |
| A swipe deletes an entry with no question, where `EntryRow.allows` lets the user delete it | `EntryListTile`, `SwipeToRemove` | `entries_test.dart`: redix-api #102: a swipe deletes a draft with no question; without Delete entries a bill does not swipe |
| AC-19.1: a rejected entry opens with its reason, and holds what it held | `AddEntryScreen._openEntry` | `entries_test.dart`: the reason shows at the top |
| R12, D10: a contractor payment opens in its contract's table under the title تعديل, and goes back to its own route | `AddEntryScreen._openEntry`, `EntryTables.tableOf` | `entries_test.dart`: R12, D10 |
| Saving goes to that entry, with its id, file and figures | `Expenses.record` | `entries_test.dart`: saving goes to that entry |
| AC-16.2: an offline change arriving after approval says it was not applied | `Outbox`, `WaitingScreen` | `entries_test.dart`: AC-16.2 |
| redix-app #83 R2, R4, R5, R6, R10: an entry's sheet shares it as text alone, in the app's language, each on its own line: what it is · the project; its item, or its partner; the supplier or contractor; the amount; the date; the status; the account; the payment method; who entered it; the notes; and its link last | `EntryShare.textOf`, `linkOf`, `InvoiceCapture.shareText` | `entry_share_test.dart`: R2, R4, R5, R6, R10, in en and in ar |
| R3, R4: every kind shares the same way, a contractor named as the contractor, and a line it has nothing for is left out | `EntryShare.textOf` | `entry_share_test.dart`: R3, R4, for a contractor payment, revenue, a contribution and a withdrawal |
| R1: once the API keeps an entry, its message offers Share, which shares the entry as the list now holds it; one kept on the phone offers nothing | `AddEntryScreen._offerShare`, `EntryShare.shareSaved`, `showMessage` | `add_entry_test.dart`: redix-app #83 R1, and without a network; `direct_entry_test.dart`: redix-app #83 R1 |
| R8: the link of an entry the reader cannot decide, or one no longer waiting, opens its sheet in القيود, saying where it stands | `EntryLinkScreen` | `entry_share_test.dart`: the link, R8, two tests |
| R8: the link grants nothing by itself: signed out, it asks to sign in first and then opens the entry | `RedixApp._redirect`, `EntryLinkScreen.isLink` | `entry_share_test.dart`: R8: the link grants nothing by itself |
| R9: the link of an entry no longer listed, or of a project the reader is not in, says it cannot be found and opens nothing | `EntryLinkScreen` | `entry_share_test.dart`: R9, two tests |
| R9: a link that cannot be read says why and offers to try again, never that the entry is gone | `EntryLinkScreen`, `LoadFailure` | `entry_share_test.dart`: R9: a link that cannot be read |
| R8: signed out with a temporary password, the link opens once the password is changed, since the change returns to sign-in, which decides where a person lands | `ChangePasswordScreen._save`, `RedixApp._redirect` | `entry_share_test.dart`: R8: signed out with a temporary password |
| A finished project says nothing about swiping an entry away | `Project.mayDeleteEntries` | `entries_test.dart`: a finished project says nothing about swiping |

## Not proved

The contractor payment's form opens an entry through the same steps, with no widget test of its own. The journey does not reach these screens yet.

A link tapped in WhatsApp reaches REDIX through the Android manifest's `https` intent filter for `LINK_HOST`, which no widget test runs. It was checked on the HUAWEI on 8 Nov 2026: a link to a made-up entry, opened as a browser opens it, reached REDIX, which said the entry cannot be found. On a phone without REDIX the link opens nothing until go-live (redix-app #83, D6).
