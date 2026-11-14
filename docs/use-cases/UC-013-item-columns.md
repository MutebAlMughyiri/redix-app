[Documentation](../README.md) › UC-013

# UC-013: Manage item columns

**What it is for:** changing the fields an item asks for without a code change (FR-41): on one item, or on the project's default template for its type.
**Who uses it:** whoever holds `manageStructure` in the project, which is Finance. A finished project shows them with nothing to change.
**Issue:** redix-app #32; the API side is redix-api #31.

## Screens

On [Categories and items](../guide/categories.md), `CategoriesScreen`:

| Element | `Key` | Does |
| --- | --- | --- |
| Columns, on an item's row | `CategoriesScreen.itemColumnsKey(id)` | Opens the screen below |

[Item columns](../guide/item-columns.md), `ItemColumnsScreen` at `/projects/:projectId/items/:itemId/columns`:

| Element | `Key` | Does |
| --- | --- | --- |
| The item's category and type | `ItemColumnsScreen.itemDetailsKey` | |
| Default template | `ItemColumnsScreen.templateKey` | Shows the template for the item's type |
| This item only | `ItemColumnsScreen.thisItemKey` | Shows this item's columns; where the screen opens |
| Hint | `ItemColumnsScreen.hintKey` | Says what dragging and a lock mean |
| Add column | `ItemColumnsScreen.addKey` | Opens the Add column dialog |
| A column | `ItemColumnsScreen.rowKey(id)` | |
| Its handle | `ItemColumnsScreen.handleKey(id)` | Drags it |
| Its name | `ItemColumnsScreen.nameKey(id)` | |
| What it is | `ItemColumnsScreen.detailsKey(id)` | Custom, type, required or optional, in reports |
| Edit | `ItemColumnsScreen.editKey(id)` | Opens the Edit column dialog |
| The choices it has, in the Edit dialog | `ItemColumnsScreen.existingChoicesKey` | A list a person added: they stay, because entries hold their ids; a choice that gives the amount a sign shows it, such as مرتجع (سالب (−)) (redix-api #129) |
| New choices, in the Edit dialog | `ItemColumnsScreen.newChoicesKey` | One a line, added to those it has |
| Lock | `ItemColumnsScreen.lockKey(id)` | On a core column, in place of Delete |
| A column's swipe | `ItemColumnsScreen.rowKey(id).swipe` | Any column but a core one: swiped from its end toward its start, it is deleted once confirmed in its row (redix-api #119); on the template it still asks whether every item takes it (redix-api #102) |
| The name, in a dialog | `ItemColumnsScreen.columnNameKey` | |
| The type, in Add column | `ItemColumnsScreen.dataTypeKey` | The five a person chooses among |
| The choices, in Add column | `ItemColumnsScreen.choicesKey` | One a line; shown for a pick list |
| Required, in a dialog | `ItemColumnsScreen.requiredKey` | Off for a new column; shown as it stands and disabled on a core column |
| Shown in reports, in a dialog | `ItemColumnsScreen.showInReportsKey` | On for a new column; shown as it stands and disabled on a core column |
| Save, Cancel, in a dialog | `ChangeDialog.saveKey`, `ChangeDialog.cancelKey` | |
| Why refused, in a dialog | `ChangeDialog.messageKey` | |
| The delete question, in the row | `ItemColumnsScreen.rowKey(id).question`, `.confirm`, `.cancel` | Asked by `SwipeToRemove` once the row is swiped (redix-api #119) |
| The list's state | `ApiListBody.messageKey`, `retryKey` | Could not read, and Try again |

The question after a change to the template, `ApplyToAllDialog`:

| Element | `Key` | Does |
| --- | --- | --- |
| What it means | `ApplyToAllDialog.explainKey` | |
| Apply to all items | `ApplyToAllDialog.applyKey` | Sends the change with `applyToAllItems` true |
| Template only | `ApplyToAllDialog.templateOnlyKey` | Sends it with `applyToAllItems` false |

## API calls

`Columns`, an `ApiList`, calls everything in redix-api's [UC-013](https://github.com/MutebAlMughyiri/redix-api/blob/main/docs/use-cases/UC-013-item-columns.md). One class serves both lists, because they sit at the same shape of address.

## Rules and where they live

| Rule | Code | Test |
| --- | --- | --- |
| In Arabic a built-in field on the entry forms carries its column's name | `columnLabel` | `column_label_test.dart` |
| It opens on this item, and says where the item sits and what it is | `ItemColumnsScreen` | `item_columns_test.dart`: it opens on this item |
| A row says what the column is | `ColumnRow` | `item_columns_test.dart`: a row says |
| AC-41.2: a core column has a lock and no delete; any other a delete and no lock | `ColumnRow` | `item_columns_test.dart`: AC-41.2 |
| AC-41.1: a column is added to this item with what was chosen, asking nothing about other items | `AddColumnDialog`, `Columns.add` | `item_columns_test.dart`: AC-41.1 |
| A pick list sends its choices, each as `{ name }` with no sign, since a sign is set by no screen yet (redix-api #129); no file type is offered | `ColumnDataType.offered`, `AddColumnDialog`, `Columns.add` | `item_columns_test.dart`: a pick list |
| A refused column stays in its dialog, with why | `ChangeDialog` | `item_columns_test.dart`: a refused column |
| A core column changes its name only | `EditColumnDialog` | `item_columns_test.dart`: a core column changes |
| No dialog offers a type to change (AC-41.3) | `EditColumnDialog` | `item_columns_test.dart`: another column changes |
| A list a person added gains choices, one a line, and those it has stay and show; no other column offers it | `EditColumnDialog`, `ItemColumn.gainsChoices`, `Columns.edit` | `item_columns_test.dart`: a list a person added gains choices; only a list a person added |
| A swipe deletes a column once confirmed in its row (redix-api #119); a short one deletes nothing; a core one does not swipe (redix-api #102) | `SwipeToRemove` | `item_columns_test.dart`: a swipe deletes a column; AC-41.2 |
| Dragging sends the new order; on an item it asks nothing | `Columns.move`, `ReorderableListView` | `item_columns_test.dart`: dragging a column sends |
| AC-41.3: every change to the template asks whether it reaches existing items | `_applyToAll`, `ApplyToAllDialog` | `item_columns_test.dart`: AC-41.3: a change to the default template |
| A finished project shows its columns with nothing to change | `Project.mayChangeStructure` | `item_columns_test.dart`: a finished project |
| AC-N03: nothing off a screen 360 points wide, in both languages | Each screen | `settings/account_test.dart`: AC-N03 |

The real app and API run it together on a real phone in `patrol_test/structure/item_columns_test.dart` and `column_template_test.dart`, which take the guide's pictures.

## Left to later use cases

| What | Use case |
| --- | --- |
| The entry form following the columns (AC-41.1, and "changes for everyone after sync") | The purchase and contractor payment entry use cases |
| The item's table in the report following them | The periodic report |
