import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../attachments/attachment_screen.dart';
import '../attachments/invoice_capture.dart';
import '../attachments/picked_file.dart';
import '../format/date_format.dart';
import '../projects/project.dart';
import '../ui/api_list_body.dart';
import '../ui/change_dialog.dart';
import '../ui/confirm_dialog.dart';
import '../ui/entry_field.dart';
import '../ui/screen_title.dart';
import '../ui/refresh_button.dart';
import '../words/words.dart';
import 'documents.dart';

/// A project's documents (UC-064): each group under its name, those in none first. Everyone opens them; whoever manages the project keeps and removes them.
class DocumentsScreen extends StatefulWidget {
  /// The documents of [project], kept through [documents], with files chosen through [capture].
  const DocumentsScreen({super.key, required this.project, required this.documents, required this.capture});

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

  /// The button that removes the document [id].
  static Key removeKey(String id) => Key('documents.remove.$id');

  /// The project.
  final Project project;

  /// Its documents.
  final Documents documents;

  /// The phone's files.
  final InvoiceCapture capture;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  @override
  void initState() {
    super.initState();
    widget.documents.loadOnOpen();
  }

  void _askToRemove(Document document) {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: words.documentsRemoveQuestion,
        subject: document.name,
        explanation: words.documentsRemoveExplain,
        confirmLabel: words.documentsRemove,
        onConfirm: () async {
          final refusal = await widget.documents.remove(document);
          messenger.showSnackBar(SnackBar(content: Text(words.text(refusal.isEmpty ? 'documents.removed' : refusal))));
        },
      ),
    );
  }

  IconData _iconOf(String contentType) =>
      contentType == 'application/pdf' ? Icons.picture_as_pdf_outlined : (contentType.startsWith('image/') ? Icons.image_outlined : Icons.description_outlined);

  Widget _tile(Document document, bool startsItsGroup, Words words) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (startsItsGroup && document.group.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(document.group, key: DocumentsScreen.groupHeadingKey(document.group), style: Theme.of(context).textTheme.titleSmall),
        ),
      Card.outlined(
        child: ListTile(
          key: DocumentsScreen.documentKey(document.id),
          leading: Icon(_iconOf(document.contentType)),
          title: Text(document.name),
          subtitle: Text('${document.fileName} · ${formatDate(document.uploadedAt)}'),
          trailing: widget.project.mayManageProject
              ? IconButton(key: DocumentsScreen.removeKey(document.id), tooltip: words.documentsRemove, icon: const Icon(Icons.delete_outline), onPressed: () => _askToRemove(document))
              : null,
          onTap: () => context.push(AttachmentScreen.pathOf(widget.project.id, document.attachmentId, fileName: document.fileName), extra: document.contentType),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.documentsTitle, subject: widget.project.name), actions: [RefreshButton(onRefresh: widget.documents.load)]),
      floatingActionButton: widget.project.mayManageProject
          ? FloatingActionButton.extended(
              key: DocumentsScreen.addKey,
              icon: const Icon(Icons.add),
              label: Text(words.documentsAdd),
              onPressed: () => showDialog<void>(context: context, builder: (_) => _DocumentDialog(documents: widget.documents, capture: widget.capture)),
            )
          : null,
      body: ApiListBody<Document>(
        list: widget.documents,
        emptyText: words.documentsNone,
        itemBuilder: (document) {
          final all = widget.documents.all;
          final index = all.indexOf(document);
          return _tile(document, index == 0 || all[index - 1].group != document.group, words);
        },
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
    final file = await widget.capture.fromAnyFile();
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
    final refusal = await widget.documents.add(_file, _name.text, _group);
    if (refusal.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(words.documentsSaved)));
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
            decoration: InputDecoration(labelText: words.documentsGroup, helperText: words.documentsGroupHint, helperMaxLines: 2, border: const OutlineInputBorder()),
            onChanged: (typed) => _group = typed,
          ),
        ),
        OutlinedButton.icon(key: DocumentsScreen.fileKey, icon: const Icon(Icons.attach_file), label: Text(_file.isNone ? words.documentsFile : _file.name), onPressed: _pickFile),
        Text(_fileMessage.isEmpty ? words.documentsFileHint : words.text(_fileMessage), style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
