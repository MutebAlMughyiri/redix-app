[Documentation](../README.md) › UC-027

# UC-027: Record a payment against a contract

**What it is for:** paying a contractor and seeing the effect before saving.
**Who uses it:** whoever holds `recordEntries`, from **Contractor payment** on the project's home, the second of the canvas's two ways in.
**Issue:** redix-app #45; the API side is redix-api #44. Simplified by redix-api #96 "Simple expense".

## Screens

`ContractorPaymentScreen`, from the canvas's `ContractorPayment.dc.html`. The camera does not open by itself: the canvas draws two buttons, and a deduction has no receipt. The receipt is optional (D16), and a payment has no tax invoice.

| Element | `Key` | Does |
| --- | --- | --- |
| Title, project | `ContractorPaymentScreen.titleKey`, `projectNameKey` | |
| Contract | `contractKey`, `ContractPicker.optionKey(id)` | Opens a sheet of the active contracts |
| A subgroup | `subgroupKey(id)` | Shown when the contract's item has named ones |
| Value, Paid, Remaining after this payment | `valueKey`, `paidKey`, `remainingKey` | An open value shows no remaining |
| Waiting for approval | `pendingKey` | Shows when anything waits, and counts in what remains |
| The bar | `progressKey` | Gone for an open value |
| The alert | `overrunKey` | Shows when this payment goes beyond the value; saving still works |
| Amount, Date | `amountKey`, `dateKey` | The amount's keyboard offers a minus sign |
| Inside, Outside | `insideKey`, `outsideKey`, `outsideExplainKey` | Outside leaves the remaining alone |
| Which account and how | `PaymentChoices.accountKey(id)`, `paymentMethodKey(id)`, `noAccountKey` | The same widget as the purchase |
| The receipt | `receiptKey`, `cameraKey`, `filesKey` | The same `InvoiceSection` as the purchase; gone while the amount is negative |
| Notes | `notesKey` | A deduction says why here (D14) |
| Send, Save draft | `sendKey`, `draftKey` | |
| Why it was refused, and that it was saved | `messageKey`, `savedKey` | |

On the home: `HomeScreen.contractorPaymentKey(id)`. On a contract's card: `ContractsScreen.pendingKey(id)`.

## API calls

`POST /projects/{id}/contractor-payments`, through `Expenses.recordContractorPayment`. `GET /projects/{id}/contracts`, `accounts/offered`, `payment-methods`, read at once with `ApiList.loadOnOpen`, and the columns of the contract's item once it is chosen.

## Rules

Tests are in `test/contractor_payments/contractor_payment_screen_test.dart`.

| Rule | Code | Test |
| --- | --- | --- |
| The contract's item's named subgroups are offered, and the choice is sent | `ContractorPaymentScreen._subgroupChoice` | a payment goes under the subgroup chosen; a contract whose item has no named subgroups offers none |
| AC-12.1: value, paid and what remains show before saving | `ContractFigures` | AC-12.1: choosing a contract |
| AC-07.1: an overrun alerts with (1,000), and is still saved | `Contract.remainingAfter`, `isOverrunBy` | AC-07.1 |
| What waits shows beside what was paid, and counts | `Contract.pending` | what waits for approval; `contracts_test`: BR-10 |
| AC-07.2: an open value has no remaining, bar or alert | `ContractFigures` | AC-07.2 |
| AC-13.1: outside, the remaining does not change | `_isOutside` | AC-13.1 |
| AC-14.1, D14: a deduction is negative, has no receipt, and says why in its notes | `_isDeduction` | AC-14.1, D14 |
| D16: a payment is sent with no receipt; a receipt taken is kept and sent | `_record` | D16: a payment is sent with no receipt; a receipt taken is kept and sent |
| A disabled contract is not on offer | `ContractPicker` | a disabled contract |
| FR-41: its item's custom columns | `_chooseContract` | FR-41 |
| Who may | `Project.mayEnterExpenses` | who holds no recordEntries; a finished project |
| Fits 360 points wide, in both languages | The screen | `test/account/my_account_test.dart`: AC-N03 |
| The real app against the real API | | `patrol_test/app_test.dart`: the journey pays 35,000 on a contract of 34,000, sees the alert and sends it |
