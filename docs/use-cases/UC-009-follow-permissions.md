[Documentation](../README.md) › UC-009

# UC-009: Follow what the user may do

**What it is for:** showing each person the controls their role allows in each project, with no role's rights written in the app.

**Who uses it:** everyone. A project manager gives roles.
**Issue:** redix-app #75; the API side is redix-api #27.

## What it does

| Where | Shows | When |
| --- | --- | --- |
| Projects | Only the projects with access, each with the person's roles | Always |
| Projects | Register new project | Always |
| A project's card | Users | The project says `manageUsers` |
| A project's card | Add unit, Close project | The project says `manageProject` |
| Settings | Projects, My account | Always |
| Settings | Registered projects | The session says `approveProjects` |
| A project's Users | New user, Add an existing user; a menu on each row | Always, on this screen |
| Roles | A tick for each project role, as the API lists them | Always, on this screen |

A new person starts at the last project role the API lists. The app names no role: a role is a row from the API with a word of its own, so a role added in the database appears here with no release.

## Rules and where they are proven

| Rule | Test |
| --- | --- |
| Anyone signed in can register a project | `projects_test.dart` |
| Users on a card shows only with `manageUsers` | `projects_test.dart` |
| Add unit and Close show only with `manageProject` | `projects_test.dart` |
| A project's roles show under its name | `projects_test.dart` |
| Settings shows Registered projects only with `approveProjects` | `settings_test.dart` |
| A project's Users lists only its people | `project_users_test.dart` |
| An existing user is added by username, and an unknown one says so | `project_users_test.dart` |
| Roles come from the API, a new one included | `user_roles_test.dart` |
| Several roles can be held; the last manager's refusal shows its word | `user_roles_test.dart` |
| A journey on a real phone | `patrol_test/app_test.dart` |
