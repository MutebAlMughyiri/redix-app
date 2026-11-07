[Documentation](../README.md) › [Use cases](../README.md#use-cases) › UC-033, UC-034, UC-035, UC-037

# UC-033, UC-034, UC-035, UC-037: See entries, fix them, and reverse them

**Purpose:** everyone in a project sees its entries, and each person what they entered. An entry is fixed before approval, and reversed after it.

**Who uses it:** everyone in the project reads. Who entered an entry changes it while it is a draft or rejected; whoever holds `manageAnyEntry` changes anything before approval; whoever holds `approveEntries` reverses.

| Element | Key |
| --- | --- |
| On the home, under القيود: how many of mine wait and were rejected, the search, the way to all | `HomeScreen.waitingCountKey`, `rejectedCountKey`, `searchEntriesKey`, `entriesKey` |
| The search, and the filters: whose, kind, status, period, clearing them, how many show | `EntriesScreen.searchKey`, `mineKey`, `allKey`, `kindKey(kind)`, `statusFilterKey(wordKey)`, `periodKey`, `clearKey`, `foundKey` |
| A row, where it stands, and why it was rejected | `EntriesScreen.rowKey`, `statusKey`, `reasonKey` |
| What can be done to it | `EntriesScreen.editKey`, `sendKey`, `deleteKey`, `reverseKey` |
| Reversing | `EntriesScreen.reverseReasonKey`, `reverseSendKey` |
| The reason at the top of the form | `AddEntryScreen.rejectionKey` |

| Rule | Code | Test |
| --- | --- | --- |
| AC-22.1, R1, R2, R3, R15: the home lists the project's latest five by anyone under القيود, someone else's saying who entered it, and counts what of mine waits and was rejected | `HomeEntries`, `EntryTile` | `entries_test.dart`: AC-22.1, R1, R2, R3, R15 |
| While the entries are first read, the home shows a spinner under القيود, and the rows once they come | `HomeEntries`, `HomeScreen.entriesLoadingKey` | `entries_test.dart`: the home shows a spinner under القيود |
| R3, R14: with none of mine the home still lists the project's; with none at all it keeps its heading, search and the way to all | `HomeEntries` | `entries_test.dart`: R3, R14; R14 |
| R4: the search beside القيود opens the list ready to type | `HomeEntries`, `EntriesScreen.startsSearching` | `entries_test.dart`: search, R4 |
| R8, R16: the text finds the item, supplier and amount, Arabic spelling read as one and digits in either script | `EntryFilter.keeps`, `EntryRow.searchText` | `entries_test.dart`: search, R8, R16 |
| R8: a kind and a status keep what holds both; mine keeps mine; clearing shows all | `EntryFilter` | `entries_test.dart`: search, R8: a kind and a status |
| R8: a period keeps the entries dated inside it, both ends included | `EntryFilter.keeps` | `entries_test.dart`: search, R8: a period |
| Everyone sees all entries, and starts on their own | `EntriesScreen` | `entries_test.dart`: everyone sees |
| A draft of their own can be changed, sent or deleted | `_EntryActions` | `entries_test.dart`: a draft of their own |
| What waits offers the field nothing to change, and someone else's neither | `_EntryActions._mayChange` | `entries_test.dart`: what waits, someone else's |
| Finance can change what waits, and what someone else entered | `_EntryActions._mayChange` | `entries_test.dart`: Finance can change |
| What is approved is only reversed, and only by whoever decides | `_EntryActions` | `entries_test.dart`: what is approved |
| AC-50.1: reversing asks why, and the entry says it was reversed | `_ReverseSheet`, `ProjectEntries.reverse` | `entries_test.dart`: AC-50.1 |
| Deleting asks first | `_EntryActions._askToDelete` | `entries_test.dart`: deleting asks first |
| AC-19.1: a rejected entry opens with its reason, and holds what it held | `AddEntryScreen._openEntry` | `entries_test.dart`: the reason shows at the top |
| R12, D10: a contractor payment opens in its contract's table under the title تعديل, and goes back to its own route | `AddEntryScreen._openEntry`, `EntryTables.tableOf` | `entries_test.dart`: R12, D10 |
| Saving goes to that entry, with its id, file and figures | `Expenses.record` | `entries_test.dart`: saving goes to that entry |
| AC-16.2: an offline change arriving after approval says it was not applied | `Outbox`, `WaitingScreen` | `entries_test.dart`: AC-16.2 |

## Not proved

The contractor payment's form opens an entry through the same steps, with no widget test of its own. The journey does not reach these screens yet.
