[Documentation](../README.md) › UC-003

# UC-003: Change password

**What it is for:** replacing the password; above all the temporary one a new user receives, which must be changed before anything else (AC-02.1).
**Who uses it:** every signed-in user; a user with a temporary password cannot reach any other screen.
**Issue:** redix-app #24; the API side is redix-api #22.

## Screen

[Change password](../guide/change-password.md), `ChangePasswordScreen` at `/change-password`:

| Element | `Key` | Does |
| --- | --- | --- |
| Current password | `ChangePasswordScreen.currentKey` | The password used to sign in today |
| New password | `ChangePasswordScreen.newKey` | At least 8 characters, different from the current one |
| New password again | `ChangePasswordScreen.confirmKey` | Must match; Enter saves |
| Save | `ChangePasswordScreen.submitKey` | Sends the change; disabled while waiting |
| Message | `ChangePasswordScreen.messageKey` | One line saying why the change was refused |

## API calls

| Call | When |
| --- | --- |
| `POST /auth/change-password`, with the access token | The user taps Save; through `Session.post`, which renews an expired access token once and sends again |

## Rules and where they live

| Rule | Code | Test |
| --- | --- | --- |
| A temporary password leads straight to the change screen (AC-02.1) | `RedixApp` router redirect | `change_password_test.dart`: signing in with a temporary password; `patrol_test/app_test.dart` against the real API |
| The change cannot be skipped while the password is temporary | `RedixApp` router redirect | `change_password_test.dart`: cannot be skipped |
| A changed password opens home | `Session.changePassword` | `change_password_test.dart`: a changed password opens home |
| New passwords that differ are caught before anything is sent | `ChangePasswordScreen` | `change_password_test.dart`: new passwords that differ |
| A refusal shows its own line: wrong current password, locked, or a weak new password | `Session.changePassword`, the API's `code` | `change_password_test.dart`: a refusal from the API |
| An expired access token is renewed once and the request sent again | `Session.post` | `change_password_test.dart`: an expired access token |
| Without a network the change says so | `Session.changePassword` | `change_password_test.dart`: without a network |

## Left to later use cases

Reaching this screen by choice, from personal settings (حسابي), comes with UC-010.
