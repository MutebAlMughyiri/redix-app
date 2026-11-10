[Documentation](../README.md) › UC-004

# UC-004: Switch the app language

**What it is for:** using the app in Arabic or English, whatever the phone's language (NFR-03).
**Who uses it:** every signed-in user.
**Issue:** redix-app #25. The API serves the words; its only part is the words of the language choice, added with the `LanguageSwitch` migration.

## Screen

The language of [Settings](../guide/settings.md) (`GeneralSettingsScreen`): a heading and the Arabic and English switch, `LanguageSwitch`, shown at once, the same switch as on the sign-in screen (Muteb, 9 Nov 2026: "make languages same before we move it to be inside a button"). The radio choice of 8 Nov 2026 is gone.

| Element | `Key` | Does |
| --- | --- | --- |
| The heading | `GeneralSettingsScreen.languageKey` | Names the choice |
| العربية and English, the language in use chosen | `LanguageSwitch.choiceKey`, `arabicKey`, `englishKey` | Switches the app to that language: Arabic right to left, English left to right |
| Message | `LanguageSwitch.messageKey` | Says switching needs a network, when it failed for that |

## API calls

| Call | When |
| --- | --- |
| `GET /translations/{language}` | The user picks the other language; the app switches only once the words have arrived |

## Rules and where they live

| Rule | Code | Test |
| --- | --- | --- |
| Settings shows the Arabic and English switch itself, the language in use chosen, with no row to open first | `GeneralSettingsScreen`, `LanguageSwitch`, `Words.languageName` | `settings/account_test.dart`: UC-004 (Muteb, 9 Nov 2026) |
| Choosing a language switches every screen to its words and direction | `AppLanguage.choose`, `RedixApp` (`locale`) | `settings/account_test.dart`: choosing English on an Arabic phone; `patrol_test/settings/language_test.dart` against the real API |
| The choice is kept on the phone and used at the next start | `AppLanguage.restore` | `settings/account_test.dart`: the chosen language is kept |
| The phone keeps the words of one language only: the new one replaces the old | `Words.load` | `words_test.dart`: the phone keeps only the language in use |
| Without a network the language stays and the app says switching needs a network | `AppLanguage.choose` | `settings/account_test.dart`: without a network |
| Until a language is chosen the app follows the phone, Arabic for any other language | `AppLanguage.locale` (empty choice) | `widget_test.dart`: a phone in another language gets Arabic |
| AC-N03: on a screen 360 points wide, every screen is right to left in Arabic and left to right in English, with nothing off the screen | Each screen | `settings/account_test.dart`: AC-N03, once per language |

## Appearance (redix-app #87, #97)

Under the language, Appearance (المظهر) offers System, Light or Dark (النظام · فاتح · داكن), drawn as the language's choice is, words only (Muteb, 10 Nov 2026). Every Settings row sits in its own frame, `Card.outlined` (Muteb, 10 Nov 2026: "i like borders for each component").

| Element | `Key` | Does |
| --- | --- | --- |
| Appearance | `GeneralSettingsScreen.appearanceKey`, `themeChoiceKey` | System, Light or Dark: `themeSystemKey`, `themeLightKey`, `themeDarkKey` |

| Rule | Code | Test |
| --- | --- | --- |
| Appearance is System, Light or Dark, words only; each draws every screen at once; on System the app turns with the phone at once, even while open; the language does not change | `LocalConfig.chooseThemeMode`, `RedixApp` (`themeMode`), `appThemeOf` | `settings/appearance_test.dart`: T1, T2, T3, T8, T9, T11, #87 R7; `patrol_test/settings/appearance_test.dart` |
| The phone keeps `themeMode_state`, 0 light, 1 dark and 2 the phone's, and opens in it from the first frame; a phone that never chose follows the phone and keeps 2, as does one that ran #87, whose `darkMode_state` is never read; a number no build kept reads as the phone's | `LocalConfig.restore` | `settings/appearance_test.dart`: T4, T5, T6, T7; Patrol: kept for the next start, and through signing out |
| Sign-in and the no-words screen follow the choice | `RedixApp` | `settings/appearance_test.dart`: #87 R9 |
| Every Settings row sits in its own frame, each heading and its choice in one | `GeneralSettingsScreen` | `settings/appearance_test.dart`: #87 R5 |
| Light and dark grow from one seed in one place, so every screen follows with no change of its own | `appThemeOf`, `AppColor` | The whole widget suite, run once with every test started dark |

## Left to later use cases

Nothing: UC-011 added fingerprint or face to Settings, and the default project stayed on the project list (UC-010).
