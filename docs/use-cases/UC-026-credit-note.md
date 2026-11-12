[Documentation](../README.md) › UC-026

# UC-026: Record a credit note or a deduction

**What it is for:** recording money coming back.
**Who uses it:** whoever enters an expense, which is Finance and Field.
**Issue:** redix-app #44; the API side is redix-api #43. Simplified by redix-api #96 "Simple expense".

## Screens

No screen of its own. On `AddEntryScreen`, the canvas's **مرتجع** switch. A credit note is typed as a plain amount, and the API keeps it negative: its own row with a minus amount, naming no bill (Muteb, 12 Nov 2026, redix-api #119 D4), so nothing is asked about a bill and nothing caps it. A saved purchase with a minus amount opens with the switch on and its plain amount.

A deduction needs no switch of its own: it is a negative amount, and it says why in its notes (D14). The amount's keyboard offers the minus sign, and `parseNumber` reads it with either digits.

| Element | `Key` | Does |
| --- | --- | --- |
| Credit note | `AddEntryScreen.creditNoteKey` | The switch |

## API calls

`POST /projects/{id}/entries` with `isCreditNote` and a plain `amount`, or a negative `amount` for a deduction.

## Rules

Tests are in `test/entries/add_entry_test.dart`. The switch shows while a purchase's table is chosen (UC-022).

| Rule | Code | Test |
| --- | --- | --- |
| AC-14.2, D4: a credit note sends a plain amount and names no bill | `_body` | AC-14.2, redix-api #119 D4: a credit note sends a plain amount and names no bill |
| AC-14.1, D14: a deduction is a negative amount, sent with why in its notes | `parseNumber`, `_body` | AC-14.1, D14: a deduction is a negative amount |
| D14: a deduction with no notes is refused with the API's reason | The API's `deductionNeedsNotes` | D14: a deduction with no notes is refused |
| Fits 360 points wide, in both languages | The screen | `test/settings/account_test.dart`: AC-N03 |
