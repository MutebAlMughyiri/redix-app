[Documentation](README.md) › Architecture

# Architecture

One Flutter app for Android and iOS, built from Flutter's own pieces: a `LocalizationsDelegate` for words, Material widgets themed from one seed color, `Key`s for every element.

```
lib/
  main.dart                 the app, its theme and languages, and the screens of UC-001
  words/
    words.dart              Words: the words of the language in use, from the API
    word_getters.g.dart     one typed getter per word key; generated, never edited
test/                       widget tests, mirroring lib/
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
| Widget tests | `test/` | With the API replaced by a fake, on every `flutter test` |
| End-to-end | `patrol_test/` | The real app on an emulator against the real API; each test also takes the user guide's screenshots |
