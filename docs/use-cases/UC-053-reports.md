[Documentation](../README.md) › [Use cases](../README.md) › UC-053, UC-056, UC-059

# UC-053, UC-059: The periodic report, and printing or sharing a report

**Purpose:** issue the numbered periodic report, read any issued one, and print or share a report's file.

**Who uses it:** whoever holds `seeReports` («يرى التقارير») reads a report, with only their own partner line (BR-31). Whoever holds `generateReports` («يُصدر التقارير») issues the next one, in an active project, and takes the files, whose رأس المال holds only the partners they may see. Without its permission each button shows gray, never hidden: Reports, المصروفات and الإيرادات on the home without `seeReports`; Issue, PDF, Excel and Print without `generateReports` (redix-api #131). Moving money and seeing all capital no longer decide either.

`ReportFiles` is the one way any report screen gets a file from the API and hands it to the phone. `InvoiceCapture`, the app's one owner of the phone's hardware, now also holds the printer (AirPrint on iPhone, the print service on Android and Huawei, with a preview) and the share sheet.

**Not proven on a phone:** no file has been printed or shared on a real device yet; the tests stand in at `InvoiceCapture`. Findings row 119 says what is left.

| Rule | Code | Test |
| --- | --- | --- |
| UC-053: issuing asks first, saying its number, and the report then shows | `ReportsScreen._askToIssue` | `UC-053: issuing asks first, saying its number, and the report then shows` |
| UC-053: a report opens as issued, with the difference from the last | `PeriodicReportScreen` | `UC-053: a report opens as it was issued, with the difference from the last` |
| AC-48.1: print opens the printer with the PDF; share hands the workbook on | `ReportFiles.hand`, `InvoiceCapture.printPdf`, `shareFile` | `AC-48.1: print opens the phone's printer with the PDF, and share hands the workbook on` |
| redix-api #131: «يرى التقارير» alone reads the report, its Issue, PDF, Excel and Print gray, never hidden | `Project.mayIssueReports`, `Project.mayTakeReportFiles`, `ReportFileButtons.mayTake` | `redix-api #131: someone holding «يرى التقارير» alone reads the report, and its Issue, PDF, Excel and Print show gray, never hidden` |
| redix-api #131: «يُصدر التقارير» issues and takes the files without moving money or seeing all capital | `Project.mayIssueReports`, `Project.mayTakeReportFiles` | `redix-api #131: «يُصدر التقارير» issues and takes the files without moving money or seeing all capital` |
| redix-api #131: a finished project issues nothing, and its files are still taken | `Project.mayIssueReports`, `Project.mayTakeReportFiles` | `redix-api #131: a finished project issues nothing, and «يُصدر التقارير» still takes its files` |
| redix-api #131: without «يرى التقارير» Reports, المصروفات and الإيرادات show gray on the home, and Contracts still opens | `ProjectSettingsCard._button`, `Project.maySeeReports` | `redix-api #131: without «يرى التقارير» Reports, المصروفات and الإيرادات show gray, never hidden, and Contracts still opens` in `project_settings_test.dart` |
| UC-057, D20: the VAT statement hands on its workbook for the period shown | `VatStatementScreen` | `UC-057, D20: the VAT statement hands on its workbook for the period shown` |
| AC-33.1: an item report hands on its PDF | `ItemReportScreen` | `AC-33.1: an item report hands on its PDF` |
| redix-api #131: without «يُصدر التقارير» an item report's PDF and Excel show gray | `ItemReportScreen`, `ReportFileButtons.mayTake` | `redix-api #131: without «يُصدر التقارير» an item report's PDF and Excel show gray` |
| redix-api #131: every permission that grays a report's button has its gate, its button working only with it | `permission_gates_test.dart` | `FR-03: An enabled Reports on the home …`, `A periodic report's working files …`, `An enabled Issue a periodic report …` |
| A file that cannot be read says so | `ReportFileButtons` | `a file that cannot be read says so` |
