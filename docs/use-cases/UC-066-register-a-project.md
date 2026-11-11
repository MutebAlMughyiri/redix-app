[Documentation](../README.md) › UC-066

# UC-066: Register a project, and approve it

**What it is for:** registering a new project from the sign-in page, and the admin's list of what is waiting.
**Who uses it:** anyone registers. Only the admin sees Registered projects.
**Issue:** redix-app #79; the API side is redix-api #83.

## Screens

| Screen | `Key` | Does |
| --- | --- | --- |
| Sign in | `SignInScreen.registerKey` | Opens the form |
| Register new project, at `/register` | `NewProjectScreen.*Key` | The project and its manager; open with no session |
| Projects | `ProjectsScreen.newProjectKey` | The same for someone signed in, with their own login |
| A waiting project | `ProjectsScreen.statusKey(id)` | Says it is waiting, with nothing to do |
| A rejected project | `ProjectsScreen.reasonKey(id)` | Says why |
| Settings | `SharedSettingsScreen.registeredKey` | With `approveProjects`: opens Registered projects |
| Registered projects, at `/registered-projects` | `RegisteredProjectsScreen.approveKey(id)`, `rejectKey(id)` | What is waiting, with the manager's details |

## Rules and where they are proven

| Rule | Test |
| --- | --- |
| The sign-in page leads to the form, with no session | `sign_in_test.dart` |
| A refusal stays on the form with what was typed | `register_project_test.dart` |
| A refusal under the send button comes into view, since on a phone it would fall below the screen | `patrol_test/projects/register_project_test.dart`, `new_project_test.dart` |
| Once sent, it returns to sign-in and says so | `register_project_test.dart` |
| A waiting or rejected project offers nothing | `projects_test.dart` |
| Only `approveProjects` sees Registered projects | `shared_settings_test.dart` |
| Approve, and Reject with a reason | `registered_projects_test.dart` |
| On a real phone, against the real API | `patrol_test/projects/register_project_test.dart`, `patrol_test/projects/approve_projects_test.dart` |
