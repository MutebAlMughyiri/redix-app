import 'package:flutter/material.dart';

import '../auth/permission.dart';
import '../format/date_format.dart';
import '../projects/project.dart';
import '../revenue/quarter_picker.dart';
import '../ui/picker_field.dart';
import '../ui/screen_title.dart';
import '../words/words.dart';
import 'report_files.dart';

/// How a period is chosen.
enum _Mode { quarter, halfYear, custom }

/// The كشف الضريبة for a quarter, a half-year or a custom period (UC-056): choosing the period and taking its Excel, whose VAT is a formula on each total (redix-api #96, D19, D20).
class VatStatementScreen extends StatefulWidget {
  /// The statement of [project], handed out through [files].
  const VatStatementScreen({super.key, required this.project, required this.files});

  /// The project.
  final Project project;

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

  /// The choice of the second half of the year.
  static const secondHalfKey = Key('vat.h2');

  @override
  State<VatStatementScreen> createState() => _VatStatementScreenState();
}

class _VatStatementScreenState extends State<VatStatementScreen> {
  var _mode = _Mode.quarter;
  var _quarter = quarterStartOf(DateTime.now());
  var _secondHalf = DateTime.now().month > 6;
  var _from = quarterStartOf(DateTime.now());
  var _to = DateTime.now();

  (DateTime, DateTime) get _period => switch (_mode) {
    _Mode.quarter => (_quarter, DateTime(_quarter.year, _quarter.month + 3, 0)),
    _Mode.halfYear => (DateTime(_quarter.year, _secondHalf ? 7 : 1), DateTime(_quarter.year, _secondHalf ? 12 : 6, _secondHalf ? 31 : 30)),
    _Mode.custom => (_from, _to),
  };

  Future<void> _pick(DateTime current, ValueChanged<DateTime> onChosen) async {
    final chosen = await showDatePicker(context: context, initialDate: current, firstDate: DateTime(widget.project.startDate.year), lastDate: DateTime(DateTime.now().year + 1, 12, 31));
    if (chosen != null && mounted) {
      setState(() => onChosen(chosen));
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = Words.of(context);
    final (first, last) = _period;
    final from = first.toIso8601String().substring(0, 10);
    final to = last.toIso8601String().substring(0, 10);
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
            onSelectionChanged: (selected) => setState(() => _mode = selected.single),
          ),
          const SizedBox(height: 12),
          switch (_mode) {
            _Mode.quarter => QuarterPicker(start: _quarter, firstYear: widget.project.startDate.year, onChanged: (start) => setState(() => _quarter = start)),
            _Mode.halfYear => Wrap(
              spacing: 8,
              children: [
                QuarterPicker(start: _quarter, firstYear: widget.project.startDate.year, onChanged: (start) => setState(() => _quarter = start)),
                ChoiceChip(label: Text(words.vatH1), selected: !_secondHalf, onSelected: (_) => setState(() => _secondHalf = false)),
                ChoiceChip(key: VatStatementScreen.secondHalfKey, label: Text(words.vatH2), selected: _secondHalf, onSelected: (_) => setState(() => _secondHalf = true)),
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
            ReportFileButtons(files: widget.files, address: '/projects/${widget.project.id}/vat-statement?from=$from&to=$to', name: 'vat-$from-$to', kinds: const [ReportFileKind.excel]),
        ],
      ),
    );
  }
}
