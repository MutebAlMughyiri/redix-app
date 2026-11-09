[Documentation](../README.md) › UC-015

# UC-015: Manage accounts and custodies

**What it is for:** defining a project's bank accounts and cash custodies, and showing each custodian what they hold (FR-22, AC-22.1).
**Who uses it:** whoever holds `manageSettings` changes them, which is Finance. Everyone with access sees them, with nothing to change (BR-31).
**Issue:** redix-app #34; the API side is redix-api #33.

## Screens

The canvas draws Accounts with reconciliation and transfers (`Accounts.dc.html`); transfers were removed on 8 Nov 2026. This use case builds its list of accounts; the rest belongs to the use cases that compute them.

The project's home, `HomeScreen`:

| Element | `Key` | Does |
| --- | --- | --- |
| Accounts | `HomeScreen.accountsKey(id)` | Opens the screen below; shown to everyone |
| My custody | `HomeScreen.custodyKey(accountId)` | One card per active account the user holds, above the project; none for someone who holds none |
| What it holds | `HomeScreen.custodyBalanceKey(accountId)` | In riyals |

[Accounts](../guide/accounts.md), `AccountsScreen` at `/projects/:projectId/accounts`:

| Element | `Key` | Does |
| --- | --- | --- |
| Add account | `AccountsScreen.addKey` | Opens the dialog; shown with `manageSettings` |
| An account's name | `AccountsScreen.nameKey(id)` | |
| Its type and custodian, or Disabled | `AccountsScreen.detailsKey(id)` | |
| What it holds | `AccountsScreen.balanceKey(id)` | |
| Its menu | `AccountsScreen.menuKey(id)` | Edit `editKey`, Disable `disableKey` or Enable `enableKey`; shown with `manageSettings` |
| The type, in Add account | `AccountsScreen.typeKey(type)` | One choice per type; it never changes |
| The name, in the dialog | `AccountsScreen.accountNameKey` | |
| The custodian, in the dialog | `AccountsScreen.custodianKey` | A `MemberPicker`: one choice for nobody, `MemberPicker.optionKey('')`, and one for each person in the project, `MemberPicker.optionKey(userId)` |
| The opening balance, in the dialog | `AccountsScreen.openingBalanceKey` | Takes Arabic or Western digits, and a minus |
| Save, in the dialog | `AccountsScreen.saveKey` | |
| Why refused, in the dialog | `AccountsScreen.dialogMessageKey` | |
| The list's states | `AccountsScreen.messageKey`, `emptyKey` | Could not read; no accounts |

## API calls

| Call | When |
| --- | --- |
| `GET /projects/{id}/accounts` | Opening the home or the screen, and after every change |
| `GET /projects/{id}/members` | Opening the screen with `manageSettings`, after the accounts |
| `POST /projects/{id}/accounts`, `.../{accountId}`, `.../{accountId}/disable`, `.../{accountId}/enable` | Adding, editing, disabling and enabling |

## Rules and where they live

| Rule | Code | Test in `test/accounts/accounts_test.dart` |
| --- | --- | --- |
| Each account shows its type, who holds it and what it holds | `AccountRow` | `each account shows its type, who holds it and what it holds` |
| Money has two decimals, separators, and negatives in brackets (NFR-04) | `formatMoney` | `money shows two decimals, thousands separators, and negatives in brackets (NFR-04)` |
| Adding sends the type, name and opening balance | `Accounts.add`, `AccountDialog` | `adding a bank account sends its type, name and opening balance, and nobody`, `adding a cash custody sends who holds it` |
| A refusal stays in the dialog | `ChangeDialog` | `a refusal stays in the dialog with its reason` |
| An opening balance cannot change once the account has entries, and the dialog says so | The API; `ChangeDialog` | `an opening balance the entries hold in place says so in the dialog` |
| An opening balance that is not a number is refused without asking the API | `AccountDialog` | `an opening balance that is not a number is refused without asking the API` |
| Editing starts from the account, and its type cannot change | `AccountDialog`, `Accounts.edit` | `editing starts from the account and sends what changed, and its type cannot change` |
| Choosing nobody sends no custodian | `Accounts.edit`, `MemberPicker` | `choosing nobody sends no custodian` |
| A custodian who left the project stays on offer until changed | `MemberPicker` | `a custodian who left the project stays on offer until changed` |
| Disabling says so on the row, and Enable brings it back (BR-15) | `AccountRow` | `disabling says so on the row, and enable brings it back` |
| Without `manageSettings` the accounts show with nothing to change (AC-22.1) | `Project.mayManageSettings` | `without manageSettings the accounts show with nothing to change (AC-22.1)` |
| A finished project shows them with nothing to change (AC-04.1) | `Project.mayManageSettings` | `a finished project shows its accounts with nothing to change` |
| A custodian sees their custody on the home, and nobody else does (AC-22.1) | `MyCustody`, `Accounts.mine` | `a custodian sees their custody on the home, and nobody else does (AC-22.1)` |
| A disabled custody leaves the home | `Accounts.mine` | `a disabled custody leaves the home` |
| A list that cannot be read says so | `ApiListBody` | `a list that cannot be read says so` |
| An expired token is renewed for each list when the home opens, and the session stays open | `HomeScreen`, `Session._renew` | `an expired access token is renewed once for each list read at once`, in `test/projects/projects_test.dart` |
| It fits 360 points wide in both languages (AC-N03) | `AccountsScreen`, `MyCustody` | `AC-N03` in `test/account/settings/account_test.dart` |

The real app is run on an emulator by the journey in `patrol_test/app_test.dart`, which adds a bank account and a custody and sees the custody on the home.

## Left to later use cases

| What | Use case |
| --- | --- |
| Pending and rejected counts beside the custody, and the card as the canvas draws it for Field | UC-037 "See my latest entries and custody balance" |
| Reconciliation, which the canvas draws on this screen | UC-040 |
