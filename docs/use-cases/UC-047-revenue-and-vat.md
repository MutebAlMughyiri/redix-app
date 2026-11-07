[Documentation](../README.md) › [Use cases](../README.md) › UC-047, UC-048, UC-056

# UC-047, UC-048, UC-056: Revenue, sales invoices and the VAT statement

**Purpose:** record VAT refunds, sales and other revenue, record sales invoices, and take the VAT statement of any period as the accountant's workbook.

**Who uses it:** everyone in the project sees revenue; whoever moves money records; whoever sees all capital takes the statement's workbook.

Revenue and Reports are on the project's home. The app shows and stores no VAT (redix-api #96, D4): `VatStatementScreen` chooses a quarter, a half-year or a custom period and hands on its Excel, whose VAT is a formula on each total (D19, D20). A VAT refund is plain revenue with no quarter (D23), and a sale is its buyer, VAT number, number, date and total (D22).

| Rule | Code | Test |
| --- | --- | --- |
| D23: a refund goes on its item with its amount and account, and no quarter | `RevenueFormScreen` | `D23: a refund is plain revenue` |
| Other revenue goes on its item and sends no quarter | `RevenueFormScreen` | `other revenue goes on its item and sends no quarter` |
| A refused entry says why and stays | `RevenueFormScreen._save` | `a refused entry says why and stays` |
| Everyone sees revenue; only whoever moves money records it | `RevenueScreen` | `everyone sees revenue, and only whoever moves money records it` |
| D22: a sales invoice sends the buyer, its number and its total | `SalesInvoiceScreen` | `D22: a sales invoice sends the buyer, its number and its total` |
| AC-42.1: an invoice may go on a sale already recorded | `SalesInvoiceScreen` | `AC-42.1: an invoice may go on a sale already recorded, so it counts once` |
| AC-32.2, D20: a quarter's Excel, and nothing else, for its first to its last day | `VatStatementScreen._period`, `ReportFileButtons` | `AC-32.2, D20: the third quarter of 2026 takes its Excel, and nothing else` |
| AC-32.2: a half-year takes six months | `VatStatementScreen._period` | `AC-32.2: a half-year takes six months` |
| AC-32.2: a custom period never ends before it starts: the last day is picked from the first on, and a first day after the last moves the last day to it | `VatStatementScreen._pick` | `AC-32.2: a custom period never ends before it starts` |
