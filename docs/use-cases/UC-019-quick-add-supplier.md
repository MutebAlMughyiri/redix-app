[Documentation](../README.md) › UC-019

# UC-019: Quick-add a supplier without leaving the expense

**What it is for:** adding a missing supplier in the middle of an entry, and going on with it, pending approval unless whoever adds it keeps the project's settings.
**Who uses it:** whoever holds `addSupplier`, which is Finance and Field. Field has no way to the sheet until UC-022 "Record a purchase expense", since its place is the expense.
**Issue:** redix-app #38; the API side is redix-api #37.

## Screens

[Choosing a supplier](../guide/supplier-picker.md), `SupplierPicker`, and `QuickAddSupplierDialog` over it. The canvas (`SupplierPicker.dc.html`) keeps the form always open at the foot of the sheet; here it is a button, as the issue asks, because the form would leave little of the list at 360 points with the keyboard up.

| Element | `Key` | Does |
| --- | --- | --- |
| New supplier, on the sheet | `SupplierPicker.quickAddKey` | Opens the dialog, starting from what the search held; shown while the project runs, with `addSupplier` |
| The name, in the dialog | `SuppliersScreen.supplierNameKey` | |
| The VAT number, in the dialog | `SuppliersScreen.vatNumberKey` | |
| Who holds a refused number, in the dialog | `SuppliersScreen.holderKey` | |
| Use this supplier, in the dialog | `SupplierPicker.useExistingKey` | Goes on with that supplier; shown unless it is disabled |
| That a new supplier waits for approval, in the dialog | `SupplierPicker.pendingHintKey` | Shown without `manageSettings` |
| Add and choose, in the dialog | `SuppliersScreen.saveKey` | |
| Why refused, in the dialog | `SuppliersScreen.dialogMessageKey` | |

## API calls

| Call | When |
| --- | --- |
| `POST /projects/{id}/suppliers` with `{ name, vatNumber }`, the number empty when it has none | Add and choose; it answers the supplier, or names the one holding the number as `existing` |

## Rules and where they live

| Rule | Code | Test in `test/suppliers/supplier_picker_test.dart` |
| --- | --- | --- |
| A name in the search starts the name | `QuickAddSupplierDialog` | `a name typed in the search starts the quick add's name` |
| A number in the search starts the VAT number, in Western digits | `QuickAddSupplierDialog`, `westernDigits` | `a number typed in the search starts the quick add's VAT number` |
| What Field adds is picked, and shows pending approval (AC-44.1) | `Suppliers.added`, `SupplierPicker` | `AC-44.1: what Field adds is picked, and shows to them pending approval` |
| It says a new supplier waits, to whoever does not keep the settings | `QuickAddSupplierDialog` | `the quick add says a new supplier waits for approval to whoever does not keep the settings` |
| Whoever keeps the settings adds it approved | The API | `whoever keeps the settings adds an approved supplier, and is told nothing of waiting` |
| An invalid number is blocked with the rule shown (AC-06.1) | `ChangeDialog` | `an invalid VAT number is blocked with the rule shown` |
| A number already used names the supplier and offers it instead | `Suppliers.holder`, `QuickAddSupplierDialog` | `a VAT number already used names the existing supplier and offers it instead` |
| A disabled supplier holding it is named and not offered (BR-15) | `QuickAddSupplierDialog` | `a disabled supplier holding the number is named and not offered` |
| Closing goes back to the search | `SupplierPicker` | `closing the quick add goes back to the search` |
| Without `addSupplier` there is no quick add | `Project.mayAddSupplier` | `without a way to add a supplier there is no quick add` |
| A finished project offers none (AC-04.1) | `Project.mayAddSupplier` | `a finished project offers no quick add` |
| It fits 360 points wide in both languages (AC-N03) | `QuickAddSupplierDialog` | `AC-N03` in `test/settings/account_test.dart` |

The real app is run on an emulator by the journey in `patrol_test/app_test.dart`, through the contract's dialog (UC-020).

## Left to later use cases

| What | Use case |
| --- | --- |
| The expense that opens the sheet, for Field | UC-022 "Record a purchase expense" |
| Filling the name and number from a QR code | UC-024 "Fill the expense from the e-invoice QR" |
| A pending supplier approved with its first expense (AC-44.1) | UC-032 "Approve or reject entries" |
