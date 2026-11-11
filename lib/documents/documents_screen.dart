import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../attachments/attachment_screen.dart';
import '../attachments/file_kind.dart';
import '../attachments/invoice_capture.dart';
import '../attachments/picked_file.dart';
import '../format/date_format.dart';
import '../projects/project.dart';
import '../reports/report_files.dart';
import '../ui/busy.dart';
import '../ui/api_list_body.dart';
import '../ui/change_dialog.dart';
import '../ui/entry_field.dart';
import '../ui/part_keys.dart';
import '../ui/screen_title.dart';
import '../ui/swipe_to_remove.dart';
import '../ui/refusal_snack_bar.dart';
import '../words/words.dart';
import 'documents.dart';
import '../ui/act_once.dart';
import '../ui/list_search.dart';
import '../words/word_fill.dart';
import '../format/parts_line.dart';

/// A project's documents (UC-064): each group under its name, those in none first. Everyone opens them; whoever manages the project keeps and removes them.
class DocumentsScreen extends StatefulWidget {
  /// The documents of [project], kept through [documents], with files chosen through [capture].
  const DocumentsScreen({super.key, required this.project, required this.documents, required this.capture, required this.files});

  /// The address of the screen.
  static const path = '/projects/:projectId/documents';

  /// The address of the documents of the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/documents';

  /// The button that adds a document.
  static const addKey = Key('documents.add');

  /// The dialog's name field.
  static const nameKey = Key('documents.name');

  /// The dialog's group field.
  static const groupKey = Key('documents.group');

  /// The dialog's file button.
  static const fileKey = Key('documents.file');

  /// The document [id].
  static Key documentKey(String id) => Key('documents.document.$id');

  /// The heading of the group [group].
  static Key groupHeadingKey(String group) => Key('documents.groupHeading.$group');

  /// The button that keeps the file of the document [id] in the phone's Downloads (redix-api #102).
  static Key downloadKey(String id) => Key('documents.download.$id');


  /// What the file field asks, or why the file was refused.
  static const fileHintKey = Key('documents.fileHint');

  /// The project.
  final Project project;

  /// Its documents.
  final Documents documents;

  /// The phone's files.
  final InvoiceCapture capture;

  /// The way a document's file reaches the phone's Downloads.
  final ReportFiles files;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  @override
  void initState() {
    super.initState();
    widget.documents.loadOnOpen();
  }

  Future<void> _download(Document document) async {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final said = await whileBusy(context, widget.files.handFile(AttachmentScreen.pathOf(widget.project.id, document.attachmentId), document.fileName, document.contentType, FileHandling.save));
    showMessage(messenger, words, said);
  }

  Widget _heading(String group) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 4),
    child: Text(group, key: DocumentsScreen.groupHeadingKey(group), style: Theme.of(context).textTheme.titleSmall),
  );

  Widget _tile(Document document, Words words) => SwipeToRemove(
        rowKey: DocumentsScreen.documentKey(document.id),
        mayRemove: widget.project.mayManageProject,
        onRemove: () => widget.documents.remove(document),
        child: ListTile(
          key: DocumentsScreen.documentKey(document.id),
          leading: Icon(FileKind.of(document.contentType).icon, key: DocumentsScreen.documentKey(document.id).icon),
          title: Text(document.name, key: DocumentsScreen.documentKey(document.id).title),
          subtitle: Text('${document.fileName} · ${formatDate(document.uploadedAt)}', key: DocumentsScreen.documentKey(document.id).subtitle),
          trailing: ActOnce(builder: (once) => IconButton(
            key: DocumentsScreen.downloadKey(document.id),
            tooltip: words.documentsDownload,
            icon: Icon(Icons.download_outlined, key: DocumentsScreen.downloadKey(document.id).icon),
            onPressed: once(() => _download(document)),
          )),
          onTap: () => context.push(AttachmentScreen.pathOf(widget.project.id, document.attachmentId, fileName: document.fileName), extra: document.contentType),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(
        title: ScreenTitle(words.documentsTitle, subject: widget.project.name),
        actions: [
          IconButton(
            key: DocumentsScreen.addKey,
            tooltip: words.documentsAdd,
            icon: Icon(Icons.add, key: DocumentsScreen.addKey.icon),
            onPressed: widget.project.mayManageProject ? () => showDialog<void>(context: context, builder: (_) => _DocumentDialog(documents: widget.documents, capture: widget.capture)) : null,
          ),
        ],
      ),
      body: ApiListBody<Document>(
        list: widget.documents,
        emptyText: words.documentsNone,
        search: ListSearch(hint: words.commonSearchIn.fill([words.documentsTitle]), textOf: (document) => partsLine([document.name, document.group, document.fileName])),
        listOf: (tiles) => ListView(
          padding: ApiListBody.padding,
          physics: ApiListBody.physics,
          children: tiles,
        ),
        groupOf: (document) => document.group,
        headingOf: _heading,
        itemBuilder: (document) => _tile(document, words),
      ),
    );
  }
}

class _DocumentDialog extends StatefulWidget {
  const _DocumentDialog({required this.documents, required this.capture});

  final Documents documents;
  final InvoiceCapture capture;

  @override
  State<_DocumentDialog> createState() => _DocumentDialogState();
}

class _DocumentDialogState extends State<_DocumentDialog> {
  final _name = TextEditingController();
  var _group = '';
  var _file = PickedFile.none();
  var _fileMessage = '';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final file = await whileBusy(context, widget.capture.fromAnyFile());
    if (mounted) {
      setState(() {
        _fileMessage = file.failure;
        _file = file.isNone ? _file : file;
      });
    }
  }

  Future<String> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final words = Words.of(context);
    if (_file.isNone) {
      return 'documents.fileRequired';
    }
    final refusal = await whileBusy(context, widget.documents.add(_file, _name.text, _group));
    if (refusal.isEmpty) {
      showMessage(messenger, words, 'documents.saved');
    }
    return refusal;
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ChangeDialog(
      title: words.documentsAdd,
      saveLabel: words.documentsSave,
      onSave: _save,
      children: [
        entryField(key: DocumentsScreen.nameKey, controller: _name, label: words.documentsName, onChanged: (_) {}),
        Autocomplete<String>(
          optionsBuilder: (typed) => widget.documents.groups.where((group) => group.contains(typed.text.trim())),
          onSelected: (group) => _group = group,
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) => TextField(
            key: DocumentsScreen.groupKey,
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(labelText: words.documentsGroup, helperText: words.documentsGroupHint, helperMaxLines: 2),
            onChanged: (typed) => _group = typed,
          ),
        ),
        OutlinedButton.icon(key: DocumentsScreen.fileKey, icon: Icon(Icons.attach_file, key: DocumentsScreen.fileKey.icon), label: Text(_file.isNone ? words.documentsFile : _file.name, key: DocumentsScreen.fileKey.label), onPressed: _pickFile),
        Text(_fileMessage.isEmpty ? words.documentsFileHint : words.text(_fileMessage), key: DocumentsScreen.fileHintKey, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
