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
| Delete | `WaitingScreen.discardKey` |
| Nothing waits | `WaitingScreen.emptyKey` |

## Rules

| Rule | Code | Test |
| --- | --- | --- |
| AC-16.1: five expenses with photos go within a minute of the network returning | `Outbox.tryEvery`, `Outbox.send` | `add_expense_test.dart`: AC-16.1 |
| AC-16.3: an upload cut after its file went keeps the file's id, and the entry lands once | `Outbox._sendOne`, with the API's UC-029 | `add_expense_test.dart`: AC-16.3 |
| Without a network the expense is kept, and the person is told | `Expenses._send`, `Expenses._keep` | `add_expense_test.dart`: without a network the expense is kept |
| A list read once answers with no network | `Session.get` | `offline_test.dart`: a list read once |
| Signing out forgets what was kept of the lists | `Session._end` | `offline_test.dart`: signing out forgets |
| Opening a project keeps every list the sync answers | `ProjectSync.refresh` | `offline_test.dart`: opening a project keeps |
| What someone else entered neither shows nor goes | `Outbox.of`, `Outbox.send` | `offline_test.dart`: what someone else entered |
| What waits survives a sign-out | `Outbox` | `offline_test.dart`: what waits survives |
| An entry the API refuses waits for its author, and is not tried again | `Outbox._refuse` | `offline_test.dart`: an entry the API refuses |
| A server that could not answer leaves it waiting | `Outbox._sendOne` | `offline_test.dart`: an answer the server could not give |
| A typed search looks in what was kept, whichever way the name is spelled | `SupplierSearch._findInKeptCopy` | `offline_test.dart`: with no network a typed search |

## Not proved

The journey cannot yet cut the network, and it has not run this code on a phone: the system stopped the emulator run for low memory on 5 Nov 2026. The folder store is tested on a real folder; the widget tests use a store in memory.
