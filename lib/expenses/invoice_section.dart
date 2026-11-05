import 'package:flutter/material.dart';

import '../attachments/picked_file.dart';
import '../words/words.dart';
import 'add_expense_screen.dart';

/// The invoice of a new expense: its picture, and the ways to take it again or pick it from the phone's files.
class InvoiceSection extends StatelessWidget {
  /// The section showing [file], with [message] saying why the last try gave none, calling [onCamera] and [onFiles].
  const InvoiceSection({super.key, required this.file, required this.message, required this.onCamera, required this.onFiles});

  /// The invoice chosen; none yet when empty.
  final PickedFile file;

  /// The word key of why the last try gave no file; empty otherwise.
  final String message;

  /// Opens the camera.
  final VoidCallback onCamera;

  /// Opens the phone's files.
  final VoidCallback onFiles;

  Widget _preview(BuildContext context, Words words) {
    final theme = Theme.of(context);
    if (!file.isNone && !file.isPdf) {
      return Image.memory(file.bytes, key: AddExpenseScreen.invoicePictureKey, fit: BoxFit.cover);
    }
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(file.isNone ? Icons.receipt_long_outlined : Icons.picture_as_pdf_outlined),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(file.isNone ? words.attachmentsInvoicePhoto : file.name, key: AddExpenseScreen.invoiceNameKey, style: theme.textTheme.bodySmall, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

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
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    key: AddExpenseScreen.cameraKey,
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: Text(file.isNone ? words.attachmentsTakePhoto : words.attachmentsRetake),
                    onPressed: onCamera,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(key: AddExpenseScreen.filesKey, icon: const Icon(Icons.folder_open_outlined), label: Text(words.attachmentsPickFile), onPressed: onFiles),
                ],
              ),
            ),
          ],
        ),
        if (message.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(words.text(message), key: AddExpenseScreen.invoiceMessageKey, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ],
    );
  }
}
