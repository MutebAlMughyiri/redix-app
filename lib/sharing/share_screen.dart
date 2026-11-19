// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../attachments/attachments.dart';
import '../attachments/invoice_capture.dart';
import '../attachments/picked_file.dart';
import '../entries/add_entry_screen.dart';
import '../entries/entry_card.dart';
import '../entries/entry_row.dart';
import '../entries/searched_entries.dart';
import '../expenses/invoice_qr.dart';
import '../expenses/qr_summary.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../projects/projects.dart';
import '../ui/act_once.dart';
import '../ui/api_list_body.dart';
import '../ui/app_color.dart';
import '../ui/bottom_button.dart';
import '../ui/busy.dart';
import '../ui/form_error.dart';
import '../ui/labelled_chips.dart';
import '../ui/messages.dart';
import '../ui/part_keys.dart';
import '../ui/screen_title.dart';
import '../ui/search_line.dart';
import '../ui/search_scope.dart';
import '../words/word_fill.dart';
import '../words/words.dart';
import 'attachable_entries.dart';

/// What opens when a picture or a PDF is shared to the app (UC-038, FR-49): put it on any entry the person may handle, an approved one too, beside the files it has (UC-039,
/// redix-app #115), found in القيود's own list and its search, the one the file's QR code matches pinned first (AC-49.2); or start a new entry with it (UC-046).
class ShareScreen extends StatefulWidget {
  /// The screen holding [file], read through [capture], in one of [projects]: their entries listed by [entriesOf], the QR code's match read and the file attached by
  /// [matchesOf], the file kept by [attachmentsOf].
  const ShareScreen({super.key, required this.file, required this.capture, required this.projects, required this.entriesOf, required this.matchesOf, required this.attachmentsOf, required this.onDone});

  /// The address of the screen.
  static const path = '/share';

  /// The way out.
  static const closeKey = Key('share.close');

  /// The line saying there is no project to enter in.
  static const noProjectKey = Key('share.noProject');

  /// The line saying the amounts differ.
  static const amountDiffersKey = Key('share.amountDiffers');

  /// The line saying the supplier differs.
  static const supplierDiffersKey = Key('share.supplierDiffers');

  /// The button attaching it.
  static const attachKey = Key('share.attach');

  /// The button starting a new entry with it.
  static const newEntryKey = Key('share.newEntry');

  /// The line saying why it was refused.
  static const messageKey = Key('share.message');

  /// The choice of the project [id].
  static Key projectKey(String id) => Key('share.project.$id');

  /// The line over the entry [id] the QR code matches, pinned over the list.
  static Key matchingKey(String id) => Key('share.matching.$id');

  /// The choice of the project the file goes to.
  static const projectChoiceKey = Key('share.projectChoice');

  /// The file shared, when it is a PDF.
  static const fileKey = Key('share.file');

  /// The spinner while the projects are read.
  static const loadingKey = Key('share.loading');

  /// The picture shared, when it is one.
  static const pictureKey = Key('share.picture');

  /// The shared file.
  final PickedFile file;

  /// The phone's barcode reader.
  final InvoiceCapture capture;

  /// The projects to choose from.
  final Projects projects;

  /// A project's entries, as القيود lists and searches them (redix-app #115 D3).
  final SearchedEntries Function(String projectId) entriesOf;

  /// What in a project the QR code matches, and the way to put the file on an entry.
  final AttachableEntries Function(String projectId) matchesOf;

  /// Where a project keeps files.
  final Attachments Function(String projectId) attachmentsOf;

  /// Called when the file was used, or the person left.
  final VoidCallback onDone;

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  var _qr = InvoiceQr.none();
  var _projectId = '';
  var _listedProjectId = '';
  var _chosen = '';
  var _message = '';

  @override
  void initState() {
    super.initState();
    widget.projects.addListener(_listOnceProjectsCome);
    widget.projects.loadOnOpen();
    if (!widget.file.isPdf) {
      unawaited(_readQr());
    }
  }

  @override
  void dispose() {
    widget.projects.removeListener(_listOnceProjectsCome);
    super.dispose();
  }

  Future<void> _readQr() async {
    final qr = InvoiceQr.parse(await widget.capture.qrTextOf(widget.file));
    if (!mounted) {
      return;
    }
    setState(() => _qr = qr);
    if (_listedProjectId.isNotEmpty) {
      await _findMatches(_listedProjectId);
    }
  }

  List<Project> get _open => widget.projects.all.where((project) => project.mayEnterExpenses && project.mayAttachFiles).toList();

  Project get _project => _open.firstWhere((project) => project.id == _projectId, orElse: () => _open.first);

  /// Lists the first project's entries once the projects are read.
  void _listOnceProjectsCome() {
    if (_listedProjectId.isEmpty && _open.isNotEmpty) {
      _list(_project);
    }
  }

  /// Lists [project]'s entries a file can go on, and reads what the QR code matches there (D3, D4).
  void _list(Project project) {
    _listedProjectId = project.id;
    widget.entriesOf(project.id).open();
    unawaited(_findMatches(project.id));
  }

  /// Reads what the QR code matches in the project [projectId] and chooses the first, as AC-49.2 asks.
  Future<void> _findMatches(String projectId) async {
    final matches = widget.matchesOf(projectId);
    await matches.findFor(_qr);
    if (mounted && matches.all.isNotEmpty && _listedProjectId == projectId) {
      setState(() => _chosen = matches.all.first.id);
    }
  }

  void _chooseProject(Project project) {
    setState(() {
      _projectId = project.id;
      _chosen = '';
    });
    _list(project);
  }

  Future<void> _attach(EntryRow entry) async {
    final words = Words.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final attachments = widget.attachmentsOf(_project.id);
    var refusal = await whileBusy(context, attachments.keep(widget.file));
    if (refusal.isEmpty) {
      refusal = await widget.matchesOf(_project.id).attach(entry.id, attachments.kept.id);
    }
    if (!mounted) {
      return;
    }
    if (refusal.isEmpty) {
      showMessage(messenger, words, 'share.attached', values: [entry.title]);
      widget.onDone();
      return;
    }
    setState(() => _message = refusal);
  }

  Future<void> _newEntry() async {
    final saved = await context.push<bool>(AddEntryScreen.sharedPathOf(_project.id), extra: _project);
    if (saved ?? false) {
      widget.onDone();
    }
  }

  Widget _card(EntryRow entry) => EntryCard(entry: entry, isChosen: entry.id == _chosen, onTap: () => setState(() => _chosen = entry.id));

  /// What differs between the QR code and the chosen [entry] (AC-49.3).
  List<Widget> _differences(EntryRow entry) {
    final words = Words.of(context);
    final style = TextStyle(color: AppColor.refusal.of(context));
    return [
      if (!_qr.isNone && _qr.total != entry.amount) Text(words.shareAmountDiffers.fill([formatMoney(_qr.total), formatMoney(entry.amount)]), key: ShareScreen.amountDiffersKey, style: style),
      if (!_qr.isNone && _qr.vatNumber != entry.supplierVatNumber) Text(words.shareSupplierDiffers, key: ShareScreen.supplierDiffersKey, style: style),
    ];
  }

  /// The entries the QR code matches, pinned over the list, each saying so (D4).
  List<Widget> _pinned(List<EntryRow> matches) {
    final words = Words.of(context);
    return [
      for (final entry in matches) ...[
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 16, end: 16, top: 8),
          child: Text(words.shareMatches, key: ShareScreen.matchingKey(entry.id), style: TextStyle(color: AppColor.brand.of(context))),
        ),
        _card(entry),
      ],
    ];
  }

  Widget _body() {
    final words = Words.of(context);
    final project = _project;
    final entries = widget.entriesOf(project.id);
    final matches = widget.matchesOf(project.id);
    return ListenableBuilder(
      listenable: Listenable.merge([entries, matches]),
      builder: (context, _) {
        final matched = {for (final entry in matches.all) entry.id};
        final chosen = [...matches.all, ...entries.all].where((entry) => entry.id == _chosen).take(1);
        final header = [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                if (_message.isNotEmpty) FormError(text: words.text(_message), textKey: ShareScreen.messageKey),
                if (widget.file.isPdf) ListTile(key: ShareScreen.fileKey, leading: Icon(Icons.picture_as_pdf_outlined, key: ShareScreen.fileKey.icon), title: Text(widget.file.name, key: ShareScreen.fileKey.title)) else SizedBox(height: MediaQuery.sizeOf(context).height * 0.25, child: Image.memory(widget.file.bytes, key: ShareScreen.pictureKey, fit: BoxFit.contain)),
                if (!_qr.isNone) QrSummary(qr: _qr, offerSupplier: false, onAddSupplier: () {}),
                if (_open.length > 1)
                  LabelledChips(
                    key: ShareScreen.projectChoiceKey,
                    label: words.shareProject,
                    choices: _open,
                    keyOf: (choice) => ShareScreen.projectKey(choice.id),
                    nameOf: (choice) => choice.name,
                    isChosen: (choice) => choice.id == project.id,
                    onChosen: _chooseProject,
                  ),
              ],
            ),
          ),
          ..._pinned(matches.all),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The search line is pinned under the header, so it stays once the picture scrolls away, and the body is the list alone, which any height
            // only shows fewer rows of: with the keyboard up, the picture and the QR summary above and the chosen entry below left a search line in
            // the body 43 px on a Pixel 6 (findings row 268; Muteb, 19 Nov 2026: "Pin the search").
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (context, _) => [
                  SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: header)),
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                    sliver: PinnedHeaderSliver(child: Material(child: SearchLine(hint: words.shareSearchEntries, waits: true))),
                  ),
                ],
                body: Builder(
                  builder: (context) => ApiListBody<EntryRow>(
                    list: entries,
                    emptyText: words.entriesEmpty,
                    keeps: (entry) => !matched.contains(entry.id),
                    itemBuilder: _card,
                    listOf: (items) => CustomScrollView(
                      physics: ApiListBody.physics,
                      slivers: [
                        SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
                        SliverPadding(padding: ApiListBody.padding, sliver: SliverList.list(children: items)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            for (final entry in chosen)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    ..._differences(entry),
                    ActOnce(builder: (once) => FilledButton(key: ShareScreen.attachKey, onPressed: once(() => _attach(entry)), child: Text(words.shareAttach, key: ShareScreen.attachKey.label))),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return SearchScope(
      startsOpen: true,
      onTyped: (typed) {
        final entries = widget.entriesOf(_project.id);
        entries.filter.text = typed;
        entries.search();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(key: ShareScreen.closeKey, icon: Icon(Icons.close, key: ShareScreen.closeKey.icon), onPressed: widget.onDone),
          title: Text(words.shareTitle, key: ScreenTitle.titleKey),
          actions: const [SearchIcons()],
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: widget.projects,
          builder: (context, _) => _open.isEmpty ? const SizedBox.shrink() : BottomButton(buttonKey: ShareScreen.newEntryKey, label: words.shareNewExpense, onPressed: _newEntry),
        ),
        body: ListenableBuilder(
          listenable: widget.projects,
          builder: (context, _) {
            if (_open.isNotEmpty) {
              return _body();
            }
            return widget.projects.isLoading ? const Center(child: CircularProgressIndicator(key: ShareScreen.loadingKey)) : Center(child: Text(widget.projects.message.isEmpty ? words.shareNoProject : words.text(widget.projects.message), key: ShareScreen.noProjectKey));
          },
        ),
      ),
    );
  }
}
