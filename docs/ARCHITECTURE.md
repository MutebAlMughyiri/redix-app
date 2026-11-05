[Documentation](README.md) › Architecture

# Architecture

One Flutter app for Android and iOS, built from Flutter's own pieces: a `LocalizationsDelegate` for words, Material widgets themed from one seed color, `Key`s for every element.

```
lib/
  main.dart                 the app: theme, languages, and the router that sends anyone without a session to sign-in
  account/my_account_screen.dart  My account: the language, the way into the password change, and signing out
  api_list.dart             ApiList: a list the API owns, and the way to change it; every settings list extends it
  ui/                       what several screens share: ApiListBody, ConfirmDialog, ChangeDialog, NameDialog, PickerField, showRefusalOf
  settings/
    settings_screen.dart    Settings: the way back to the project list, My account and, for the admin, the registered projects
    payment_method.dart     PaymentMethod, as the API answers it
    payment_methods.dart    PaymentMethods: the ApiList of one project's methods, and its changes
    payment_methods_screen.dart  a project's VAT rate and payment methods
    payment_method_row.dart one method, with its menu
    vat_rate_dialog.dart    the dialog that asks for the rate
  accounts/
    account.dart            Account and AccountType, as the API answers them
    accounts.dart           Accounts: the ApiList of one project's accounts, and its changes
    accounts_screen.dart    a project's bank accounts and cash custodies
    account_row.dart        one account, with its menu
    account_dialog.dart     the dialog that adds or edits an account
    my_custody.dart         what the signed-in user holds, on the project's home
    offered_accounts.dart   OfferedAccounts: the ApiList of what the signed-in user's entry may be paid from
  partners/
    partner.dart            Partner, as the API answers them
    partners.dart           Partners: the ApiList of one project's partners, and its changes
    partners_screen.dart    a project's partners
    partner_dialog.dart     the dialog that adds or edits a partner
  suppliers/
    supplier.dart           Supplier and SupplierStatus, as the API answers them
    suppliers.dart          Suppliers: the ApiList of one project's register, and its changes
    suppliers_screen.dart   a project's supplier register
    supplier_row.dart       one supplier, with its menu
    supplier_dialog.dart    the dialog that adds or edits a supplier
    vat_number_field.dart   the VAT number, or that there is none, and who already holds it
    supplier_search.dart    SupplierSearch: the ApiList of what the API finds for what was typed
    supplier_picker.dart    the sheet that picks a supplier by name or VAT number
    quick_add_supplier_dialog.dart  the dialog that adds a missing supplier, or offers the one already holding its number
  attachments/
    attachment.dart         Attachment: a file the API keeps, as it answers it
    attachments.dart        Attachments: the way to keep a file on the API
    picked_file.dart        PickedFile: what the camera or the files gave
    invoice_capture.dart    InvoiceCapture: the one place that touches the camera and the files
    picture_compression.dart  compressedPicture: a picture under 1 MB
  expenses/
    add_expense_screen.dart a new purchase expense
    invoice_section.dart    its invoice: the picture, and the ways to take or pick it
    invoice_figures.dart    InvoiceFigures: the amounts shown while typing; the API computes the ones kept
    figures_box.dart        those amounts, read-only and to two decimals
    column_value_field.dart the field of one custom column, by what it holds
    expenses.dart           Expenses: the way to record an expense, and what it was refused over
    earlier_entry.dart      EarlierEntry: the entry an invoice number repeats, as the API answers it
    invoice_qr.dart         InvoiceQr: what a Saudi e-invoice's QR code carries, read from its text
    qr_summary.dart         what was read from the code, and the offer to add its seller
  contracts/
    contract.dart           Contract and ContractFilter, as the API answers them
    contracts.dart          Contracts: the ApiList of one project's contracts, and its changes
    contracts_screen.dart   a project's contracts, with their filters
    contract_card.dart      one contract: value, paid, remaining and a bar, with its menu
    contract_dialog.dart    the dialog that adds or amends a contract
  projects/
    project.dart            Project and Unit, as the API answers them
    projects.dart           Projects: the ApiList of projects, and its changes
    projects_screen.dart    the project list, the first screen after sign-in, and the default project
    project_choice.dart     one project on the list
    project_card.dart       the open project, on its home
    add_unit_dialog.dart    the Add unit dialog
    member.dart             Member: someone in a project, as a person choosing among them sees them
    members.dart            Members: the ApiList of one project's active people
    member_picker.dart      the field that chooses someone in a project, or nobody
    new_project_screen.dart the new project form
  users/
    user.dart               User, as the API answers it
    users.dart              Users: the ApiList of one project's people, and its changes
    users_screen.dart       a project's people
    user_row.dart           one user on the list, with its menu
    role.dart               Role, as the API answers it; the app names no role
    roles.dart              Roles: the ApiList of what a project can give
    user_roles_screen.dart  a person's roles in a project
    add_existing_user_dialog.dart  the Add an existing user dialog
    edit_user_dialog.dart   the Edit dialog
    reset_password_dialog.dart  the Reset password dialog
    new_user_screen.dart    the new user form
  structure/
    category.dart           Category, Item, Subgroup and ItemType, as the API answers them
    categories.dart         Categories: the ApiList of one project's structure, and its changes
    categories_screen.dart  a project's categories and items, dragged into order
    category_card.dart      one category, opening to its items
    item_row.dart           one item, with its menu
    add_item_dialog.dart    the Add item dialog
    subgroups_screen.dart   an item's subgroups
    item_column.dart        ItemColumn and ColumnDataType, as the API answers them
    columns.dart            Columns: the ApiList of one item's columns or of a default template, and its changes
    item_columns_screen.dart  an item's columns, or the default template for its type
    column_row.dart         one column, with its handle and its lock or delete
    add_column_dialog.dart  the Add column dialog
    edit_column_dialog.dart the Edit column dialog
    apply_to_all_dialog.dart  the question after a change to the template
    offered_items.dart      OfferedItems: the ApiList of what an entry of one type may choose
    item_picker.dart        the field that chooses an item, from a sheet of what is on offer
  format/
    date_format.dart        formatDate: the app's one date format, dd.MM.yyyy
    number_format.dart      formatMoney (NFR-04), formatPlain, and parseNumber: what a person typed, in Arabic or Western digits
  api.dart                  the API's address and how a reply's JSON is read, shared by every feature
  auth/
    permission.dart         Permission: what the API says a user may do, as its name in the API
    session.dart            Session: the signed-in session, kept in the Keychain or Keystore
    biometrics.dart         Biometrics: the fingerprint or face check, one fixed word behind the phone's prompt
    sign_in_screen.dart     the sign-in screen
    change_password_screen.dart  the password change, forced while the password is temporary
  home/home_screen.dart     the home of the open project, and where a person lands
  words/
    words.dart              Words: the words of the language in use, from the API
    app_language.dart       AppLanguage: the language the user chose, kept on the phone
    word_getters.g.dart     one typed getter per word key; generated, never edited
    no_words_screen.dart    the word-free screen of a first start without a network
test/                       widget tests, mirroring lib/; app_harness.dart owns the fake API and storage
patrol_test/                end-to-end tests on a real emulator, against the real API
config/                     one file per environment, naming the API's address
tool/
  sync_translations.dart    regenerates word_getters.g.dart from the database keys
  update_guide_images.dart  copies Patrol's screenshots into docs/guide/images
docs/                       these pages
```

## Words

The code holds a word's key, never its value. `Words.of(context).appTitle` reads the key `app.title` in the language in use.

1. `WordsDelegate` asks `Words.load` for the language in use: the one chosen in My account (`AppLanguage`), else the phone's (Arabic for any language other than Arabic or English).
2. The phone keeps one language with its ETag. Kept words show at once and are refreshed in the background; another language is fetched from `GET /translations/{language}` first.
3. A first start without a network has no words: `NoWordsScreen` shows only an icon and a retry button, and a retry loads the words again.
4. Choosing a language in My account fetches its words first; only then does `AppLanguage` keep the choice and tell `RedixApp`, which rebuilds in the new `locale`. Without a network nothing changes.

## Session and screens

1. `main` reads the kept session (`Session.restore`) before the first frame, then renews it in the background with `POST /auth/refresh`.
2. `go_router` sends every route to `/sign-in` while the session is closed, to `/change-password` while the password is temporary, and away from sign-in once open; it listens to `Session`, so a sign-in, a password change or an ended session moves the screen at once.
3. Every request made as the user goes through `Session.post`: it sends the access token, and on a `401` renews the session once and sends again. Renewals run one after another, because each replaces the refresh token the next one needs.
4. Each screen declares its `path` and its element `Key`s.

## Data the API owns

Settings such as projects keep nothing on the phone: the API owns every rule, the app sends the change and draws what the API answers. `ApiList` reads the list again after every answer, so its order and each status have one source. A screen with two lists reads them at once. `Projects` and `Users` extend it, and hold only their own calls; `ApiListBody` draws its states on every such screen. A dragged row is the one thing shown before the API answers: `ApiList.reorder` keeps it where it was dropped, and a refused or lost order goes back to what the API holds. A change whose answer says more than a code reads `ApiList.lastAnswer`. A list whose address follows what is asked, like a search, moves with `ApiList.pointAt`, and an answer from the old address never shows.

## Rules every part follows

| Rule | Where it lives |
| --- | --- |
| No word value in the code; words come from the API | `lib/words/` |
| Every element a user sees or acts on has a `Key` constant on its screen | Each screen |
| One class to a file: a screen's card, row and dialogs are files of their own | Each feature folder |
| Every public class and member has a doc comment | The lint `public_member_api_docs` |
| The API's address comes from the environment's config file (`--dart-define-from-file=config/local.json`); none is built in | `apiBaseUrl`, `config/` |

## Tests

| Kind | Where | Runs |
| --- | --- | --- |
| Widget tests | `test/` | With the API and secure storage replaced by fakes from `app_harness.dart`, on every `flutter test` |
| End-to-end | `patrol_test/` | The real app on an emulator against the real API; each test also takes the user guide's screenshots |
