---
name: code-cites-its-rule
description: In the REDIX app, every widget, screen and model method a user can reach says in its doc comment which business rule or use case it carries (BR-, FR-, AC-, NFR- from the BRS, UC-NNN, or an issue's decision), and every change to what a user sees changes the use case page and the guide in the same commit. Use when writing or changing any Dart under lib/, when writing a test, and when reviewing a diff.
---

# Code cites its rule

> Brought from the Testin project, 12 November 2026.

REDIX's business is written down before it is built: the BRS numbers every rule (`BR-`, `FR-`, `AC-`, `NFR-`), the use case issues are `UC-NNN` in build order, and a decision made on an issue is `redix-api #119 D4`. Two things follow.

> ## The code says which rule it carries, and the documents change when the code does.

## 1. The doc comment names the rule

REDIX code carries doc comments (`public_member_api_docs` is on), and the rule goes in them, with the date and the owner's word when the rule came from him:

```dart
/// The one way a row is removed (the owner, 8 Nov 2026, redix-api #102) ... The swipe does not remove: the row asks in place,
/// حذف and إلغاء inside it, never a window over the screen (the owner, 12 Nov 2026, redix-api #119).
class SwipeToRemove extends StatefulWidget {
```

Measured 12 November 2026: 113 of the 223 files in `lib/` cite a `BR-`, `FR-`, `AC-`, `NFR-` or `UC-` number, and the code names an issue 191 times.

## 2. The test name states the rule

A widget test or a Patrol case is named for the rule it proves, and starts with what it cites: `'redix-api #119: an approved entry swiped away comes back from the bar; a draft, deleted for good, offers no undo'`. Every rule has a positive and a negative case, and Patrol finds by exact key, never by position.

## 3. The documents change in the same commit

A change a user can see changes, in the same commit:

| Document | What changes |
| --- | --- |
| `docs/use-cases/UC-NNN-*.md` | The step, and the rule's row in the Rules table: the rule, the code that enforces it, the test that proves it |
| `docs/guide/*.md` | The page a user reads, and its pictures, retaken by the Patrol run |
| `docs/decisions.md` | A dated row when a decision was made |
| The BRS | Through its own page, when a rule's text changes |

A commit that changes what a button does and leaves the step that names the button is incomplete.

## The identifier has to exist

A comment naming a rule the BRS or the use case page does not hold is worse than none: the next reader trusts it and goes looking. Grep the use case pages in both repos before citing.

## When there is no rule yet

Write the rule first. When the business is unclear or two rules disagree, stop: it is an open question for the owner, never a guess in code (`redix-code-standard`). A rule that cannot be written in one plain sentence usually means the design is wrong.

## When a method carries no rule

Plumbing carries no citation: a private helper no user could describe, a constructor, a `build` that only lays out. The test: **could a user describe what this does without being shown the code?** If yes, it has a rule, and the comment names it.

## Never weaken the documents to match the code

When code and document disagree, one is wrong and the disagreement is a finding (redix-api #76). Rewriting a rule so today's code satisfies it is not a fix.
