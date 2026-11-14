[Documentation](../README.md) › UC-002

# UC-002: Sign in with username and password

**What it is for:** getting into the app; once signed in, staying in, including offline; and, with «نسيت كلمة المرور؟», resetting a forgotten password with a code sent by email (redix-api #127).
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
| «نسيت كلمة المرور؟» | `SignInScreen.forgotKey`, `.label` | Opens the forgotten password (redix-api #127) |

[Forgot password](../guide/forgot-password.md), `ForgotPasswordScreen` at `/forgot-password`, which the router lets anyone reach without a session:

| Element | `Key` | Does |
| --- | --- | --- |
| Title | `ScreenTitle.titleKey` | «نسيت كلمة المرور؟» |
| Username or email | `ForgotPasswordScreen.loginKey` | The account whose password was forgotten, by its username or its email (D5) |
| Send the code | `ForgotPasswordScreen.sendKey`, `.label` | Asks for a code, in the phone's language; again sends a new one, which ends the earlier |
| The sentence | `ForgotPasswordScreen.sentKey` | «إن كان للحساب بريد، أرسلنا إليه رمزًا صالحًا 15 دقيقة.», the same for any account (R5); the next fields show under it |
| Code | `ForgotPasswordScreen.codeKey` | The six digits the email carried |
| New password, again | `ForgotPasswordScreen.newKey`, `confirmKey` | The new password twice, with what the password policy asks under it |
| Change the password | `ForgotPasswordScreen.resetKey`, `.label` | Sends the code and the new password; once changed, back on sign-in, saying «تغيّرت كلمة المرور. سجّل الدخول.» (`messageKeyOf('auth.passwordReset')`) |
| Message | `ForgotPasswordScreen.messageKey` | One line above the first field: why a step was refused |

## API calls

| Call | When |
| --- | --- |
| `POST /auth/sign-in` | The user taps Sign in |
| `POST /auth/forgot-password` | Send the code, with `Accept-Language` the phone's language (redix-api #127) |
| `POST /auth/reset-with-code` | Change the password |
| `POST /auth/refresh` | At start, when the phone keeps a session; when the app comes back to the screen; 30 seconds before the access token runs out, at the `accessTokenExpiresAt` of the last session answer; after a refused request (redix-api #126 R6) |

## Rules and where they live

| Rule | Code | Test |
| --- | --- | --- |
| Without a session every screen leads to sign-in | `RedixApp` router redirect | `sign_in_test.dart`: without a session |
| The right password opens home (FR-01) | `Session.signIn`, router redirect | `sign_in_test.dart`: the right password; `patrol_test/auth/sign_in_test.dart` against the real API |
| The session is kept only in the Keychain or Keystore (NFR-09) | `Session`, `flutter_secure_storage` | `sign_in_test.dart`: the right password |
| A refusal shows one line that never says which field was wrong (AC-01.2) | `SignInScreen`, the API's `code` | `sign_in_test.dart`: a wrong password, a locked account |
| Without a network, sign-in says so | `Session.signIn` | `sign_in_test.dart`: without a network |
| A server answer that names no refusal says the server could not sign in, never that there is no connection | `refusalOf`, `answerOf` in `lib/api.dart` | `sign_in_test.dart`: a server answer that names no refusal |
| A kept session opens home directly and is renewed in the background | `Session.restore` | `sign_in_test.dart`: a kept session |
| redix-api #127 AC-02.6: «نسيت كلمة المرور؟» opens the reset without a session; the code is asked for the username or email typed; the code and the new password twice change it, back on sign-in saying so | `SignInScreen`, `ForgotPasswordScreen`, `askResetCode`, `resetWithCode`, the router's redirect | `forgot_password_test.dart`; `patrol_test/auth/forgot_password_test.dart` |
| redix-api #127 AC-02.7: once asked, one sentence says a code went to the email if the account has one, the same for any account, and only then the code is asked | `ForgotPasswordScreen` | `forgot_password_test.dart`: once asked, one sentence; `patrol_test/auth/forgot_password_test.dart`: an unknown username |
| redix-api #127 AC-02.10: the code is asked in the phone's language | `askResetCode`, `Accept-Language` | `forgot_password_test.dart`: in the language the phone is in |
| redix-api #127 AC-02.8: a wrong or spent code, a weak password, and asking too often are each refused with their word, and the screen stays; new passwords that differ send nothing | `ForgotPasswordScreen`, `askResetCode`, `resetWithCode` | `forgot_password_test.dart`; `patrol_test/auth/forgot_password_test.dart` |
| redix-api #127: without a network asking says so | `askResetCode` | `forgot_password_test.dart`: without a network |
| Without a network a kept session stays open, so work goes on offline (FR-16) | `Session.restore` | `sign_in_test.dart`: without a network a kept session |
| A session the API refuses ends on sign-in with a notice (AC-01.3, NFR-09) | `Session.restore` | `sign_in_test.dart`: a kept session the API refuses |
| redix-api #126 R6: the session renews on its own when the app opens, when it comes back to the screen and 30 seconds before its access token runs out, one renewal waiting at a time and none after sign-out; each of these renewals reads the project list again. A renewal after a refused request reads nothing again, so an API that refuses even a renewed token is renewed and read once more, never in a loop | `Session.renew`, `Session._renewAfterRefusal`, `Projects` | `session_renewal_test.dart`; `projects_test.dart`: an expired access token is renewed once for each list |

## Left to later use cases

The forced change of a temporary password (UC-003), and the user's projects after sign-in (UC-010).
