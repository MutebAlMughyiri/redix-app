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
| [Projects](guide/projects.md) | Everyone, by their role in each project |
| [Home](guide/home.md) | Everyone, for the projects they have access to |
| [Settings](guide/settings.md) | Everyone signed in |
| [My account](guide/my-account.md) | Everyone signed in |
| [Users](guide/users.md) | Project managers |
| [Register a project](guide/register-a-project.md) | Everyone; the admin approves |
| [Categories and items](guide/categories.md) | Whoever does a project's finance |
| [Item columns](guide/item-columns.md) | Whoever does a project's finance |
| [Payment methods and VAT](guide/payment-methods.md) | Whoever does a project's finance |
| [Accounts](guide/accounts.md) | Everyone in the project; whoever does its finance changes them |
| [Partners](guide/partners.md) | The project's manager and whoever does its finance |
| [Suppliers](guide/suppliers.md) | Everyone in the project; whoever does its finance changes them |
| [Choosing a supplier](guide/supplier-picker.md) | Whoever enters an expense or a contract |
| [New purchase expense](guide/add-expense.md) | Whoever enters expenses in the project |
| [Contracts](guide/contracts.md) | Everyone in the project; whoever does its finance changes them |

## Use cases

Numbered in build order; the same number in the API's documentation is the same slice of the app.

| Use case | What it does | Who |
| --- | --- | --- |
| [UC-001](use-cases/UC-001-setup.md) | The base: Arabic and English from the database, the theme, the first screen, the no-network screen | Everyone |
| [UC-002](use-cases/UC-002-sign-in.md) | Sign in with a username and password, and stay signed in | Every user |
| [UC-003](use-cases/UC-003-change-password.md) | Change the password, forced while it is temporary | Every signed-in user |
| [UC-004](use-cases/UC-004-language.md) | Switch the app between Arabic and English in My account | Every signed-in user |
| [UC-006](use-cases/UC-006-projects.md) | A project and its units, and close it when finished | A financial supervisor adds units and closes |
| [UC-007](use-cases/UC-007-users.md) | Correct logins, disable them, and reset a forgotten password | Project managers |
| [UC-008](use-cases/UC-008-project-roles.md) | Add people to a project and give their roles | Project managers |
| [UC-009](use-cases/UC-009-follow-permissions.md) | Show each person the controls their role allows in each project | Everyone |
| [UC-010](use-cases/UC-010-projects-and-default.md) | Choose a project after sign-in, see it by your role in it, and set a default | Everyone |
| [UC-011](use-cases/UC-011-biometrics.md) | Sign in with a fingerprint or face instead of the password | Everyone, for this phone |
| [UC-012](use-cases/UC-012-categories-and-items.md) | Shape a project's categories, items and subgroups, and choose what a new project copies | Whoever does a project's finance |
| [UC-013](use-cases/UC-013-item-columns.md) | Change the fields an item asks for, on one item or on the default template | Whoever does a project's finance |
| [UC-014](use-cases/UC-014-payment-methods-and-vat.md) | Keep a project's payment methods and its VAT rate | Whoever does a project's finance |
| [UC-015](use-cases/UC-015-accounts-and-custodies.md) | Define a project's accounts and custodies, and show each custodian what they hold | Whoever does a project's finance changes; everyone sees |
| [UC-016](use-cases/UC-016-partners.md) | Keep a project's partners, each linked to their login | Whoever does a project's finance changes; its manager reads |
| [UC-017](use-cases/UC-017-suppliers.md) | Keep a project's supplier register clean | Whoever does a project's finance changes; everyone with access reads |
| [UC-018](use-cases/UC-018-pick-a-supplier.md) | Find a supplier by name or VAT number, and pick it | Whoever enters an expense or a contract |
| [UC-019](use-cases/UC-019-quick-add-supplier.md) | Add a missing supplier without leaving what is being entered | Finance and Field |
| [UC-020](use-cases/UC-020-contracts.md) | Record and follow what each contractor was promised | Whoever does a project's finance changes; everyone with access reads |
| [UC-021](use-cases/UC-021-capture-invoice.md) | Photograph an invoice, cropped and under 1 MB, and keep a contract's document | Whoever may enter an expense; Finance for a contract |
| [UC-022](use-cases/UC-022-expense-details.md) | Enter a purchase expense, and send it or save it as a draft | Finance and Field |
| [UC-066](use-cases/UC-066-register-a-project.md) | Register a project from the sign-in page, and approve it | Anyone registers; only the admin approves |
| [UC-062](use-cases/UC-062-sign-out.md) | Sign out of this phone | Every signed-in user |
