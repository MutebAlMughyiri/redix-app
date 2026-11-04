[Documentation](../README.md) › UC-008

# UC-008: Add people to a project and give their roles

**What it is for:** deciding who works on each project, and as what (FR-36).
**Who uses it:** each project's manager, for that project alone. What each role may then do is UC-009.
**Issue:** redix-app #28; the API side is redix-api #26.

## Screens

A project's Users, `UsersScreen` at `/projects/:projectId/users`, opened from the project's card (`ProjectsScreen.usersKey(id)`), and Roles, `UserRolesScreen` at `/projects/:projectId/users/:userId/roles`, opened from a person's menu (`UsersScreen.rolesKey`):

| Element | `Key` | Does |
| --- | --- | --- |
| New user | `UsersScreen.newUserKey` | Opens the form; a new login is born in this project, as the last role |
| Add an existing user | `UsersScreen.addExistingKey` | Asks for their exact username (`UsersScreen.existingUsernameKey`), as the last role |
| Whose | `UserRolesScreen.nameKey` | The person's name |
| A role's tick | `UserRolesScreen.roleKey(roleId)` | Gives or takes the role, at once |

The roles come from the API, in its order, so a role added in the database appears with no release. Someone can hold more than one. A refusal shows in a SnackBar.

## API calls

| Call | When |
| --- | --- |
| `GET /projects/{projectId}/users` | Opening Users, and after every answer |
| `GET /projects/{projectId}/roles` | Opening Roles |
| `POST /projects/{projectId}/users` | Adding a new user |
| `POST /projects/{projectId}/users/existing` | Adding an existing user |
| `POST /projects/{projectId}/users/{userId}/roles/{roleId}` | Ticking a role |
| `POST /projects/{projectId}/users/{userId}/roles/{roleId}/remove` | Unticking a role |

## Rules and where they live

| Rule | Code | Test |
| --- | --- | --- |
| A tick gives the role at once, and someone can hold more than one | `UserRolesScreen`, `Users.give` | `user_roles_test.dart`: a tick gives the role |
| Unticking takes the role away | `Users.take` | `user_roles_test.dart`: unticking |
| Roles come from the API, a new one included | `Roles` | `user_roles_test.dart`: roles come from the API |
| Taking the last role takes them off the list | `Users.take`, `UserRolesScreen` | `user_roles_test.dart`: taking their last role |
| The last manager's refusal shows its word | `showRefusalOf` | `user_roles_test.dart`: a refusal |
| A row on a project's list shows the roles alone | `UserRow` | `users_test.dart`: the title names the project |
| An existing user is added by username, and an unknown one says so | `AddExistingUserDialog` | `users_test.dart`: an existing user, an unknown username |
| AC-N03: right to left in Arabic, left to right in English, nothing off a screen 360 points wide | Each screen | `my_account_test.dart`: AC-N03, once per language |

## Left to later use cases

Opening the project list right after sign-in, and the default project (UC-010).
