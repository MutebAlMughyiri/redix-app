[Documentation](../README.md) › [Use cases](../README.md) › UC-040 to UC-046

# UC-040 to UC-044, and UC-022's third source: Money that moves without an expense

**Purpose:** see where the money is, compare the accounts with the books, and record what partners put in and take out.

**Who uses it:** whoever may move money enters these. Everyone sees the accounts, the difference, the total capital and their own line.

`ApiObject` now owns reading and changing anything the API owns; `ApiList` is one of those that holds a list.

A partner paying with their own money is a capital movement (redix-api #96, D27), so no account belongs to a partner, and the reconciliation has no "owed to partners" line (redix-api #99).

| Rule | Code | Test |
| --- | --- | --- |
| AC-24.1: the card shows the surplus, the total, and the difference in brackets | `ReconciliationCard` | `AC-24.1: the card shows the surplus, the total, and the difference in brackets` |
| Typing a balance shows the total and the difference, and saving sends each | `ReconcileScreen` | `typing a balance shows the total and the difference, and saving sends each` |
| A balance left empty stops it before it is sent | `ReconcileScreen._save` | `a balance left empty stops it before it is sent` |
| Only whoever moves money enters balances; everyone sees the card | `AccountsScreen._above`, `Project.mayMoveMoney` | `only whoever moves money enters balances, and everyone sees the card` |
| Transfers between accounts are gone: FR-23 and AC-23.1 are retired (Muteb, 8 Nov 2026) | `AccountsScreen` | `transfers between accounts are gone: Accounts offers only the actual balances` |
| AC-27.1: a balance and a share with ten decimals, under the total | `PartnersScreen._row`, `formatShare` | `AC-27.1: each partner shows their balance and a share with ten decimals, under the total` |
| BR-31: a reader has a way in | `ProjectCard`, `PartnersScreen` | `BR-31: a reader has a way in` |
| R1: Partners has no حركة; a partner's money is entered from Add entry (redix-api #101) | `PartnersScreen` | `direct_entry_test.dart`: R1 |
| R3, R5, R13: Finance finds the revenue items, and last the active partners under Partners; R9: anyone else neither | `TablePicker`, `EntryTable`, `TableCategory.isPartners` | `direct_entry_test.dart`: R3, R5, R13; R9; `permission_gates_test.dart`: two gates |
| R2, R7, R11: a contribution with its receipt is sent for approval; with سحب on, a withdrawal | `DirectEntryFields` | `direct_entry_test.dart`: R2, R7, R11; R7 |
| AC-25.1: refused without a receipt it says why and keeps what was typed; paid in cash asks why instead | `DirectEntryFields._receipt` | `direct_entry_test.dart`: two AC-25.1 tests |
| BR-23: a receipt saying another amount warns, and the same amount does not | `DirectEntryFields._receiptDiffers` | `direct_entry_test.dart`: BR-23 |
| R3: revenue is sent for approval on its item and table; an amount that is no number stops it | `DirectEntryFields._record` | `direct_entry_test.dart`: R3; R10 |
| D9: a revenue or partner entry has one button, never a draft | `AddEntryScreen._directEntry` | `direct_entry_test.dart`: D9 |
| R8: Revenue has no New revenue, and keeps New sale | `RevenueScreen` | `direct_entry_test.dart`: R8 |
| R12, AC-49.4: a shared file offers New entry and no capital receipt, and goes with a partner picked in Add entry | `ShareScreen`, `AddEntryScreen` | `direct_entry_test.dart`: R12 |
| R16: Approvals names a partner's entry and its kind, and a revenue entry's item; Purchases leaves them out | `PendingApproval.title`, `kindWordKey` | `approvals_test.dart`: two R16 tests |
| A partner opens to their movements, with receipts and a way to reverse | `MovementsScreen` | `a partner opens to their movements, each with its receipt, and Finance can reverse one` |
| AC-25.3: Finance chooses what becomes of what a partner paid | `ApprovalsScreen._details` | `AC-25.3: Finance chooses what becomes of what a partner paid` |
