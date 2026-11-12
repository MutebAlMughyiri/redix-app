---
name: redix-review
description: What "review" means in the REDIX app - Muteb's own review of a change before it is committed - simple, clean, well structured, no customization, named and cited from the business, then the checks in order. Read it whenever he says "review", "our review", "review then commit" or "redix review", and before committing any change to redix-app.
---

# REDIX review (app)

> Brought from the Testin project, 12 November 2026, where Muteb defined it: *"our review ... simple code, clean, well-structured, no customization and every thing based on business. no redundant as possible unless it required to make code simpler. rules and use cases added to each method and class."*

A review is not a bug hunt. It takes a change that already works and makes it **simpler without changing what it does**, then commits it. What a user sees stays exactly as tested on the phone; only the shape of the code moves.

## The seven questions

Ask each of every file in the diff, in this order.

| # | Question | What a "no" looks like | Read |
| --- | --- | --- | --- |
| 1 | **Is it simple?** The direct form, fewest parts, fewest lines for the same behavior, the platform's widget before one of ours | A helper, flag or parameter that carries what the caller already knows; a widget drawn where Flutter has one | `deliver-smallest-change`, `use-what-the-platform-has` |
| 2 | **Is it clean?** No null where an empty value stands in, a `Key` on every element a user sees or acts on, every word through `Words.of(context)`, no dead code, `flutter analyze` at zero | A `?` meaning "not set", a typed string in a widget, an element a test finds by text or position | `redix-code-standard` |
| 3 | **Is it well structured?** Each class and file one job its name says, in its feature folder | A file named for one job holding another, a screen's state doing a model's work | `a-class-does-one-job`, `logic-lives-with-its-owner` |
| 4 | **Does every shared fact have one owner?** A word, a color, a key, a message, a removal | The same lookup, color or decision in two places | `centralize-shared-design` |
| 5 | **No customization?** One surface holding every member, each graying or hiding itself as REDIX decided | A per-screen variant of a bar or a sheet; a subclassed widget | `one-surface-many-states` |
| 6 | **Is everything named for the business?** The glossary's words, in full | `data`, `item`, a shortened word, a near-twin name | `names-say-the-business` |
| 7 | **Does everything a user can reach cite its rule, and do the documents say what the code does?** | A behavior with no `BR-`, `FR-`, `AC-` or `UC-` in its doc comment; a use case page or guide page left behind | `code-cites-its-rule` |

**No redundancy, unless it makes the code simpler.** Keep a repetition only when removing it needs more code or a less readable shape, and say so.

## What a review may and may not do

- **May:** rename, move a method to its owner, inline a one-use helper, delete a parameter, a branch or a class, merge two copies into one owner, add a missing citation, reword a document the code no longer matches.
- **May not:** change what a user sees, add a feature, or fix an unrelated defect inside the review. Those are findings: rows in redix-api #76 (`report-findings`).
- **If a feature is what makes the code complicated,** say so with its cost and ask whether to keep, simplify or remove it. Removing it is a fair answer.
- **Fewer lines or the same** for the same behavior. A review that grows the diff explains each added line.

## Checks before the commit

In this order.

1. `flutter analyze`: zero issues. Never `dart format` on the repo's files.
2. `flutter test`: every widget test.
3. On the phone: build and install with `adb install -r`; Muteb tests by hand, and the change is fixed and reinstalled until he says ok. Never `adb shell monkey`, never touch the phone's rotation.
4. Patrol, the classes the change touches: `patrol test` on the phone (on Muteb's PC, `C:\Users\mtb\REDIX\.night\patrol.ps1 -Package @('entries')`). The full run (`run-all.ps1`) comes before a push.

## Reporting it

One short table of what the review changed and why, then the checks and their results (a run in one line: "batch 5 ended 13:05: 103 pass, 0 fail, 0 skip"), then any finding left as a finding. Commit on `main`, one commit per use case, ending with the `Co-Authored-By` line and no session link. Push only when Muteb says push.
