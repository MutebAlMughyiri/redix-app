[Documentation](README.md) › Architecture

# Architecture

One Flutter app for Android and iOS, built from Flutter's own pieces: a `LocalizationsDelegate` for words, Material widgets themed from one seed color, `Key`s for every element.

```
lib/
  main.dart                 the app: theme, languages, and the router that sends anyone without a session to sign-in
  account/my_account_screen.dart  My account: the language and the way into the password change
  settings/settings_screen.dart   Settings: the way into My account and, for owners, Projects
  projects/
    project.dart            Project and Unit, as the API answers them
    projects.dart           Projects: the list as the API last answered it, and every change to it
    projects_screen.dart    the projects, one card each, with the Add unit and close dialogs
    new_project_screen.dart the new project form
  format/date_format.dart   formatDate: the app's one date format, dd.MM.yyyy
  api.dart                  the API's address and how a reply's JSON is read, shared by every feature
  auth/
    session.dart            Session: the signed-in session, kept in the Keychain or Keystore
    sign_in_screen.dart     the sign-in screen
    change_password_screen.dart  the password change, forced while the password is temporary
  home/home_screen.dart     the screen a signed-in user lands on
  words/
    words.dart              Words: the words of the language in use, from the API
    app_language.dart       AppLanguage: the language the user chose, kept on the phone
    word_getters.g.dart     one typed getter per word key; generated, never edited
    no_words_screen.dart    the word-free screen of a first start without a network
test/                       widget tests, mirroring lib/; app_harness.dart owns the fake API and storage
patrol_test/                end-to-end tests on a real emulator, against the real API
config/                     one file per environment, naming the API's address
tool/
  sync_translations.dart    regenerates word_getters.g.dart from the database keys
  update_guide_images.dart  copies Patrol's screenshots into docs/guide/images
docs/                       these pages
```

## Words

The code holds a word's key, never its value. `Words.of(context).appTitle` reads the key `app.title` in the language in use.

1. `WordsDelegate` asks `Words.load` for the language in use: the one chosen in My account (`AppLanguage`), else the phone's (Arabic for any language other than Arabic or English).
2. The phone keeps one language with its ETag. Kept words show at once and are refreshed in the background; another language is fetched from `GET /translations/{language}` first.
3. A first start without a network has no words: `NoWordsScreen` shows only an icon and a retry button, and a retry loads the words again.
4. Choosing a language in My account fetches its words first; only then does `AppLanguage` keep the choice and tell `RedixApp`, which rebuilds in the new `locale`. Without a network nothing changes.

## Session and screens

1. `main` reads the kept session (`Session.restore`) before the first frame, then renews it in the background with `POST /auth/refresh`.
2. `go_router` sends every route to `/sign-in` while the session is closed, to `/change-password` while the password is temporary, and away from sign-in once open; it listens to `Session`, so a sign-in, a password change or an ended session moves the screen at once.
3. Every request made as the user goes through `Session.post`: it sends the access token, and on a `401` renews the session once and sends again.
4. Each screen declares its `path` and its element `Key`s.

## Data the API owns

Settings such as projects keep nothing on the phone: the API owns every rule, the app sends the change and draws what the API answers. `Projects` reads the list again after every answer, so its order and each status have one source.

## Rules every part follows

| Rule | Where it lives |
| --- | --- |
| No word value in the code; words come from the API | `lib/words/` |
| Every element a user sees or acts on has a `Key` constant on its screen | Each screen |
| Every public class and member has a doc comment | The lint `public_member_api_docs` |
| The API's address comes from the environment's config file (`--dart-define-from-file=config/local.json`); none is built in | `apiBaseUrl`, `config/` |

## Tests

| Kind | Where | Runs |
| --- | --- | --- |
| Widget tests | `test/` | With the API and secure storage replaced by fakes from `app_harness.dart`, on every `flutter test` |
| End-to-end | `patrol_test/` | The real app on an emulator against the real API; each test also takes the user guide's screenshots |
