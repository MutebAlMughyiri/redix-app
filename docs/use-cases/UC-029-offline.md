[Documentation](../README.md) › [Use cases](../README.md#use-cases) › UC-029

# UC-029: Record entries without a network

**Purpose:** keep working on a site with no coverage. An entry saved without a network waits on the phone and goes by itself when the network returns.

**Who uses it:** whoever enters expenses in the project.

## What the phone keeps

| What | Where | For how long |
| --- | --- | --- |
| Every list the app read, by its address (`Session.get`) | `copies` in `FolderStore`, the app's private folder | Until sign-out, because the next user must not see it |
| Every list an entry needs, at opening a project (`ProjectSync`, `GET /projects/{id}/sync`) | The same | The same |
| Entries waiting, and their files (`Outbox`) | `outbox`, `outbox-files` | Until they land. They survive a sign-out and go only with whoever entered them |

Android's backup of the app's data is off, so none of this leaves the phone that way.

## Screens

| Element | Key |
| --- | --- |
| The line on the home saying how many wait | `HomeScreen.waitingKey` |
| A row on **Waiting to sync** | `WaitingScreen.rowKey` |
| Where it stands | `WaitingScreen.stateKey` |
| Send again, for a refused entry | `WaitingScreen.sendAgainKey` |
| A waiting entry's swipe, which forgets it once confirmed in its row (redix-api #119) (redix-api #102) | `WaitingScreen.rowKey(id).swipe` |
| Nothing waits | `WaitingScreen.emptyKey` |

## Rules

| Rule | Code | Test |
| --- | --- | --- |
| AC-16.1: five expenses with photos go within a minute of the network returning | `Outbox.tryEvery`, `Outbox.send` | `add_entry_test.dart`: AC-16.1 |
| AC-16.3: an upload cut after its file went keeps the file's id, and the entry lands once | `Outbox._sendOne`, with the API's UC-029 | `add_entry_test.dart`: AC-16.3 |
| Without a network an entry is kept, whatever its table, and the person is told | `EntryRecording._send`, `EntryRecording._keep` | `add_entry_test.dart`: without a network the expense is kept; `one_entry_test.dart`: R8, D12 |
| A list read once answers with no network | `Session.get` | `offline_test.dart`: a list read once |
| redix-api #126: a copy an earlier version kept in a shape this one no longer reads answers as nothing kept, saying the list could not be read, and the next read comes from the API; a copy in today's shape still answers | `ApiObject.load` | `offline_test.dart`: a project list an earlier version kept; a project list kept in the shape this version reads |
| Signing out forgets what was kept of the lists | `Session._end` | `offline_test.dart`: signing out forgets |
| Opening a project keeps every list the sync answers | `ProjectSync.refresh` | `offline_test.dart`: opening a project keeps |
| What someone else entered neither shows nor goes | `Outbox.of`, `Outbox.send` | `offline_test.dart`: what someone else entered |
| What waits survives a sign-out | `Outbox` | `offline_test.dart`: what waits survives |
| An entry the API refuses waits for its author, and is not tried again | `Outbox._refuse` | `offline_test.dart`: an entry the API refuses |
| A server that could not answer leaves it waiting | `Outbox._sendOne` | `offline_test.dart`: an answer the server could not give |
| A typed search looks in what was kept, whichever way the name is spelled | `SupplierSearch._findInKeptCopy` | `offline_test.dart`: with no network a typed search |

## On a real phone

`patrol_test/offline/offline_entries_test.dart` runs this code on the HUAWEI with its link to the API cut. The folder store is tested on a real folder; the widget tests use a store in memory.
