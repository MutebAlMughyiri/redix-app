[Documentation](../README.md) › [Use cases](../README.md) › UC-040 to UC-046

# UC-040 to UC-044, and UC-022's third source: Money that moves without an expense

**Purpose:** see where the money is, compare the accounts with the books, and record what partners put in and take out.

**Who uses it:** whoever may move money enters these. Everyone sees the accounts, the difference, the total capital and their own line.

`ApiObject` now owns reading and changing anything the API owns; `ApiList` is one of those that holds a list.

A partner paying with their own money is a capital movement (redix-api #96, D27), so no account belongs to a partner, and the reconciliation has no "owed to partners" line (redix-api #99).

| Rule | Code | Test |
| --- | --- | --- |
| AC-24.1: the card shows the surplus, the total, and the difference in brackets | `ReconciliationCard` | `AC-24.1: the card shows the surplus, the total, and the difference in brackets` |
| Pulling Accounts down reads the card above the accounts again; there is no Refresh button (Muteb, 9 Nov 2026) | `AccountsScreen` (`alsoRefresh`) | `Muteb, 9 Nov 2026: there is no Refresh button, and pulling the list down reads the card above the accounts again` |
| Typing a balance shows the total and the difference, and saving sends each | `ReconcileScreen` | `typing a balance shows the total and the difference, and saving sends each` |
| A balance left empty stops it before it is sent | `ReconcileScreen._save` | `a balance left empty stops it before it is sent` |
| Only whoever moves money enters balances; everyone sees the card | `AccountsScreen._above`, `Project.mayMoveMoney` | `only whoever moves money enters balances, and everyone sees the card` |
| Transfers between accounts are gone: FR-23 and AC-23.1 are retired (Muteb, 8 Nov 2026) | `AccountsScreen` | `transfers between accounts are gone: Accounts offers only the actual balances` |
| AC-27.1: a balance and a share with ten decimals, under the total | `PartnersScreen._row`, `formatShare` | `AC-27.1: each partner shows their balance and a share with ten decimals, under the total` |
| Pulling Partners down reads the capital above the partners again; there is no Refresh button (Muteb, 9 Nov 2026) | `PartnersScreen` (`alsoRefresh`) | `Muteb, 9 Nov 2026: there is no Refresh button, and pulling the list down reads the capital above the partners again` |
| BR-31: a reader has a way in | `ProjectSettingsCard`, `PartnersScreen` | `BR-31: a reader has a way in` |
| R1: Partners has no حركة; a partner's money is entered from Add entry (redix-api #101) | `PartnersScreen` | `one_entry_test.dart`: R1 |
| R3, R5, R13, redix-api #109: Finance finds the revenue items, and the partners as the tables of رأس المال, an item like any other, since capital is revenue (BR-06); the search finds رأس المال by its name in either spelling; R9: anyone else neither | `TablePicker`, `EntryTable` | `one_entry_test.dart`: R3, R5, R13; redix-api #109 (the search); R9; `permission_gates_test.dart`: two gates |
| A contribution with its receipt is sent for approval through the one route, asking no payment method; with «سحب مبلغ» chosen in «نوع الحركة», رأس المال's list column, a withdrawal (redix-api #110, #129) | `AddEntryScreen._itemsOwnFields`, `ColumnValueField` | `one_entry_test.dart`: R8; R7 |
| A contribution is one amount, sent as it is, its receipt optional like every entry's: no "paid in cash", no reason, no second amount and no warning (Muteb, 8 Nov 2026; AC-25.1 and BR-23 retired) | `AddEntryScreen`, `EntryFile` | `one_entry_test.dart`: Muteb, 8 Nov 2026: a contribution is one amount |
| R3: revenue is sent for approval on its item and table; an amount that is no number stops it | `AddEntryScreen._body`, `AddEntryScreen._whatIsWrong` | `one_entry_test.dart`: R3; R10 |
| A revenue or partner entry is saved as a draft or sent, kept on the phone without a network, and fixed after a rejection, as an expense is; redix-api #101 D9 is reversed (redix-api #110) | `AddEntryScreen`, `EntryRecording`, `EntryKind.recordedWith` | `one_entry_test.dart`: R8, D6; R8, D12; R14, two tests |
| R12, AC-49.4: a shared file offers New entry and no capital receipt, and goes with a partner picked in Add entry | `ShareScreen`, `AddEntryScreen` | `one_entry_test.dart`: R12 |
| R16: Approvals names a partner's entry and its kind, and a revenue entry's item; Purchases leaves them out | `PendingApproval.title`, `kindWordKey` | `approvals_test.dart`: two R16 tests |
| A partner opens to their movements, with receipts; whoever holds the removal swipes one away, and the capital is read again (redix-api #119) | `MovementsScreen`, `SwipeToRemove` | `a partner opens to their movements, each with its receipt`; `redix-api #119: whoever holds the removal swipes a movement away` |
