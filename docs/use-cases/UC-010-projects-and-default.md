[Documentation](../README.md) › UC-010

# UC-010: Pick, switch and set the default project

**What it is for:** after sign-in, choosing a project, seeing it, and managing it by your role in it (FR-36, FR-37).
**Who uses it:** everyone signed in.
**Issue:** redix-app #29; the API side is redix-api #28.

## Where a person lands

Decided at app start and at sign-in, and nowhere else:

| State | Lands on |
| --- | --- |
| A default, still with access: a default always opens directly (Muteb, 8 Nov 2026) | That project's home |
| Anything else | The list |

## Screens

The list, `ProjectsScreen` at `/`:

| Element | `Key` | Does |
| --- | --- | --- |
| Choose a project | `ProjectsScreen.titleKey` | The heading |
| A project's card | `ProjectsScreen.cardKey(id)` | Opens its home; one the user was made inactive in shows gray and disabled, `ProjectsScreen.detailsKey(id)` saying «حسابك غير مفعّل في هذا المشروع.», with no star, and does not open (redix-api #126 D2) |
| Its star | `ProjectsScreen.starKey(id)` | Makes it the default, saying so in a message (`messageKeyOf('projects.defaultSet')`), or clears it |
| Settings | `ProjectsScreen.sharedSettingsKey` | Opens Settings |
| Register new project | `ProjectsScreen.newProjectKey` | Opens the form (UC-066) |

Settings, `SharedSettingsScreen`, has **Default project** (`SharedSettingsScreen.defaultProjectKey`), which opens `DefaultProjectSheet`:

| Element | `Key` | Does |
| --- | --- | --- |
| Title, what the tick does | `DefaultProjectSheet.titleKey`, `hintKey` | |
| A project's tick | `DefaultProjectSheet.optionKey(id)`, `.title` | Every approved project; the default is ticked. Ticking makes it the default and says so; ticking another moves it; unticking clears it |

The star and the tick change the default through one owner, `toggleDefaultProject`.

The home, `HomeScreen` at `/projects/:projectId`, shows the project's card; its Settings hold Users (`manageUsers`) and More info, where Add unit and Close project are (`manageProject`, UC-006). Settings has **Switch project** (`SharedSettingsScreen.switchProjectKey`), which goes to the list.

The button beside Settings, `HomeScreen.collapseKey`, hides the conclusion (`SummaryCard`) and the project's buttons (`ProjectSettingsCard`) completely, and shows them again. The phone keeps it as `summary_projectSetting_state`, 1 expanded and 0 collapsed, through `LocalConfig`.

## Rules and where they live

| Rule | Test |
| --- | --- |
| Sign-in shows the list | `projects_test.dart` |
| redix-app #91 R1, R2: the button beside Settings hides the summary completely, and shows it again | `collapsed_home_test.dart` |
| R4: the project's buttons hide with it | `collapsed_home_test.dart` |
| R5: the icon says what the next tap does: `unfold_less` while everything shows, `unfold_more` while collapsed | `collapsed_home_test.dart` |
| R6, R9: the phone keeps how it was left through a restart and a sign-out | `collapsed_home_test.dart` |
| R7: custody, the entries and Add entry stay | `collapsed_home_test.dart` |
| R8: it is kept as `summary_projectSetting_state`, 0 collapsed and 1 expanded; a key not found starts expanded and is set to 1 | `collapsed_home_test.dart` |
| R10: a collapsed home hides them from the first frame | `collapsed_home_test.dart` |
| A card opens its home, and back returns to the list | `home_test.dart` |
| The buttons follow the role in the open project (AC-36.2) | `home_test.dart` |
| The list has no change buttons | `projects_test.dart` |
| AC-37.1: the star makes a project the default and a message says so; it moves and clears the default; a refusal says why | `projects_test.dart` |
| Default project in Settings lists every approved project with a tick, none waiting or rejected; ticking sets and moves the default and says so, unticking clears it, a refusal says why | `shared_settings_test.dart` |
| AC-37.1: a default opens directly at sign-in and at start | `home_test.dart` |
| A project gone while open returns to the list | `home_test.dart` |
| redix-api #126 D2: a project the user was made inactive in shows gray and disabled, saying so under its name, with no star, and does not open; one he is active in beside it opens | `projects_test.dart` |
| redix-api #126 R4: made inactive in the open project, the project list replaces its screens at the next renewal; still active, the home stays | `home_test.dart` |
| Switch project reaches the list | `shared_settings_test.dart` |
| On a real phone, against the real API | `patrol_test/projects/project_list_test.dart`, `patrol_test/projects/default_project_test.dart`, `patrol_test/home/collapse_home_test.dart` |
