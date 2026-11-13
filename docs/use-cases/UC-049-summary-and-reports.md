[Documentation](../README.md) › [Use cases](../README.md) › UC-049, UC-050, UC-051, UC-063

# UC-049, UC-050, UC-051, UC-063: The summary and the reports

**Purpose:** the project's figures on its home, an item's report, the contracts, and completion and cost.

**Who uses it:** everyone in the project. Only whoever decides entries sees the way to what waits; only the manager sets the completion.

The home reads the figures again whenever it comes back into view, so an approval shows as soon as Finance returns (AC-34.1). The contracts report is the contracts screen (UC-020), reached from the home, which holds its PDF and Excel for whoever sees all capital; the item reports, the actual balances and the VAT refund open from the home's buttons too, and Reports holds the periodic reports alone (Muteb, 9 Nov 2026).

| Rule | Code | Test |
| --- | --- | --- |
| AC-34.1: the home shows the surplus, revenue, expenses and the difference | `SummaryCard` | `AC-34.1: the home shows the surplus, revenue, expenses and the difference`, `before any reconciliation there is no difference to show` |
| What waits opens the inbox, and coming back reads the figures again | `HomeScreen._open` | `what waits opens the inbox, and coming back reads the figures again` |
| Findings row 147: the card counts everything waiting, and says waiting expenses and waiting revenue with capital apart, each only when something waits | `WaitingFigures`, `SummaryCard` | `summary_test.dart`: what waits opens the inbox |
| Field sees the figures and no way to approve | `SummaryCard._figures` | `Field sees the figures and no way to approve` |
| The home's revenue and expenses totals open to their categories with their totals, and a category opens nothing; المصروفات and الإيرادات, two buttons in Project settings, hold the items, each its own side with no switch (Muteb, 9 and 12 Nov 2026) | `SummaryCard`, `ItemReportsScreen` | `the categories show only once a tile is tapped`; `a category on the home opens nothing`; `المصروفات and الإيرادات are two screens` |
| A category opens to its items with their totals, an item to its report | `ItemReportsScreen` | `a category opens to its items with their totals, and an item opens its report` |
| BR-06, redix-api #109: the revenue side is its categories in the structure's order, رأس المال first like any other, adding up to the revenue | `SummaryFigures.revenueCategories` | `BR-06, redix-api #109: the revenue side is its categories` |
| redix-api #109: رأس المال opens to its item like any category, and the item to its report, a table per partner the API lets the reader see (BR-31) | `ItemReportsScreen`, `ItemReportScreen` | `redix-api #109: رأس المال opens to its item like any category` |
| UC-063: everyone sees the completion the API computed, and no cost line beside it; nobody types it (7 Nov 2026) | `SummaryCard` | `UC-063: everyone sees the completion the API computed, and no cost line beside it` |
| AC-30.1: an item report shows its total, a table per subgroup, and each contract; each row what it shows under its table's own columns, a list by its choice, an amount as money, and no bill number (redix-api #129, R1) | `ItemReportScreen._row`, `ReportColumn` | `AC-30.1: an item report shows its total, a table per subgroup, and each contract with what remains` |
| AC-31.1: the reports open the contracts | `ReportsScreen` | `AC-31.1: the reports open the contracts, with value, paid and remaining` |
