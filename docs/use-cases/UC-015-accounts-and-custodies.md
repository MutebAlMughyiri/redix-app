[Documentation](../README.md) › UC-015

# UC-015: Manage accounts and custodies

**What it is for:** defining a project's bank accounts and cash custodies, moving money between them, seeing what each holds against what was really counted in it, and tracing what was done to them (FR-22, FR-23, AC-22.1, redix-app #89).
**Who uses it:** whoever holds `manageSettings` adds, changes, disables and deletes accounts; whoever holds `moveMoney` transfers and types the actual balances; everyone with access sees them and their history, a partner's money only with `seeAllCapital` (BR-31).
**Issue:** redix-app #34 and #89; the API side is redix-api #33.

## Screens

Accounts and the actual balances are one screen since redix-app #89; the home's Actual balances button is gone.

The project's home, `HomeScreen`:

| Element | `Key` | Does |
| --- | --- | --- |
| Accounts | `HomeScreen.accountsKey(id)` | Opens the screen below; shown to everyone |
| My custody | `HomeScreen.custodyKey(accountId)` | One card per active account the user holds, above the project; none for someone who holds none |
| What it holds | `HomeScreen.custodyBalanceKey(accountId)` | In riyals |

[Accounts](../guide/accounts.md), `AccountsScreen` at `/projects/:projectId/accounts`:

| Element | `Key` | Does |
| --- | --- | --- |
| Add account, in the top bar | `AccountsScreen.addKey` | Opens the dialog; gray without `manageSettings` |
| History, in the top bar | `AccountsScreen.historyKey` | Opens the account history |
| The card | `ReconciliationCard.cardKey` | The surplus, the total counted at the last check, and the difference |
| A type's heading | `AccountsScreen.groupKey(type)` | Bank accounts, then cash custodies |
| An account's name | `AccountsScreen.nameKey(id)` | |
| Its type and custodian, or Disabled, and what the last check counted | `AccountsScreen.detailsKey(id)` | Nothing counted for an account that check did not hold |
| What it holds | `AccountsScreen.balanceKey(id)` | Its approved entries and transfers; no opening balance |
| Its menu | `AccountsScreen.menuKey(id)` | Edit `editKey`, Disable `disableKey` or Enable `enableKey`, Delete `deleteKey`, gray with its reason once something names the account; shown with `manageSettings` |
| Transfer, at the bottom | `AccountsScreen.transferKey` | Opens the transfer; gray without `moveMoney` or with fewer than two active accounts |
| Update, at the bottom | `AccountsScreen.updateKey` | Opens the typing of the actual balances; gray without `moveMoney` |
| The type, in Add account | `AccountsScreen.typeKey(type)` | One choice per type; it never changes |
| The name, in the dialog | `AccountsScreen.accountNameKey` | |
| The custodian, in the dialog | `AccountsScreen.custodianKey` | A `MemberPicker`: one choice for nobody, `MemberPicker.optionKey('')`, and one for each person in the project |

The transfer, `TransferDialog`:

| Element | `Key` | Does |
| --- | --- | --- |
| From | `TransferDialog.fromKey` | The active accounts; each choice `TransferDialog.choiceKey(fromKey, accountId)` |
| What From holds now | `TransferDialog.balanceNowKey` | |
| To | `TransferDialog.toKey` | The active accounts but From |
| Amount, date, notes | `TransferDialog.amountKey`, `dateKey`, `notesKey` | |

The account history, `AccountHistoryScreen` at `/projects/:projectId/accounts/history`:

| Element | `Key` | Does |
| --- | --- | --- |
| All accounts, one account, What I did | `AccountHistoryScreen.allKey`, `accountKey(id)`, `mineKey` | Read the history again with that filter, from the newest |
| A line | `AccountHistoryScreen.lineKey(id)` | What, how much and which accounts; who and when under it |
| More | `AccountHistoryScreen.moreKey` | Shown while the last page was full; adds the next page below |

## API calls

| Call | When |
| --- | --- |
| `GET /projects/{id}/accounts` | Opening the home or the screen, and after every change |
| `GET /projects/{id}/reconciliations/latest` | Opening Accounts, and pulling it down |
| `GET /projects/{id}/members` | Opening the screen with `manageSettings`, after the accounts |
| `POST /projects/{id}/accounts`, `.../{accountId}`, `.../{accountId}/disable`, `.../{accountId}/enable`, `.../{accountId}/delete` | Adding, editing, disabling, enabling and deleting |
| `POST /projects/{id}/transfers` | A transfer |
| `GET /projects/{id}/accounts/history?account=&mine=&before=` | Opening History, choosing a filter, and More |

## Rules and where they live

| Rule | Code | Test |
| --- | --- | --- |
| Each account shows its type, who holds it and what it holds | `AccountRow` | `accounts_test.dart`: `each account shows its type, who holds it and what it holds` |
| Money has two decimals, separators, and negatives in brackets (NFR-04) | `formatMoney` | `accounts_test.dart`: `money shows two decimals, thousands separators, and negatives in brackets (NFR-04)` |
| An account has no opening balance: adding sends its type and name, and the dialog asks no balance (redix-app #89, R10) | `Accounts.add`, `AccountDialog` | `accounts_test.dart`: `R10: adding a bank account sends its type and name, nobody, and no balance`, `R10: the dialog asks no balance, adding or editing` |
| A refusal stays in the dialog | `ChangeDialog` | `accounts_test.dart`: `a refusal stays in the dialog with its reason` |
| Editing changes the name and who holds it; the type cannot change, and the balance does not move | `AccountDialog`, `Accounts.edit` | `accounts_test.dart`: `editing starts from the account and sends what changed, and its type cannot change` |
| Choosing nobody sends no custodian | `Accounts.edit`, `MemberPicker` | `accounts_test.dart`: `choosing nobody sends no custodian` |
| A custodian who left the project stays on offer until changed | `MemberPicker` | `accounts_test.dart`: `a custodian who left the project stays on offer until changed` |
| Disabling says so on the row, and Enable brings it back (BR-15) | `AccountRow` | `accounts_test.dart`: `disabling says so on the row, and enable brings it back` |
| An account nothing names is deleted after the question; once something names it Delete stays gray and says why (BR-15) | `AccountMenu`, `rowMenuItem` | `transfers_history_test.dart`: the Delete group |
| The actual balances are on Accounts: the card on top, each account's counted amount on its line, Transfer and Update in its one bottom bar (R1) | `AccountsScreen`, `BottomButton` | `money_test.dart`: UC-041 group; `bottom_button_test.dart`: `D21` |
| A transfer moves money between two active accounts at once; To never offers From; a refusal stays in the dialog in the transfer's words (FR-23, R14, R26) | `TransferDialog`, `Accounts.transfer` | `transfers_history_test.dart`: the Transfer group |
| History reads by its project alone, every account or one, everyone or What I did, a page at a time (R17-R22) | `AccountHistory`, `AccountHistoryScreen` | `transfers_history_test.dart`: the History group; the isolation cases H1-H15 in redix-api `AccountHistoryTests` |
| Without `manageSettings` the accounts show with nothing to change (AC-22.1) | `Project.mayManageSettings` | `accounts_test.dart`: `without manageSettings the accounts show with nothing to change (AC-22.1)` |
| A finished project shows them with nothing to change (AC-04.1) | `Project.mayManageSettings` | `accounts_test.dart`: `a finished project shows its accounts with nothing to change` |
| A custodian sees their custody on the home, and nobody else does (AC-22.1) | `MyCustody`, `Accounts.mine` | `accounts_test.dart`: `a custodian sees their custody on the home, and nobody else does (AC-22.1)` |
| A disabled custody leaves the home | `Accounts.mine` | `accounts_test.dart`: `a disabled custody leaves the home` |
| Each control shows to whoever holds its permission, and is gray or absent without it | The screen | `permission_gates_test.dart`: Add an account, تحديث on Accounts, Transfer on Accounts |
| It fits 360 points wide in both languages (AC-N03) | `AccountsScreen`, `MyCustody` | `AC-N03` in `test/settings/account_test.dart` |

The real app runs on a real phone against the real API in `patrol_test/accounts/accounts_test.dart`, `actual_balances_test.dart`, `transfers_history_test.dart`, `patrol_test/home/custody_test.dart` and `patrol_test/money/account_balance_figures_test.dart`, one case per rule.

## Left to later use cases

| What | Use case |
| --- | --- |
| Pending and rejected counts beside the custody, and the card as the canvas draws it for Field | UC-037 "See my latest entries and custody balance" |
| The history of everything else in a project, beyond its accounts | UC-069, redix-api #86 |
