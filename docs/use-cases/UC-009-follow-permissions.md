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
| A project's card | Reports, المصروفات, الإيرادات, working; gray, never hidden, without it | The project says `seeReports` (redix-api #131) |
| Reports | Issue, working; gray without it | The project says `generateReports` and is active (redix-api #131) |
| Every report, and a contract's menu | PDF, Excel and Print, working; gray without it | The project says `generateReports` (redix-api #131) |
| Contracts | A contract's card opens its own table | The project says `seeReports` (redix-api #131) |
| More info | Rename, Add unit, a unit's menu, the description's field and Save, Close project | The project says `manageProject` and is active |
| Settings | Switch project, the default project, the language and the account | Always |
| Settings | Registered projects | The session says `approveProjects` |
| A project's Users | New user, Add an existing user; a menu on each row | Always, on this screen |
| Roles | A tick for each project role, as the API lists them | Always, on this screen |
| A person's permissions, the new-user form | «الجداول»: each category folded, each item ticking its tables at once, half-ticked while some are, each table ticked while the person sees it (redix-api #106 D8) | Always, on these screens |
| صلاحياتي | «الجداول التي تراها», read only, and under it that the periodic report is for whoever sees every table (redix-api #106 D9) | Always |
| A project's card | Reports gray, never hidden, for someone who does not see every table; المصروفات and الإيرادات stay | The project's `unseenTables` is not empty (redix-api #106 R7) |
| Contracts | The statement's PDF and Excel gray for someone who does not see every table | The project's `unseenTables` is not empty (redix-api #106 R12) |

A new person starts at the last project role the API lists. The app names no role: a role is a row from the API with a word of its own, so a role added in the database appears here with no release.

## Rules and where they are proven

| Rule | Test |
| --- | --- |
| Anyone signed in can register a project | `projects_test.dart` |
| Users on a project's home shows only with `manageUsers` | `home_test.dart` |
| Rename, Add unit, the unit menus, the description and Close show only with `manageProject` | `project_info_test.dart`, `permission_gates_test.dart` |
| A project shows under its name what the signed-in user may do in it | `projects_test.dart` |
| Settings shows Registered projects only with `approveProjects` | `shared_settings_test.dart` |
| A project's Users lists only its people | `users_test.dart` |
| An existing user is added by username, and an unknown one says so | `users_test.dart` |
| Every permission a project can give is ticked one by one, at once (redix-api #89) | `user_permissions_test.dart` |
| A refusal shows its word, and nothing changes | `user_permissions_test.dart` |
| redix-api #131: a report's button without its permission shows gray, never hidden, and works once it is held | `permission_gates_test.dart`, `project_settings_test.dart`, `report_files_test.dart`, `patrol_test/home/buttons_test.dart`, `patrol_test/reports/periodic_report_test.dart` |
| Each permission on a real phone, against the real API | `patrol_test/users/user_permissions_test.dart`, `patrol_test/users/my_permissions_test.dart` |
| redix-api #106 R5, D8: every table is ticked until unticked, each category folded under «الجداول» | `table_ticks_test.dart` |
| redix-api #106 R4: unticking a table sends it and half-ticks its item; ticking it again sends it back | `table_ticks_test.dart` |
| redix-api #106 D8: an item's tick unticks all its tables at once | `table_ticks_test.dart` |
| redix-api #106 R3: a new person is added with the tables the form left unticked | `table_ticks_test.dart` |
| redix-api #106 D9, R7: صلاحياتي shows the tables one sees, read only, and the periodic reports button is gray for someone narrowed | `table_ticks_test.dart` |
| redix-api #106 on a real phone: a manager unticks a table and its entry leaves the person's القيود; صلاحياتي shows what one sees | `patrol_test/users/table_sight_test.dart` |
