[Documentation](../README.md) › UC-026

# UC-026: Record a credit note or a deduction

**What it is for:** recording money coming back.
**Who uses it:** whoever enters an expense, which is Finance and Field.
**Issue:** redix-app #44; the API side is redix-api #43. Simplified by redix-api #96 "Simple expense".

## Screens

No screen of its own. On `AddEntryScreen`, «نوع القيد», the purchase's list column of «شراء» (+) and «مرتجع» (−), whose sign decides the total's direction (redix-api #129): choosing «مرتجع» makes the purchase a credit note. It is typed as a plain amount, and the API keeps it negative: its own row with a minus amount, naming no bill (the owner, 12 Nov 2026, redix-api #119 D4), so nothing is asked about a bill and nothing caps it. A saved purchase whose «نوع القيد» is «مرتجع» opens with it chosen and its plain amount.

A deduction needs no switch of its own: it is a negative amount, and it says why in its description, «الوصف» (D14, redix-api #129). The amount's keyboard offers the minus sign, and `parseNumber` reads it with either digits.

| Element | `Key` | Does |
| --- | --- | --- |
| نوع القيد | `AddEntryScreen.columnKey('entryType')`, `columnOptionKey('entryType', choiceId)` | The dropdown of its choices |

## API calls

`POST /projects/{id}/entries` with `columnValues.entryType`, the id of «مرتجع», and a plain `amount`, or a negative `amount` for a deduction.

## Rules

Tests are in `test/entries/add_entry_test.dart`. «نوع القيد» shows while a purchase's table whose item has it is chosen (UC-022).

| Rule | Code | Test |
| --- | --- | --- |
| AC-14.2, D4: a credit note is «مرتجع» of «نوع القيد», sends a plain amount and names no bill (redix-api #129) | `_itemsOwnFields`, `_body` | AC-14.2, redix-api #119 D4, #129: a credit note is «مرتجع» of «نوع القيد» |
| A saved purchase whose «نوع القيد» is «مرتجع» opens with it chosen and its plain amount, and is sent again as one | `_openEntry`, `ItemColumn.signOf` | `entries_test.dart`: redix-api #119 D4, #129 |
| AC-14.1, D14: a deduction is a negative amount, sent with why in its description | `parseNumber`, `_body` | AC-14.1, D14: a deduction is a negative amount |
| D14: a deduction with no description is refused with the API's reason | The API's `deductionNeedsDescription` | D14: a deduction with no notes is refused |
| Fits 360 points wide, in both languages | The screen | `test/settings/account_test.dart`: AC-N03 |
