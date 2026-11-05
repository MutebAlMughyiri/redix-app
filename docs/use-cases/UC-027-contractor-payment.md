[Documentation](../README.md) › UC-027

# UC-027: Record a payment against a contract

**What it is for:** paying a contractor and seeing the effect before saving.
**Who uses it:** whoever holds `recordEntries`, from **Contractor payment** on the project's home, the second of the canvas's two ways in.
**Issue:** redix-app #45; the API side is redix-api #44.

## Screens

`ContractorPaymentScreen`, from the canvas's `ContractorPayment.dc.html`. Where the canvas offers **من شريك**, that waits for UC-045 "Expense paid from a partner's money", as on the purchase. The camera does not open by itself: the canvas draws two buttons, and a deduction has no receipt.

| Element | `Key` | Does |
| --- | --- | --- |
| Title, project | `ContractorPaymentScreen.titleKey`, `projectNameKey` | |
| Contract | `contractKey`, `ContractPicker.optionKey(id)` | Opens a sheet of the active contracts |
| Value, Paid, Remaining after this payment | `valueKey`, `paidKey`, `remainingKey` | An open value shows no remaining |
| Waiting for approval | `pendingKey` | Shows when anything waits, and counts in what remains |
| The bar | `progressKey` | Gone for an open value |
| The alert | `overrunKey` | Shows when this payment goes beyond the value; saving still works |
| Amount, Date | `amountKey`, `dateKey` | The amount's keyboard offers a minus sign |
| Inside, Outside | `insideKey`, `outsideKey`, `outsideExplainKey` | Outside leaves the remaining alone |
| Where it is paid from and how | `PaymentChoices.sourceKey(type)`, `accountKey(id)`, `paymentMethodKey(id)`, `noAccountKey` | The same widget as the purchase |
| The receipt | `receiptKey`, `cameraKey`, `filesKey` | The same `InvoiceSection` as the purchase |
| Why it is deducted | `deductionReasonKey` | Takes the receipt's place while the amount is negative |
| Tax invoice | `hasInvoiceKey`, `invoiceNumberKey`, `invoiceDateKey`, `invoiceAmountKey`, `invoiceVatKey` | The VAT shows as the API will compute it |
| Notes | `notesKey` | |
| Send, Save draft | `sendKey`, `draftKey` | |
| Why it was refused, and that it was saved | `messageKey`, `savedKey` | |

On the home: `HomeScreen.contractorPaymentKey(id)`. On a contract's card: `ContractsScreen.pendingKey(id)`.

## API calls

`POST /projects/{id}/contractor-payments`, through `Expenses.recordContractorPayment`. `GET /projects/{id}/contracts`, `accounts/offered`, `payment-methods`, read at once with `ApiList.loadOnOpen`, and the columns of the contract's item once it is chosen.

## Rules

Tests are in `test/contractor_payments/contractor_payment_screen_test.dart`.

| Rule | Code | Test |
| --- | --- | --- |
| AC-12.1: value, paid and what remains show before saving | `ContractFigures` | AC-12.1: choosing a contract |
| AC-07.1: an overrun alerts with (1,000), and is still saved | `Contract.remainingAfter`, `isOverrunBy` | AC-07.1 |
| What waits shows beside what was paid, and counts | `Contract.pending` | what waits for approval; `contracts_test`: BR-10 |
| AC-07.2: an open value has no remaining, bar or alert | `ContractFigures` | AC-07.2 |
| AC-13.1: outside, the remaining does not change | `_isOutside` | AC-13.1 |
| AC-14.1: a deduction is negative and says why | `_isDeduction` | AC-14.1 |
| AC-12.1: no receipt is refused with a message; the receipt is kept and sent | `_record` | AC-12.1: sending with no receipt |
| A disabled contract is not on offer | `ContractPicker` | a disabled contract |
| The tax invoice sends its number, date and amount, and shows its VAT | `_body`, `InvoiceFigures.of` | a tax invoice sends; a contractor with no VAT number; a tax invoice with no number |
| FR-41: its item's custom columns | `_chooseContract` | FR-41 |
| AC-17.1: the same tax invoice again asks | `DuplicateInvoiceDialog` | AC-17.1 |
| Who may | `Project.mayEnterExpenses` | who holds no recordEntries; a finished project |
| Fits 360 points wide, in both languages | The screen | `test/account/my_account_test.dart`: AC-N03 |
| The real app against the real API | | `patrol_test/app_test.dart`: the journey pays 35,000 on a contract of 34,000, sees the alert and sends it |
