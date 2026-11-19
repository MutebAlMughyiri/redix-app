---
name: size-by-screen-and-font
description: In the REDIX app, a size is a part of the screen or follows the phone's text size, never a large fixed number of logical pixels. Use when writing or changing anything that sets a width, a height, a picture's box, a sheet's or a dialog's size, or a text's size - SizedBox(width:/height:), Container constraints, BoxConstraints, fontSize.
---

# Size by the screen and the font

> Brought from the Testin project, 12 November 2026, where the owner wrote: *"Our design must be based on screen dimensions by percentage, so it shows perfect on all screens, and if the font value is bigger."*

REDIX runs on small and large phones, on Android, iPhone and Huawei, and the user can raise the phone's text size. A box written as a number of pixels is right on the phone it was tried on and wrong on the others: too tall on a small screen, too short for large text, cutting a word.

## The rule

**A size is a part of something the user has, never a large fixed number.**

| What is being sized | Size it by | How |
| --- | --- | --- |
| A box, a picture, a sheet | A part of the screen | `MediaQuery.sizeOf(context).height * 0.25`; or let the layout size it: `Expanded`, `Flexible`, `AspectRatio`, `FractionallySizedBox` |
| Text | The theme, which follows the phone's text size | `Theme.of(context).textTheme.titleMedium`; never a `fontSize` number |
| A box holding text | The text itself | No fixed height: let it grow with the text size |
| A gap, a padding, a border, a thin bar | A small fixed number | `8`, `16`, `SwipeToRemove.barWidth` (4): Flutter's logical pixels already follow the screen's density |

## Never

- A box of hundreds of pixels: `SizedBox(height: 160)`, `width: 300`.
- A `fontSize:` number, which ignores the phone's text size.
- A fixed height on anything that holds words.

## Measured, 12 November 2026

One box in `lib/` breaks it: `lib/sharing/share_screen.dart:267`, the shared picture's preview at `SizedBox(height: 160)`. A row in redix-api #76. No `fontSize:` is a number: the one in `lib/ui/row_menu.dart` reads the theme's.

## Before you hand the change over

Raise the phone's text size to its largest and look again, then picture the smallest phone REDIX supports. If either cuts or overflows, a number is still hiding somewhere.
