[Documentation](../README.md) › UC-006

# UC-006: Manage projects and units

**What it is for:** creating a project with its units, adding a unit later, and closing a finished project (FR-04).
**Who uses it:** whoever registers a project becomes its manager (UC-066); its financial supervisors add units and close it; everyone with a role in it reads it (UC-009).
**Issue:** redix-app #26; the API side is redix-api #24.

## Screens

[Settings](../guide/settings.md), `SettingsScreen` at `/settings`, opened from the settings button on the list's top bar (`ProjectsScreen.settingsKey`) or a project's home (`HomeScreen.settingsKey`):

| Element | `Key` | Does |
| --- | --- | --- |
| Switch project | `SettingsScreen.switchProjectKey` | Goes to the list (UC-010) |
| My account | `SettingsScreen.myAccountKey` | Opens My account |

[Home](../guide/home.md), `HomeScreen` at `/projects/:projectId`, and the elements of the list, `ProjectsScreen` at `/` (UC-010):

| Element | `Key` | Does |
| --- | --- | --- |
| New project | `ProjectsScreen.newProjectKey` | Opens the new project form |
| A project's card | `HomeScreen.cardKey(id)` | One project; running projects first, then the newest |
| Name | `HomeScreen.titleKey` | The project's name, in the top bar |
| Details | `HomeScreen.detailsKey(id)` | The start date, and Read-only once finished |
| Status | `HomeScreen.statusKey(id)` | Running or Finished |
| A unit | `HomeScreen.unitKey(id)` | The project's units, in order |
| No units yet | `HomeScreen.noUnitsKey(id)` | Shown while the project has no units |
| Add unit | `HomeScreen.addUnitKey(id)` | Running projects only: asks for a name and adds the unit at the end |
| Unit name | `HomeScreen.unitNameKey` | In the Add unit dialog |
| Add unit, in the dialog | `HomeScreen.saveUnitKey` | Sends the unit; disabled while waiting |
| Message, in the dialog | `HomeScreen.unitMessageKey` | One line saying why the unit was refused |
| Close project | `HomeScreen.closeKey(id)` | Running projects only: asks first |
| The project's name, in the question | `HomeScreen.closeNameKey` | Which project is being closed |
| What closing means, in the question | `HomeScreen.closeExplainKey` | It becomes read-only, and this cannot be undone |
| Close project, in the question | `HomeScreen.confirmCloseKey` | Closes the project |
| Cancel, in the question | `HomeScreen.cancelCloseKey` | Changes nothing |
| No projects yet | `ProjectsScreen.emptyKey` | Shown while there are no projects |
| Could not load | `ProjectsScreen.messageKey` | Shown when the list cannot be read |
| Try again | `ProjectsScreen.retryKey` | Reads the list again |

New project, `NewProjectScreen` at `/projects/new`:

| Element | `Key` | Does |
| --- | --- | --- |
| Project name | `NewProjectScreen.nameKey` | Any name of 1 to 100 characters |
| Start date | `NewProjectScreen.startDateKey` | Today until changed; opens the date picker |
| Unit name | `NewProjectScreen.unitNameKey` | The next unit to add |
| Add unit | `NewProjectScreen.addUnitKey` | Adds it to the list below; disabled while the name is empty |
| A unit | `NewProjectScreen.unitKey(index)` | A unit to be created with the project |
| Remove unit | `NewProjectScreen.removeUnitKey(index)` | Takes it off the list |
| Create project | `NewProjectScreen.submitKey` | Sends everything at once; disabled while waiting |
| Message | `NewProjectScreen.messageKey` | One line saying why it was refused |

## API calls

| Call | When |
| --- | --- |
| `GET /projects` | Opening Projects, Try again, and after every answer to a change |
| `POST /projects` | Create project: the name, the start date and the units, at once |
| `POST /projects/{projectId}/units` | Add unit |
| `POST /projects/{projectId}/close` | Close project, once confirmed |

All go through `Session`, which renews an expired access token once and sends again. Nothing about projects is kept on the phone, so these screens need a network.

## Rules and where they live

| Rule | Code | Test |
| --- | --- | --- |
| Everyone sees Switch project | `SettingsScreen` | `settings_test.dart`: anyone else sees Switch project and My account |
| A project is created with its units, at once | `Projects.create`; `ProjectsEndpoints.Create` in the API | `new_project_test.dart`: a project is created with its units; Patrol |
| A unit typed but not yet added goes with the project | `NewProjectScreen` | `new_project_test.dart`: a unit typed but not yet added |
| A project needs no units | `NewProjectScreen` | `new_project_test.dart`: a project needs no units |
| Add unit waits for a name | `NewProjectScreen` | `new_project_test.dart`: Add unit waits for a name |
| A refused name shows its own line, and nothing typed is lost | `ApiList.change`, `NewProjectScreen` | `new_project_test.dart`: a refused name |
| Without a network the form and the close say so, and nothing changes | `ApiList.change` | `new_project_test.dart`: without a network; `home_test.dart`: closing without a network |
| A refusal with no code shows the general word | `ApiList.change` | `home_test.dart`: a refusal with no code |
| An expired access token is renewed once when reading the list too | `Session._send` | `projects_test.dart`: an expired access token |
| A unit can be removed until the project is created | `NewProjectScreen` | `new_project_test.dart`: a unit can be removed |
| The start date is today until changed, and shows as dd.MM.yyyy (NFR-04) | `NewProjectScreen`, `formatDate` | `new_project_test.dart`: the start date; `date_format_test.dart` |
| Closing asks first and says what it means; Cancel changes nothing | `ProjectsScreen`, `ConfirmDialog` | `home_test.dart`: closing asks first |
| A finished project is read-only and stays listed (AC-04.1) | `Project.isFinished`, `ProjectCard`; `Project.IsReadOnly` in the API | `home_test.dart`: a finished project stays listed; Patrol |
| The list says when it is empty, and when it cannot load | `ApiList.load`, `ApiListBody` | `projects_test.dart`: with no projects yet; without a network |
| The list is read again after every answer, so someone else's change shows | `ApiList.change` | `home_test.dart`: a project someone else closed |
| Arabic names show as typed | `jsonOf` | `projects_test.dart`: Arabic names |
| AC-N03: right to left in Arabic, left to right in English, nothing off a screen 360 points wide | Each screen | `my_account_test.dart`: AC-N03, once per language |

## Left to later use cases

| What | Use case |
| --- | --- |
| Copying the structure from the template or an earlier project (AC-05.2) | UC-012, the first with categories and items to copy |
| Refusing new entries and approvals in a finished project | Each entry use case |
| Settings' other rows | Their own use cases, from UC-007 |
