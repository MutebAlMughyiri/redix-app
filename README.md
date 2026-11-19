# REDIX app

The mobile app of REDIX (Real Estate Development Intelligence): one Flutter codebase for Android, iPhone and Huawei, in Arabic and English.
What it does, use case by use case, is in this repo's issues; how it works, and the user guide, are in the [documentation](docs/README.md).

## Run it

Needs Flutter (stable), Android Studio with the Android SDK, and Windows Developer Mode on (Flutter plugins need it).

```
flutter pub get
adb reverse tcp:5010 tcp:5010
flutter run --dart-define-from-file=config/dev.json
```

Run it on an Android emulator (Android Studio › Device Manager) or a phone with USB debugging on. iPhone builds need a Mac with Xcode.

## The API's address

Each environment has a config file in `config/`, passed when building or running with `--dart-define-from-file`:

| Environment | File | `API_BASE_URL` |
| --- | --- | --- |
| dev, automated runs (the API's `Dev`) | `config/dev.json` | `http://127.0.0.1:5010` |
| qa, Muteb's own testing (the API's `QA`) | `config/qa.json` | `http://127.0.0.1:5012` |
| prod, the published app (the API's `Prod`) | `config/prod.json` | The server's public address, over `https`; empty until the server is published, so a prod build stops at start saying so |

Each environment's file also names its app, under the company's prefix (redix-app #118 D2): dev installs as `com.techdetails.redix.dev`, "REDIX dev", with links on `dev.redix.test`; qa as `com.techdetails.redix.qa`, "REDIX qa", on `qa.redix.test`. Both can be on one phone, and prod as `com.techdetails.redix`, "REDIX". Patrol always builds dev, so a run never touches the qa app (redix-app #95). The activity keeps the code's own package: start an app with `adb shell am start -n com.techdetails.redix.qa/redix.MainActivity`.

On a phone, `127.0.0.1` is the phone itself; `adb reverse tcp:5010 tcp:5010` routes it to the developer's machine, on the emulator and on a phone plugged in by USB alike. Run it once after the emulator or phone connects. A release build only talks `https`: Android and iOS block plain `http` outside debug builds. An app built without a config file stops at start with a message naming the flag.

## Words and languages

Every word the app shows lives in the REDIX database (the `TranslationKeys` and `Translations` tables of the API). The app's code holds no word, only its key.

- Screens read words through `Words.of(context)`, with one typed getter per key, for example `words.appTitle` for the key `app.title`.
- The words of the language in use come from `GET /translations/{language}`. The phone keeps that one language only, with its version tag: next start it shows the kept words at once and asks the API whether they changed (an unchanged bundle costs an empty `304`).
- The first start needs a network. Without one, the app shows a no-network icon and a retry button, which need no words.
- The language is the one chosen in My account, kept on the phone; until one is chosen it follows the phone, Arabic for any other language. Arabic reads right to left, English left to right.
- After adding a word key in the database, run the API and regenerate the getters, then commit the result:

```
dart run tool/sync_translations.dart
```

It rewrites `lib/words/word_getters.g.dart` from the keys alone. Never edit it by hand.

## App icon

`assets/icon/icon.svg` is the master: the letter R under a roof, white on the theme teal. `icon_foreground.svg` is the same mark without the background, for Android's adaptive icon. After changing either, render each to a 1024 px PNG beside it, for example with headless Chrome:

```
chrome --headless --hide-scrollbars --default-background-color=00000000 --window-size=1024,1024 --screenshot=assets/icon/icon.png assets/icon/icon.svg
```

Then regenerate every Android and iPhone size, never editing them by hand:

```
dart run flutter_launcher_icons
```

## Every element has a key

Every element a user sees or acts on carries a `Key`, declared as a constant on its own screen, for example `HomeScreen.titleKey`. Widget tests and Patrol tests find elements by these constants, never by typed strings.

## Test

```
flutter analyze
flutter test
patrol test --device emulator-5554 --dart-define-from-file=config/dev.json
dart run tool/update_guide_images.dart
```

The last line copies the screenshots the Patrol tests took into the user guide's `docs/guide/images/`.

`flutter test` runs the widget tests, with the API replaced by a fake. `patrol test` runs the real app end to end on a running emulator (`patrol_cli`: `dart pub global activate patrol_cli`), so the API must be running too: `REDIX_Environment=Dev go run ./cmd/server` in redix-api's `go-backend`.

CI runs all three on every push. Its Patrol job checks out redix-api with the `REDIX_API_TOKEN` secret (a fine-grained token with read access to redix-api), starts the Go API as Dev on a fresh SQLite file, then runs Patrol on an Android emulator.
