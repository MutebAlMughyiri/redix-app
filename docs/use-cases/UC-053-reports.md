[Documentation](../README.md) › [Use cases](../README.md) › UC-053, UC-056, UC-059

# UC-053, UC-059: The periodic report, and printing or sharing a report

**Purpose:** issue the numbered periodic report, read any issued one, and print or share a report's file.

**Who uses it:** whoever moves money issues. Everyone in the project reads a report, with only their own partner line. Only whoever sees every partner's capital gets the files (BR-31).

`ReportFiles` is the one way any report screen gets a file from the API and hands it to the phone. `InvoiceCapture`, the app's one owner of the phone's hardware, now also holds the printer (AirPrint on iPhone, the print service on Android and Huawei, with a preview) and the share sheet.

**Not proven on a phone:** no file has been printed or shared on a real device yet; the tests stand in at `InvoiceCapture`. Findings row 119 says what is left.

| Rule | Code | Test |
| --- | --- | --- |
| UC-053: issuing asks first, saying its number, and the report then shows | `ReportsScreen._askToIssue` | `UC-053: issuing asks first, saying its number, and the report then shows` |
| UC-053: a report opens as issued, with the difference from the last | `PeriodicReportScreen` | `UC-053: a report opens as it was issued, with the difference from the last` |
| AC-48.1: print opens the printer with the PDF; share hands the workbook on | `ReportFiles.hand`, `InvoiceCapture.printPdf`, `shareFile` | `AC-48.1: print opens the phone's printer with the PDF, and share hands the workbook on` |
| BR-31: someone who sees only their own capital reads the report and gets no files | `PeriodicReportScreen` | `BR-31: someone who sees only their own capital reads the report and gets no files` |
| UC-057, UC-058: the VAT statement hands on its files for the period shown | `VatStatementScreen` | `UC-057, UC-058: the VAT statement hands on its workbook, its PDF and its invoice images for the period shown` |
| AC-33.1: an item report hands on its PDF | `ItemReportScreen` | `AC-33.1: an item report hands on its PDF` |
| A file that cannot be read says so | `ReportFileButtons` | `a file that cannot be read says so` |
