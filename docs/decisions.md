[Documentation](README.md) › Decisions

# Decisions

Newest first. Each says what was decided and why; the code and the issues hold the details.

| Date | Decision | Why |
| --- | --- | --- |
| 2026-11-05 | Projects and roles is its own screen, saved at each tick, not a section of the new user form | One way to assign, for new and existing users; it differs from the canvas, and a new user takes two steps |
| 2026-11-05 | A newly ticked project starts as Reader, and the role is three chips that wrap | Reader is the least a user can be given; Muteb added it, and three choices do not fit the canvas's switch at 360 points |
| 2026-11-05 | Signing out always leaves this phone; the server is told when it can be reached | Leaving a shared phone must always work; the phone forgets its tokens, and the server closes the session after 12 hours unused |
| 2026-11-05 | One class to a file, and what a second feature needs moves to one owner: `ApiList`, `ApiListBody`, `ConfirmDialog`, `ChangeDialog`, `showRefusalOf` | Muteb: "our code must be simple and clean, well structured"; seven more settings lists are coming, and a copy would drift |
| 2026-11-05 | New user is a form of its own, not under the list as on the canvas, and a row's actions are in Material's menu, not a strip under the row | One look across settings lists, and Material draws and places the menu |
| 2026-11-05 | The form has Mobile, which may be empty | The canvas lacks it; the issues and the database design have it, and nothing uses it yet |
| 2026-11-05 | Settings is a list of rows holding Projects and My account, and home opens it | The canvas puts Settings in both roles' navigation with My account inside it; rows are Material's own, and only two members exist so far, against the canvas's nine pills |
| 2026-11-05 | Each project is a card on the list, carrying Add unit and Close project, with no details screen | The canvas draws settings sections this way, and it means one screen fewer |
| 2026-11-05 | Close and Add unit are Material dialogs, not the canvas's bottom sheet | Flutter's dialog handles the keyboard by itself |
| 2026-11-05 | `Projects` reads the list again after every answer from the API, and keeps nothing on the phone | One source of order and status, and another owner's change shows up; FR-16's offline work is about entries |
| 2026-11-05 | One `formatDate`, with Western digits and no new package | Two lines; the canvas shows 26.10.2026 on its Arabic screens, as the accountant's statement does |
| 2026-11-04 | The sign-in screen is headed by the logo and the app's name, not by what the app is for | Muteb's call on seeing the app on a real phone: the first screen carries the brand |
| 2026-11-01 | My account (حسابي) is built with UC-004, from Material's own parts, and holds the language and the way into the password change | UC-004 needs a place to choose the language; the screens canvas has no design for it yet (findings row 20) |
| 2026-11-01 | The chosen language is kept on the phone, and switches only after its words arrive | UC-004 keeps it on the phone; fetching first means a failed switch leaves the app as it was, never without words |
| 2026-11-01 | The API's address comes from a config file per environment (`config/local.json` is `http://127.0.0.1:5010`, routed to the developer's machine with `adb reverse`); production gets its own file | One owner of each address; publishing changes a file, not code; `127.0.0.1` with `adb reverse` works on the emulator and on a USB phone alike |
| 2026-11-01 | Routing with `go_router`, state with Flutter's own `ChangeNotifier`, sessions in `flutter_secure_storage` | The Flutter team's router, no third-party state library until one is needed, and the Keychain or Keystore as NFR-09 asks |
| 2026-11-01 | API calls are a small client on the `http` package; a client generated from the OpenAPI document waits until there are many endpoints | Two calls do not justify a code generator and its build step |
| 2026-11-01 | The user guide's screenshots are taken by the Patrol tests | A picture of the real app, never out of date |
| 2026-11-01 | Every public class and member has a doc comment, enforced by `public_member_api_docs` | A contributor understands each method |
| 2026-11-01 | The code holds word keys only, and the phone keeps one language | No word value ships in the app, and the phone holds no more than it shows |
| 2026-11-01 | Words come from the database through the API, not from files in the app | A word changes without an app release |
| 2026-11-01 | Patrol runs the real app end to end against the real API, in CI too | Tests replace manual testing |
| 2026-11-01 | Every element a user sees or acts on has a `Key` constant on its screen | Tests find elements by meaning, never by text |
| 2026-11-01 | Arabic and English from the first release | Both languages are used |
