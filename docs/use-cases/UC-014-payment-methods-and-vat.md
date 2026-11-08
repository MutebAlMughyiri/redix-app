[Documentation](../README.md) › UC-014

# UC-014: Manage payment methods

**What it is for:** keeping the payment methods entries choose from (FR-40).
**Who uses it:** whoever holds `manageSettings` in the project, which is Finance. A finished project shows them with nothing to change.
**Issue:** redix-app #33; the API side is redix-api #32.

## Screens

The canvas has no screen for this (findings row 7), so it is built from Material's parts, as Categories and items is. A project has no VAT rate to set: the VAT statement's workbook works the VAT out at the config row `vatRatePercent` (redix-api #96, D18).

Settings, `SettingsScreen`, reached from the project's card:

| Element | `Key` | Does |
| --- | --- | --- |
| Payment methods | `SettingsScreen.paymentMethodsKey` | Opens the screen below; shown with `manageSettings` |

[Payment methods](../guide/payment-methods.md), `PaymentMethodsScreen` at `/projects/:projectId/payment-methods`:

| Element | `Key` | Does |
| --- | --- | --- |
| Add | `PaymentMethodsScreen.addKey` | Opens the name dialog |
| A method's name | `PaymentMethodsScreen.nameKey(id)` | |
| That it is disabled | `PaymentMethodsScreen.disabledKey(id)` | |
| Its menu | `PaymentMethodsScreen.menuKey(id)` | Rename `renameKey`, Disable `disableKey` or Enable `enableKey`; a method is deleted by swiping its row, `rowKey(id).swipe` (redix-api #102) |
| The name, in a dialog | `PaymentMethodsScreen.dialogNameKey` | |
| Save, in a dialog | `PaymentMethodsScreen.saveKey` | |
| Why refused, in a dialog | `PaymentMethodsScreen.dialogMessageKey` | |
| The list's states | `PaymentMethodsScreen.messageKey`, `emptyKey` | Could not read; no methods |

## API calls

| Call | When |
| --- | --- |
| `GET /projects/{id}/payment-methods` | Opening the screen, and after every change |
| `POST /projects/{id}/payment-methods`, `.../{methodId}`, `.../{methodId}/disable`, `.../{methodId}/enable`, `.../{methodId}/delete` | Adding, renaming, disabling, enabling and deleting |

## Rules and where they live

| Rule | Code | Test in `test/settings/payment_methods_test.dart` |
| --- | --- | --- |
| Methods show in order, and a disabled one says so | `PaymentMethodRow` | `methods show in order, and a disabled one says so` |
| Adding sends the name and shows the new method | `PaymentMethods.add` | `adding sends the name and shows the new method` |
| A refused name stays in the dialog with its reason | `ChangeDialog` | `a refused name stays in the dialog with its reason` |
| Renaming starts from the name | `PaymentMethodRow`, `NameDialog` | `renaming starts from the name and sends the new one` |
| A disabled method stays on the list, and Enable brings it back (AC-40.1) | `PaymentMethods.disable`, `enable` | `disabling keeps the method on the list, and enable brings it back` |
| A swipe deletes a method with no question; a method an expense was paid with is not deleted, and the refusal says to disable it | `PaymentMethods.delete`, `SwipeToRemove` | `redix-api #102: a swipe deletes a method with no question, and the method leaves the list`, `a method an expense was paid with is not deleted, and the refusal says to disable it` |
| A refused change says why | `showRefusalOf` | `a refused disable says why` |
| A number may be typed in Arabic digits, since the app is Arabic first | `parseNumber` | `a typed number reads Western and Arabic digits and thousands separators` |
| A finished project shows them with nothing to change (AC-04.1) | `Project.mayManageSettings` | `a finished project shows its methods with nothing to change` |
| Without `manageSettings` there is no way in | `SettingsScreen` | `without manageSettings there is no way in` |
| It fits 360 points wide in both languages (AC-N03) | `PaymentMethodsScreen` | `AC-N03` in `test/account/my_account_test.dart` |

The real app is run on an emulator by the journey in `patrol_test/app_test.dart`, which adds a method and disables it.
