[Documentation](../README.md) › [Use cases](../README.md) › UC-040 to UC-046

# UC-040 to UC-044, and UC-022's third source: Money that moves without an expense

**Purpose:** see where the money is and move it, compare the accounts with the books, and record what partners put in and take out.

**Who uses it:** whoever may move money enters these. Everyone sees the accounts, the difference, the total capital and their own line.

`ApiObject` now owns reading and changing anything the API owns; `ApiList` is one of those that holds a list.

A partner paying with their own money is a capital movement (redix-api #96, D27), so no account belongs to a partner, and the reconciliation has no "owed to partners" line (redix-api #99).

| Rule | Code | Test |
| --- | --- | --- |
| AC-24.1: the card shows the surplus, the total, and the difference in brackets | `ReconciliationCard` | `AC-24.1: the card shows the surplus, the total, and the difference in brackets` |
| Typing a balance shows the total and the difference, and saving sends each | `ReconcileScreen` | `typing a balance shows the total and the difference, and saving sends each` |
| A balance left empty stops it before it is sent | `ReconcileScreen._save` | `a balance left empty stops it before it is sent` |
| Only whoever moves money enters balances or a transfer; everyone sees the card | `AccountsScreen._above`, `Project.mayMoveMoney` | `only whoever moves money enters balances or a transfer, and everyone sees the card` |
| AC-23.1: a transfer sends both accounts, the amount, the date and the file | `TransferScreen` | `AC-23.1: a transfer sends both accounts, the amount, the date and the file` |
| The latest transfers show, and Finance can reverse one | `AccountsScreen._transferRow` | `the latest transfers show, and Finance can reverse one` |
| AC-27.1: a balance and a share with ten decimals, under the total | `PartnersScreen._row`, `formatShare` | `AC-27.1: each partner shows their balance and a share with ten decimals, under the total` |
| BR-31: a reader has a way in, and no way to enter a movement | `ProjectCard`, `PartnersScreen` | `BR-31: a reader has a way in, and no way to enter a movement` |
| A partner opens to their movements, with receipts and a way to reverse | `MovementsScreen` | `a partner opens to their movements, each with its receipt, and Finance can reverse one` |
| AC-25.1: a movement sends its receipt; refused without one, it says why | `CapitalMoveScreen` | `AC-25.1: a movement sends its receipt`, `AC-25.1: refused without a receipt, it says why and stays` |
| AC-25.1: paid in cash asks why, not for a receipt | `CapitalMoveScreen._receiptSection` | `AC-25.1: paid in cash asks why, not for a receipt` |
| BR-23: a receipt saying another amount warns | `CapitalMoveScreen._receiptDiffers` | `BR-23: a receipt saying another amount warns` |
| A settlement fills in all the partner holds | `CapitalMoveScreen._chooseType` | `a settlement fills in all the partner holds` |
| AC-26.1: a carry asks for no receipt, and sends each side | `CapitalMoveScreen._carry` | `AC-26.1: a carry asks for no receipt, and sends each side`, `a carry from a project is the same route from the other side` |
| AC-25.3: Finance chooses what becomes of what a partner paid | `ApprovalsScreen._details` | `AC-25.3: Finance chooses what becomes of what a partner paid` |
| AC-49.4: Finance may use a shared file as a capital receipt; Field may not | `ShareScreen` | `AC-49.4: Finance may use a shared file as a capital movement receipt, and Field may not`, `AC-49.4: Field sees no capital movement option` |
