[Documentation](../README.md) › UC-004

# UC-004: Switch the app language

**What it is for:** using the app in Arabic or English, whatever the phone's language (NFR-03).
**Who uses it:** every signed-in user.
**Issue:** redix-app #25. The API serves the words; its only part is the words of My account, added with the `LanguageSwitch` migration.

## Screen

The language row of [Settings](../guide/settings.md) (`SettingsScreen`), `LanguageTile`. It moved there from My account on 8 Nov 2026 (Muteb: "move language to be as a button that once clicked then show radio button selection"). The sign-in screen keeps its own switch, `LanguageSwitch`.

| Element | `Key` | Does |
| --- | --- | --- |
| The language row, naming the language in use | `LanguageTile.tileKey`, `tileKey.subtitle` | Opens the choice |
| A radio button per language in `Words.languages`, the one in use chosen | `LanguageTile.optionKey(language)`, the group `tileKey.body` | Switches the app to that language: Arabic right to left, English left to right |
| Message | `messageKeyOf('myAccount.languageNeedsNetwork')` | Says switching needs a network, when it failed for that |

## API calls

| Call | When |
| --- | --- |
| `GET /translations/{language}` | The user picks the other language; the app switches only once the words have arrived |

## Rules and where they live

| Rule | Code | Test |
| --- | --- | --- |
| Settings has a language row naming the language in use, opening one radio button per language with the one in use chosen; My account no longer holds it | `LanguageTile`, `Words.languageName` | `my_account_test.dart`: UC-004 (Muteb, 8 Nov 2026); UC-004: My account no longer holds the language |
| Choosing a language switches every screen to its words and direction | `AppLanguage.choose`, `RedixApp` (`locale`) | `my_account_test.dart`: choosing English on an Arabic phone; `patrol_test/app_test.dart` against the real API |
| The choice is kept on the phone and used at the next start | `AppLanguage.restore` | `my_account_test.dart`: the chosen language is kept |
| The phone keeps the words of one language only: the new one replaces the old | `Words.load` | `words_test.dart`: the phone keeps only the language in use |
| Without a network the language stays and the app says switching needs a network | `AppLanguage.choose` | `my_account_test.dart`: without a network |
| Until a language is chosen the app follows the phone, Arabic for any other language | `AppLanguage.locale` (empty choice) | `widget_test.dart`: a phone in another language gets Arabic |
| AC-N03: on a screen 360 points wide, every screen is right to left in Arabic and left to right in English, with nothing off the screen | Each screen | `my_account_test.dart`: AC-N03, once per language |

## Left to later use cases

Nothing: UC-011 added fingerprint or face to My account, and the default project stayed on the project list (UC-010).
