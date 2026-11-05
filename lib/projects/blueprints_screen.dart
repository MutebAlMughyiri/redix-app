import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../attachments/attachment_screen.dart';
import '../attachments/attachments.dart';
import '../attachments/invoice_capture.dart';
import '../attachments/picked_file.dart';
import '../format/date_format.dart';
import '../ui/api_list_body.dart';
import '../ui/change_dialog.dart';
import '../ui/confirm_dialog.dart';
import '../ui/entry_field.dart';
import '../ui/labelled_chips.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'blueprints.dart';
import 'project.dart';

/// A project's engineering blueprints (UC-064): everyone who reads the project opens them; whoever manages it keeps and removes them.
class BlueprintsScreen extends StatefulWidget {
  /// The blueprints of [project] through [blueprints], their files kept through [attachments] from what [capture] picks.
  const BlueprintsScreen({super.key, required this.project, required this.blueprints, required this.attachments, required this.capture});

  /// The screen's route.
  static const path = '/projects/:projectId/blueprints';

  /// The route of the project [projectId]'s blueprints.
  static String pathOf(String projectId) => '/projects/$projectId/blueprints';

  /// The button that adds a blueprint.
  static const addKey = Key('blueprints.add');

  /// The title field, in the dialog that adds one.
  static const titleKey = Key('blueprints.titleField');

  /// The button that picks the file, in that dialog.
  static const fileKey = Key('blueprints.file');

  /// The blueprint [id].
  static Key blueprintKey(String id) => Key('blueprints.blueprint.$id');

  /// The button that removes the blueprint [id].
  static Key removeKey(String id) => Key('blueprints.remove.$id');

  /// The choice of the unit [id] in that dialog; empty for the whole project.
  static Key unitKey(String id) => Key('blueprints.unit.$id');

  /// The project.
  final Project project;

  /// Its blueprints.
  final Blueprints blueprints;

  /// The way to keep a file.
  final Attachments attachments;

  /// The phone's files.
  final InvoiceCapture capture;

  @override
  State<BlueprintsScreen> createState() => _BlueprintsScreenState();
}

class _BlueprintsScreenState extends State<BlueprintsScreen> {
  @override
  void initState() {
    super.initState();
    widget.blueprints.loadOnOpen();
  }

  void _askToRemove(Blueprint blueprint) {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: words.blueprintsRemoveQuestion,
        subject: blueprint.title,
        explanation: words.blueprintsRemoveExplain,
        confirmLabel: words.blueprintsRemove,
        onConfirm: () async {
          final refusal = await widget.blueprints.remove(blueprint);
          messenger.showSnackBar(SnackBar(content: Text(words.text(refusal.isEmpty ? 'blueprints.removed' : refusal))));
        },
      ),
    );
  }

  Widget _tile(Blueprint blueprint, bool isFirstOfItsPlace, Words words) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isFirstOfItsPlace)
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(blueprint.unitName.isEmpty ? words.blueprintsProject : blueprint.unitName, style: theme.textTheme.titleSmall),
          ),
        Card.outlined(
          child: ListTile(
            key: BlueprintsScreen.blueprintKey(blueprint.id),
            leading: Icon(blueprint.contentType == 'application/pdf' ? Icons.picture_as_pdf_outlined : Icons.image_outlined),
            title: Text(blueprint.title),
            subtitle: Text('${blueprint.fileName} · ${formatDate(blueprint.uploadedAt)}'),
            trailing: widget.project.mayManageProject
                ? IconButton(key: BlueprintsScreen.removeKey(blueprint.id), tooltip: words.blueprintsRemove, icon: const Icon(Icons.delete_outline), onPressed: () => _askToRemove(blueprint))
                : null,
            onTap: () => context.push(AttachmentScreen.pathOf(widget.project.id, blueprint.attachmentId), extra: blueprint.contentType),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.blueprintsTitle, subject: widget.project.name)),
      floatingActionButton: widget.project.mayManageProject
          ? FloatingActionButton.extended(
              key: BlueprintsScreen.addKey,
              icon: const Icon(Icons.add),
              label: Text(words.blueprintsAdd),
              onPressed: () => showDialog<void>(context: context, builder: (_) => _BlueprintDialog(project: widget.project, blueprints: widget.blueprints, attachments: widget.attachments, capture: widget.capture)),
            )
          : null,
      body: ApiListBody<Blueprint>(
        list: widget.blueprints,
        emptyText: words.blueprintsNone,
        itemBuilder: (blueprint) {
          final all = widget.blueprints.all;
          final index = all.indexOf(blueprint);
          return _tile(blueprint, index == 0 || all[index - 1].unitName != blueprint.unitName, words);
        },
      ),
    );
  }
}

/// The dialog that keeps a new blueprint: what it shows, what it is for, and its file.
class _BlueprintDialog extends StatefulWidget {
  const _BlueprintDialog({required this.project, required this.blueprints, required this.attachments, required this.capture});

  final Project project;

  final Blueprints blueprints;

  final Attachments attachments;

  final InvoiceCapture capture;

  @override
  State<_BlueprintDialog> createState() => _BlueprintDialogState();
}

class _BlueprintDialogState extends State<_BlueprintDialog> {
  final _title = TextEditingController();
  var _unitId = '';
  var _file = PickedFile.none();
  var _fileMessage = '';

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final file = await widget.capture.fromFiles();
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
      return 'blueprints.unknownAttachment';
    }
    final refusal = await widget.attachments.keep(_file);
    if (refusal.isNotEmpty) {
      return refusal;
    }
    final kept = await widget.blueprints.add(widget.attachments.kept.id, _unitId, _title.text);
    if (kept.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(words.blueprintsSaved)));
    }
    return kept;
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return ChangeDialog(
      title: words.blueprintsAdd,
      saveLabel: words.blueprintsSave,
      onSave: _save,
      children: [
        entryField(key: BlueprintsScreen.titleKey, controller: _title, label: words.blueprintsTitleField, onChanged: (_) {}),
        LabelledChips<(String, String)>(
          label: words.blueprintsFor,
          choices: [('', words.blueprintsProject), for (final unit in widget.project.units) (unit.id, unit.name)],
          keyOf: (choice) => BlueprintsScreen.unitKey(choice.$1),
          nameOf: (choice) => choice.$2,
          isChosen: (choice) => choice.$1 == _unitId,
          onChosen: (choice) => setState(() => _unitId = choice.$1),
        ),
        OutlinedButton.icon(key: BlueprintsScreen.fileKey, icon: const Icon(Icons.attach_file), label: Text(_file.isNone ? words.blueprintsFile : _file.name), onPressed: _pickFile),
        Text(_fileMessage.isEmpty ? words.blueprintsFileHint : words.text(_fileMessage), style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
