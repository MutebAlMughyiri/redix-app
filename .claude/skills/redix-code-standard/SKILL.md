---
name: redix-code-standard
description: How REDIX app code is written - best practice of Flutter, simple, clean and well structured, no customizations or workarounds, and only what the business (the BRS and the use case) asks. Read before writing or changing any code in this repo.
---

# REDIX code standard (app)

> "Our code must be best practice, simple, clean and structured well. No customizations or workarounds, as we follow the business." — Muteb, 1 November 2026

## Follow the business

- The BRS and the use case issue (`UC-NNN`) say what the code does. Build exactly that: no extra feature, and no rule bent to make the code easier.
- Every rule the use case lists has a widget test that runs it, and every use case with a screen has a Patrol test that runs the real app on an emulator. The test name states the rule.
- When the business is unclear, or two rules disagree, stop. It becomes an open question in the BRS, never a guess in code.

## Best practice of the platform, no customizations

- Use what Flutter already provides, the way its documentation shows it: a `LocalizationsDelegate` for words (`Words.of(context)`), Material widgets themed from one seed color, `Key`s to find widgets, `flutter_test` and Patrol for tests.
- Never draw, subclass or wrap a widget to make it do what it does not support, and never work around the platform. If Flutter cannot do what the use case needs, say so before writing code.
- Keep packages current. `flutter analyze` stays at zero issues: a lint is fixed, never ignored.

## Simple and clean

- The smallest code that does the job: no dead code, no speculative helper, no comment that repeats the code.
- Every shared thing has one owner. Words come only from the API through `Words.of(context)`: the code holds a word's key, never its value, and no string is typed into a widget. The supported languages are `Words.languages`.
- Every element a user sees or acts on has a `Key`, declared as a constant on its own screen (`HomeScreen.titleKey`). Tests find elements by those constants, never by typed text.
- Names come from the translations glossary (issue "Translations: English terms and their Arabic"). Its "In code" column is the Dart name.
- No null where a value can stand in: an empty value of its own type, not `?` and a check at every reader.

## Structured well

- One folder per feature under `lib/` (for example `lib/words/`). Tests mirror it under `test/` and `patrol_test/`.
- The generated `lib/words/word_getters.g.dart` comes only from `tool/sync_translations.dart` and is never edited by hand.
