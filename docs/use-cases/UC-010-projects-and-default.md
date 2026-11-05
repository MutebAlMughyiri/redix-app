[Documentation](../README.md) › UC-010

# UC-010: Pick, switch and set the default project

**What it is for:** after sign-in, choosing a project, seeing it, and managing it by your role in it (FR-36, FR-37).
**Who uses it:** everyone signed in.
**Issue:** redix-app #29; the API side is redix-api #28.

## Where a person lands

Decided at app start and at sign-in, and nowhere else:

| State | Lands on |
| --- | --- |
| A default, with "open directly" on, and still with access | That project's home |
| Anything else | The list |

## Screens

The list, `ProjectsScreen` at `/`:

| Element | `Key` | Does |
| --- | --- | --- |
| Choose a project | `ProjectsScreen.titleKey` | The heading |
| A project's card | `ProjectsScreen.cardKey(id)` | Opens its home |
| Its star | `ProjectsScreen.starKey(id)` | Makes it the default, or clears it |
| Open directly | `ProjectsScreen.openDefaultKey` | Disabled until there is a default |
| Settings | `ProjectsScreen.settingsKey` | Opens Settings |
| Register new project | `ProjectsScreen.newProjectKey` | Opens the form (UC-066) |

The home, `HomeScreen` at `/projects/:projectId`, shows the project's card, with Users (`manageUsers`), and Add unit and Close project (`manageProject`). Settings has **Switch project** (`SettingsScreen.switchProjectKey`), which goes to the list.

## Rules and where they live

| Rule | Test |
| --- | --- |
| Sign-in shows the list | `projects_test.dart` |
| A card opens its home, and back returns to the list | `home_test.dart` |
| The buttons follow the role in the open project (AC-36.2) | `home_test.dart` |
| The list has no change buttons | `projects_test.dart` |
| The star sets, moves and clears the default | `projects_test.dart` |
| The switch waits for a default | `projects_test.dart` |
| A default with the switch on opens directly at sign-in and at start (AC-37.1) | `home_test.dart` |
| A project gone while open returns to the list | `home_test.dart` |
| Switch project reaches the list | `settings_test.dart` |
| A journey on a real phone | `patrol_test/app_test.dart` |
