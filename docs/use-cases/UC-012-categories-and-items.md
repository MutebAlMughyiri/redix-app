[Documentation](../README.md) › UC-012

# UC-012: Manage categories and items

**What it is for:** shaping a project's expense structure: its categories, their items and the items' subgroups (FR-05, FR-38, FR-39).
**Who uses it:** whoever holds `manageStructure` in the project, which is Finance. The way in follows that permission, and the app names no role.
**Issue:** redix-app #31; the API side is redix-api #30.

## Screens

The project's home, `HomeScreen`:

| Element | `Key` | Does |
| --- | --- | --- |
| Categories and items | `HomeScreen.categoriesKey(id)` | Opens the screen below; shown with `manageStructure` |

New project, `NewProjectScreen`, signed in:

| Element | `Key` | Does |
| --- | --- | --- |
| Copy categories and items from | `NewProjectScreen.structureSourceKey` | The default template unless changed, or an approved project on the user's list. The sign-in page's form has no such field |

[Categories and items](../guide/categories.md), `CategoriesScreen` at `/projects/:projectId/categories`:

| Element | `Key` | Does |
| --- | --- | --- |
| Hint | `CategoriesScreen.hintKey` | Says dragging sets the order of the report |
| New category | `CategoriesScreen.addCategoryKey` | Opens the name dialog |
| A category | `CategoriesScreen.cardKey(id)`, `categoryTileKey(id)` | Opens and closes to show its items |
| Its handle | `CategoriesScreen.categoryHandleKey(id)` | Drags it |
| Its name | `CategoriesScreen.categoryNameKey(id)` | |
| How many items, or Disabled | `CategoriesScreen.categoryDetailsKey(id)` | |
| Add item | `CategoriesScreen.addItemKey(id)` | Opens the Add item dialog |
| Rename | `CategoriesScreen.renameCategoryKey(id)` | Opens the name dialog |
| Disable, Enable | `CategoriesScreen.disableCategoryKey(id)`, `enableCategoryKey(id)` | Whichever applies |
| No items yet | `CategoriesScreen.noItemsKey(id)` | |
| An item | `CategoriesScreen.itemKey(id)` | |
| Its handle | `CategoriesScreen.itemHandleKey(id)` | Drags it inside its category |
| Its name | `CategoriesScreen.itemNameKey(id)` | |
| Its type, or Disabled | `CategoriesScreen.itemDetailsKey(id)` | |
| Columns | `CategoriesScreen.itemColumnsKey(id)` | Opens [its columns](UC-013-item-columns.md) |
| Its menu | `CategoriesScreen.itemMenuKey(id)` | Rename `renameItemKey`, Change type `changeTypeKey`, Tables `tablesKey`, the percentage of each table `tablePercentagesKey`, Disable `disableItemKey` or Enable `enableItemKey` |
| The name, in a dialog | `CategoriesScreen.nameKey` | |
| The type, in Add item | `CategoriesScreen.itemTypeKey(type)` | One choice per type, each in full; Purchases + contractor payments unless changed |
| Save, in a dialog | `CategoriesScreen.saveKey` | |
| Why refused, in a dialog | `CategoriesScreen.dialogMessageKey` | |
| The list's states | `CategoriesScreen.messageKey`, `emptyKey` | Could not read; no categories |

[Tables](../guide/categories.md#tables), `ItemTablesScreen` at `/projects/:projectId/items/:itemId/tables`:

| Element | `Key` | Does |
| --- | --- | --- |
| Hint | `ItemTablesScreen.hintKey` | Says the order is the sheet's |
| Add subgroup | `ItemTablesScreen.addKey` | Opens the name dialog; shown only on an item that takes purchases, since a sub-table holds purchases |
| A table | `ItemTablesScreen.rowKey(id)`, `tableNameKey(id)` | Every table the item's sheet prints: its general one, its subgroups and its contracts |
| What it prints | `ItemTablesScreen.detailsKey(id)` | Its kind and how many entries it holds |
| Handle | `ItemTablesScreen.handleKey(id)` | Drags the table; the order is the sheet's |
| Rename | `ItemTablesScreen.renameKey(id)` | A subgroup only; opens the name dialog |
| A subgroup's swipe | `ItemTablesScreen.rowKey(id).swipe` | A named subgroup only: swiped from its end toward its start, it is removed with no question; one that entries use comes back and the refusal says why (redix-api #102) |

## API calls

`Categories`, an `ApiList`, calls everything in redix-api's [UC-012](https://github.com/MutebAlMughyiri/redix-api/blob/main/docs/use-cases/UC-012-categories-and-items.md) except `GET .../categories/offered`, which the entry use cases will call. `Projects.create` sends `structureSourceId` when an earlier project was chosen.

## Rules and where they live

| Rule | Code | Test |
| --- | --- | --- |
| The way in follows `manageStructure` | `ProjectCard`, `Permission.manageStructure` | `categories_test.dart`: without the permission there is no way in |
| Categories show in order, each with how many items it holds | `CategoryCard` | `categories_test.dart`: categories show in order |
| An item shows its type | `Item.type`, `ItemRow` | `categories_test.dart`: a category opens to its items |
| AC-39.1: dragging a category sends the order, and it stays where it was dropped | `Categories.moveCategory`, `ApiList.reorder`, `ReorderableListView` | `categories_test.dart`: AC-39.1 |
| Dragging an item orders its category | `Categories.moveItem` | `categories_test.dart`: dragging an item |
| A refused or lost order goes back to what the API holds | `ApiList.reorder` | `categories_test.dart`: a refused order; an order lost |
| AC-05.3: an item has no delete, only Disable and Enable | `ItemRow` | `categories_test.dart`: AC-05.3 |
| A category is disabled and enabled, and says so | `CategoryCard` | `categories_test.dart`: a category is disabled |
| A new item takes the type chosen | `AddItemDialog` | `categories_test.dart`: a new item is sent |
| A refused name stays in its dialog, with why | `ChangeDialog` | `categories_test.dart`: a refused name |
| AC-46.8: an item lists every table its sheet prints, and only a subgroup is renamed or removed | `ItemTablesScreen` | `categories_test.dart`: AC-46.8: an item lists every table |
| A subgroup is added to the tables and renamed there | `ItemTablesScreen`, `ItemTables.addSubgroup` | `categories_test.dart`: a subgroup is added to the tables |
| A sub-table holds purchases: only an item that takes purchases offers one to add (Muteb, 7 Nov 2026) | `ItemType.takesPurchases`, `ItemTablesScreen` | `categories_test.dart`: an item that takes no purchases offers no sub-table |
| A sub-table added here is offered in إضافة قيد as its table and sheet, الجلاي (دفعات العظم), and takes a purchase | `ItemTablesScreen`, `EntryTable.label` | `categories_test.dart`: a sub-table added here is offered in إضافة قيد |
| AC-46.8: dragging a table sends the order of every table and stays; a refused order goes back and says why | `ItemTables.move`, `ApiList.reorder` | `categories_test.dart`: AC-46.8: dragging a table; a refused order of tables |
| A named subgroup is removed by a swipe with no question; the general table and a contract do not swipe; one that entries use comes back and the refusal says why (redix-api #102) | `ItemTables.deleteSubgroup`, `SwipeToRemove` | `categories_test.dart`: a named subgroup is removed by a swipe; AC-46.8; a subgroup that entries use |
| An item's type changes from its menu, starting from the one it has; one with entries keeps it and the dialog says why | `ChangeItemTypeDialog`, `ItemTypeChoice`, `Categories.changeItemType` | `categories_test.dart`: an item's type changes from its menu; an item with entries keeps its type |
| A finished project shows its structure with nothing to change (AC-04.1) | `Project.mayChangeStructure` | `categories_test.dart`: a finished project |
| AC-05.2: a new project can copy an approved earlier one, and the sign-in page offers none | `NewProjectScreen` | `categories_test.dart`: a new project |
| AC-N03: nothing off a screen 360 points wide, in both languages | Each screen | `settings/account_test.dart`: AC-N03 |

The real app and API run it together on a real phone in `patrol_test/structure/categories_test.dart`, `items_test.dart` and `item_tables_test.dart`, which take the guide's pictures.

## Left to later use cases

| What | Use case |
| --- | --- |
| AC-05.1 and AC-38.1 on the phone: the item picker at entry | The entry use cases; the API's rule and test are in now |
