---
name: use-what-the-platform-has
description: Before building any surface or service of a REDIX app feature - a message bar, a confirmation, a sheet, a picker, a scanner, a share, a print, a store of a choice, navigation - find what Flutter, Material or an already-used package does, and use it through the app's existing owner. Build REDIX's own only when none can do it, and say so with the evidence before writing code. Use when designing a feature, when choosing between "use X" and "build X", and when reviewing code that draws or stores something itself.
---

# Use what the platform has

> Brought from the Testin project, 12 November 2026, where Muteb wrote: *"use exist idea tools is better that customize new thing."* REDIX's own form of it: *"No customizations or workarounds, as we follow the business."* (Muteb, 1 November 2026, `redix-code-standard`).

A user already knows the phone: its message bar, its sheets, its share, its keyboard. A feature that uses the platform's own widget is learned the moment it appears, follows the phone's theme and text size, and is maintained by Flutter. A feature that builds its own copy is a second thing to learn and a part REDIX maintains forever.

> ## The platform's widget first, through REDIX's owner of it. Our own only with evidence that there is none.

## The order of choice

1. **A Flutter or Material widget, through the app's owner of it** where one exists.
2. **A package the app already depends on**, through its owner.
3. **A new package**: named in the feature's design, with why 1 and 2 cannot, so it is approved with the design; kept current like every package.
4. **REDIX's own**: only when 1 to 3 cannot do it. Say which widget was checked and why it cannot, in the design or the issue, before the first line.

Never offer 4 as a peer of 1. Never draw, subclass or wrap a widget to make it do what it does not support.

## What the app already uses, and its owner

Reach for these; never build beside them.

| Need | Platform | REDIX's owner |
| --- | --- | --- |
| A word on screen | `LocalizationsDelegate` | `Words.of(context)` (`lib/words/words.dart`) |
| A message in the bar, with an action | `SnackBar` | `showMessage`, `showRefusalOf` (`lib/ui/refusal_snack_bar.dart`) |
| Remove a row, asking in place | `Dismissible` | `SwipeToRemove` (`lib/ui/swipe_to_remove.dart`) |
| A button pressed once while its work runs | `FilledButton` and the rest | `ActOnce` (`lib/ui/act_once.dart`) |
| A screen's main action at the bottom | Material buttons | `BottomButton` (`lib/ui/bottom_button.dart`) |
| Go to a screen, come back | `go_router` | the routes in `lib/main.dart` |
| A choice kept on this phone | `shared_preferences` | `LocalConfig` (`lib/config/local_config.dart`) |
| The signed-in session, secrets | `flutter_secure_storage` | `Session` (`lib/auth/session.dart`) |
| Something read from the API | `http` | `ApiObject`, `ApiList` (`lib/api_object.dart`, `lib/api_list.dart`) |
| Work done while offline | `http` | `Outbox` (`lib/offline/outbox.dart`) |
| Share, save, receive a file | `share_plus`, `file_saver`, `receive_sharing_intent` | `lib/attachments/invoice_capture.dart` |

## A worked case

Removing an entry first asked in a window over the screen. Muteb, 12 November 2026: *"it is old way to show confirmation pop up"*. The answer was not a custom widget: `Dismissible`'s own `confirmDismiss` asks the row to show its question, and the bar's own `SnackBarAction` offers تراجع. Two platform hooks, one owner (`SwipeToRemove`), no window.

## What this does not mean

- **Not "never write our own".** The business is REDIX's own: an entry, an account, the periodic report. When the platform has no widget for the domain, the code is REDIX's, and that is correct.
- **Not a reason to bypass an owner.** Where REDIX wraps a platform widget in one owner, a feature calls the owner, never the widget directly, so every feature gets the owner's improvements.

## Checks before building a surface or a service

1. Which Flutter or Material widget, or which package already in `pubspec.yaml`, does this? Name it.
2. Does REDIX already wrap it? Call the owner.
3. If none works, write down what was checked and why it cannot, before the first line of code.
