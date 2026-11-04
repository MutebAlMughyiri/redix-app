[Documentation](../README.md) › UC-007

# UC-007: Manage users

**What it is for:** creating the accounts of the people who use the app, correcting them, disabling them, and resetting a forgotten password (FR-02).
**Who uses it:** project managers, from a project's card; the system admin, for every login, from Settings (BR-29).
**Issue:** redix-app #27; the API side is redix-api #25.

## Screens

[Users](../guide/users.md), `UsersScreen` at `/users`, opened from Settings (`SettingsScreen.usersKey`):

| Element | `Key` | Does |
| --- | --- | --- |
| New user | `UsersScreen.newUserKey` | Opens the new user form |
| A user's row | `UsersScreen.rowKey(id)` | One user; active users first, by name |
| Name | `UsersScreen.nameKey(id)` | Their name, muted once disabled |
| Details | `UsersScreen.detailsKey(id)` | Their username and mobile |
| Disabled | `UsersScreen.statusKey(id)` | The badge of a disabled user |
| The row's menu | `UsersScreen.menuKey(id)` | Edit, Roles on a project's list, Reset password, and Disable or Enable |
| Edit | `UsersScreen.editKey` | Opens the Edit dialog: `editNameKey`, `editMobileKey` |
| Reset password | `UsersScreen.resetPasswordKey` | Opens the Reset password dialog: `resetNameKey`, `resetExplainKey`, `resetPasswordFieldKey` |
| Save, in both dialogs | `UsersScreen.saveKey` | Sends the change; disabled while waiting |
| Message, in both dialogs | `UsersScreen.dialogMessageKey` | One line saying why it was refused, keeping what was typed |
| Disable | `UsersScreen.disableKey` | Asks first: `disableNameKey`, `disableExplainKey`, `confirmDisableKey`, `cancelDisableKey` |
| Enable | `UsersScreen.enableKey` | Enables, with no question |

The list's empty, loading and could-not-load states are `ApiListBody`'s, shared with Projects.

New user, `NewUserScreen` at `/users/new`:

| Element | `Key` | Does |
| --- | --- | --- |
| Name | `NewUserScreen.nameKey` | 1 to 100 characters; shows on their entries |
| Username | `NewUserScreen.usernameKey` | 1 to 50 characters, unique; never changes |
| Mobile | `NewUserScreen.mobileKey` | Up to 20 characters; may be empty |
| Temporary password | `NewUserScreen.passwordKey` | At least 8 characters; shown as typed, to pass on |
| Add user | `NewUserScreen.submitKey` | Sends everything; disabled while waiting |
| Message | `NewUserScreen.messageKey` | One line saying why it was refused |

## API calls

| Call | When |
| --- | --- |
| `GET /users` | Opening Users, Try again, and after every answer to a change |
| `POST /users` | Add user |
| `POST /users/{userId}` | Saving Edit |
| `POST /users/{userId}/reset-password` | Saving Reset password |
| `POST /users/{userId}/disable`, `/enable` | Disable, once confirmed; Enable |

## Rules and where they live

| Rule | Code | Test |
| --- | --- | --- |
| Only whoever manages logins sees every login | `SettingsScreen`, `Session.may` | `settings_test.dart`: anyone else sees Projects and My account |
| A new user can sign in and must change the temporary password (AC-02.1) | The API; `RedixApp`'s redirect | `ProjectUsersTests.AManagerCreatesALoginInTheProjectWhoStartsAsTheLastRoleAndMustChangeThePassword`, in the API |
| A refusal shows its own line, and nothing typed is lost | `Users`, `NewUserScreen` | `new_user_test.dart`: a taken username |
| A row shows the username alone when there is no mobile | `UserRow` | `users_test.dart`: a row shows |
| The temporary password shows as typed, so the project manager can pass it on | `NewUserScreen` | `new_user_test.dart`: the temporary password shows as typed |
| Disabling asks first and says what it means; Cancel changes nothing | `UsersScreen`, `ConfirmDialog` | `users_test.dart`: disabling asks first |
| A refused change stays in its dialog with what was typed | `ChangeDialog` | `users_test.dart`: a refused edit |
| Reset password names the user and says what it means | `ResetPasswordDialog` | `users_test.dart`: Reset password |
| Without a network the list and the form say so | `ApiList`, `NewUserScreen` | `users_test.dart`, `new_user_test.dart`: without a network |
| A disabled user stays listed, muted, and can be enabled | `UserRow`, `UsersScreen` | `users_test.dart`: a disabled user stays listed |
| Every row has the whole menu | `UserRow` | `users_test.dart`: every row has the whole menu |
| A disabled user's session ends at their next request (AC-01.3) | The API | `UsersTests.DisablingAUserEndsTheOpenSessionAtTheNextRequest`, in the API |
| AC-N03: right to left in Arabic, left to right in English, nothing off a screen 360 points wide | Each screen | `my_account_test.dart`: AC-N03, once per language |

## Left to later use cases

| What | Use case |
| --- | --- |
| A user's roles on the row | UC-008, UC-009 |
| A cash custody created with the user | UC-015 |
