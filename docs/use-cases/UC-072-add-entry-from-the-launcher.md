[Documentation](../README.md) › UC-072

# UC-072: Add an entry from the app's icon and the home-screen widget

**What it is for:** reaching Add entry without opening the project first (Muteb, 8 and 15 Nov 2026): holding REDIX's icon offers «إضافة قيد», and a home-screen widget does the same, with the latest entries under its button.
**Who uses it:** everyone who records entries; anyone else lands where the app would let them.
**Issue:** redix-app #86 "Add entry from the app icon's long press, and home-screen widgets for Add entry and the capital", revision 2 of its design. The API is untouched.

## The rule

«إضافة قيد» outside the app is one link, `/add-entry` (`LauncherAddEntry.path`). The router resolves it against the session once the projects are read, beside `HomeScreen.landingOf`, in `HomeScreen.addEntryLandingOf`:

| The person | `/add-entry` lands on |
| --- | --- |
| Signed out | Sign-in, the router's own redirect; once signed in, the home, as every sign-in lands (G1) |
| No default project, or one they may no longer open | The project list |
| Default project, may record | Add entry in it, its home behind to come back to |
| Default project, may not record | Its home, where «إضافة قيد» is gray |

Add entry sits under its project's home in the router (`AddEntryScreen.path`, `entries/new`), so a link that opens it has the home behind it; reached by a link it reads its project from the list the landing read.

## API calls

| Call | When |
| --- | --- |
| `GET /projects` | Before `/add-entry` lands, so a start from the launcher knows whether the person may still open the default project and record in it |

## Rules and where they live

| Rule | Code | Test |
| --- | --- | --- |
| AC-86.1, AC-86.2: whoever records in the default project lands on Add entry in it, the home behind | `HomeScreen.addEntryLandingOf`, the `/add-entry` route in `main.dart` | `launcher/add_entry_landing_test.dart`: AC-86.1, AC-86.2 |
| AC-86.1: started by the link, before the projects are read, the app still lands on Add entry | `_addEntryLanding` in `main.dart` | `launcher/add_entry_landing_test.dart`: started by the link |
| AC-86.3: without a default project, or with one the person is inactive in, the project list | `HomeScreen.addEntryLandingOf`, `Project.mayOpen` | `launcher/add_entry_landing_test.dart`: AC-86.3, twice |
| AC-86.6: whoever may not record lands on the home, «إضافة قيد» gray | `HomeScreen.addEntryLandingOf`, `Project.mayEnterExpenses` | `launcher/add_entry_landing_test.dart`: AC-86.6 |
| AC-86.5, G1: signed out, sign-in; then the home | the router's redirect in `main.dart` | `launcher/add_entry_landing_test.dart`: AC-86.5, G1 |
