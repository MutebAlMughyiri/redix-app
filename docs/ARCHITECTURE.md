[Documentation](README.md) › Architecture

# Architecture

One Flutter app for Android and iOS, built from Flutter's own pieces: a `LocalizationsDelegate` for words, Material widgets themed from one seed color, `Key`s for every element.

```
lib/
  main.dart                 the app: theme, languages, and the router that sends anyone without a session to sign-in
  api.dart                  the API's address, shared by every feature
  auth/
    session.dart            Session: the signed-in session, kept in the Keychain or Keystore
    sign_in_screen.dart     the sign-in screen
    change_password_screen.dart  the password change, forced while the password is temporary
  home/home_screen.dart     the screen a signed-in user lands on
  words/
    words.dart              Words: the words of the language in use, from the API
    word_getters.g.dart     one typed getter per word key; generated, never edited
    no_words_screen.dart    the word-free screen of a first start without a network
test/                       widget tests, mirroring lib/; app_harness.dart owns the fake API and storage
patrol_test/                end-to-end tests on a real emulator, against the real API
tool/
  sync_translations.dart    regenerates word_getters.g.dart from the database keys
  update_guide_images.dart  copies Patrol's screenshots into docs/guide/images
docs/                       these pages
```

## Words

The code holds a word's key, never its value. `Words.of(context).appTitle` reads the key `app.title` in the language in use.

1. `WordsDelegate` asks `Words.load` for the phone's language (Arabic for any language other than Arabic or English).
2. The phone keeps one language with its ETag. Kept words show at once and are refreshed in the background; another language is fetched from `GET /translations/{language}` first.
3. A first start without a network has no words: `NoWordsScreen` shows only an icon and a retry button, and a retry loads the words again.

## Session and screens

1. `main` reads the kept session (`Session.restore`) before the first frame, then renews it in the background with `POST /auth/refresh`.
2. `go_router` sends every route to `/sign-in` while the session is closed, to `/change-password` while the password is temporary, and away from sign-in once open; it listens to `Session`, so a sign-in, a password change or an ended session moves the screen at once.
3. Every request made as the user goes through `Session.post`: it sends the access token, and on a `401` renews the session once and sends again.
4. Each screen declares its `path` and its element `Key`s.

## Rules every part follows

| Rule | Where it lives |
| --- | --- |
| No word value in the code; words come from the API | `lib/words/` |
| Every element a user sees or acts on has a `Key` constant on its screen | Each screen |
| Every public class and member has a doc comment | The lint `public_member_api_docs` |
| The API's address comes from `--dart-define=API_BASE_URL`, the emulator's view of the developer's machine by default | `apiBaseUrl` |

## Tests

| Kind | Where | Runs |
| --- | --- | --- |
| Widget tests | `test/` | With the API and secure storage replaced by fakes from `app_harness.dart`, on every `flutter test` |
| End-to-end | `patrol_test/` | The real app on an emulator against the real API; each test also takes the user guide's screenshots |
