[Documentation](../README.md) › UC-008

# UC-008: Assign users to projects with a role

**What it is for:** deciding who works on which project, and as what (FR-36).
**Who uses it:** owners. What each role may then do is UC-009.
**Issue:** redix-app #28; the API side is redix-api #26.

## Screen

Projects and roles, `UserProjectsScreen` at `/users/:userId/projects`, opened from a user's menu (`UsersScreen.projectsKey`); an owner's menu does not offer it:

| Element | `Key` | Does |
| --- | --- | --- |
| Whose | `UserProjectsScreen.nameKey` | The user's name |
| A project's tick | `UserProjectsScreen.tickKey(projectId)` | Gives or takes away the project, at once |
| Finance, Field and Reader | `UserProjectsScreen.roleKey(projectId, role)` | The role in that project, at once; shown while ticked |

A project starts as Reader when ticked: the least a user can be given, so a stray tick gives the least. A refusal shows in a SnackBar.

## API calls

| Call | When |
| --- | --- |
| `GET /projects`, `GET /users` | Opening the screen, and after every answer |
| `POST /users/{userId}/projects/{projectId}` | Ticking, or choosing a role |
| `POST /users/{userId}/projects/{projectId}/remove` | Unticking |

## Rules and where they live

| Rule | Code | Test |
| --- | --- | --- |
| Ticking gives the project as Reader | `UserProjectRow` | `user_projects_test.dart`: ticking |
| Choosing a role changes it at once | `Users.assign` | `user_projects_test.dart`: choosing a role |
| Unticking takes the project away | `Users.remove` | `user_projects_test.dart`: unticking |
| A finished project can be given, and says it is finished | `UserProjectRow` | `user_projects_test.dart`: a finished project |
| A user's row shows their projects and roles | `UserRow` | `users_test.dart`: a row shows |
| An owner's row says every project, and its menu has no Projects and roles | `UserRow` | `users_test.dart`: an owner's row |
| AC-N03: right to left in Arabic, left to right in English, nothing off a screen 360 points wide | Each screen | `my_account_test.dart`: AC-N03, once per language |

## Left to later use cases

What each role may do (UC-009), and the list where a user opens their projects, with the default project (UC-010).
