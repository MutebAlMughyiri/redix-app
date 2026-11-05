import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../attachments/invoice_capture.dart';
import '../auth/session.dart';
import '../words/words.dart';

/// A kind of file a report comes as.
enum ReportFileKind {
  /// The PDF, shared.
  pdf('pdf', 'application/pdf', 'reports.pdf', Icons.picture_as_pdf_outlined),

  /// The workbook, shared.
  excel('xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'reports.excel', Icons.table_chart_outlined),

  /// The PDF, printed.
  print('pdf', 'application/pdf', 'reports.print', Icons.print_outlined),

  /// The invoice images, shared as one ZIP.
  zip('zip', 'application/zip', 'reports.invoiceImages', Icons.folder_zip_outlined);

  const ReportFileKind(this.extension, this.mimeType, this.wordKey, this.icon);

  /// The end of the file's address and of its name.
  final String extension;

  /// What the file is.
  final String mimeType;

  /// The key of the word on its button.
  final String wordKey;

  /// Its button's icon.
  final IconData icon;
}

/// Gets a report's file from the API and hands it to the phone's printer or share sheet (UC-059): the one way any report screen does so.
class ReportFiles {
  /// The files read through [_session], handed to the phone through [_capture].
  ReportFiles(this._session, this._capture);

  final Session _session;
  final InvoiceCapture _capture;

  /// Gets the file at [address] of [kind] and hands it on, named [name]. Returns an empty string once handed, otherwise the word key of why not.
  Future<String> hand(String address, String name, ReportFileKind kind) async {
    try {
      final path = address.contains('?') ? address.replaceFirst('?', '/${kind.extension}?') : '$address/${kind.extension}';
      final response = await _session.read(path);
      if (response.statusCode != 200) {
        return 'reports.fileFailed';
      }
      final Uint8List bytes = response.bodyBytes;
      final fileName = '$name.${kind.extension}';
      await (kind == ReportFileKind.print ? _capture.printPdf(bytes, fileName) : _capture.shareFile(bytes, fileName, kind.mimeType));
      return '';
    } on Exception catch (error) {
      debugPrint('$address not handed: $error');
      return 'reports.fileFailed';
    }
  }
}

/// The buttons that get a report's files: the PDF, the workbook, printing, and any [kinds] given.
class ReportFileButtons extends StatelessWidget {
  /// The buttons of the report at [address], named [name], through [files].
  const ReportFileButtons({super.key, required this.files, required this.address, required this.name, this.kinds = const [ReportFileKind.pdf, ReportFileKind.excel, ReportFileKind.print]});

  /// The button of [kind] for the report [name].
  static Key buttonKey(String name, ReportFileKind kind) => Key('reportFile.$name.${kind.name}');

  /// The way to the files.
  final ReportFiles files;

  /// The report's address, before the file's own end.
  final String address;

  /// The files' name.
  final String name;

  /// Which buttons show.
  final List<ReportFileKind> kinds;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final kind in kinds)
          OutlinedButton.icon(
            key: buttonKey(name, kind),
            icon: Icon(kind.icon),
            label: Text(words.text(kind.wordKey)),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final refusal = await files.hand(address, name, kind);
              if (refusal.isNotEmpty) {
                messenger.showSnackBar(SnackBar(content: Text(words.text(refusal))));
              }
            },
          ),
      ],
    );
  }
}
