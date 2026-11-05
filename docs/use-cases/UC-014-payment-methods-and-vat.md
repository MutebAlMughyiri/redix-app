[Documentation](../README.md) › UC-014

# UC-014: Manage payment methods and the VAT rate

**What it is for:** keeping the payment methods entries choose from (FR-40), and the rate their VAT is computed at (BR-14).
**Who uses it:** whoever holds `manageSettings` in the project, which is Finance. A finished project shows them with nothing to change.
**Issue:** redix-app #33; the API side is redix-api #32.

## Screens

The canvas has no screen for this (findings row 7), so it is built from Material's parts, as Categories and items is.

The project's home, `HomeScreen`:

| Element | `Key` | Does |
| --- | --- | --- |
| Payment methods and VAT | `HomeScreen.paymentMethodsKey(id)` | Opens the screen below; shown with `manageSettings` |

[Payment methods and VAT](../guide/payment-methods.md), `PaymentMethodsScreen` at `/projects/:projectId/payment-methods`:

| Element | `Key` | Does |
| --- | --- | --- |
| The VAT rate | `PaymentMethodsScreen.vatRateKey` | As a percentage, with as few decimals as it needs |
| What it applies to | `PaymentMethodsScreen.vatHintKey` | |
| Change | `PaymentMethodsScreen.changeVatRateKey` | Opens the rate dialog |
| The rate, in its dialog | `PaymentMethodsScreen.vatPercentKey` | Takes Arabic or Western digits |
| Add | `PaymentMethodsScreen.addKey` | Opens the name dialog |
| A method's name | `PaymentMethodsScreen.nameKey(id)` | |
| That it is disabled | `PaymentMethodsScreen.disabledKey(id)` | |
| Its menu | `PaymentMethodsScreen.menuKey(id)` | Rename `renameKey`, Disable `disableKey` or Enable `enableKey` |
| The name, in a dialog | `PaymentMethodsScreen.dialogNameKey` | |
| Save, in a dialog | `PaymentMethodsScreen.saveKey` | |
| Why refused, in a dialog | `PaymentMethodsScreen.dialogMessageKey` | |
| The list's states | `PaymentMethodsScreen.messageKey`, `emptyKey` | Could not read; no methods |

## API calls

| Call | When |
| --- | --- |
| `GET /projects/{id}/payment-methods` | Opening the screen, and after every change |
| `POST /projects/{id}/payment-methods`, `.../{methodId}`, `.../{methodId}/disable`, `.../{methodId}/enable` | Adding, renaming, disabling and enabling |
| `POST /projects/{id}/vat-rate` with `{ vatPercent }` | Changing the rate, after which the project list is read again, since each project carries its rate |

## Rules and where they live

| Rule | Code | Test in `test/settings/payment_methods_test.dart` |
| --- | --- | --- |
| Methods show in order, and a disabled one says so | `PaymentMethodRow` | `methods show in order, and a disabled one says so` |
| Adding sends the name and shows the new method | `PaymentMethods.add` | `adding sends the name and shows the new method` |
| A refused name stays in the dialog with its reason | `ChangeDialog` | `a refused name stays in the dialog with its reason` |
| Renaming starts from the name | `PaymentMethodRow`, `NameDialog` | `renaming starts from the name and sends the new one` |
| A disabled method stays on the list, and Enable brings it back (AC-40.1) | `PaymentMethods.disable`, `enable` | `disabling keeps the method on the list, and enable brings it back` |
| A refused change says why | `showRefusalOf` | `a refused disable says why` |
| The rate shows as a percentage | `formatPlain` | `the rate shows as a percentage, with what it applies to`, `a plain number shows as few decimals as it needs` |
| Changing the rate sends the percentage and shows the new one | `Projects.setVatPercent`, `VatRateDialog` | `changing the rate starts from it, sends the percentage and shows the new one` |
| A number may be typed in Arabic digits, since the app is Arabic first | `parseNumber` | `a rate in Arabic digits is understood`, `a typed number reads Western and Arabic digits and thousands separators` |
| What is not a number is refused without asking the API | `VatRateDialog` | `what is not a number is refused without asking the API` |
| A rate the API refuses stays in the dialog | `ChangeDialog` | `a rate the API refuses stays in the dialog with its reason` |
| A finished project shows them with nothing to change (AC-04.1) | `Project.mayManageSettings` | `a finished project shows its methods and rate with nothing to change` |
| Without `manageSettings` there is no way in | `ProjectCard` | `without manageSettings there is no way in` |
| A list that cannot be read says so | `ApiListBody` | `a list that cannot be read says so` |
| It fits 360 points wide in both languages (AC-N03) | `PaymentMethodsScreen` | `AC-N03` in `test/account/my_account_test.dart` |

The real app is run on an emulator by the journey in `patrol_test/app_test.dart`, which adds a method, disables it and changes the rate.
