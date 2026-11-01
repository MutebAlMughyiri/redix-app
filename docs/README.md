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
| [Home](guide/home.md) | Everyone |

## Use cases

Numbered in build order; the same number in the API's documentation is the same slice of the app.

| Use case | What it does | Who |
| --- | --- | --- |
| [UC-001](use-cases/UC-001-setup.md) | The base: Arabic and English from the database, the theme, the home screen, the no-network screen | Everyone |
