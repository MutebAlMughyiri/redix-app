[Documentation](../README.md) › UC-017

# UC-017: Manage suppliers

**What it is for:** keeping a project's supplier register clean: adding, changing and disabling suppliers, and seeing which wait for approval.
**Who uses it:** whoever holds `manageSettings` changes it, which is Finance. Everyone with access reads it.
**Issue:** redix-app #36; the API side is redix-api #35.

## Screens

The canvas draws the supplier picker (`SupplierPicker.dc.html`), which is UC-018. It has no screen for the register, so this one is built from the same parts as Accounts.

The project's home, `HomeScreen`:

| Element | `Key` | Does |
| --- | --- | --- |
| Suppliers | `HomeScreen.suppliersKey(id)` | Opens the screen below, for everyone with access |

[Suppliers](../guide/suppliers.md), `SuppliersScreen` at `/projects/:projectId/suppliers`:

| Element | `Key` | Does |
| --- | --- | --- |
| Add supplier | `SuppliersScreen.addKey` | Opens the dialog; shown with `manageSettings` |
| A supplier's name | `SuppliersScreen.nameKey(id)` | |
| That it is disabled or pending approval, its VAT number or that it has none, and its default item | `SuppliersScreen.detailsKey(id)` | |
| A supplier's menu | `SuppliersScreen.menuKey(id)` | Shown with `manageSettings` |
| Edit, Disable, Enable, in the menu | `SuppliersScreen.editKey`, `disableKey`, `enableKey` | |
| The name, in the dialog | `SuppliersScreen.supplierNameKey` | |
| The VAT number, in the dialog | `SuppliersScreen.vatNumberKey` | Arabic digits are sent as Western ones |
| Who holds a refused number, in the dialog | `SuppliersScreen.holderKey` | |
| The mobile, in the dialog | `SuppliersScreen.mobileKey` | |
| The default item, in the dialog | `SuppliersScreen.defaultItemKey` | An `ItemPicker`: a sheet of what a purchase is offered, with `ItemPicker.optionKey(id)`, and `ItemPicker.optionKey('')` for none |
| Save, in the dialog | `SuppliersScreen.saveKey` | |
| Why refused, in the dialog | `SuppliersScreen.dialogMessageKey` | |
| The list's states | `SuppliersScreen.messageKey`, `emptyKey` | Could not read; no suppliers |

## API calls

| Call | When |
| --- | --- |
| `GET /projects/{id}/suppliers` | Opening the screen, and after every change |
| `GET /projects/{id}/categories/offered?itemType=purchases` | Opening the screen with `manageSettings` |
| `POST /projects/{id}/suppliers`, `.../{supplierId}`, `.../{supplierId}/disable`, `.../enable` | Adding, editing, disabling and enabling |

## Rules and where they live

| Rule | Code | Test in `test/suppliers/suppliers_test.dart` |
| --- | --- | --- |
| Each supplier shows its VAT number and default item | `Supplier.detailsIn` | `each supplier shows its VAT number and default item` |
| A supplier pending approval is marked, and one with no number shows none | `Supplier.detailsIn` | `a supplier pending approval is marked, and one with no number shows none` |
| Adding sends only what was filled in | `Suppliers.add` | `adding sends the name and the VAT number, and only what was filled in` |
| Arabic digits are sent as Western ones | `westernDigits`, `Suppliers` | `a VAT number and a mobile typed in Arabic digits are sent in Western ones` |
| BR-16: the VAT number may stay empty, which is no number, and there is no switch for it (AC-06.2) | `VatNumberField`, `Suppliers` | `BR-16: a supplier is sent with its VAT number left empty` |
| An invalid number stays in the dialog with the rule (AC-06.1) | `ChangeDialog` | `an invalid VAT number stays in the dialog with the rule` |
| A number another supplier holds is refused, naming it (AC-06.1) | `Suppliers.holder`, `VatNumberField` | `a VAT number another supplier holds is refused, naming that supplier` |
| Editing starts from the supplier and changes it | `SupplierDialog`, `Suppliers.edit` | `editing starts from the supplier and changes it` |
| Editing a supplier with no number shows it empty | `SupplierDialog` | `editing a supplier with no number shows its VAT number empty` |
| A default item is chosen among what a purchase is offered, and can be taken away | `ItemPicker`, `OfferedItems` | `a default item is chosen among what a purchase is offered, and can be taken away` |
| Disabled, it stays on the list, marked, and can be enabled (BR-15) | `SupplierRow` | `a disabled supplier stays on the list, marked, and can be enabled` |
| The general cash supplier stays active, and the refusal says why; no menu in the app has a disabled entry with a reason, so the refusal is what shows | `showRefusalOf`, the word `suppliers.generalCashSupplier` | `the general cash supplier stays active, and the refusal says why` |
| A project with no suppliers says so | `ApiListBody` | `a project with no suppliers says so` |
| Without keeping the settings there is nothing to change | `Project.mayManageSettings` | `without keeping the settings the register shows with nothing to change` |
| A finished project shows it with nothing to change (AC-04.1) | `Project.mayManageSettings` | `a finished project shows its register with nothing to change` |
| A list that cannot be read says so | `ApiListBody` | `a list that cannot be read says so` |
| It fits 360 points wide in both languages (AC-N03) | `SuppliersScreen`, `SupplierDialog` | `AC-N03` in `test/settings/account_test.dart` |

The real app is run on an emulator by the journey in `patrol_test/app_test.dart`, which adds a supplier with a default item.

## Left to later use cases

| What | Use case |
| --- | --- |
