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

## Dark mode (redix-app #87)

Under the language, a switch like the fingerprint one turns every screen dark at once (Muteb, 10 Nov 2026). Every Settings row sits in its own frame, `Card.outlined` (Muteb, 10 Nov 2026: "i like borders for each component").

| Element | `Key` | Does |
| --- | --- | --- |
| Dark mode | `GeneralSettingsScreen.darkModeKey` | Turns the app dark, or back to light |

| Rule | Code | Test |
| --- | --- | --- |
| Dark mode turns every screen dark at once, and off turns it light; the language does not change | `LocalConfig.toggleDarkMode`, `RedixApp` (`themeMode`), `appThemeOf` | `settings/dark_mode_test.dart`: R1, R2, R3, R7; `patrol_test/settings/dark_mode_test.dart` |
| The phone keeps `darkMode_state`, 0 light and 1 dark, and opens in it from the first frame; a phone that never chose starts light and keeps 0 | `LocalConfig.restore` | `settings/dark_mode_test.dart`: R6; Patrol: kept for the next start, and through signing out |
| Sign-in and the no-words screen follow the choice | `RedixApp` | `settings/dark_mode_test.dart`: R9 |
| Every Settings row sits in its own frame, the language heading and its choice in one | `GeneralSettingsScreen` | `settings/dark_mode_test.dart`: R5 |
| Light and dark grow from one seed in one place, so every screen follows with no change of its own | `appThemeOf`, `AppColor` | The whole widget suite, run once with every test started dark |

## Left to later use cases

Nothing: UC-011 added fingerprint or face to Settings, and the default project stayed on the project list (UC-010).
