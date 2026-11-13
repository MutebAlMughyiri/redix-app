[Documentation](../README.md) › UC-007

# UC-007: Manage users

**What it is for:** creating the accounts of the people who use the app, correcting them, making them inactive in a project, and resetting a forgotten password (FR-02).
**Who uses it:** project managers, from a project's card (BR-29).
**Issue:** redix-app #27; the API side is redix-api #25.

## Screens

[Users](../guide/users.md), `UsersScreen` at `/projects/:projectId/users`, opened from the home of a project (`HomeScreen.usersKey(id)`):

| Element | `Key` | Does |
| --- | --- | --- |
| New user | `UsersScreen.newUserKey` | Opens the new user form |
| A user's row | `UsersScreen.rowKey(id)` | One user; active users first, by name |
| Name | `UsersScreen.nameKey(id)` | Their name, muted while inactive in this project |
| Details | `UsersScreen.detailsKey(id)` | Their username, what they are called in this project, and their mobile |
| Permissions | `UsersScreen.permissionsLineKey(id)` | How many permissions they hold in this project (UC-008) |
| Disabled | `UsersScreen.statusKey(id)` | «معطّل», the badge of a person inactive in this project (redix-api #126 D1) |
| The row's menu | `UsersScreen.menuKey(id)` | Edit, Permissions (`UsersScreen.permissionsKey`, UC-008), Reset password, and Disable or Enable |
| Edit | `UsersScreen.editKey` | Opens the Edit dialog: `editNameKey`, `editRoleNameKey`, `editMobileKey` |
| Reset password | `UsersScreen.resetPasswordKey` | Opens the Reset password dialog: `resetNameKey`, `resetExplainKey`, `resetPasswordFieldKey` |
| Save, Cancel, in both dialogs | `ChangeDialog.saveKey`, `ChangeDialog.cancelKey` | Save sends the change, once while it is sent; Cancel closes the dialog unchanged |
| Message, in both dialogs | `ChangeDialog.messageKey` | One line saying why it was refused, keeping what was typed |
| Disable | `UsersScreen.disableKey` | Asks first in a `ConfirmDialog`: `ConfirmDialog.titleKey`, `subjectKey` (the person's name), `explanationKey`, `confirmKey`, `cancelKey` |
| Enable | `UsersScreen.enableKey` | Enables, with no question |

A refused Disable or Enable says why in the bar (`messageKeyOf(wordKey)`).

The list's empty, loading and could-not-load states are `ApiListBody`'s, shared with Projects.

New user, `NewUserScreen` at `/projects/:projectId/users/new`:

| Element | `Key` | Does |
| --- | --- | --- |
| Name | `NewUserScreen.nameKey` | 1 to 100 characters; shows on their entries |
| Username | `NewUserScreen.usernameKey` | 1 to 50 characters, unique; never changes |
| What they are called in this project | `NewUserScreen.roleNameKey` | May be empty (UC-008) |
| Mobile | `NewUserScreen.mobileKey` | Up to 20 characters; may be empty |
| Temporary password | `NewUserScreen.passwordKey` | At least 8 characters; shown as typed, to pass on |
| Permissions | `NewUserScreen.permissionsHeadingKey`, `NewUserScreen.permissionKey(permission)` | What the new login may do in this project, See the project always ticked (UC-008) |
| Add user | `NewUserScreen.submitKey` | Sends everything; disabled while waiting |
| Message | `NewUserScreen.messageKey` | One line saying why it was refused |

## API calls

| Call | When |
| --- | --- |
| `GET /projects/{projectId}/users` | Opening Users, Try again, and after every answer to a change |
| `POST /projects/{projectId}/users` | Add user |
| `PUT /users/{userId}` | Saving Edit, when the name or the mobile changed |
| `PUT /projects/{projectId}/users/{userId}/role-name` | Saving Edit, when what they are called in this project changed |
| `POST /users/{userId}/reset-password` | Saving Reset password |
| `POST /projects/{projectId}/users/{userId}/disable`, `/enable` | Disable, once confirmed; Enable. Each answers the user, and is for this project alone (redix-api #126 D1) |

## Rules and where they live

| Rule | Code | Test |
| --- | --- | --- |
| A new user can sign in and must change the temporary password (AC-02.1) | The API; `RedixApp`'s redirect | `ProjectUsersTests.AManagerCreatesALoginInTheProjectWhoStartsAsTheLastRoleAndMustChangeThePassword`, in the API |
| A refusal shows its own line, and nothing typed is lost | `Users`, `NewUserScreen` | `new_user_test.dart`: a taken username |
| A row shows the username alone when there is no mobile | `UserRow` | `users_test.dart`: a row shows |
| The temporary password shows as typed, so the project manager can pass it on | `NewUserScreen` | `new_user_test.dart`: the temporary password shows as typed |
| Disabling asks first and says what it means; Cancel changes nothing | `UsersScreen`, `ConfirmDialog` | `users_test.dart`: disabling asks first |
| A refused change stays in its dialog with what was typed | `ChangeDialog` | `users_test.dart`: a refused edit |
| Reset password names the user and says what it means | `ResetPasswordDialog` | `users_test.dart`: Reset password |
| Without a network the list and the form say so | `ApiList`, `NewUserScreen` | `users_test.dart`, `new_user_test.dart`: without a network |
| redix-api #126 D1: Disable makes a person inactive in this project alone, through its route; they stay listed, muted with «معطّل», and Enable makes them active again | `Users`, `UserRow`, `UsersScreen` | `users_test.dart`: Disable makes a person inactive through this project's route |
| redix-api #126 D1: a person inactive in another project shows active in this one | `User.isInactive`, which reads this project's line | `users_test.dart`: a person inactive in another project |
| redix-api #126 R8: the last manager of a project cannot be made inactive in it, «users.lastManager» | The API; `UsersScreen` shows the refusal | `users_test.dart`: making the last manager inactive is refused |
| Every row has the whole menu | `UserRow` | `users_test.dart`: every row has the whole menu |
| redix-api #126 R2, R4, R5: a person inactive in a project still signs in; his project list shows it gray with «حسابك غير مفعّل في هذا المشروع.»; every call about it is refused as for a project he is not in, and the list replaces it at the next renewal | The API; `ProjectChoice`, `HomeScreen` (UC-010) | `projects_test.dart`, `home_test.dart`; `patrol_test/auth/sign_in_test.dart` |
| AC-N03: right to left in Arabic, left to right in English, nothing off a screen 360 points wide | Each screen | `settings/account_test.dart`: AC-N03, once per language |

## Left to later use cases

| What | Use case |
| --- | --- |
| A user's roles on the row | UC-008, UC-009 |
| A cash custody created with the user | UC-015 |
