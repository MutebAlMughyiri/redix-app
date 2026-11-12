import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../attachments/invoice_capture.dart';
import '../auth/session.dart';
import '../ui/busy.dart';
import '../ui/part_keys.dart';
import '../ui/messages.dart';
import '../words/words.dart';
import '../ui/act_once.dart';

Future<String> _save(InvoiceCapture capture, Uint8List bytes, String name, String mimeType) async {
  await capture.saveFile(bytes, name, mimeType);
  return 'reports.downloaded';
}

Future<String> _share(InvoiceCapture capture, Uint8List bytes, String name, String mimeType) async {
  await capture.shareFile(bytes, name, mimeType);
  return '';
}

Future<String> _print(InvoiceCapture capture, Uint8List bytes, String name, String mimeType) async {
  await capture.printPdf(bytes, name);
  return '';
}

/// What can be done with a report's file on the phone (FR-48).
enum FileHandling {
  /// Kept in the phone's Download folder, to be copied to a computer.
  save('reports.save', Icons.download_outlined, _save),

  /// Handed to the share sheet, for WhatsApp or email.
  share('reports.share', Icons.share_outlined, _share),

  /// Sent to the phone's printer, with a preview.
  print('reports.print', Icons.print_outlined, _print);

  const FileHandling(this.wordKey, this.icon, this._hand);

  /// The key of the word that names it.
  final String wordKey;

  /// Its icon.
  final IconData icon;

  final Future<String> Function(InvoiceCapture capture, Uint8List bytes, String name, String mimeType) _hand;

  /// Does it with [bytes] of [mimeType], named [name], through [capture]. Returns the word key of what to tell the person; empty when there is nothing to say.
  Future<String> handTo(InvoiceCapture capture, Uint8List bytes, String name, String mimeType) => _hand(capture, bytes, name, mimeType);
}

/// A kind of file a report comes as, and what can be done with it.
enum ReportFileKind {
  /// The PDF.
  pdf('pdf', 'application/pdf', 'reports.pdf', Icons.picture_as_pdf_outlined, [FileHandling.save, FileHandling.share]),

  /// The workbook.
  excel('xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'reports.excel', Icons.table_chart_outlined, [FileHandling.save, FileHandling.share]),

  /// The PDF, printed.
  print('pdf', 'application/pdf', 'reports.print', Icons.print_outlined, [FileHandling.print]);

  const ReportFileKind(this.extension, this.mimeType, this.wordKey, this.icon, this.handings);

  /// The end of the file's address and of its name.
  final String extension;

  /// What the file is.
  final String mimeType;

  /// The key of the word on its button.
  final String wordKey;

  /// Its button's icon.
  final IconData icon;

  /// What its button offers; asked once when there is more than one.
  final List<FileHandling> handings;
}

/// Gets a report's or a document's file from the API and saves, shares or prints it on the phone (UC-059, redix-api #102): the one way any screen does so.
class ReportFiles {
  /// The files read through [_session], handed to the phone through [_capture].
  ReportFiles(this._session, this._capture);

  final Session _session;
  final InvoiceCapture _capture;

  /// Gets the file at [address] of [kind], named [name], and does [handing] with it. Returns the word key of what to tell the person: why it could not, or that it was saved; empty when there is nothing to say.
  Future<String> hand(String address, String name, ReportFileKind kind, FileHandling handing) =>
      handFile(address.contains('?') ? address.replaceFirst('?', '/${kind.extension}?') : '$address/${kind.extension}', '$name.${kind.extension}', kind.mimeType, handing);

  /// Gets the file at [path], named [name] and holding [mimeType], and does [handing] with it; answers as [hand] does.
  Future<String> handFile(String path, String name, String mimeType, FileHandling handing) async {
    try {
      final response = await _session.read(path, file: true);
      if (response.statusCode != 200) {
        return 'reports.fileFailed';
      }
      return await handing.handTo(_capture, response.bodyBytes, name, mimeType);
    } on Exception catch (error) {
      debugPrint('$path not handed: $error');
      return 'reports.fileFailed';
    }
  }
}

/// Gets the report file of [kind] at [address], named [name], through [files], and hands it on: at once when the kind is handed one way, as printing is, otherwise after
/// asking whether to save or share it. The one way a button or a menu choice gets a report's file (Muteb, 12 Nov 2026: a contract's ⋮ holds its PDF and Excel).
Future<void> handReportFile(BuildContext context, ReportFiles files, String address, String name, ReportFileKind kind) async {
  Future<void> run(FileHandling handing) => showRefusalOf(context, whileBusy(context, files.hand(address, name, kind, handing)));
  if (kind.handings.length == 1) {
    return run(kind.handings.single);
  }
  final words = Words.of(context);
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final handing in kind.handings)
            ListTile(
              key: ReportFileButtons.handingKey(name, kind, handing),
              leading: Icon(handing.icon, key: ReportFileButtons.handingKey(name, kind, handing).icon),
              title: Text(words.text(handing.wordKey), key: ReportFileButtons.handingKey(name, kind, handing).title),
              onTap: () {
                Navigator.pop(sheet);
                run(handing);
              },
            ),
        ],
      ),
    ),
  );
}

/// The buttons that get a report's files: the PDF, the workbook, printing, and any [kinds] given.
class ReportFileButtons extends StatelessWidget {
  /// The buttons of the report at [address], named [name], through [files].
  const ReportFileButtons({super.key, required this.files, required this.address, required this.name, this.kinds = const [ReportFileKind.pdf, ReportFileKind.excel, ReportFileKind.print]});

  /// The button of [kind] for the report [name].
  static Key buttonKey(String name, ReportFileKind kind) => Key('reportFile.$name.${kind.name}');

  /// The choice of [handing] for that file, once its button asks.
  static Key handingKey(String name, ReportFileKind kind, FileHandling handing) => Key('reportFile.$name.${kind.name}.${handing.name}');

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
          ActOnce(builder: (once) => OutlinedButton.icon(
            key: buttonKey(name, kind),
            icon: Icon(kind.icon, key: buttonKey(name, kind).icon),
            label: Text(words.text(kind.wordKey), key: buttonKey(name, kind).label),
            onPressed: once(() => handReportFile(context, files, address, name, kind)),
          )),
      ],
    );
  }
}
