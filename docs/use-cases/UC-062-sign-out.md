[Documentation](../README.md) › UC-062

# UC-062: Sign out

**What it is for:** leaving a phone: a shared one, or one being handed on (added by Muteb on 5 Nov 2026; numbered last, built after UC-007).
**Who uses it:** every signed-in user.
**Issue:** redix-app #74; the API side is redix-api #78.

## Screen

In [Settings](../guide/settings.md):

| Element | `Key` | Does |
| --- | --- | --- |
| Sign out | `SettingsScreen.signOutKey` | Asks first, through `ConfirmDialog`, then signs out and leads to the sign-in screen |

## API calls

| Call | When |
| --- | --- |
| `POST /auth/sign-out` | Once confirmed; answers `204`, and the phone forgets its tokens whatever the answer |

## Rules and where they live

| Rule | Code | Test |
| --- | --- | --- |
| Signing out asks first, and Cancel changes nothing | `SettingsScreen`, `ConfirmDialog` | `my_account_test.dart`: signing out asks first |
| Signing out ends the session here and leads to sign-in, with no message | `Session.signOut` | `my_account_test.dart`: signing out; Patrol |
| Without a network the phone still signs out | `Session.signOut` | `my_account_test.dart`: without a network |
| The chosen language stays on the phone | `AppLanguage`, untouched | `my_account_test.dart`: the language stays |
| The next user signs in as themselves | `Session`, the router | `my_account_test.dart`: the next user; Patrol |

## Left to later use cases

UC-029 "Accept offline uploads exactly once" must warn before signing out while entries are unsent, or they would be stranded.
