# REDIX app documentation

The mobile app of REDIX (Real Estate Development Intelligence): the field supervisor records expenses and invoices, the financial supervisor approves them and issues the reports. One Flutter app for Android, iPhone and Huawei, in Arabic and English.

| Page | Read it to |
| --- | --- |
| [User guide](#user-guide) | Learn what each screen is for and how to use it |
| [Architecture](ARCHITECTURE.md) | See how the app is built, where each thing lives, and how words, sessions and screens work |
| [Decisions](decisions.md) | Know why things are as they are |
| [Use cases](#use-cases) | Know what each part does, who may use it, and where each rule lives in the code |

The business behind every page is the [BRS](https://claude.ai/artifact/JJPc1nSe6ekignSgXUpYB4) (private link); the API's documentation is in the redix-api repo.

## User guide

| Screen | Who sees it |
| --- | --- |
| [Sign in](guide/sign-in.md) | Everyone not signed in |
| [Change password](guide/change-password.md) | Everyone with a temporary password |
| [Home](guide/home.md) | Everyone signed in |
| [Settings](guide/settings.md) | Everyone signed in |
| [My account](guide/my-account.md) | Everyone signed in |
| [Projects](guide/projects.md) | Owners |
| [Users](guide/users.md) | Owners |

## Use cases

Numbered in build order; the same number in the API's documentation is the same slice of the app.

| Use case | What it does | Who |
| --- | --- | --- |
| [UC-001](use-cases/UC-001-setup.md) | The base: Arabic and English from the database, the theme, the home screen, the no-network screen | Everyone |
| [UC-002](use-cases/UC-002-sign-in.md) | Sign in with a username and password, and stay signed in | Every user |
| [UC-003](use-cases/UC-003-change-password.md) | Change the password, forced while it is temporary | Every signed-in user |
| [UC-004](use-cases/UC-004-language.md) | Switch the app between Arabic and English in My account | Every signed-in user |
| [UC-006](use-cases/UC-006-projects.md) | Create a project with its units, and close it when finished | The financial supervisor (an owner, until UC-008) |
| [UC-007](use-cases/UC-007-users.md) | Add users, correct them, disable them, and reset a forgotten password | Owners |
| [UC-008](use-cases/UC-008-project-roles.md) | Give users projects as finance, field or reader | Owners |
| [UC-062](use-cases/UC-062-sign-out.md) | Sign out of this phone | Every signed-in user |
