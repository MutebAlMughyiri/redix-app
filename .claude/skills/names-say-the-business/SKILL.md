---
name: names-say-the-business
description: Every class, widget, function, field, variable, key, word key and test in the REDIX app is named with the business word from the glossary, in full - an entry is an entry, a capital movement a capital movement, never a shortened or generic name. Use when adding or renaming anything in redix-app, when writing a test name, a doc comment, an issue or a message to the owner, and when a name says data, item, list or value where a business word belongs.
---

# Names say the business word, in full

> Brought from the Testin project, 12 November 2026. In Testin the owner wrote: *"correct name will allow me and contributors to understand easily and any name should match our correct names in business."*

## The one owner of the words

The glossary is the redix-app issue **"Translations: English terms and their Arabic"** (#21). Its **In code** column is the name a term has in Dart, in C#, in the API's fields and in enum values. A term is agreed there before it becomes a word in the database or a name in code. This skill does not repeat the list; read the issue.

The names of the app's own parts are fixed too, and used the same way in the business, in Dart and in .NET: **Summary**, **Project settings**, **Shared settings**, **Latest entries**, **Entry card**, **Custody card**.

## The rule

**Name it after the thing it is about, with the glossary's word spelled out.**

| Not this | This | Why |
| --- | --- | --- |
| `data`, `item`, `row` alone | `entry`, `account`, `capitalMovement` | The reader is reading the name, not the type |
| `list` | `entries`, `accounts` | Plural of the business word |
| `amt`, `qty`, `proj`, `acc` | `amount`, `quantity`, `project`, `account` | No short names for the business |
| a test named `works` | `a credit note is a negative total of its own` | A test's name is a sentence about the business (the rule it proves) |
| a key `'btn1'` | `AddEntryScreen.removeKey` | A key is named for the element, on its own screen |

Measured 12 November 2026: no `final`, `var` or typed local or field in `lib/` is named `acc`, `proj`, `amt`, `qty`, `tx`, `msg`, `btn`, `req`, `res`, `ctx`, `cfg`, `idx`, `val`, `tmp` or `str`.

**What may stay short:** Dart's and Flutter's own idioms (`e` in a catch, `i` in a loop, `context`), and a package's import prefix written as its own README writes it (`http`, `img`).

## Every sentence to the owner too

Chats, designs, `AskUserQuestion` briefs and issues use the same words as the code and the screens: an entry (قيد) not "a record", a custody (عهدة) not "a balance", a project not "a site". A word the glossary does not hold is added to the glossary first.

## Stored and sent names

A field the API sends, a word key, a `LocalConfig` key is renamed only on purpose, never by a sweep: it is a contract with the API, the database or the phone's saved choices. Diff every string literal before and after a rename.

## Checks before you name something

1. Which glossary term is this? Write its **In code** name in full.
2. Would a contributor who has never read this file know what the name holds?
3. Does the name repeat the type (`list`, `data`, `model`) instead of saying the business word?
4. Is it shortened? Then it is a Dart idiom or a package prefix, or it is spelled out.
