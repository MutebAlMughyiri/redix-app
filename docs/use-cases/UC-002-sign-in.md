[Documentation](../README.md) › UC-002

# UC-002: Sign in with username and password

**What it is for:** getting into the app; once signed in, staying in, including offline.
**Who uses it:** every user with an account.
**Issue:** redix-app #23; the API side is redix-api #21.

## Screen

[Sign in](../guide/sign-in.md), `SignInScreen` at `/sign-in`:

| Element | `Key` | Does |
| --- | --- | --- |
| Logo | `SignInScreen.logoKey` | The app icon, at the top of the screen |
| App name | `SignInScreen.titleKey` | Under the logo: REDIX |
| Username | `SignInScreen.usernameKey` | The name the user signs in with |
| Password | `SignInScreen.passwordKey` | Hidden as typed; Enter signs in |
| Sign in | `SignInScreen.submitKey` | Sends both; disabled while waiting |
| Message | `SignInScreen.messageKey` | One line: why sign-in was refused, or why the last session ended |

## API calls

| Call | When |
| --- | --- |
| `POST /auth/sign-in` | The user taps Sign in |
| `POST /auth/refresh` | At start, when the phone keeps a session |

## Rules and where they live

| Rule | Code | Test |
| --- | --- | --- |
| Without a session every screen leads to sign-in | `RedixApp` router redirect | `sign_in_test.dart`: without a session |
| The right password opens home (FR-01) | `Session.signIn`, router redirect | `sign_in_test.dart`: the right password; `patrol_test/app_test.dart` against the real API |
| The session is kept only in the Keychain or Keystore (NFR-09) | `Session`, `flutter_secure_storage` | `sign_in_test.dart`: the right password |
| A refusal shows one line that never says which field was wrong (AC-01.2) | `SignInScreen`, the API's `code` | `sign_in_test.dart`: a wrong password, a locked account |
| Without a network, sign-in says so | `Session.signIn` | `sign_in_test.dart`: without a network |
| A server answer that names no refusal says the server could not sign in, never that there is no connection | `refusalOf`, `answerOf` in `lib/api.dart` | `sign_in_test.dart`: a server answer that names no refusal |
| A kept session opens home directly and is renewed in the background | `Session.restore` | `sign_in_test.dart`: a kept session |
| Without a network a kept session stays open, so work goes on offline (FR-16) | `Session.restore` | `sign_in_test.dart`: without a network a kept session |
| A session the API refuses ends on sign-in with a notice (AC-01.3, NFR-09) | `Session.restore` | `sign_in_test.dart`: a kept session the API refuses |

## Left to later use cases

The forced change of a temporary password (UC-003), and the user's projects after sign-in (UC-010).
