[Documentation](../README.md) › UC-027

# UC-027: Record a payment against a contract

**What it is for:** paying a contractor and seeing the effect before saving.
**Who uses it:** whoever holds `recordEntries`, from **إضافة قيد** on the project's home, choosing the contract's table (UC-022).
**Issue:** redix-app #45; the API side is redix-api #44. Simplified by redix-api #96 "Simple expense"; one screen with the purchase since redix-app #84.

## Screens

`AddEntryScreen` once a contract's table is chosen: the contract is the table, so a payment asks no subgroup and goes under its item's general one (redix-app #84, R11). The receipt is optional (D16), and a payment has no tax invoice. The fields every entry has, the file, date, amount, account, method and notes, are UC-022's.

| Element | `Key` | Does |
| --- | --- | --- |
| The contract | `AddEntryScreen.tableKey`, `TablePicker.optionKey(id)` | Its row sits under its item in the table sheet, the disabled ones left out |
| Value, Paid, Remaining after this payment | `AddEntryScreen.valueKey`, `paidKey`, `remainingKey` | An open value shows no remaining |
| Waiting for approval | `pendingKey` | Shows when anything waits, and counts in what remains |
| The bar | `progressKey` | Gone for an open value |
| The alert | `overrunKey` | Shows when this payment goes beyond the value; saving still works |
| Inside, Outside | `insideKey`, `outsideKey`, `outsideExplainKey` | Outside leaves the remaining alone |
| Amount | `amountKey` | Labelled by the item's `amount` column; its keyboard offers a minus sign |
| The receipt | `cameraKey`, `filesKey` | The same `InvoiceSection` as the purchase, named for a receipt |

On a contract's card: `ContractsScreen.pendingKey(id)`.

## API calls

`POST /projects/{id}/entries`, through `EntryRecording.record`, the contract being the table (redix-api #110). `GET /projects/{id}/contracts` gives the figures, and the columns of the contract's item are read once it is chosen.

## Rules

Tests are in `test/entries/add_entry_contract_test.dart`.

| Rule | Code | Test |
| --- | --- | --- |
| R10, R11: a contract's table takes the payment, sent with its contract and no item or subgroup | `AddEntryScreen._body` | R10, R11 |
| AC-12.1: value, paid and what remains show before saving | `ContractFigures` | AC-12.1: choosing a contract |
| AC-07.1: an overrun alerts with (1,000), and is still saved | `Contract.remainingAfter`, `isOverrunBy` | AC-07.1 |
| What waits shows beside what was paid, and counts | `Contract.pending` | what waits for approval; `contracts_test`: BR-10 |
| AC-07.2: an open value has no remaining, bar or alert | `ContractFigures` | AC-07.2 |
| AC-13.1: outside, the remaining does not change | `_isOutside` | AC-13.1 |
| AC-14.1, D14: a deduction is negative, raises what remains, and says why in its notes | `_isDeduction`, `_whatIsWrong` | AC-14.1, D14 |
| D16: a payment is sent with no receipt; a receipt taken is kept and sent | `_record` | D16: a payment is sent with no receipt; a receipt taken is kept and sent |
| A disabled contract is not on offer | `GET /entry-tables` | a disabled contract |
| FR-41: its item's custom columns | `_chooseTable` | FR-41 |
| Who may | `Project.mayEnterExpenses` | who holds no recordEntries; a finished project |
| Fits 360 points wide, in both languages | The screen | `test/account/my_account_test.dart`: AC-N03 |
| The real app against the real API | | `patrol_test/app_test.dart`: the journey pays 35,000 on a contract of 34,000, sees the alert and sends it |
