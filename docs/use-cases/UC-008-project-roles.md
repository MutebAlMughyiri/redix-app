[Documentation](../README.md) › UC-008

# UC-008: Add people to a project and tick what each may do

**What it is for:** deciding who works on each project, and what each may do in it (FR-36). Since redix-api #89 "No roles: each person's permissions ticked per project" there are no roles: each person's permissions are ticked one by one.
**Who uses it:** each project's manager, for that project alone. What each permission opens is UC-009.
**Issue:** redix-app #28; the API side is redix-api #26 and #89.

## Screens

A project's Users, `UsersScreen` at `/projects/:projectId/users`, opened from Settings, and a person's permissions, `UserPermissionsScreen` at `/projects/:projectId/users/:userId/permissions`, opened from a person's menu (`UsersScreen.permissionsKey`):

| Element | `Key` | Does |
| --- | --- | --- |
| New user | `UsersScreen.newUserKey` | Opens the form; a new login is born in this project with what is ticked there |
| Add an existing user | `UsersScreen.addExistingKey` | Asks for their exact username (`UsersScreen.existingUsernameKey`) |
| Whose | `UserPermissionsScreen.nameKey` | The person's name |
| A permission's tick | `UserPermissionsScreen.permissionKey(permission)` | Gives or takes the permission, at once |

Every permission a project can give is listed, with what the person holds ticked. Unticking See the project takes them off the project. A refusal shows in a SnackBar.

## API calls

| Call | When |
| --- | --- |
| `GET /projects/{projectId}/users` | Opening Users, and after every answer |
| `POST /projects/{projectId}/users` | Adding a new user, with what is ticked |
| `POST /projects/{projectId}/users/existing` | Adding an existing user |
| `POST /projects/{projectId}/users/{userId}/permissions/{permission}` | Ticking a permission |
| `POST /projects/{projectId}/users/{userId}/permissions/{permission}/remove` | Unticking a permission |

## Rules and where they live

| Rule | Code | Test |
| --- | --- | --- |
| The screen names whose permissions these are and ticks every one a project can give, with what they hold ticked | `UserPermissionsScreen` | `user_permissions_test.dart`: the screen says whose permissions these are |
| A tick gives the permission at once, by its name, and unticking takes it away | `UserPermissionsScreen`, `Users.give`, `Users.take` | `user_permissions_test.dart`: a tick gives the permission at once |
| Unticking See the project takes them off the list | `Users.take` | `user_permissions_test.dart`: unticking See the project |
| A refusal shows its word in a SnackBar, and nothing changes | `showRefusalOf` | `user_permissions_test.dart`: a refusal shows its word |
| Going back while a permission is being saved, the home reads only after it is saved | `UserPermissionsScreen` | `user_permissions_test.dart`: going back while a permission is being saved |
| What is ticked is sent with a new user, and See the project is always ticked | `NewUserScreen` | `new_user_test.dart`: what is ticked is sent with the new user |
| An existing user is added by username, and an unknown one says so | `AddExistingUserDialog` | `users_test.dart`: an existing user is added, an unknown username stays |
| AC-N03: right to left in Arabic, left to right in English, nothing off a screen 360 points wide | Each screen | `settings/account_test.dart`: AC-N03 |

## Left to later use cases

Opening the project list right after sign-in, and the default project (UC-010).
