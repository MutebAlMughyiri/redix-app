[Documentation](../README.md) › UC-016

# UC-016: Manage partners

**What it is for:** keeping the list of a project's partners, and linking each to their login, so that person's capital is theirs to see (BR-31).
**Who uses it:** whoever holds `manageSettings` changes them, which is Finance. Whoever holds `seeAllCapital` reads them.
**Issue:** redix-app #35; the API side is redix-api #34.

## Screens

The canvas draws Partners with capital, shares and movements (`Partners.dc.html`), which need the ledger. This use case builds the list of partners under the title Partners.

The project's home, `HomeScreen`:

| Element | `Key` | Does |
| --- | --- | --- |
| Partners | `HomeScreen.partnersKey(id)` | Opens the screen below; shown with `seeAllCapital`. Someone else's own capital comes with UC-044 |

[Partners](../guide/partners.md), `PartnersScreen` at `/projects/:projectId/partners`:

| Element | `Key` | Does |
| --- | --- | --- |
| Add partner | `PartnersScreen.addKey` | Opens the dialog; shown with `manageSettings` |
| A partner's name | `PartnersScreen.nameKey(id)` | |
| Their login, or No login | `PartnersScreen.detailsKey(id)` | |
| Edit | `PartnersScreen.editKey(id)` | Opens the dialog; shown with `manageSettings` |
| The name, in the dialog | `PartnersScreen.partnerNameKey` | |
| The login, in the dialog | `PartnersScreen.loginKey` | A `MemberPicker`: one choice for no login, `MemberPicker.optionKey('')`, and one for each person in the project, `MemberPicker.optionKey(userId)` |
| What the login is for, in the dialog | `PartnersScreen.loginHintKey` | |
| Save, in the dialog | `PartnersScreen.saveKey` | |
| Why refused, in the dialog | `PartnersScreen.dialogMessageKey` | |
| The list's states | `PartnersScreen.messageKey`, `emptyKey` | Could not read; no partners |

## API calls

| Call | When |
| --- | --- |
| `GET /projects/{id}/partners` | Opening the screen, and after every change |
| `GET /projects/{id}/members` | Opening the screen with `manageSettings`, after the partners |
| `POST /projects/{id}/partners`, `.../{partnerId}` | Adding and editing |

## Rules and where they live

| Rule | Code | Test in `test/partners/partners_test.dart` |
| --- | --- | --- |
| Each partner shows their login, or that they have none | `PartnersScreen` | `each partner shows their login, or that they have none` |
| Adding by name alone sends no login | `Partners.add` | `adding by name alone sends no login` |
| Adding with a login sends it, and says what it is for | `PartnerDialog`, `MemberPicker` | `adding with a login sends it, and says what it is for` |
| A refusal stays in the dialog | `ChangeDialog` | `a refusal stays in the dialog with its reason` |
| Editing starts from the partner and renames them | `PartnerDialog`, `Partners.edit` | `editing starts from the partner and renames them` |
| Editing can give a login, and take it away | `Partners.edit` | `editing can give a login, and take it away` |
| A project with no partners says so | `ApiListBody` | `a project with no partners says so` |
| Seeing all capital without keeping the settings shows them with nothing to change | `Project.mayManageSettings` | `seeing all capital without keeping the settings shows them with nothing to change` |
| A finished project shows them with nothing to change (AC-04.1) | `Project.mayManageSettings` | `a finished project shows its partners with nothing to change` |
| Everyone in the project has a way in, each seeing their own line; whoever holds `seeAllCapital` sees every partner (BR-31) | `ProjectCard`, `PartnersScreen` | `partners_test.dart`: everyone in the project has a way in |
| A list that cannot be read says so | `ApiListBody` | `a list that cannot be read says so` |
| It fits 360 points wide in both languages (AC-N03) | `PartnersScreen`, `PartnerDialog` | `AC-N03` in `test/account/my_account_test.dart` |

The real app is run on an emulator by the journey in `patrol_test/app_test.dart`, which adds a partner with no login and one with a login.

## Left to later use cases

| What | Use case |
| --- | --- |
| Capital movements, a withdrawn partner's status, and the movements the canvas lists | The capital movement use cases |
| Each partner's capital and share, and someone seeing only their own | UC-044 "Compute partner shares" |
