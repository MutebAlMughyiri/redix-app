import 'package:flutter/material.dart';

import '../attachments/invoice_capture.dart';
import '../attachments/picked_file.dart';
import '../projects/project.dart';
import '../words/words.dart';
import 'invoice_section.dart';

/// A new purchase expense (UC-021): the camera opens first, and the invoice's picture stays on the screen.
class AddExpenseScreen extends StatefulWidget {
  /// The screen entering an expense in [project], reaching the phone through [capture].
  const AddExpenseScreen({super.key, required this.project, required this.capture});

  /// The project the expense belongs to.
  final Project project;

  /// The phone's camera and files.
  final InvoiceCapture capture;

  /// The screen's route.
  static const path = '/projects/:projectId/expenses/new';

  /// The route of a new expense in the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/expenses/new';

  /// The screen's title.
  static const titleKey = Key('addExpense.title');

  /// The button that opens the camera.
  static const cameraKey = Key('addExpense.camera');

  /// The button that opens the phone's files.
  static const filesKey = Key('addExpense.files');

  /// The picture of the invoice.
  static const invoicePictureKey = Key('addExpense.invoicePicture');

  /// The line under the place of the invoice: what it is for until there is one, and the name of a PDF.
  static const invoiceNameKey = Key('addExpense.invoiceName');

  /// The line that says why the last try gave no file.
  static const invoiceMessageKey = Key('addExpense.invoiceMessage');

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  var _invoice = PickedFile.none();
  var _invoiceMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _takeFrom(widget.capture.fromCamera));
  }

  Future<void> _takeFrom(Future<PickedFile> Function() source) async {
    final file = await source();
    if (!mounted) {
      return;
    }
    setState(() {
      _invoiceMessage = file.failure;
      _invoice = file.isNone ? _invoice : file;
    });
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${words.expensesNew} · ${widget.project.name}', key: AddExpenseScreen.titleKey)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InvoiceSection(file: _invoice, message: _invoiceMessage, onCamera: () => _takeFrom(widget.capture.fromCamera), onFiles: () => _takeFrom(widget.capture.fromFiles)),
        ],
      ),
    );
  }
}
