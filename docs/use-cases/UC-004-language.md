[Documentation](../README.md) › UC-004

# UC-004: Switch the app language

**What it is for:** using the app in Arabic or English, whatever the phone's language (NFR-03).
**Who uses it:** every signed-in user.
**Issue:** redix-app #25. The API serves the words; its only part is the words of My account, added with the `LanguageSwitch` migration.

## Screen

[My account](../guide/my-account.md) (حسابي), `MyAccountScreen` at `/my-account`, opened from [Settings](../guide/settings.md) (`SettingsScreen.myAccountKey`):

| Element | `Key` | Does |
| --- | --- | --- |
| العربية | `MyAccountScreen.arabicKey` | Switches the app to Arabic, right to left |
| English | `MyAccountScreen.englishKey` | Switches the app to English, left to right |
| Message | `MyAccountScreen.messageKey` | Says switching needs a network, when it failed for that |
| Change password | `MyAccountScreen.changePasswordKey` | Opens [Change password](../guide/change-password.md), with a way back |

## API calls

| Call | When |
| --- | --- |
| `GET /translations/{language}` | The user picks the other language; the app switches only once the words have arrived |

## Rules and where they live

| Rule | Code | Test |
| --- | --- | --- |
| Choosing a language switches every screen to its words and direction | `AppLanguage.choose`, `RedixApp` (`locale`) | `my_account_test.dart`: choosing English on an Arabic phone; `patrol_test/app_test.dart` against the real API |
| The choice is kept on the phone and used at the next start | `AppLanguage.restore` | `my_account_test.dart`: the chosen language is kept |
| The phone keeps the words of one language only: the new one replaces the old | `Words.load` | `words_test.dart`: the phone keeps only the language in use |
| Without a network the language stays and the app says switching needs a network | `AppLanguage.choose` | `my_account_test.dart`: without a network |
| Until a language is chosen the app follows the phone, Arabic for any other language | `AppLanguage.locale` (empty choice) | `widget_test.dart`: a phone in another language gets Arabic |
| AC-N03: on a screen 360 points wide, every screen is right to left in Arabic and left to right in English, with nothing off the screen | Each screen | `my_account_test.dart`: AC-N03, once per language |

## Left to later use cases

Nothing: UC-011 added fingerprint or face to My account, and the default project stayed on the project list (UC-010).
