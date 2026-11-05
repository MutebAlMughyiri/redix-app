import 'package:flutter/material.dart';

import '../auth/permission.dart';
import '../format/date_format.dart';
import '../format/number_format.dart';
import '../projects/project.dart';
import '../revenue/quarter_picker.dart';
import '../ui/api_object_body.dart';
import '../ui/picker_field.dart';
import '../ui/refusal_snack_bar.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'report_files.dart';
import 'vat_statement.dart';

/// How a period is chosen.
enum _Mode { quarter, halfYear, custom }

/// The VAT statement for a quarter, a half-year or a custom period (UC-056), with what it left out.
class VatStatementScreen extends StatefulWidget {
  /// The statement of [project], read through [statement].
  const VatStatementScreen({super.key, required this.project, required this.statement, required this.files});

  /// The way to its files.
  final ReportFiles files;

  /// The address of the screen.
  static const path = '/projects/:projectId/reports/vat';

  /// The address of the screen for the project [projectId].
  static String pathOf(String projectId) => '/projects/$projectId/reports/vat';

  /// The choice of a half-year.
  static const halfYearKey = Key('vat.halfYear');

  /// The choice of a custom period.
  static const customKey = Key('vat.custom');

  /// The first day of a custom period.
  static const fromKey = Key('vat.from');

  /// The last day of a custom period.
  static const toKey = Key('vat.to');

  /// The choice of the second half.
  static const secondHalfKey = Key('vat.h2');

  /// The period of the quarter starting [start].
  static Key periodKey(String start) => Key('vat.period.$start');

  /// The net due of the quarter starting [start].
  static Key netKey(String start) => Key('vat.net.$start');

  /// The purchase row of the entry [id].
  static Key rowKey(String id) => Key('vat.row.$id');

  /// The exception of the entry [id].
  static Key exceptionKey(String id) => Key('vat.exception.$id');

  /// The button declaring an invoice in the next quarter.
  static const declareLaterKey = Key('vat.declareLater');

  /// The project.
  final Project project;

  /// The statement.
  final VatStatement statement;

  @override
  State<VatStatementScreen> createState() => _VatStatementScreenState();
}

class _VatStatementScreenState extends State<VatStatementScreen> {
  var _mode = _Mode.quarter;
  var _quarter = quarterStartOf(DateTime.now());
  var _secondHalf = DateTime.now().month > 6;
  var _from = quarterStartOf(DateTime.now());
  var _to = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _read());
  }

  (DateTime, DateTime) get _period => switch (_mode) {
    _Mode.quarter => (_quarter, DateTime(_quarter.year, _quarter.month + 3, 0)),
    _Mode.halfYear => (DateTime(_quarter.year, _secondHalf ? 7 : 1), DateTime(_quarter.year, _secondHalf ? 12 : 6, _secondHalf ? 31 : 30)),
    _Mode.custom => (_from, _to),
  };

  Future<void> _read() {
    final (first, last) = _period;
    return widget.statement.readPeriod(first, last);
  }

  void _change(VoidCallback change) {
    setState(change);
    _read();
  }

  Future<void> _pick(DateTime current, ValueChanged<DateTime> onChosen) async {
    final chosen = await showDatePicker(context: context, initialDate: current, firstDate: DateTime(widget.project.startDate.year), lastDate: DateTime(DateTime.now().year + 1, 12, 31));
    if (chosen != null && mounted) {
      _change(() => onChosen(chosen));
    }
  }

  void _askToDeclareLater(VatPurchaseRow row, VatQuarter quarter) {
    final words = Words.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(row.description),
            FilledButton(
              key: VatStatementScreen.declareLaterKey,
              onPressed: () async {
                Navigator.of(sheet).pop();
                await showRefusalOf(context, widget.statement.declareIn(row.entryId, DateTime(quarter.start.year, quarter.start.month + 3)));
                await _read();
              },
              child: Text(words.vatDeclareLater),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, double amount, {Key? key, bool isStrong = false}) => Row(
    children: [
      Expanded(child: Text(label, style: isStrong ? const TextStyle(fontWeight: FontWeight.bold) : null)),
      Text(formatMoney(amount), key: key, style: isStrong ? const TextStyle(fontWeight: FontWeight.bold) : null),
    ],
  );

  Widget _quarterCard(VatQuarter quarter) {
    final words = Words.of(context);
    final start = quarter.start.toIso8601String().substring(0, 10);
    final creditNotes = quarter.purchases.where((row) => row.isCreditNote).length;
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            Text('${words.text('vat.q${quarter.number}')} ${quarter.start.year} · ${formatDate(quarter.start)} – ${formatDate(quarter.end)}', key: VatStatementScreen.periodKey(start), style: Theme.of(context).textTheme.titleSmall),
            Text('${words.vatPurchaseInvoices}: ${quarter.purchases.length}${creditNotes > 0 ? ' · ${words.vatCreditNotes} $creditNotes' : ''}'),
            _line(words.vatAfterDiscount, quarter.purchasesAfterDiscount),
            _line(words.vatPurchasesVat, quarter.purchasesVat),
            _line(words.vatTotal, quarter.purchasesTotal),
            _line(words.vatSalesVat, quarter.salesVat),
            if (quarter.realEstateTax != 0) _line(words.vatRealEstateTax, quarter.realEstateTax),
            const Divider(),
            _line(quarter.netDue < 0 ? words.vatNetRefund : words.vatNetDue, quarter.netDue, key: VatStatementScreen.netKey(start), isStrong: true),
            if (quarter.purchases.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(words.vatPurchaseInvoices),
                children: [
                  for (final row in quarter.purchases)
                    ListTile(
                      key: VatStatementScreen.rowKey(row.entryId),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('${row.row}. ${row.description}'),
                      subtitle: Text(formatDate(row.date)),
                      trailing: Text(formatMoney(row.total)),
                      onTap: widget.project.mayMoveMoney ? () => _askToDeclareLater(row, quarter) : null,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _exceptions(VatStatementFigures figures) {
    final words = Words.of(context);
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(words.vatExceptions, style: Theme.of(context).textTheme.titleSmall),
            if (figures.exceptions.isEmpty) Text(words.vatNoExceptions),
            for (final row in figures.exceptions)
              ListTile(
                key: VatStatementScreen.exceptionKey(row.entryId),
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(words.text('vat.${row.reason}')),
                subtitle: Text([formatDate(row.date), row.companyName, if (row.invoiceNumber.isNotEmpty) row.invoiceNumber].join(' · ')),
                trailing: Text(formatMoney(row.amount)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    return Scaffold(
      appBar: AppBar(title: ScreenTitle(words.vatTitle, subject: widget.project.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<_Mode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: _Mode.quarter, label: Text(words.vatQuarter)),
              ButtonSegment(value: _Mode.halfYear, label: Text(words.vatHalfYear, key: VatStatementScreen.halfYearKey)),
              ButtonSegment(value: _Mode.custom, label: Text(words.vatCustom, key: VatStatementScreen.customKey)),
            ],
            selected: {_mode},
            onSelectionChanged: (selected) => _change(() => _mode = selected.single),
          ),
          const SizedBox(height: 12),
          switch (_mode) {
            _Mode.quarter => QuarterPicker(start: _quarter, firstYear: widget.project.startDate.year, onChanged: (start) => _change(() => _quarter = start)),
            _Mode.halfYear => Wrap(
              spacing: 8,
              children: [
                QuarterPicker(start: _quarter, firstYear: widget.project.startDate.year, onChanged: (start) => _change(() => _quarter = start)),
                ChoiceChip(label: Text(words.vatH1), selected: !_secondHalf, onSelected: (_) => _change(() => _secondHalf = false)),
                ChoiceChip(key: VatStatementScreen.secondHalfKey, label: Text(words.vatH2), selected: _secondHalf, onSelected: (_) => _change(() => _secondHalf = true)),
              ],
            ),
            _Mode.custom => Column(
              spacing: 8,
              children: [
                PickerField(key: VatStatementScreen.fromKey, label: words.vatFrom, value: formatDate(_from), onTap: () => _pick(_from, (date) => _from = date)),
                PickerField(key: VatStatementScreen.toKey, label: words.vatTo, value: formatDate(_to), onTap: () => _pick(_to, (date) => _to = date)),
              ],
            ),
          },
          const SizedBox(height: 12),
          if (widget.project.may(Permission.seeAllCapital))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Builder(
                builder: (context) {
                  final (first, last) = _period;
                  final from = first.toIso8601String().substring(0, 10);
                  final to = last.toIso8601String().substring(0, 10);
                  return ReportFileButtons(files: widget.files, address: '/projects/${widget.project.id}/vat-statement?from=$from&to=$to', name: 'vat-$from-$to', kinds: const [ReportFileKind.excel, ReportFileKind.pdf, ReportFileKind.zip]);
                },
              ),
            ),
          ApiObjectBody(
            object: widget.statement,
            builder: (figures) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final quarter in figures.quarters) _quarterCard(quarter),
                _exceptions(figures),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
