[Documentation](../README.md) › UC-001

# UC-001: Set up the base

**What it is for:** the base every later use case builds on: the app in Arabic and English with its words from the database, the theme and icon, and the first screens.
**Who uses it:** everyone, before sign-in.
**Issue:** redix-app #22; the API side is redix-api #20.

## Screens

| Screen | Elements (`Key`) | Guide |
| --- | --- | --- |
| Home | `HomeScreen.titleKey` the app's name, `HomeScreen.subtitleKey` what it is for | [Home](../guide/home.md) |
| No network | `NoWordsScreen.iconKey` the no-network icon, `NoWordsScreen.retryKey` the retry button | Shown only on a first start without a network |

## API calls

| Call | When |
| --- | --- |
| `GET /translations/{language}` | At start, for the phone's language; with the kept ETag when the phone has words |

## Rules and where they live

| Rule | Code | Test |
| --- | --- | --- |
| Arabic right to left, English left to right | `RedixApp` locales | `widget_test.dart`: Arabic and English |
| Any other phone language gets Arabic | `Words.languages` order | `widget_test.dart`: another language |
| A language the phone lacks is fetched and kept; only one is kept | `Words.load` | `words_test.dart` |
| Kept words show at once and are refreshed with their ETag | `Words.load` | `words_test.dart` |
| Without a network, another language's words never show | `Words.load` | `words_test.dart` |
| A first start without a network shows no words and retries | `NoWordsScreen`, `WordsDelegate.attempt` | `widget_test.dart`: first start without a network |
| The real app opens with words from the real API | The whole app | `patrol_test/app_test.dart` |
