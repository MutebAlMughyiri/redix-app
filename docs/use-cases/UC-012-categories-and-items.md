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
| Its menu | `CategoriesScreen.itemMenuKey(id)` | Rename `renameItemKey`, Change type `changeTypeKey`, Subgroups `subgroupsKey`, Disable `disableItemKey` or Enable `enableItemKey` |
| The name, in a dialog | `CategoriesScreen.nameKey` | |
| The type, in Add item | `CategoriesScreen.itemTypeKey(type)` | One choice per type, each in full; Purchases + contractor payments unless changed |
| Save, in a dialog | `CategoriesScreen.saveKey` | |
| Why refused, in a dialog | `CategoriesScreen.dialogMessageKey` | |
| The list's states | `CategoriesScreen.messageKey`, `emptyKey` | Could not read; no categories |

[Subgroups](../guide/categories.md#subgroups), `SubgroupsScreen` at `/projects/:projectId/items/:itemId/subgroups`:

| Element | `Key` | Does |
| --- | --- | --- |
| Hint | `SubgroupsScreen.hintKey` | Says what a subgroup is for |
| No subgroups | `SubgroupsScreen.emptyKey` | |
| Add subgroup | `SubgroupsScreen.addKey` | Opens the name dialog |
| A subgroup | `SubgroupsScreen.subgroupNameKey(id)` | The item's general group is never shown |
| Handle | `SubgroupsScreen.handleKey(id)` | Drags the subgroup; the order is the report's, and the general group stays first |
| Rename | `SubgroupsScreen.renameKey(id)` | Opens the name dialog |
| Remove | `SubgroupsScreen.deleteKey(id)` | Asks first, naming the subgroup, through `ConfirmDialog`; one that entries use stays and the refusal says why |

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
| A subgroup is added and renamed; the general one is not shown | `Item.namedSubgroups`, `SubgroupsScreen` | `categories_test.dart`: subgroups |
| Dragging a subgroup sends the order of the named ones and stays; a refused order goes back and says why | `Categories.moveSubgroup`, `ApiList.reorder` | `categories_test.dart`: dragging a subgroup; a refused order of subgroups |
| A subgroup is removed only after asking; one that entries use stays and the refusal says why | `Categories.deleteSubgroup`, `ConfirmDialog`, `showRefusalOf` | `categories_test.dart`: a subgroup is removed; a subgroup that entries use |
| An item's type changes from its menu, starting from the one it has; one with entries keeps it and the dialog says why | `ChangeItemTypeDialog`, `ItemTypeChoice`, `Categories.changeItemType` | `categories_test.dart`: an item's type changes; an item with entries keeps its type |
| A finished project shows its structure with nothing to change (AC-04.1) | `Project.mayChangeStructure` | `categories_test.dart`: a finished project |
| AC-05.2: a new project can copy an approved earlier one, and the sign-in page offers none | `NewProjectScreen` | `categories_test.dart`: a new project |
| AC-N03: nothing off a screen 360 points wide, in both languages | Each screen | `my_account_test.dart`: AC-N03 |

The real app and API run it together in `patrol_test/app_test.dart`, which takes the guide's pictures.

## Left to later use cases

| What | Use case |
| --- | --- |
| AC-05.1 and AC-38.1 on the phone: the item picker at entry | The entry use cases; the API's rule and test are in now |
