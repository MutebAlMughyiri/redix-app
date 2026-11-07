[Documentation](../README.md) › UC-006

# UC-006: Manage projects and units

**What it is for:** creating a project with its units, adding a unit later, and closing a finished project (FR-04).
**Who uses it:** whoever registers a project becomes its manager (UC-066); whoever holds `manageProject` in it, which Finance does, renames it, adds, renames and deletes units, and closes it; everyone with a role in it reads it (UC-009).
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
| Status | `HomeScreen.statusKey(id)` | Active or Finished |
| A unit | `HomeScreen.unitKey(id)` | The project's units, in order |
| No units yet | `HomeScreen.noUnitsKey(id)` | Shown while the project has no units |
| Add unit, in Settings | `SettingsScreen.addUnitKey` | Active projects, with `manageProject`: asks for a name and adds the unit at the end |
| Unit name | `SettingsScreen.unitNameKey` | In the Add unit dialog |
| Add unit, in the dialog | `SettingsScreen.saveUnitKey` | Sends the unit; disabled while waiting |
| Message, in the dialog | `SettingsScreen.unitMessageKey` | One line saying why the unit was refused |
| Rename project, in Settings | `SettingsScreen.renameProjectKey` | Active projects, with `manageProject`: asks for the name, starting from the current one (BR-38) |
| A unit's menu | `HomeScreen.unitMenuKey(id)` | Active projects, with `manageProject`; the shared unit is not on the list |
| Rename unit, in the menu | `HomeScreen.renameUnitKey` | Asks for the name, starting from the current one |
| Delete unit, in the menu | `HomeScreen.deleteUnitKey` | Asks first, naming the unit; a unit in use stays and the refusal says why |
| The name, in the rename dialogs | `NameDialog.nameKey` | |
| Save, in the rename dialogs | `ChangeDialog.saveKey` | Sends the name; a refusal stays in the dialog (`ChangeDialog.messageKey`) |
| The unit's name, in the delete question | `ConfirmDialog.subjectKey` | Which unit is being deleted |
| Delete unit, in the question | `ConfirmDialog.confirmKey` | Deletes the unit |
| Close project, in Settings | `SettingsScreen.closeProjectKey` | Active projects, with `manageProject`: asks first |
| The project's name, in the question | `SettingsScreen.closeNameKey` | Which project is being closed |
| What closing means, in the question | `SettingsScreen.closeExplainKey` | It becomes read-only, and this cannot be undone |
| Close project, in the question | `SettingsScreen.confirmCloseKey` | Closes the project |
| Cancel, in the question | `SettingsScreen.cancelCloseKey` | Changes nothing |
| No projects yet | `ProjectsScreen.emptyKey` | Shown while there are no projects |
| Could not load | `ProjectsScreen.messageKey` | Shown when the list cannot be read |
| Try again | `ProjectsScreen.retryKey` | Reads the list again |

New project, `NewProjectScreen` at `/projects/new`:

| Element | `Key` | Does |
| --- | --- | --- |
| Project name | `NewProjectScreen.nameKey` | Any name of 1 to 100 characters |
| Start date | `NewProjectScreen.startDateKey` | Today until changed; opens the date picker |
| Copy categories and items from | `NewProjectScreen.structureSourceKey` | The default template unless changed, or an approved earlier project (UC-012) |
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
| `POST /projects/{projectId}` | Rename project |
| `POST /projects/{projectId}/units/{unitId}` | Rename unit |
| `POST /projects/{projectId}/units/{unitId}/delete` | Delete unit, once confirmed |
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
| A read waits for the changes sent before it, so going back while a role is being saved still shows the new role on the home | `Session.get`, `Session._remember` | `user_roles_test.dart`: going back while a role is being saved |
| An expired access token is renewed once for each read, one renewal after another, so reads at once keep the session open | `Session._send`, `Session._renew` | `projects_test.dart`: an expired access token |
| A unit can be removed until the project is created | `NewProjectScreen` | `new_project_test.dart`: a unit can be removed |
| The start date is today until changed, and shows as dd.MM.yyyy (NFR-04) | `NewProjectScreen`, `formatDate` | `new_project_test.dart`: the start date; `date_format_test.dart` |
| Closing asks first and says what it means; Cancel changes nothing | `ProjectsScreen`, `ConfirmDialog` | `home_test.dart`: closing asks first |
| A finished project is read-only and stays listed (AC-04.1) | `Project.isFinished`, `ProjectCard`; `Project.IsReadOnly` in the API | `home_test.dart`: a finished project stays listed; Patrol |
| The list says when it is empty, and when it cannot load | `ApiList.load`, `ApiListBody` | `projects_test.dart`: with no projects yet; without a network |
| The list is read again after every answer, so someone else's change shows | `ApiList.change` | `home_test.dart`: a project someone else closed |
| A unit's name that repeats is refused with its own word, on the form and in Add unit (BR-37) | The API; the words `projects.unitNameTaken`, `register.unitNameTaken` | `new_project_test.dart`: a unit name the project already has; `home_test.dart`: a unit name the project already has |
| Whoever holds `manageProject` renames the open project and its units, each starting from the current name (BR-38) | `Projects.rename`, `Projects.renameUnit`, `NameDialog` | `home_test.dart`: whoever manages the project renames it; a unit is renamed from its menu |
| A name another unit holds stays in the dialog with its reason (BR-37) | `ChangeDialog` | `home_test.dart`: a name another unit holds |
| A unit is deleted only after asking, naming it; one in use stays and the refusal says why (BR-38) | `Projects.deleteUnit`, `ConfirmDialog`, `showRefusalOf` | `home_test.dart`: a unit is deleted from its menu; a unit that entries or contracts use |
| The shared unit is not on the list, and nothing offers a change without `manageProject` or in a finished project | `Project.units`, `ProjectCard` | `home_test.dart`: the shared unit is not on the list; without manageProject |
| A project with entries waiting for approval stays open, and the refusal says why (BR-35) | `showRefusalOf`, the word `projects.pendingEntries` | `home_test.dart`: a project with entries waiting for approval |
| Arabic names show as typed | `jsonOf` | `projects_test.dart`: Arabic names |
| AC-N03: right to left in Arabic, left to right in English, nothing off a screen 360 points wide | Each screen | `my_account_test.dart`: AC-N03, once per language |

## Left to later use cases

| What | Use case |
| --- | --- |
| Refusing new entries and approvals in a finished project | Each entry use case |
| Settings' other rows | Their own use cases, from UC-007 |
