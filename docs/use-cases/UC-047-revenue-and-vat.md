[Documentation](../README.md) › [Use cases](../README.md) › UC-047, UC-048, UC-056

# UC-047, UC-048, UC-056: Revenue, sales invoices and the VAT statement

**Purpose:** record VAT refunds, sales and other revenue, record sales invoices, and see the VAT statement for any period.

**Who uses it:** everyone in the project sees revenue and the statement; whoever moves money records.

Revenue and Reports are on the project's home. The exports (UC-057, UC-058) come with the report files.

| Rule | Code | Test |
| --- | --- | --- |
| AC-28.1: a refund shows what the statement expected and the difference | `RevenueScreen` | `AC-28.1: a refund shows what the statement expected and the difference` |
| A refund sends its quarter, amount and account; other revenue no quarter | `RevenueFormScreen`, `QuarterPicker` | `a refund sends its quarter, its amount and its account`, `other revenue sends no quarter` |
| A refused entry says why and stays | `RevenueFormScreen._save` | `a refused entry says why and stays` |
| Everyone sees revenue; only whoever moves money records it | `RevenueScreen` | `everyone sees revenue, and only whoever moves money records it` |
| A sales invoice sends the buyer and its figures, with the real estate tax by default | `SalesInvoiceScreen` | `a sales invoice sends the buyer and its figures, with the real estate tax by default` |
| AC-42.1: an invoice may go on a sale already recorded | `SalesInvoiceScreen` | `AC-42.1: an invoice may go on a sale already recorded, so it counts once` |
| AC-32.2: the third quarter runs 01.07.2026 to 30.09.2026; a refund shows in brackets | `VatStatementScreen._quarterCard` | `AC-32.2: the third quarter of 2026 runs from 01.07.2026 to 30.09.2026, and a refund shows in brackets` |
| Choosing a quarter or a half-year reads its days | `VatStatementScreen._period` | `choosing a quarter reads its first and last days`, `AC-32.2: a half-year reads six months` |
| AC-32.3: what was left out shows, saying why | `VatStatementScreen._exceptions` | `AC-32.3: what was left out shows, saying why` |
| BR-17: Finance may declare an invoice in the next quarter | `VatStatementScreen._askToDeclareLater` | `BR-17: Finance may declare an invoice in the next quarter` |
