# REDIX app

The mobile app of REDIX (Real Estate Development Intelligence): one Flutter codebase for Android, iPhone and Huawei, in Arabic and English.
What it does, use case by use case, is in this repo's issues; how it works, and the user guide, are in the [documentation](docs/README.md).

## Run it

Needs Flutter (stable), Android Studio with the Android SDK, and Windows Developer Mode on (Flutter plugins need it).

```
flutter pub get
flutter run
```

Run it on an Android emulator (Android Studio › Device Manager) or a phone with USB debugging on. iPhone builds need a Mac with Xcode.
The app calls the API at `http://10.0.2.2:5010`, which is the developer's machine as the Android emulator sees it; another address is passed with `--dart-define=API_BASE_URL=...`.

## Words and languages

Every word the app shows lives in the REDIX database (the `TranslationKeys` and `Translations` tables of the API). The app's code holds no word, only its key.

- Screens read words through `Words.of(context)`, with one typed getter per key, for example `words.appTitle` for the key `app.title`.
- The words of the language in use come from `GET /translations/{language}`. The phone keeps that one language only, with its version tag: next start it shows the kept words at once and asks the API whether they changed (an unchanged bundle costs an empty `304`).
- The first start needs a network. Without one, the app shows a no-network icon and a retry button, which need no words.
- The language follows the phone: Arabic right to left, English left to right, Arabic for any other language.
- After adding a word key in the database, run the API and regenerate the getters, then commit the result:

```
dart run tool/sync_translations.dart
```

It rewrites `lib/words/word_getters.g.dart` from the keys alone. Never edit it by hand.

## Every element has a key

Every element a user sees or acts on carries a `Key`, declared as a constant on its own screen, for example `HomeScreen.titleKey`. Widget tests and Patrol tests find elements by these constants, never by typed strings.

## Test

```
flutter analyze
flutter test
patrol test --device emulator-5554
dart run tool/update_guide_images.dart
```

The last line copies the screenshots the Patrol tests took into the user guide's `docs/guide/images/`.

`flutter test` runs the widget tests, with the API replaced by a fake. `patrol test` runs the real app end to end on a running emulator (`patrol_cli`: `dart pub global activate patrol_cli`), so the API must be running too: `dotnet run --project src/Redix.Api --launch-profile http` in redix-api.

CI runs all three on every push. Its Patrol job checks out redix-api with the `REDIX_API_TOKEN` secret (a fine-grained token with read access to redix-api), starts SQL Server and the API, then runs Patrol on an Android emulator.
