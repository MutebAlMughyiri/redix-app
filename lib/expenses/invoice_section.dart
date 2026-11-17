import 'package:flutter/material.dart';

import '../attachments/picked_file.dart';
import '../projects/project.dart';
import '../words/words.dart';
import '../entries/add_entry_screen.dart';
import '../ui/part_keys.dart';
import '../ui/app_color.dart';
import '../ui/refusal_text.dart';

/// The file of a new expense, its invoice or its receipt: its picture, and the ways to take it again or pick it from the phone's files. Shown only where [showsIn] says.
class InvoiceSection extends StatelessWidget {
  /// The part showing [file], or [emptyLabel] until there is one, with [message] saying why the last try gave none, calling [onCamera] and [onFiles].
  const InvoiceSection({super.key, required this.file, required this.emptyLabel, required this.message, required this.onCamera, required this.onFiles, this.isReading = false});

  /// The invoice chosen; none yet when empty.
  final PickedFile file;

  /// What the file is for, said until there is one.
  final String emptyLabel;

  /// The word key of why the last try gave no file; empty otherwise.
  final String message;

  /// Opens the camera.
  final VoidCallback onCamera;

  /// Opens the phone's files.
  final VoidCallback onFiles;

  /// True to show the file alone, with no way to take another, as an entry read only shows what it was filled with (redix-app #90); nothing when it has none.
  final bool isReading;

  Widget _preview(BuildContext context, Words words) {
    final theme = Theme.of(context);
    if (!file.isNone && !file.isPdf) {
      return Image.memory(file.bytes, key: AddEntryScreen.invoicePictureKey, fit: BoxFit.cover);
    }
    return ColoredBox(
      color: AppColor.mutedSurface.of(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(file.isNone ? Icons.receipt_long_outlined : Icons.picture_as_pdf_outlined, key: AddEntryScreen.invoiceNameKey.icon),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(file.isNone ? emptyLabel : file.name, key: AddEntryScreen.invoiceNameKey, style: theme.textTheme.bodySmall, maxLines: 3, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  /// Whether [project]'s form shows the file at all: an entry read only shows the file it has, a new one shows it to whoever may attach files.
  static bool showsIn(Project project, PickedFile file, {required bool isReading}) => isReading ? !file.isNone : project.mayAttachFiles;

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: ClipRRect(borderRadius: BorderRadius.circular(12), child: _preview(context, words)),
              ),
            ),
            const SizedBox(width: 12),
            if (isReading)
              const Spacer(flex: 2)
            else
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      key: AddEntryScreen.cameraKey,
                      icon: Icon(Icons.document_scanner_outlined, key: AddEntryScreen.cameraKey.icon),
                      label: Text(file.isNone ? words.attachmentsTakePhoto : words.attachmentsRetake, key: AddEntryScreen.cameraKey.label),
                      onPressed: onCamera,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(key: AddEntryScreen.filesKey, icon: Icon(Icons.folder_open_outlined, key: AddEntryScreen.filesKey.icon), label: Text(words.attachmentsPickFile, key: AddEntryScreen.filesKey.label), onPressed: onFiles),
                  ],
                ),
              ),
          ],
        ),
        if (message.isNotEmpty) ...[
          const SizedBox(height: 8),
          refusalText(context, words.text(message), AddEntryScreen.invoiceMessageKey),
        ],
      ],
    );
  }
}
