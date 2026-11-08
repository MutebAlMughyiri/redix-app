[Documentation](../README.md) › UC-006

# UC-006: Manage projects and units

**What it is for:** creating a project with its units and description, keeping its own record on one page, More info, where units are added and the project is renamed, described and closed (FR-04, redix-api #93).
**Who uses it:** whoever registers a project becomes its manager (UC-066); whoever holds `manageProject` in it, which Finance does, renames it, adds, renames and deletes units, keeps its description, and closes it; everyone with a role in it reads More info (UC-009).
**Issue:** redix-app #26 and redix-api #93; the API side is redix-api #24.

## Screens

[Settings](../guide/settings.md), `SettingsScreen` at `/settings`, opened from the settings button on the list's top bar (`ProjectsScreen.settingsKey`) or a project's home (`HomeScreen.settingsKey`):

| Element | `Key` | Does |
| --- | --- | --- |
| Switch project | `SettingsScreen.switchProjectKey` | Goes to the list (UC-010) |
| My account | `SettingsScreen.myAccountKey` | Opens My account |
| More info | `SettingsScreen.projectInfoKey` | Only from a project, for everyone in it: opens More info |

[More info](../guide/projects.md#more-info), `ProjectInfoScreen` at `/projects/:projectId/info`, reading the project live from the app's list:

| Element | `Key` | Does |
| --- | --- | --- |
| Name | `ProjectInfoScreen.nameKey` | The project's name |
| Rename | `ProjectInfoScreen.renameKey` | Active projects, with `manageProject`: asks for the name, starting from the current one (BR-38) |
| Details | `ProjectInfoScreen.detailsKey` | The start date, and Read-only once finished |
| Status | `ProjectInfoScreen.statusKey` | Active or Finished |
| Units | `ProjectInfoScreen.unitsKey` | The heading of the units |
| Add unit | `ProjectInfoScreen.addUnitKey` | Active projects, with `manageProject`: asks for a name and adds the unit at the end |
| Unit name | `ProjectInfoScreen.unitNameKey` | In the Add unit dialog |
| Add unit, in the dialog | `ProjectInfoScreen.saveUnitKey` | Sends the unit; disabled while waiting |
| Message, in the dialog | `ProjectInfoScreen.unitMessageKey` | One line saying why the unit was refused |
| A unit | `ProjectInfoScreen.unitKey(id)` | The project's units, in order |
| No units yet | `ProjectInfoScreen.noUnitsKey` | Shown while the project has no units |
| A unit's menu | `ProjectInfoScreen.unitMenuKey(id)` | Active projects, with `manageProject`; the shared unit is not on the list |
| Rename unit, in the menu | `ProjectInfoScreen.renameUnitKey` | Asks for the name, starting from the current one |
| A unit's swipe | `ProjectInfoScreen.unitRowKey(id).swipe` | Active projects, with `manageProject`: swiped from its end toward its start, it is deleted with no question; one in use comes back and the refusal says why (redix-api #102) |
| The swipe hint | `ProjectInfoScreen.swipeHintKey` | Under the units, for whoever may delete them |
| The name, in the rename dialogs | `NameDialog.nameKey` | |
| Save, in the rename dialogs | `ChangeDialog.saveKey` | Sends the name; a refusal stays in the dialog (`ChangeDialog.messageKey`) |
| Description | `ProjectInfoScreen.descriptionHeadingKey` | The heading of the description |
| The description's field | `ProjectInfoScreen.descriptionKey` | Active projects, with `manageProject`: up to 2,000 characters, counted; starts from the kept description, and reading the project again never replaces what is typed |
| Save description | `ProjectInfoScreen.saveDescriptionKey` | Sends it; says "Description saved." (`messageKeyOf('projectInfo.saved')`), or why it was refused, keeping what was typed |
| The description, to read | `ProjectInfoScreen.descriptionTextKey` | For everyone else and in a finished project: the description, or "No description yet." |
| Close project | `ProjectInfoScreen.closeKey` | Active projects, with `manageProject`: asks first |
| The project's name, in the question | `ProjectInfoScreen.closeNameKey` | Which project is being closed |
| What closing means, in the question | `ProjectInfoScreen.closeExplainKey` | It becomes read-only, and this cannot be undone |
| Close project, in the question | `ProjectInfoScreen.confirmCloseKey` | Closes the project; the page turns read-only |
| Cancel, in the question | `ProjectInfoScreen.cancelCloseKey` | Changes nothing |

[Home](../guide/home.md), `HomeScreen` at `/projects/:projectId`, and the elements of the list, `ProjectsScreen` at `/` (UC-010):

| Element | `Key` | Does |
| --- | --- | --- |
| New project | `ProjectsScreen.newProjectKey` | Opens the new project form |
| A project's card | `HomeScreen.cardKey(id)` | The project's buttons; its start date, status and units are on More info |
| Name | `HomeScreen.titleKey` | The project's name, in the top bar |
| Finished · Read-only | `HomeScreen.finishedKey(id)` | Only on a finished project, one line at the top of the card |
| No projects yet | `ProjectsScreen.emptyKey` | Shown while there are no projects |
| Could not load | `ProjectsScreen.messageKey` | Shown when the list cannot be read |
| Try again | `ProjectsScreen.retryKey` | Reads the list again |

New project, `NewProjectScreen` at `/projects/new`:

| Element | `Key` | Does |
| --- | --- | --- |
| Project name | `NewProjectScreen.nameKey` | Any name of 1 to 100 characters |
| Description (optional) | `NewProjectScreen.descriptionKey` | Up to 2,000 characters, counted; also on Register a project (UC-066) |
| Start date | `NewProjectScreen.startDateKey` | Today until changed; opens the date picker |
| Copy categories and items from | `NewProjectScreen.structureSourceKey` | The default template unless changed, or an approved earlier project (UC-012) |
| Unit name | `NewProjectScreen.unitNameKey` | The next unit to add |
| Add unit | `NewProjectScreen.addUnitKey` | Adds it to the list below; disabled while the name is empty |
| A unit | `NewProjectScreen.unitKey(index)` | A unit to be created with the project |
| A unit's swipe | `NewProjectScreen.unitKey(number).swipe` | Takes it off the list; each unit keeps the number it was added with, so the next keeps its place (redix-api #102) |
| Create project | `NewProjectScreen.submitKey` | Sends everything at once; disabled while waiting |
| Message | `NewProjectScreen.messageKey` | One line saying why it was refused |

## API calls

| Call | When |
| --- | --- |
| `GET /projects` | Opening Projects, Try again, and after every answer to a change |
| `POST /projects` | Create project: the name, the start date, the units and the description, at once |
| `POST /projects/{projectId}/units` | Add unit |
| `POST /projects/{projectId}` | Rename project |
| `POST /projects/{projectId}/description` | Save description |
| `POST /projects/{projectId}/units/{unitId}` | Rename unit |
| `POST /projects/{projectId}/units/{unitId}/delete` | Delete unit, once confirmed |
| `POST /projects/{projectId}/close` | Close project, once confirmed |

All go through `Session`, which renews an expired access token once and sends again. Nothing about projects is kept on the phone, so these screens need a network.

## Rules and where they live

| Rule | Code | Test |
| --- | --- | --- |
| Everyone sees Switch project | `SettingsScreen` | `settings_test.dart`: anyone else sees Switch project and My account |
| More info is in Settings only when it is opened from a project, for everyone in it | `SettingsScreen` | `settings_test.dart`: anyone else sees Switch project and My account, and not the registered projects; from a project Settings opens after Reports and holds More info; `home_test.dart`: a reader or a field supervisor has More info |
| The home shows no start date, status or units; More info shows them, the units in order (redix-api #93 R1) | `ProjectCard`, `ProjectInfoScreen` | `home_test.dart`: R1; `project_info_test.dart`: R1 |
| A finished project's home says in one line that it is finished and read-only (R13) | `ProjectCard` | `home_test.dart`: R13; `project_info_test.dart`: closing makes it finished |
| Everyone in the project reads More info and its description; only `manageProject` changes it, and only while it is open (R8, AC-04.1) | `Project.mayManageProject`, `ProjectInfoScreen` | `project_info_test.dart`: R8; a finished project shows read-only; whoever manages an open project has Rename, Add unit…; `permission_gates_test.dart`: More info's five gates |
| The description is kept, empty clears it, and saving says "Description saved." (R3, R12) | `Projects.describe`, `ProjectInfoScreen` | `project_info_test.dart`: R3, R12; the description kept starts the field |
| A description has at most 2,000 characters, counted, on More info, New project and Register a project (R10) | `Project.descriptionMaxLength` | `project_info_test.dart`: R10; `new_project_test.dart`: R10; `register_project_test.dart`: R10 |
| A refused or unsent description says why and keeps what was typed; reading the project again never replaces it (R14) | `ProjectInfoScreen` | `project_info_test.dart`: R14, three tests |
| A description can be written when the project is made or registered, and none is needed (R5) | `Projects.create`, `registerProject` | `new_project_test.dart`: R5, two tests; `register_project_test.dart`: R5 |
| The admin reads the description before deciding; a project with none shows no line (R11) | `RegisteredProjectsScreen` | `registered_projects_test.dart`: R11, two tests |
| A project is created with its units, at once | `Projects.create`; `ProjectsEndpoints.Create` in the API | `new_project_test.dart`: a project is created with its units; Patrol |
| A unit typed but not yet added goes with the project | `NewProjectScreen` | `new_project_test.dart`: a unit typed but not yet added |
| redix-api #109: the partners declared in the form, the one still typed last, go with the project, from the list and from the sign-in page; a swipe takes one off. The units and the partners are one list, `TypedNames` | `NewProjectScreen`, `TypedNames`, `Projects.create`, `registerProject` | `new_project_test.dart`: redix-api #109; `register_project_test.dart`: sending returns to sign-in |
| A project needs no units | `NewProjectScreen` | `new_project_test.dart`: a project needs no units |
| Add unit waits for a name | `NewProjectScreen` | `new_project_test.dart`: Add unit waits for a name |
| A refused name shows its own line, and nothing typed is lost | `ApiList.change`, `NewProjectScreen` | `new_project_test.dart`: a refused name; `project_info_test.dart`: a refused name stays in the dialog |
| Without a network the form and the close say so, and nothing changes | `ApiList.change` | `new_project_test.dart`: without a network; `project_info_test.dart`: closing without a network |
| A refusal with no code shows the general word | `ApiList.change` | `project_info_test.dart`: a refusal with no code |
| A read waits for the changes sent before it, so going back while a permission is being saved still shows it on the home | `Session.get`, `Session._remember` | `user_permissions_test.dart`: going back while a permission is being saved |
| An expired access token is renewed once for each read, one renewal after another, so reads at once keep the session open | `Session._send`, `Session._renew` | `projects_test.dart`: an expired access token |
| A unit is swiped off the list until the project is created (redix-api #102) | `NewProjectScreen` | `new_project_test.dart`: redix-api #102: a unit is swiped off the list until the project is created |
| The start date is today until changed, and shows as dd.MM.yyyy (NFR-04) | `NewProjectScreen`, `formatDate` | `new_project_test.dart`: the start date; `date_format_test.dart` |
| Closing asks first and says what it means; Cancel changes nothing | `ProjectInfoScreen`, `ConfirmDialog` | `project_info_test.dart`: closing asks first |
| A finished project is read-only and stays listed (AC-04.1) | `Project.isFinished`, `ProjectInfoScreen`; `Project.IsReadOnly` in the API | `project_info_test.dart`: a finished project shows read-only; `home_test.dart`: R13; Patrol |
| The list says when it is empty, and when it cannot load | `ApiList.load`, `ApiListBody` | `projects_test.dart`: with no projects yet; without a network |
| The list is read again after every answer, so someone else's change shows | `ApiList.change` | `project_info_test.dart`: a project someone else closed |
| A unit's name that repeats is refused with its own word, on the form and in Add unit (BR-37) | The API; the words `projects.unitNameTaken`, `register.unitNameTaken` | `new_project_test.dart`: a unit name the project already has; `project_info_test.dart`: BR-37, two tests |
| Whoever holds `manageProject` renames the open project and its units, each starting from the current name; More info and the home follow (BR-38) | `Projects.rename`, `Projects.renameUnit`, `NameDialog` | `project_info_test.dart`: whoever manages the project renames it; a unit is renamed from its menu |
| A unit is deleted by a swipe with no question; a refused one comes back and the refusal says why (BR-38, redix-api #102) | `Projects.deleteUnit`, `SwipeToRemove` | `project_info_test.dart`: a unit is removed by a swipe; a refused unit comes back |
| Nothing offers a unit change without `manageProject` or in a finished project | `UnitRow` | `project_info_test.dart`: without manageProject; a finished project shows read-only |
| More info shows the project it was opened from | `Projects.latest` | `project_info_test.dart`: More info of a second project |
| A project with entries waiting for approval stays open, and the refusal says why (BR-35) | `showRefusalOf`, the word `projects.pendingEntries` | `project_info_test.dart`: BR-35; Patrol |
| Arabic names show as typed | `jsonOf` | `projects_test.dart`: Arabic names |
| AC-N03: right to left in Arabic, left to right in English, nothing off a screen 360 points wide | Each screen | `my_account_test.dart`: AC-N03, once per language |

## Left to later use cases

| What | Use case |
| --- | --- |
| Refusing new entries and approvals in a finished project | Each entry use case |
| Settings' other rows | Their own use cases, from UC-007 |
