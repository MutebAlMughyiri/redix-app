[Documentation](README.md) › Architecture

# Architecture

One Flutter app for Android and iOS, built from Flutter's own pieces: a `LocalizationsDelegate` for words, Material widgets themed from one seed color, `Key`s for every element.

```
lib/
  api.dart                  The API's address, from the environment's config file: `config/dev.json` for automated runs, `config/qa.json` for Muteb's own testing, `config/prod.json` for a release (redix-api #118); and the one place an answer is read: `jsonOf`, `answerOf`, `refusalOf`, `madeFrom`
  api_list.dart             A list the API owns, as it last answered, and the way to change it
  api_object.dart           Something the API owns, as it last answered, and the way to change it
  main.dart                 The app: its theme, its languages, and its screens
  account/
  accounts/
    account.dart            What kind of account holds a project's money, as the API names it, each knowing its word
    account_dialog.dart     Asks for an account's name and who holds it, and for a new account its type, which is set once; no balance (redix-app #89)
    transfer_dialog.dart    Moves money from one active account to another (FR-23)
    account_history*.dart   The account history: its lines, their words and icons, the filters and the next page
    account_row.dart        One account: its type and who holds it, or that it is disabled, what it holds and, for whoever keeps the settings, a menu of what can be done to it
    accounts.dart           A project's accounts and cash custodies, and the one way to change them
    accounts_screen.dart    A project's bank accounts and cash custodies: everyone with access sees them, and whoever keeps the settings adds, changes and disables them
    actual_balances_screen.dart The actual balances against the books, from the home, and تحديث to enter them again
    custody_card.dart         What the signed-in user holds, on the project's home: one card per account, and nothing for someone who holds none
    offered_accounts.dart   What the signed-in user's entry may be paid from
    reconcile_screen.dart   What each account and custody really holds, with the total and the difference as they are typed
    reconciliation.dart     One account against the books
    reconciliation_card.dart What the accounts should hold, what they really held, and the difference, red while it is not zero
  approvals/
    approvals.dart          What waits for a decision in a project, and the way to decide it
    approvals_screen.dart   Finance's inbox: what waits, oldest first, to approve one at a time or many at once, or to reject saying why
    approval_history.dart   What was approved and rejected, by whom and when, a page at a time, as the HistoryList the other histories are
    approval_history_screen.dart  السجل from the inbox's title bar: the approval history through HistoryView, filtered by kind of entry
    pending_approval.dart   An entry waiting for Finance's decision
    reject_sheet.dart       Rejects an entry, saying why: the reason returns to who entered it
  attachments/
    attachment.dart         A picture or a PDF the API keeps for a project, as it answers it
    attachment_screen.dart  Opens a file a project keeps: a picture to zoom into, or any other file, a PDF included, handed to the phone by its name to open
    attachments.dart        Keeps a project's files on the API, for an entry or a contract to name
    file_kind.dart          What a kept file is, by its content type, and the icon that shows it: the one owner of "is it a picture or a PDF" for whatever opens or lists a file
    invoice_capture.dart    The phone's camera, files, printer and share sheet, as the app reaches them: the one place that touches them, so a test can stand in for hardware it does not have
    picked_file.dart        What the camera or the files gave: a file, nothing when the person went back, or why neither
    picture_compression.dart A picture must be smaller than this many bytes to be kept: 1 MB, as the API counts it
  auth/
    biometrics.dart         The fingerprint or face check
    change_password_screen.dart The change-password screen: the current password and the new one twice
    forgot_password_screen.dart «نسيت كلمة المرور؟», open without a session: a code to the account's email, then the code and the new password twice (redix-api #127)
    password_reset.dart     Asks the API for a reset code and resets with it, no session, in the phone's language
    permission.dart         What the API says a user may do, named as the API names it
    session.dart            The signed-in session: the tokens the API issued, kept only in the Keychain or Keystore, and the one way to call the API as the user
    sign_in_screen.dart     The sign-in screen: username and password, or a fingerprint or face on a phone that uses them, with the language choice at the top so it can be read before signing in, and «نسيت كلمة المرور؟»
  config/
    app_config.dart         The configurable values the API keeps: how long a request waits for its answer, and later anything else made configurable
  contractor_payments/
    contract_figures.dart   What the chosen contract stands at with this payment, before it is saved: its value, what was paid, what waits, what remains after it, and the alert of an overrun
  contracts/
    contract.dart           A contract of a project, as the API answers it
    contract_card.dart      One contract: its contractor, item and unit, how it stands, its value, paid and remaining, with a bar of how much is paid and, for whoever keeps the settings, a menu of what can be done to it
    contract_dialog.dart    Asks for a contract's terms, and its contractor, item and unit while no payment names it
    contracts.dart          A project's contracts, and the one way to change them
    contracts_screen.dart   A project's contracts: everyone with access follows each one's value, paid and remaining, and whoever keeps the settings adds, amends and disables them
  documents/
    documents.dart          A document kept for the project: any file under a name, in a group when one was given
    documents_screen.dart   A project's documents: each group under its name, those in none first
  entries/
    add_entry_screen.dart   إضافة قيد: one form adds an entry to any table, an expense's, a revenue item's or a partner, asking every entry the same things and each table only its own (redix-api #110); it also opens an entry read only, as it was filled, with what can be done to it (redix-app #90)
    entries_screen.dart     A project's entries: each person's own, or all of them, searched and filtered on the API a page at a time with Show more, and what can be done to one
    entry_filter.dart       What the search of a project's entries asks the API to keep: what was typed, whose, which kinds, where they stand and when
    entry_link_screen.dart  Where a shared entry's link, or a notification about an entry, lands: Approvals on it for whoever may decide it, otherwise its sheet
    entry_share.dart        An entry as text for any app the phone shares to, ending in its link
    entry_recording.dart    Records a project's entries on the API through one route, whatever their table, or keeps them in the outbox while there is no network
    entry_kind.dart         What an entry is, named as the API names it, with the word key that names it: the one owner the filter, the entries list and Approvals read
    entry_row.dart          An entry on a list, and how an entry is called by its number, «قيد 312» (redix-api #128)
    entry_attachment.dart   A file an entry holds, as its page lists it: its role, name, type and when it was sent (redix-app #115)
    entry_attachment_role.dart What a file is to its entry, with the word that names it on the entry's page
    entry_status.dart       Where an entry stands, named as the API names it, and the color that marks it (redix-app #90)
    entry_tables.dart       One table an entry may go into, and what it asks beyond every entry
    entry_card.dart         An entry on a list of project's entries: tapping it opens its actions, and swiping it removes it where the user may delete it
    latest_entries.dart     The project's entries on its home: the newest by anyone, as many at a time as Settings chooses, a search beside the heading, and Show more for as many again
    newest_entries.dart     The one owner of reading entries a page at a time: the home's newest, each Show more reading as many again
    opened_entry.dart       The entry a page opened, read by its id as the lists show it, whichever list opened it: where it stands, sending and reversing it (findings row 201)
    project_entries.dart    A project's entries, newest first: everyone who reads the project sees them all, and only their own drafts
    searched_entries.dart   The Entries screen's search: the newest entries with what was typed and chosen sent to the API, a page at a time
    saved_entry.dart        An entry as the API keeps it, whatever its table, with every file it holds, read to fill Add entry when it is changed and to list its files
    table_picker.dart       The field that chooses the table an expense goes into, opening a sheet of every table on offer: by category, each item with its general table first and its named tables and contracts under it, with a search over the items' and the tables' names
  expenses/
    column_value_field.dart The field of one custom column, drawn from what the column holds: a required one is marked
    entry_date.dart         Asks for an entry's date in project, from current: within its period and not in the future
    invoice_qr.dart         What a Saudi e-invoice's QR code carries: the text is base64 of tag, length and value, one after another, tags 1 to 5 being the seller, its VAT number, the time, the total including VAT and the VAT
    invoice_section.dart    The file of a new expense, its invoice or its receipt: its picture, and the ways to take it again or pick it from the phone's files
    original_invoice_picker.dart The field that links a credit note to the bill it returns, which it needs (D13), opening a sheet of what that supplier's bills have left to return
    payment_choice.dart     What a person chose to pay an entry from, and how
    payment_choices.dart    The account an entry moves money through, for any table, and how an expense was paid: an expense offers only what the signed-in user may pay from
    qr_summary.dart         What was read from the invoice's QR code: its five fields, and an offer to add the seller when no supplier holds its number
  history/
    history_list.dart       A history, newest first, a page at a time: of every thing it covers or one, everyone's lines or one person's, and those holding what was typed
    history_view.dart       The one look of every history: the search line, its filters (a thing and a person: everyone, «أنا», each member), the lines and المزيد
    project_history.dart    «سجل المشروع»'s lines (what was done, to what, its name and what else it names) and their kinds, as the HistoryList every history is
    project_history_screen.dart  «سجل المشروع» from Project settings, for whoever holds seeProjectHistory: every action in the project, filtered by kind and person
    my_history.dart         «سجلي»'s lines: what happened to one's own login, and who did it
    my_history_screen.dart  «سجلي» from Settings: one's sign-ins, passwords, fingerprint and details, filtered by kind
  format/
    date_format.dart        A date as the app shows it, in both languages: Gregorian dd.MM.yyyy; a moment the API sends, read in the phone's own time (momentOf)
    number_format.dart      A number as a person types it: no separators, and as few decimals as it needs, at most two, so 15 is 15 and 7.5 is 7.5
    parts_line.dart         The non-empty parts of a line joined by a middle dot, the one way a row writes its details
  home/
    summary_card.dart     The project's figures at a glance: what waits for approval, the surplus, the completion, the reconciliation difference, and the revenue and expenses totals, each opening to its categories with their totals; a category opens nothing
    home_screen.dart        The home of the open project: the project, with what the user's permissions allow in it
  launcher/
    launcher_add_entry.dart REDIX outside the app: «إضافة قيد» on the icon's menu and the home-screen widget, with the latest entries under its button, whose every tap opens the one link /add-entry (redix-app #86); the widget itself is android/app/src/main/kotlin/redix/AddEntryWidget.kt, drawing what this saves
  notifications/
    notification_row.dart   Something a person was told: its words come from kind, in their language
    notifications.dart      What the signed-in person was told
    notifications_bell.dart The way to what the person was told, counting what they have not seen
    notifications_screen.dart What the person was told, newest first
  offline/
    folder_store.dart       Keeps files in the app's private folder on the phone
    local_store.dart        What this phone keeps outside the app's memory, in named files inside folders
    outbox.dart             The entries waiting on this phone for the network
    pending_entry.dart      An entry waiting on this phone for the network
    project_sync.dart       Keeps on the phone what a project's screens read, so that an entry can be entered with no network
    waiting_screen.dart     What waits on this phone for the project: an entry the network has not taken yet, or one the API refused, which waits for its author
  partners/
    capital.dart            One partner's capital
    capital_movement.dart   One movement of a partner's capital
    capital_movements.dart  One partner's movements, newest first
    movements_screen.dart   One partner's movements, each with its receipt; whoever holds the removal swipes one away
    partner.dart            A partner in a project, as the API answers them
    partner_dialog.dart     Asks for a partner's name and their login
    partner_history*.dart   The partners' history: its lines, their words and icons
    partner_menu.dart       A partner's ⋮ menu: rename, and Delete, gray saying why while capital, something waiting or someone else's draft holds them
    partners.dart           A project's partners, and the one way to change them
    partners_screen.dart    A project's partners and capital: the total, each line the user may see with its balance and share, and a way into its movements
  projects/
    default_project_toggle.dart Makes project the default project of session, or clears it when it already is, the one way the star and Settings both change it
    member.dart             Someone in a project, as a person choosing among them sees them
    member_picker.dart      Chooses someone in a project, or nobody, as a list of choices with every name in full
    members.dart            The active people of one project, for choosing who holds something in it
    new_project_screen.dart The form that registers a project: its name, its start date and its units
    project.dart            Where a project stands, as the API says it, each knowing its word so no reader needs to tell them apart
    project_settings_card.dart The open project's buttons, four to a page, swiped sideways and going round, with a dot for each page; the four used most first
    project_file_loading.dart Loads a project file (UC-071): pick the .json, say yes, send it, then the bar says what was loaded or the refused list opens
    project_file_refusal.dart One refusal of a project file's load, by the file's item, table and row, and whose word says why
    project_file_refusals_screen.dart What a project file's load refused: nothing saved, every row listed at once
    project_choice.dart     One project on the list: its name, units and its status
    project_status_chip.dart Where a project stands, as a chip: the project list and More info draw the same one
    project_info_screen.dart More info (معلومات المشروع, redix-api 93): the project's own record on one page, its name, start date, status, units and description
    project_registration.dart Registers a project from the sign-in page, with its description, no session, and a new login as its manager
    projects.dart           The projects, and the one way to change them
    projects_screen.dart    The project list, the first screen after sign-in: the projects the user has access to, one to open, and the default project
    registered_project.dart A project waiting for the admin, as the API answers it: what is needed to decide, and nothing more
    registered_projects.dart What is waiting for the admin, and the one way to decide it
    registered_projects_screen.dart Registered projects: what is waiting for the admin, with the manager's details and a decision
    unit_row.dart           One unit on More info: its name and, for whoever manages the open project, a menu to rename it and a swipe that removes it
  reports/
    summary.dart          One item's total, one category's, and the project's figures
    item_report.dart        An item's report: its tables' columns and each purchase or payment under them, as the API prints them (redix-api #129)
    item_report_screen.dart Everything spent on one item: a table per subgroup, then each contract with its value, paid and remaining
    periodic_report_screen.dart One periodic report as it was issued: what everyone may read, and its files for whoever may export them
    periodic_reports.dart   A periodic report issued
    quarter_picker.dart     A quarter chosen by its year and its number, each as chips, from the year firstYear to this one
    report_files.dart       What can be done with a report's file on the phone
    reports_screen.dart     A project's periodic reports: the next one and those issued before
    item_reports_screen.dart المصروفات or الإيرادات, each its own button in Project settings: one side's categories, each with its total and share, opening on its items, each opening its report
    category_share.dart     A category's name and total over a bar of its share of its side
    vat_statement_screen.dart How a period is chosen
    waiting_figures.dart    What waits for approval, as two figures: expenses, which lower the surplus once approved, and revenue with partners' money, which raises it
    year_chips.dart         A year chosen as chips, from this year back to firstYear
  settings/
    default_project_sheet.dart The choice of the default project, from Settings: every project the user may open with a tick, the default one ticked
    my_email_dialog.dart    «بريدي», its first step: the new address, to which a code is sent (redix-api #127)
    my_email_code_dialog.dart «بريدي», its second step: the code, which makes the new address the email
    payment_method.dart     A way a project pays, such as شبكة, as the API answers it
    payment_method_row.dart One payment method: its name, whether it is disabled and, for whoever keeps the settings, a menu of what can be done to it
    payment_methods.dart    A project's payment methods, and the one way to change them
    payment_methods_screen.dart A project's payment methods: whoever keeps its settings adds, renames, disables and deletes them; one an expense was paid with is only disabled
    shared_settings_screen.dart    Settings (الإعدادات), one screen: who is signed in, Switch project, the default project, the registered projects for the admin, the language, fingerprint or face, «بريدي», the password change, «سجلي» and signing out
  sharing/
    attachable_entries.dart The entries of a project a shared file's QR code matches, and the way to put a file on an entry
    share_screen.dart       What opens when a picture or a PDF is shared to the app: put it on any entry the person may handle, found in القيود's list and its search, or start a new entry with it
  structure/
    add_column_dialog.dart  Asks for a new column: its name, its type, which never changes after, the choices of a list, whether entry requires it, and whether it prints
    add_item_dialog.dart    Asks for a new item's name and type, which is set once
    apply_to_all_dialog.dart Asks whether a change to the default template reaches the items that already exist
    categories.dart         A project's categories with their items and subgroups, and the one way to change them
    categories_screen.dart  A project's categories and items: whoever shapes the structure adds, renames, drags and disables them
    category.dart           What an item is for, as the API names it, each knowing its word
    category_card.dart      One category of the list: its name, how many items it holds or that it is disabled, and a handle to drag it
    change_item_type_dialog.dart Asks what an item is for now, starting from what it is
    column_label.dart       What an entry form calls the built-in field key
    column_row.dart         One column on the list: its name and what it is, a handle to drag it and a way to change it; a core column shows a lock, and any other is removed by a swipe
    columns.dart            The columns of one item, or of a project's default template for one type of item, and the one way to change them
    edit_column_dialog.dart Changes a column: its name, and unless it is core whether entry requires it and whether it prints
    item_column.dart        What a column holds, as the API names it, each knowing its word
    item_columns_screen.dart The fields an item asks for: this item's own, or the project's default template for its type, each added, renamed, dragged and deleted
    item_picker.dart        The field that chooses an item, opening a sheet of what is on offer, by category, with every name in full
    item_row.dart           One item under its category: its name and type, or that it is disabled, a handle to drag it, the way into its columns, and a menu of what can be done to it
    item_tables.dart        What a table of an item's sheet prints, as the API names it
    item_tables_screen.dart An item's tables, in the order its sheet prints them: its general table, each subgroup a person named, and each contract's payments, each with how many approved entries it holds
    item_type_choice.dart   What an item is for: its side first, expenses or revenue, then one of that side's types, for the dialogs that add an item and change its type
    offered_items.dart      What an entry of one type may choose from, by category
  suppliers/
    quick_add_supplier_dialog.dart Asks for a missing supplier's name and VAT number, without leaving what is being entered
    supplier.dart           Where a supplier stands, as the API names it
    supplier_dialog.dart    Asks for a supplier's name, VAT number or that it has none, mobile and default item
    supplier_picker.dart    Picks a supplier from a project's register: a sheet that searches by name or VAT number, so free text never names a supplier, and adds a missing one without leaving what is being entered
    supplier_row.dart       One supplier: its name, what the register says about it and, for whoever keeps the settings, a menu of what can be done to it
    supplier_search.dart    What an entry may pick from a project's register: what the API finds for what was typed
    suppliers.dart          A project's supplier register, and the one way to change it
    suppliers_screen.dart   A project's supplier register: everyone with access sees it, and whoever keeps the settings adds, changes and disables its suppliers
    vat_number_field.dart   Asks for a supplier's VAT number, which may stay empty, and names the supplier already holding a number that was refused
  ui/
    app_color.dart          Every color the app shows, named for what it is for (a refusal, something quiet, a card's frame, an entry waiting) and taken from the theme; the one place a color is chosen
    amount_line.dart        A label with its amount at the end of the line, each in the style the screen wants
    api_list_body.dart      The body of a screen that shows an ApiList: why it could not load with a way to try again, loading, empty, or its items, which are read again when pulled down
    api_object_body.dart    What shows something the API owns: why it could not load with a way to try again, or what builder draws from it
    arabic_spelling.dart    The letters a person may write either way, as `ArabicSpelling` on the API treats them, and what was typed as the API is asked it
    busy.dart               A spinner over the screen while a file is picked, read or sent, removing itself once the work ends
    bottom_button.dart      A screen's main action: one full-width filled button at its bottom, the same on every screen
    change_dialog.dart      A dialog that sends a change: it closes once saved, and a refusal stays in it with what was typed
    confirm_dialog.dart     Asks before a change that deserves a second thought: what it applies to, what it means, and a red button to go ahead
    drag_handle.dart        The one drag handle of a row put in order, grayed and still while a search narrows its list
    filter_line.dart        The one line of filters under a search line: a segmented choice, a chip on or off, a chip opening a list of many or of one, an action chip
    entry_field.dart        One typed field of an entry's form, the same on every kind of entry: text, or a number on the phone's number keyboard, which has a minus sign when it isSigned
    form_error.dart    A form's error: the line above its first field, brought to the top of the view when it appears (redix-app #98)
    form_button_style.dart  The one style of a form's full-width main button, which stays inside the form
    form_section.dart       One section of a long form: its children on a card, evenly spaced
    labelled_chips.dart     A choice among a few, drawn as chips under what is being chosen
    list_search.dart        What a list is searched by, on the phone or on the API, what its search line says and its filters, and how the phone matches what was typed
    name_dialog.dart        Asks for one name, for adding or renaming anything in a project, or one «رقم القيد» for the entries' filter
    part_keys.dart          The keys of the parts inside a keyed element: its label, icon, title, subtitle and the field it is drawn as
    picker_field.dart       A field whose value is chosen elsewhere: it looks like a text field, shows what was chosen, and opens the choice when tapped
    picker_sheet.dart       Opens a sheet of choices, the same for every picker
    refusal_text.dart       A refusal or failure said in words, in the one refusal color
    row_menu.dart           A row's ⋮ menu and its choices; each row lists its own
    row_stripe.dart         Rows one under another a shade apart: an odd row takes the scheme's next tone
    messages.dart           The key of the SnackBar saying the word wordKey: every message has its own key, made from what it says, so a test finds it by key
    screen_title.dart       A screen's title in the app bar, with what it belongs to on a line beneath, so a long title on a narrow phone never cuts the name to a letter
    search_line.dart        The one search line, shown while its screen's search is open, ready to type, handing what is typed on once typing pauses for a list the API searches, its ✕ closing it and clearing what was typed; the filter line under it while open
    search_scope.dart       One screen's search (redix-app #104, version 3): SearchScope over its Scaffold holds whether the line and the filters show and what is typed; SearchIcons in the title bar opens them, the filter icon filled while a filter is in use
    swipe_to_remove.dart    The one way a row is removed, and the one frame of a row that can be: an outlined card with a red bar inside its end edge where it may be removed, swiped from that edge toward its start past 40% of its width, once confirmed in its row (redix-api #119)
    title_bar_add.dart      The plus in a title bar, for what is added rarely, grayed without the permission
  users/
    add_existing_user_dialog.dart Adds someone who already has a login to this project, by their exact username, so a manager never sees another project's people
    edit_user_dialog.dart   Corrects a user's name, mobile and email
    new_user_screen.dart    The new user form: their name, username, mobile, email and a temporary password they change at first sign-in
    permission_tick.dart    One permission as a tick: its name and what it allows
    permission_ticks.dart   Every permission of a project as a tick, the capital ones under their headings with the partners to choose: the one list Permissions, صلاحياتي and the new-person form draw
    my_permissions_screen.dart صلاحياتي, from the home: what the signed-in user may do in the project, ticked, read only
    reset_password_dialog.dart Sets a new temporary password for a user, typed by whoever manages them, who passes it on
    user.dart               A person in a project, as the API answers them
    user_permissions_screen.dart What one person may do in one project: a tick for each permission, saved at once
    user_row.dart           One user on the list: their name, username, mobile and how many permissions they hold, a badge when inactive in this project, and a menu of what can be done to them
    users.dart              The people of one project, and the one way to change them
    users_screen.dart       The people of one project, for its manager: one row per user, with a menu to edit, tick permissions, reset the password, and make them inactive in this project or active again
  words/
    app_language.dart       The language the user chose, on the sign-in screen or in Settings, kept on the phone; empty while the app follows the phone's language
    language_switch.dart    The choice between Arabic and English, the same on the sign-in screen and in Settings, with the line that says why it could not switch
    no_words_screen.dart    Shown on a first start without a network, when the app has no words yet; it needs none, only an icon and a retry button
    word_getters.g.dart     generated by tool/sync_translations.dart from the API's words; never edited by hand
    words.dart              The words of the language in use, fetched from the API. The app's code names a word by its key; WordGetters gives one typed getter per key
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

1. `WordsDelegate` asks `Words.load` for the language in use: the one chosen in Settings (`AppLanguage`), else the phone's (Arabic for any language other than Arabic or English).
2. The phone keeps one language with its ETag. Kept words show at once and are refreshed in the background; another language is fetched from `GET /translations/{language}` first.
3. A first start without a network has no words: `NoWordsScreen` shows only an icon and a retry button, and a retry loads the words again.
4. Choosing a language in Settings fetches its words first; only then does `AppLanguage` keep the choice and tell `RedixApp`, which rebuilds in the new `locale`. Without a network nothing changes.
5. Each time words load, `WordsDelegate.onLoaded` hands them to `LauncherAddEntry`, which writes «إضافة قيد» on the icon's menu and the home-screen widget in the app's language (redix-app #86 R5).

## Session and screens

1. `main` reads the kept session (`Session.restore`) before the first frame, then renews it in the background with `POST /auth/refresh`. It renews again on its own when the app comes back to the screen (`RedixApp`'s `AppLifecycleListener`) and 30 seconds before the access token runs out (one `Timer`), and after each renewal `Projects` reads the list again, so a project the user was made inactive in leaves the screen (redix-api #126).
2. `go_router` sends every route to `/sign-in` while the session is closed, to `/change-password` while the password is temporary, and away from sign-in once open; it listens to `Session.access`, so a sign-in, a password change or an ended session moves the screen at once, and nothing else does: a refresh of `go_router` rebuilds the open screens without the `extra` they were opened with (redix-api #126).
3. Every request made as the user goes through `Session.post`: it sends the access token, and on a `401` renews the session once and sends again. Renewals run one after another, because each replaces the refresh token the next one needs. A read waits for what was sent before it, so leaving a screen while a change is on its way cannot show the old value. `Session.get` keeps each list it reads, and answers from that copy when the network fails; `ProjectSync` fills the copies on opening a project; `Outbox` holds entries waiting for the network (UC-029).
4. Each screen declares its `path` and its element `Key`s.
5. «إضافة قيد» from the icon's menu or the home-screen widget is one link, `/add-entry`; its route reads the projects, then lands as `HomeScreen.addEntryLandingOf` says: Add entry in the default project, its home, or the project list (redix-app #86). Add entry sits under its project's home, so a link that opens it has the home behind it.

## Data the API owns

Settings such as projects keep nothing on the phone: the API owns every rule, the app sends the change and draws what the API answers. `ApiList` reads the list again after every answer, so its order and each status have one source. A screen with two lists reads them at once. `Projects` and `Users` extend it, and hold only their own calls; `ApiListBody` draws its states on every such screen; a screen that filters its list hands it `keeps`, so a filter that keeps nothing says so in the list's own empty line. Every refusal becomes a word key in one place, `refusalOf` in `lib/api.dart`: the code the API names, or `refused` when it names none. Every answer becomes what the app holds in one place too, `madeFrom` in `lib/api.dart`: one in a shape this version no longer reads, as a copy an earlier version kept on the phone may be, fails as nothing kept would (redix-api #126). A dragged row is the one thing shown before the API answers: `ApiList.reorder` keeps it where it was dropped, and a refused or lost order goes back to what the API holds. A change whose answer says more than a code reads `ApiList.lastAnswer`. A list whose address follows what is asked, like a search, moves with `ApiList.pointAt`, and an answer from the old address never shows.

## Rules every part follows

| Rule | Where it lives |
| --- | --- |
| No word value in the code; words come from the API | `lib/words/` |
| No color in a screen: every color is an `AppColor`, named for what it is for and read from the theme, so a design change or a dark mode is made in one file (Muteb, 9 Nov 2026) | `lib/ui/app_color.dart`; `app_color_test` fails on any other file that picks a color |
| Every element a user sees or acts on has a `Key` constant on its screen, and every label, icon, title, subtitle, card and message has one too: a part inside a keyed element takes its element's key and the part's name (`HomeScreen.accountsKey(id).label`), and a message its word (`messageKeyOf('projects.pendingEntries')`). A test finds an element by its key, never by its text or its place | Each screen, `PartKeys`, `messageKeyOf` |
| A button that sends something goes through `ActOnce`: the first tap runs its action and the button stays gray until the action ends, so a double tap cannot act twice; buttons that must not run together share one `ActOnce` (Muteb, 10 Nov 2026). `BottomButton` has it built in. A button that only opens a screen needs none, because the new screen covers it from its first frame | `lib/ui/act_once.dart`, `BottomButton` |
| Light and dark grow from one function, `appThemeOf`, from `AppColor.seed`; Appearance in Shared settings keeps `themeMode_state`, 0 light, 1 dark and 2 the phone's (the default), in `LocalConfig`, which tells `RedixApp` so every screen redraws at once, and on the phone's Flutter redraws with the phone (redix-app #87, #97) | `lib/ui/app_theme.dart`, `LocalConfig`, `SharedSettingsScreen` |
| A screen's main action is `BottomButton`: one full-width filled button in the `Scaffold`'s `bottomNavigationBar`, its bar keyed `BottomButton.barKey`, a plus unless the action says otherwise; no screen draws a floating button. Adding what is added rarely is `TitleBarAdd`, a plus in the title bar instead (Accounts, Partners, Documents, Payment methods, Users: redix-app #101, #106). Without the permission either shows grayed, never hidden | `lib/ui/bottom_button.dart` |
| One class to a file: a screen's card, row and dialogs are files of their own | Each feature folder |
| Every public class and member has a doc comment | The lint `public_member_api_docs` |
| The environment's config file (`--dart-define-from-file=config/dev.json`, `config/qa.json` or `config/prod.json`, named as the API's environments `Dev`, `QA` and `Prod`) decides the API's address and, through `build.gradle.kts`, the app's id, its name and its link host; none is built in, and without the file the app is `com.techdetails.redix`, REDIX, `redix.test`, the production names (redix-app #95, #118 D2) | `apiBaseUrl`, `config/`, `build.gradle.kts` |

## Tests

| Kind | Where | Runs |
| --- | --- | --- |
| Widget tests | `test/` | With the API and secure storage replaced by fakes from `app_harness.dart`, on every `flutter test` |
| End-to-end | `patrol_test/` | The real app on an emulator against the real API; each test also takes the user guide's screenshots |
