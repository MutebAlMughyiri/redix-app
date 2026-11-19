[Documentation](../README.md) › UC-072

# UC-072: Add an entry from the app's icon and the home-screen widget

**What it is for:** reaching Add entry without opening the project first (the owner, 8 and 15 Nov 2026): holding REDIX's icon offers «إضافة قيد», and a home-screen widget does the same, with the latest entries under its button.
**Who uses it:** everyone who records entries; anyone else lands where the app would let them.
**Issue:** redix-app #86 "Add entry from the app icon's long press, and home-screen widgets for Add entry and the capital", revision 2 of its design. The API holds only its one word, `home.widgetReadAt`.

## The rule

«إضافة قيد» outside the app is one link, `/add-entry` (`LauncherAddEntry.path`). The router resolves it against the session once the projects are read, beside `HomeScreen.landingOf`, in `HomeScreen.addEntryLandingOf`:

| The person | `/add-entry` lands on |
| --- | --- |
| Signed out | Sign-in, the router's own redirect; once signed in, the home, as every sign-in lands (G1) |
| No default project, or one they may no longer open | The project list |
| Default project, may record | Add entry in it, its home behind to come back to |
| Default project, may not record | Its home, where «إضافة قيد» is gray |

Add entry sits under its project's home in the router (`AddEntryScreen.path`, `entries/new`), so a link that opens it has the home behind it; reached by a link it reads its project from the list the landing read.

## Outside the app

Drawn by the phone's launcher, not by Flutter. One owner, `LauncherAddEntry` (`lib/launcher/launcher_add_entry.dart`), writes what they say from the app's words each time the words load, at start, at a change of language and at a retry (`WordsDelegate.onLoaded`), and nothing while the phone has no words yet.

| Element | Where | Does |
| --- | --- | --- |
| «إضافة قيد» on the icon's menu | A dynamic shortcut through Flutter's `quick_actions` (D4), the menu's only item, titled `entries.new` | Opens `/add-entry`, also when the tap starts the app (`LauncherAddEntry.listen`) |
| «إضافة قيد» on the home-screen widget | `AddEntryWidget` (`android/app/src/main/kotlin/redix/AddEntryWidget.kt`), an Android AppWidget through `home_widget` (D5); its label and link are saved by `LauncherAddEntry.showWords` | Opens `https://{linkHost}/add-entry` straight to the app's activity, as a link reaches it; before the app has run once, the app as its icon opens it |
| The home-screen widget's rows | Saved through `home_widget` each time the home reads «آخر القيود» (`HomeScreen`, `NewestEntries.firstPage`, D8): as many as «عدد القيود المعروضة», each its title, its card's details line (`EntryCard.detailsOf`) and its amount, with when they were read, «آخر تحديث 15/11/2026 10:30» (`home.widgetReadAt`) | A row opens its entry's own link (`EntryShare.linkOf`, `EntryLinkScreen`, D9); nothing reads in the background, and a read that fails leaves the rows as they were (G6) |

The widget is `res/layout/add_entry_widget.xml`: the button in the app's own color, Android's list of the rows (`entry_widget_row.xml`, fed through `RemoteViewsCompat`), and the time they were read; with no rows it shows the button alone (D10). Its ground and words follow the phone's light or dark mode. The launcher's picker names it by the app's name and one line, the only words shown before the app runs (G5): «زر لإضافة قيد», and "A button to add an entry" on a phone in English (`res/values/strings.xml`, `res/values-en/strings.xml`). The Huawei's launcher shows Android's shortcuts and widgets, so it needs nothing of its own (D6); the iPhone's widget waits for a Mac (D7).

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
| R1, AC-86.4: the icon's menu holds «إضافة قيد» alone, and the widget's button says it, in the app's language | `LauncherAddEntry.showWords`, `WordsDelegate.onLoaded` | `launcher/launcher_add_entry_test.dart`: R1, AC-86.4, in each language |
| R5: a first start with no words writes nothing outside the app | `LauncherAddEntry.showWords` | `launcher/launcher_add_entry_test.dart`: R5 |
| AC-86.1: a tap on the icon's «إضافة قيد», or a start from it, opens Add entry in the default project; a start from the icon itself, the home | `LauncherAddEntry.listen`, `RedixApp` | `launcher/launcher_add_entry_test.dart`: AC-86.1, three cases |
| R10, AC-86.8: however the session ends, the widget's rows and their time are emptied; a renewal empties nothing | `LauncherAddEntry.forgetEntries`, `RedixApp` listening to `Session.access` | `launcher/launcher_add_entry_test.dart`: R10, AC-86.8; R10: a renewal |
| R9, AC-86.7: the widget lists what «آخر القيود» read, as many as show at a time, each as its card says it, and when, in the word «آخر تحديث {0}» | `HomeScreen`, `NewestEntries.firstPage`, `LauncherAddEntry.showEntries`, `EntryCard.detailsOf` | `launcher/launcher_add_entry_test.dart`: R9, AC-86.7; R9, G7: at 8 |
| R9: Show more adds nothing to the widget | `NewestEntries.firstPage` | `launcher/launcher_add_entry_test.dart`: R9: Show more |
| AC-86.7: a row's link opens its entry | `EntryShare.linkOf`, `EntryLinkScreen` | `launcher/launcher_add_entry_test.dart`: AC-86.7: a row's link |
| R10, AC-86.8: the rows read before signing out are gone once signed out | `LauncherAddEntry.forgetEntries` | `launcher/launcher_add_entry_test.dart`: R10, AC-86.8: the rows |
| AC-86.2, AC-86.3, AC-86.5, AC-86.6, AC-86.7 on the phone: the widget's tap lands as the rule says, and a row opens its entry | `AddEntryWidget`, the router | Patrol `launcher/add_entry_launcher_test.dart`, through `Pc.tapTheWidget` |
