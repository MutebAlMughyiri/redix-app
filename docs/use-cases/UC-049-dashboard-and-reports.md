[Documentation](../README.md) › [Use cases](../README.md) › UC-049, UC-050, UC-051, UC-063

# UC-049, UC-050, UC-051, UC-063: The dashboard and the reports

**Purpose:** the project's figures on its home, an item's report, the contracts, and completion and cost.

**Who uses it:** everyone in the project. Only whoever decides entries sees the way to what waits; only the manager sets the completion.

The home reads the figures again whenever it comes back into view, so an approval shows as soon as Finance returns (AC-34.1). The contracts report is the contracts screen (UC-020), reached from Reports.

| Rule | Code | Test |
| --- | --- | --- |
| AC-34.1: the home shows the surplus, revenue, expenses and the difference | `DashboardCard` | `AC-34.1: the home shows the surplus, revenue, expenses and the difference`, `before any reconciliation there is no difference to show` |
| What waits opens the inbox, and coming back reads the figures again | `HomeScreen._open` | `what waits opens the inbox, and coming back reads the figures again` |
| Field sees the figures and no way to approve | `DashboardCard._figures` | `Field sees the figures and no way to approve` |
| A category opens to its items, an item to its report | `DashboardCard._category` | `a category opens to its items, and an item opens its report` |
| BR-06: the revenue side starts with رأس المال, which the app names, and its lines add up to the revenue; the capital line holds no partner and does not open (BR-31) | `DashboardFigures.revenueSide`, `CategoryTotal.capital`, `DashboardCard._category` | `BR-06: the revenue side starts with capital, named by the app, and the lines add up to the revenue`, `BR-31: the capital line holds no partner and does not open, with no arrow to tap` |
| UC-063: the manager sets the completion; everyone sees it and the cost | `DashboardCard._askCompletion` | `UC-063: the manager sets the completion, and everyone sees it with the cost`, `UC-063: only the manager sets it` |
| AC-30.1: an item report shows its total, a table per subgroup, and each contract | `ItemReportScreen` | `AC-30.1: an item report shows its total, a table per subgroup, and each contract with what remains` |
| AC-31.1: the reports open the contracts | `ReportsScreen` | `AC-31.1: the reports open the contracts, with value, paid and remaining` |
