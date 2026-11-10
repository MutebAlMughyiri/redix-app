[Documentation](../README.md) › UC-011

# UC-011: Sign in with fingerprint or face

**What it is for:** opening the app without typing the password (FR-35).
**Who uses it:** anyone who signed in with the password on this phone, and turned it on in Settings.
**Issue:** redix-app #30; the API side is redix-api #29.

## How it works

The session stays in the Keychain or Keystore, as it always did. Behind the fingerprint or face sits one fixed word, and being able to read it is the check. The tokens are never behind it, because they change at every renewal, and an iPhone asks again at every write to a guarded item.

The app learns whether the phone has it on from the session the server answered, so ending the session or the next person signing in clears it with no code.

## Screens

[Sign in](../guide/sign-in.md), `SignInScreen`:

| Element | `Key` | Does |
| --- | --- | --- |
| Sign in with fingerprint or face | `SignInScreen.unlockKey` | Shows while `Session.canUnlock`; the screen asks once by itself as it opens |
| The message | `SignInScreen.messageKey` | `biometrics.failed`, or `biometrics.usePassword` after the third try |

[Settings](../guide/settings.md), `SettingsScreen`:

| Element | `Key` | Does |
| --- | --- | --- |
| Sign in with fingerprint or face | `SettingsScreen.biometricsKey` | Turns it on, asking first; turns it off with no prompt |
| The message | `SettingsScreen.biometricsMessageKey` | `biometrics.notAvailable` or `biometrics.notChanged` |

## Rules and where they live

| Rule | Code | Test |
| --- | --- | --- |
| With it on, the app asks first, and a pass opens the kept session (AC-35.1) | `Session.restore`, `Session.unlock` | `biometrics_test.dart` |
| After 3 failures only the password remains (AC-35.2) | `Session.canUnlock` | `biometrics_test.dart` |
| A new fingerprint or face can never pass (AC-35.2) | `Biometrics.passes` | `biometrics_test.dart`; the emulator run |
| A prompt with no answer leaves the form working | `SignInScreen` | `biometrics_test.dart` |
| Renewals never ask | `Session._keep` | `biometrics_test.dart` |
| A pass works without a network (FR-16) | `Session.unlock` | `biometrics_test.dart` |
| A session ended on the server ends on sign-in after the pass | `Session._renew` | `biometrics_test.dart` |
| The next person to sign in does not inherit it | `Session._apply` | `biometrics_test.dart` |
| Turning it on asks first; it stays off if that fails or there is no network | `Session.setBiometrics` | `settings/account_test.dart` |
| Turning it off asks nothing | `Session.setBiometrics` | `settings/account_test.dart` |
| A journey on an emulator with no fingerprint: the real plugin refuses, and the app says what to do | `Biometrics.turnOn` | `patrol_test/auth/biometrics_test.dart`, on a phone with no fingerprint |

## Proven with the real prompt

Widget tests fake the prompt. The plugin and the Keystore were run for real on an Android 37 emulator with a simulated finger, on 5 Nov 2026:

| Moment | What happened |
| --- | --- |
| Turning it on | The prompt showed; a pass turned it on |
| A cold start | The prompt showed; a pass opened the kept session |
| Use password on the prompt | The plugin never answers; the form stayed usable, and the button asked again |
| A second fingerprint added to the phone | The new finger passed the prompt, but the read answered nothing: "Could not confirm it is you", and only the password worked |

Not run: a real finger on a real phone, and an iPhone.
