[Documentation](../README.md) › [Use cases](../README.md) › UC-047, UC-048, UC-056

# UC-047, UC-056: Revenue and the VAT statement

**Purpose:** take the VAT statement of any period as the accountant's workbook. Revenue is entered from Add entry and listed in القيود (UC-033).

**No Revenue screen and no sales invoice** (Muteb, 8 Nov 2026: "remove those completely"). Revenue is entered from Add entry, on a revenue item's table, waits for approval, and shows in القيود with every other entry, where it is reversed. The sales invoice, its route and its table went; RedixReal held none. The VAT statement keeps its purchases.

**Who uses it:** everyone in the project sees revenue; whoever moves money records; whoever sees all capital takes the statement's workbook.

Reports is on the project's home. The app shows and stores no VAT (redix-api #96, D4): `VatStatementScreen` chooses a quarter, a half-year or a custom period and hands on its Excel, whose VAT is a formula on each purchase's total (D19, D20).

| Rule | Code | Test |
| --- | --- | --- |
| AC-32.2, D20: a quarter's Excel, and nothing else, for its first to its last day | `VatStatementScreen._period`, `ReportFileButtons` | `AC-32.2, D20: the third quarter of 2026 takes its Excel, and nothing else` |
| AC-32.2: a half-year takes six months | `VatStatementScreen._period` | `AC-32.2: a half-year takes six months` |
| AC-32.2: a custom period never ends before it starts: the last day is picked from the first on, and a first day after the last moves the last day to it | `VatStatementScreen._pick` | `AC-32.2: a custom period never ends before it starts` |
