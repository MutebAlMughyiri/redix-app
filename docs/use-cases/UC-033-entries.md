[Documentation](../README.md) › [Use cases](../README.md#use-cases) › UC-033, UC-034, UC-035, UC-037

# UC-033, UC-034, UC-035, UC-037: See entries, fix them, and reverse them

**Purpose:** everyone in a project sees its entries, and each person what they entered. An entry is fixed before approval, and reversed after it.

**Who uses it:** everyone in the project reads. Who entered an entry changes it while it is a draft or rejected; whoever holds `manageAnyEntry` changes anything before approval; whoever holds `approveEntries` reverses.

| Element | Key |
| --- | --- |
| On the home: how many wait and were rejected, the way to all | `HomeScreen.waitingCountKey`, `rejectedCountKey`, `entriesKey` |
| The filters | `EntriesScreen.mineKey`, `allKey` |
| A row, where it stands, and why it was rejected | `EntriesScreen.rowKey`, `statusKey`, `reasonKey` |
| What can be done to it | `EntriesScreen.editKey`, `sendKey`, `deleteKey`, `reverseKey` |
| Reversing | `EntriesScreen.reverseReasonKey`, `reverseSendKey` |
| The reason at the top of a form | `AddExpenseScreen.rejectionKey`, `ContractorPaymentScreen.rejectionKey` |

| Rule | Code | Test |
| --- | --- | --- |
| AC-22.1: the home counts what waits and what was rejected, and shows the latest | `MyEntriesSummary` | `entries_test.dart`: AC-22.1 |
| Everyone sees all entries, and starts on their own | `EntriesScreen` | `entries_test.dart`: everyone sees |
| A draft of their own can be changed, sent or deleted | `_EntryActions` | `entries_test.dart`: a draft of their own |
| What waits offers the field nothing to change, and someone else's neither | `_EntryActions._mayChange` | `entries_test.dart`: what waits, someone else's |
| Finance can change what waits, and what someone else entered | `_EntryActions._mayChange` | `entries_test.dart`: Finance can change |
| What is approved is only reversed, and only by whoever decides | `_EntryActions` | `entries_test.dart`: what is approved |
| AC-50.1: reversing asks why, and the entry says it was reversed | `_ReverseSheet`, `ProjectEntries.reverse` | `entries_test.dart`: AC-50.1 |
| Deleting asks first | `_EntryActions._askToDelete` | `entries_test.dart`: deleting asks first |
| AC-19.1: a rejected entry opens with its reason, and holds what it held | `AddExpenseScreen._openEntry` | `entries_test.dart`: the reason shows at the top |
| Saving goes to that entry, with its id, file and figures | `Expenses.record` | `entries_test.dart`: saving goes to that entry |
| AC-16.2: an offline change arriving after approval says it was not applied | `Outbox`, `WaitingScreen` | `entries_test.dart`: AC-16.2 |

## Not proved

The contractor payment's form opens an entry through the same steps, with no widget test of its own. The journey does not reach these screens yet.
