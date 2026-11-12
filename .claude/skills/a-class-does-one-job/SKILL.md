---
name: a-class-does-one-job
description: Before adding a method, a function or a widget to an existing class or file in the REDIX app, check that it is the same job the class or file already does, and that its name still says which. Use when a shared file under lib/ui grows, when a screen's state class gains a method about another screen's business, or when a file's name and what it holds have drifted apart.
---

# A class does one job, and its name says which

> Brought from the Testin project, 12 November 2026, at Muteb's word: *"let us also bring our skills that in testin project ... skills like every class do one job"*.

A class, or a Dart file of top-level functions, earns its name by doing one job. The failure this catches is not a bad class. It is a good one that quietly took on a second job, one convenient function at a time, until its name stopped describing it. Nothing breaks when that happens, which is why it survives review.

## A REDIX example

`lib/ui/refusal_snack_bar.dart` is named for refusals. It holds three things:

| What | Its job |
| --- | --- |
| `messageKeyOf(wordKey)` | The key of any message's SnackBar |
| `showMessage(...)` | Shows any message: a refusal, a confirmation, «حُذف.» with تراجع (redix-api #119) |
| `showRefusalOf(context, change)` | Waits for a change and shows its refusal |

Two of the three are about every message, not refusals. A reader looking for how the app shows «حُذف.» does not open a file called refusal. The job is "show a message in the bar", and the name should say so. This is a finding (row in redix-api #76), not a fix to slip into another change.

## The rule

**Before adding a method, say the class's job in one sentence, then the new method's job. If the second sentence is not the first, the method goes somewhere else.**

"It's related" is not the test; "it is the same job" is. A message and the delivery of a message are related and are not the same job.

## The signals

- A function that composes a value is added to a file that shows values, or one that decides is added to one that draws.
- The new name repeats a domain noun the class name does not contain: a `ProjectEntries` method that knows about a partner's capital has learned another feature's business.
- A doc comment on the new method cites a rule or a use case from another feature folder.
- The class name would need an "and" to be accurate.
- Names ending in `Manager`, `Helper`, `Util`, `Service` or `Handler`. They describe no job, so nothing contradicts them and they accumulate. Measured 12 November 2026: none in `lib/`. Keep it that way.

## Where the method goes instead

In order; stop at the first that fits.

1. **A type that already owns this vocabulary.** `Words` owns every word, `AppColor` every color, `PartKeys` every part key.
2. **The model the value is about.** An entry's question goes on `EntryRow` or `OpenedEntry`, a list's on its `ApiList`.
3. **A new file named for the job**, in the feature's folder under `lib/`.
4. **The single caller**, when exactly one place uses it.

Never "the file that already imports what I need".

## This is not

- **Not an argument against shared owners.** `centralize-shared-design` says a thing needs *an* owner; this skill says the owner is not whatever class is convenient.
- **Not an argument for many tiny classes.** A class with one job may be large. The question is whether one sentence covers all of it.

## When you find one

In code you were not asked to change: a finding, a row in redix-api #76 (`report-findings`). In the class you are editing: say it in one sentence, move the methods, keep every key and every word byte-identical, and let the widget tests prove nothing else moved.
