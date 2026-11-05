[Documentation](../README.md) › [Use cases](../README.md) › UC-036

# UC-036: See what you were told

**Purpose:** a bell on the project list and the project's home counts what was not seen, and opens the list. Tapping one opens what it is about.

**Who uses it:** everyone signed in.

| Tapping | Opens |
| --- | --- |
| An entry that waits | The inbox of its project |
| A decision on your entry | The project's entries, with that entry's actions open |
| A decision on your project | The project list, which says why |

**Not built:** a push to a closed phone, which needs Firebase and Huawei accounts, and a phone token to register. The list is read when these screens open. Findings row 114 "UC-036, push to a closed phone" says what is missing.

| Rule | Code | Test |
| --- | --- | --- |
| The bell counts what was not seen | `Notifications.unread`, `NotificationsBell` | `the bell counts what was not seen` |
| The list says what happened and where, in the phone's language | `NotificationsScreen` | `the list says what happened, in which project, in the words of the phone` |
| AC-20.1: tapping a decision opens the entry, and marks it seen | `NotificationsScreen._open`, `EntriesScreen.openEntryId` | `AC-20.1: tapping a decision opens the entry, and marks it seen` |
| Tapping what waits opens the inbox | `NotificationsScreen._open` | `tapping what waits for a decision opens the inbox` |
| Tapping a decided project goes to the project list | `NotificationsScreen._open` | `tapping a decided project goes to the project list, which says why` |
