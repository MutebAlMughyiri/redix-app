[Documentation](../README.md) › [Use cases](../README.md) › UC-049, UC-050, UC-051, UC-063

# UC-049, UC-050, UC-051, UC-063: The dashboard and the reports

**Purpose:** the project's figures on its home, an item's report, the contracts, and completion and cost.

**Who uses it:** everyone in the project. Only whoever decides entries sees the way to what waits; only the manager sets the completion.

The home reads the figures again whenever it comes back into view, so an approval shows as soon as Finance returns (AC-34.1). The contracts report is the contracts screen (UC-020), reached from the home, which holds its PDF and Excel for whoever sees all capital; the item reports, the actual balances and the VAT refund open from the home's buttons too, and Reports holds the periodic reports alone (Muteb, 9 Nov 2026).

| Rule | Code | Test |
| --- | --- | --- |
| AC-34.1: the home shows the surplus, revenue, expenses and the difference | `DashboardCard` | `AC-34.1: the home shows the surplus, revenue, expenses and the difference`, `before any reconciliation there is no difference to show` |
| What waits opens the inbox, and coming back reads the figures again | `HomeScreen._open` | `what waits opens the inbox, and coming back reads the figures again` |
| Findings row 147: the card counts everything waiting, and says waiting expenses and waiting revenue with capital apart, each only when something waits | `WaitingFigures`, `DashboardCard` | `dashboard_test.dart`: what waits opens the inbox |
| Field sees the figures and no way to approve | `DashboardCard._figures` | `Field sees the figures and no way to approve` |
| A category opens to its items, an item to its report | `DashboardCard._category` | `a category opens to its items, and an item opens its report` |
| BR-06, redix-api #109: the revenue side is its categories in the structure's order, رأس المال first like any other, adding up to the revenue | `DashboardFigures.revenueCategories` | `BR-06, redix-api #109: the revenue side is its categories` |
| redix-api #109: رأس المال opens to its item like any category, and the item to its report, a table per partner the API lets the reader see (BR-31) | `DashboardCard`, `ItemReportScreen` | `redix-api #109: رأس المال opens to its item like any category` |
| UC-063: everyone sees the completion the API computed, and no cost line beside it; nobody types it (7 Nov 2026) | `DashboardCard` | `UC-063: everyone sees the completion the API computed, and no cost line beside it` |
| AC-30.1: an item report shows its total, a table per subgroup, and each contract | `ItemReportScreen` | `AC-30.1: an item report shows its total, a table per subgroup, and each contract with what remains` |
| AC-31.1: the reports open the contracts | `ReportsScreen` | `AC-31.1: the reports open the contracts, with value, paid and remaining` |
