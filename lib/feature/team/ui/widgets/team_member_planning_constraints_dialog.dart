import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:note_sondage/feature/team/domain/entities/planning_worker_type_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_planning_constraints_entity.dart';

class TeamMemberPlanningConstraintsDialogResult {
  const TeamMemberPlanningConstraintsDialogResult({
    required this.constraints,
    required this.workerTypes,
  });

  final TeamMemberPlanningConstraintsEntity constraints;
  final List<PlanningWorkerTypeEntity> workerTypes;
}

class TeamMemberPlanningConstraintsDialog extends StatefulWidget {
  const TeamMemberPlanningConstraintsDialog({
    super.key,
    required this.memberEmail,
    required this.availableWorkerTypes,
    this.initialConstraints,
  });

  final String memberEmail;
  final List<PlanningWorkerTypeEntity> availableWorkerTypes;
  final TeamMemberPlanningConstraintsEntity? initialConstraints;

  static Future<TeamMemberPlanningConstraintsDialogResult?> show(
    BuildContext context, {
    required String memberEmail,
    required List<PlanningWorkerTypeEntity> availableWorkerTypes,
    TeamMemberPlanningConstraintsEntity? initialConstraints,
  }) {
    return showDialog<TeamMemberPlanningConstraintsDialogResult>(
      context: context,
      builder: (context) => TeamMemberPlanningConstraintsDialog(
        memberEmail: memberEmail,
        availableWorkerTypes: availableWorkerTypes,
        initialConstraints: initialConstraints,
      ),
    );
  }

  @override
  State<TeamMemberPlanningConstraintsDialog> createState() =>
      _TeamMemberPlanningConstraintsDialogState();
}

class _TeamMemberPlanningConstraintsDialogState
    extends State<TeamMemberPlanningConstraintsDialog> {
  static const _weekdays = <String>[
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];

  static const _shiftTypes = <String>[
    'MORNING',
    'AFTERNOON',
    'NIGHT',
    'WEEKEND',
  ];

  late String? _workerType;
  late List<PlanningWorkerTypeEntity> _workerTypes;
  late Set<String> _availableWeekdays;
  late Set<String> _preferredShiftTypes;
  late Set<String> _blockedShiftTypes;
  late List<_StoredDateRange> _unavailableDateRanges;
  late bool _overtimeAllowed;
  late bool _avoidConsecutiveShifts;

  late final TextEditingController _minDailyCtrl;
  late final TextEditingController _maxDailyCtrl;
  late final TextEditingController _maxWeeklyCtrl;
  late final TextEditingController _maxMonthlyCtrl;
  late final TextEditingController _minRestCtrl;
  late final TextEditingController _maxNightsCtrl;
  late final TextEditingController _maxWeekendsCtrl;
  late final TextEditingController _notesCtrl;

  String get _languageCode =>
      Localizations.localeOf(context).languageCode.toLowerCase();

  _PlanningConstraintsStrings get _strings =>
      _PlanningConstraintsStrings(_languageCode);

  @override
  void initState() {
    super.initState();
    final initial = widget.initialConstraints;
    _workerTypes = _normalizeWorkerTypes(widget.availableWorkerTypes);
    _workerType = initial?.workerType;
    if (_workerType != null &&
        !_workerTypes.any((item) => item.code == _workerType)) {
      _workerType = null;
    }
    _availableWeekdays = {...?initial?.availableWeekdays};
    _preferredShiftTypes = {...?initial?.preferredShiftTypes};
    _blockedShiftTypes = {...?initial?.blockedShiftTypes};
    _unavailableDateRanges = _parseStoredDateRanges(
      initial?.unavailableDateRanges ?? const <String>[],
    );
    _overtimeAllowed = initial?.overtimeAllowed ?? false;
    _avoidConsecutiveShifts = initial?.avoidConsecutiveShifts ?? false;
    _minDailyCtrl = TextEditingController(
      text: initial?.minDailyHours?.toString() ?? '',
    );
    _maxDailyCtrl = TextEditingController(
      text: initial?.maxDailyHours?.toString() ?? '',
    );
    _maxWeeklyCtrl = TextEditingController(
      text: initial?.maxWeeklyHours?.toString() ?? '',
    );
    _maxMonthlyCtrl = TextEditingController(
      text: initial?.maxMonthlyHours?.toString() ?? '',
    );
    _minRestCtrl = TextEditingController(
      text: initial?.minRestHoursBetweenShifts?.toString() ?? '',
    );
    _maxNightsCtrl = TextEditingController(
      text: initial?.maxConsecutiveNightShifts?.toString() ?? '',
    );
    _maxWeekendsCtrl = TextEditingController(
      text: initial?.maxConsecutiveWeekendShifts?.toString() ?? '',
    );
    _notesCtrl = TextEditingController(text: initial?.notes ?? '');
  }

  @override
  void dispose() {
    _minDailyCtrl.dispose();
    _maxDailyCtrl.dispose();
    _maxWeeklyCtrl.dispose();
    _maxMonthlyCtrl.dispose();
    _minRestCtrl.dispose();
    _maxNightsCtrl.dispose();
    _maxWeekendsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 720;
    final dialogWidth = math.min<double>(
      mediaQuery.size.width * 0.94,
      isCompact ? 420.0 : 540.0,
    );
    final sectionSpacing = isCompact ? 12.0 : 14.0;
    final helperStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: isCompact ? 11.5 : 12.0,
      height: 1.3,
    );

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 24,
        vertical: isCompact ? 16 : 24,
      ),
      titlePadding: EdgeInsets.fromLTRB(
        isCompact ? 16 : 20,
        isCompact ? 14 : 18,
        isCompact ? 16 : 20,
        0,
      ),
      contentPadding: EdgeInsets.fromLTRB(
        isCompact ? 16 : 20,
        12,
        isCompact ? 16 : 20,
        isCompact ? 12 : 16,
      ),
      actionsPadding: EdgeInsets.fromLTRB(
        isCompact ? 12 : 16,
        0,
        isCompact ? 12 : 16,
        isCompact ? 10 : 12,
      ),
      title: Text(
        _strings.planningConstraintsTitle,
        style: theme.textTheme.titleMedium?.copyWith(
          fontSize: isCompact ? 17 : 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: dialogWidth,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.8),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.memberEmail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: isCompact ? 12.5 : 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(_strings.dialogIntro, style: helperStyle),
                SizedBox(height: sectionSpacing),
                _buildWorkerTypeField(context, isCompact),
                SizedBox(height: sectionSpacing),
                _ChipSection(
                  title: _strings.weekdayAvailabilityTitle,
                  helper: _strings.weekdayAvailabilityHelper,
                  options: _weekdays,
                  selected: _availableWeekdays,
                  labelBuilder: _strings.weekdayLabel,
                  compact: isCompact,
                  onToggle: (value) => _toggle(_availableWeekdays, value),
                ),
                SizedBox(height: sectionSpacing),
                _ChipSection(
                  title: _strings.preferredShiftTypesTitle,
                  helper: _strings.preferredShiftTypesHelper,
                  options: _shiftTypes,
                  selected: _preferredShiftTypes,
                  labelBuilder: _strings.shiftTypeLabel,
                  compact: isCompact,
                  onToggle: (value) => _toggle(_preferredShiftTypes, value),
                ),
                SizedBox(height: sectionSpacing),
                _ChipSection(
                  title: _strings.blockedShiftTypesTitle,
                  helper: _strings.blockedShiftTypesHelper,
                  options: _shiftTypes,
                  selected: _blockedShiftTypes,
                  labelBuilder: _strings.shiftTypeLabel,
                  compact: isCompact,
                  onToggle: (value) => _toggle(_blockedShiftTypes, value),
                ),
                SizedBox(height: sectionSpacing),
                _buildUnavailableDateRanges(context, isCompact),
                SizedBox(height: sectionSpacing),
                Wrap(
                  spacing: isCompact ? 8 : 10,
                  runSpacing: isCompact ? 8 : 10,
                  children: [
                    _NumberField(
                      controller: _minDailyCtrl,
                      label: _strings.minHoursDay,
                      compact: isCompact,
                    ),
                    _NumberField(
                      controller: _maxDailyCtrl,
                      label: _strings.maxHoursDay,
                      compact: isCompact,
                    ),
                    _NumberField(
                      controller: _maxWeeklyCtrl,
                      label: _strings.maxHoursWeek,
                      compact: isCompact,
                    ),
                    _NumberField(
                      controller: _maxMonthlyCtrl,
                      label: _strings.maxHoursMonth,
                      compact: isCompact,
                    ),
                    _NumberField(
                      controller: _minRestCtrl,
                      label: _strings.minRestHours,
                      compact: isCompact,
                    ),
                    _NumberField(
                      controller: _maxNightsCtrl,
                      label: _strings.maxConsecutiveNights,
                      compact: isCompact,
                    ),
                    _NumberField(
                      controller: _maxWeekendsCtrl,
                      label: _strings.maxConsecutiveWeekends,
                      compact: isCompact,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                  value: _overtimeAllowed,
                  title: Text(
                    _strings.overtimeAllowed,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: isCompact ? 12.5 : 13,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _overtimeAllowed = value);
                  },
                ),
                SwitchListTile(
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                  value: _avoidConsecutiveShifts,
                  title: Text(
                    _strings.avoidConsecutiveShifts,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: isCompact ? 12.5 : 13,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _avoidConsecutiveShifts = value);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesCtrl,
                  maxLines: isCompact ? 3 : 4,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: isCompact ? 12.5 : 13,
                  ),
                  decoration: _denseInputDecoration(
                    _strings.operationalNotes,
                    compact: isCompact,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_strings.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(_strings.save)),
      ],
    );
  }

  Widget _buildWorkerTypeField(BuildContext context, bool compact) {
    final theme = Theme.of(context);
    PlanningWorkerTypeEntity? selectedWorkerType;
    for (final workerType in _workerTypes) {
      if (workerType.code == _workerType) {
        selectedWorkerType = workerType;
        break;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _workerType,
          isDense: true,
          decoration: _denseInputDecoration(
            _strings.workerTypeLabel,
            compact: compact,
          ),
          items: _workerTypes
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item.code,
                  child: Text(
                    _strings.workerTypeLabelForEntity(item),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: compact ? 12.5 : 13,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _workerType = value),
        ),
        const SizedBox(height: 8),
        Text(
          selectedWorkerType == null
              ? _strings.workerTypeEmptyHelper
              : _strings.workerTypeDescription(selectedWorkerType),
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: compact ? 11.5 : 12,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _strings.workerTypeDisclaimer(
            selectedWorkerType,
            hasExplicitDailyHours: _maxDailyCtrl.text.trim().isNotEmpty,
          ),
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: compact ? 10.5 : 11,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 12,
                vertical: compact ? 8 : 10,
              ),
            ),
            onPressed: _manageWorkerTypes,
            icon: const Icon(Icons.badge_outlined, size: 18),
            label: Text(_strings.manageWorkerTypes),
          ),
        ),
      ],
    );
  }

  Widget _buildUnavailableDateRanges(BuildContext context, bool compact) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _strings.unavailablePeriodsTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _strings.unavailablePeriodsHelper,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: compact ? 11.5 : 12,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        if (_unavailableDateRanges.isEmpty)
          Text(
            _strings.noUnavailablePeriods,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: compact ? 11.5 : 12,
            ),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _unavailableDateRanges
                .map(
                  (range) => InputChip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(
                      _strings.formatDateRange(range.start, range.end),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: compact ? 10.5 : 11,
                      ),
                    ),
                    onDeleted: () {
                      setState(() {
                        _unavailableDateRanges = _unavailableDateRanges
                            .where(
                              (item) => item.storageToken != range.storageToken,
                            )
                            .toList();
                      });
                    },
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: compact ? 8 : 10,
            ),
          ),
          onPressed: _addUnavailableDateRange,
          icon: const Icon(Icons.event_busy_outlined, size: 18),
          label: Text(_strings.addUnavailablePeriod),
        ),
      ],
    );
  }

  InputDecoration _denseInputDecoration(String label, {required bool compact}) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 10 : 12,
      ),
    );
  }

  Future<void> _addUnavailableDateRange() async {
    final now = DateTime.now();
    final pickedStart = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: _strings.selectStartDate,
    );
    if (pickedStart == null || !mounted) {
      return;
    }
    final pickedEnd = await showDatePicker(
      context: context,
      initialDate: pickedStart,
      firstDate: pickedStart,
      lastDate: DateTime(2100),
      helpText: _strings.selectEndDate,
    );
    if (pickedEnd == null) {
      return;
    }
    final range = _StoredDateRange(
      DateTime(pickedStart.year, pickedStart.month, pickedStart.day),
      DateTime(pickedEnd.year, pickedEnd.month, pickedEnd.day),
    );
    setState(() {
      _unavailableDateRanges = [
        ..._unavailableDateRanges.where(
          (item) => item.storageToken != range.storageToken,
        ),
        range,
      ]..sort((left, right) => left.start.compareTo(right.start));
    });
  }

  void _toggle(Set<String> target, String value) {
    setState(() {
      if (target.contains(value)) {
        target.remove(value);
      } else {
        target.add(value);
      }
    });
  }

  void _submit() {
    Navigator.of(context).pop(
      TeamMemberPlanningConstraintsDialogResult(
        constraints: TeamMemberPlanningConstraintsEntity(
          workerType: _workerType,
          availableWeekdays: _availableWeekdays.toList(),
          preferredShiftTypes: _preferredShiftTypes.toList(),
          blockedShiftTypes: _blockedShiftTypes.toList(),
          unavailableDateRanges: _unavailableDateRanges
              .map((range) => range.storageToken)
              .toList(),
          minDailyHours: _parseInt(_minDailyCtrl.text),
          maxDailyHours: _parseInt(_maxDailyCtrl.text),
          maxWeeklyHours: _parseInt(_maxWeeklyCtrl.text),
          maxMonthlyHours: _parseInt(_maxMonthlyCtrl.text),
          overtimeAllowed: _overtimeAllowed,
          avoidConsecutiveShifts: _avoidConsecutiveShifts,
          minRestHoursBetweenShifts: _parseInt(_minRestCtrl.text),
          maxConsecutiveNightShifts: _parseInt(_maxNightsCtrl.text),
          maxConsecutiveWeekendShifts: _parseInt(_maxWeekendsCtrl.text),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        ),
        workerTypes: _workerTypes,
      ),
    );
  }

  Future<void> _manageWorkerTypes() async {
    final updatedWorkerTypes = await showDialog<List<PlanningWorkerTypeEntity>>(
      context: context,
      builder: (context) => _WorkerTypeCatalogDialog(
        workerTypes: _workerTypes,
        strings: _strings,
      ),
    );
    if (updatedWorkerTypes == null || !mounted) {
      return;
    }
    setState(() {
      _workerTypes = _normalizeWorkerTypes(updatedWorkerTypes);
      if (_workerType != null &&
          !_workerTypes.any((item) => item.code == _workerType)) {
        _workerType = null;
      }
    });
  }

  int? _parseInt(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return null;
    }
    return int.tryParse(value);
  }

  List<_StoredDateRange> _parseStoredDateRanges(List<String> rawValues) {
    return rawValues
        .map(_StoredDateRange.tryParse)
        .whereType<_StoredDateRange>()
        .toList()
      ..sort((left, right) => left.start.compareTo(right.start));
  }

  List<PlanningWorkerTypeEntity> _normalizeWorkerTypes(
    List<PlanningWorkerTypeEntity> rawWorkerTypes,
  ) {
    final deduplicated = <String, PlanningWorkerTypeEntity>{};
    for (final builtIn in PlanningWorkerTypeEntity.builtIns) {
      deduplicated[builtIn.code] = builtIn;
    }
    for (final workerType in rawWorkerTypes) {
      final code = workerType.code.trim();
      if (code.isEmpty) {
        continue;
      }
      deduplicated[code] = workerType;
    }
    return deduplicated.values.toList();
  }
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.title,
    required this.helper,
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.compact,
    required this.onToggle,
  });

  final String title;
  final String helper;
  final List<String> options;
  final Set<String> selected;
  final String Function(String value) labelBuilder;
  final bool compact;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          helper,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: compact ? 11.5 : 12,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options
              .map(
                (option) => FilterChip(
                  label: Text(
                    labelBuilder(option),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: compact ? 10.5 : 11,
                    ),
                  ),
                  selected: selected.contains(option),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: (_) => onToggle(option),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _WorkerTypeCatalogDialog extends StatefulWidget {
  const _WorkerTypeCatalogDialog({
    required this.workerTypes,
    required this.strings,
  });

  final List<PlanningWorkerTypeEntity> workerTypes;
  final _PlanningConstraintsStrings strings;

  @override
  State<_WorkerTypeCatalogDialog> createState() =>
      _WorkerTypeCatalogDialogState();
}

class _WorkerTypeCatalogDialogState extends State<_WorkerTypeCatalogDialog> {
  late List<PlanningWorkerTypeEntity> _workerTypes;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _hoursCtrl;

  @override
  void initState() {
    super.initState();
    _workerTypes = [...widget.workerTypes];
    _nameCtrl = TextEditingController();
    _hoursCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 720;
    final customWorkerTypes = _workerTypes
        .where((item) => item.isCustom)
        .toList();

    return AlertDialog(
      title: Text(widget.strings.manageWorkerTypes),
      content: SizedBox(
        width: compact ? 340 : 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.strings.manageWorkerTypesHelper,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ..._workerTypes.map(
                (workerType) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    widget.strings.workerTypeLabelForEntity(workerType),
                  ),
                  subtitle: Text(
                    widget.strings.workerTypeDescription(workerType),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (workerType.defaultMaxHoursPerDay != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${workerType.defaultMaxHoursPerDay}h',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                      if (workerType.isCustom)
                        IconButton(
                          tooltip: widget.strings.deleteCustomWorkerType,
                          onPressed: () {
                            setState(() {
                              _workerTypes = _workerTypes
                                  .where((item) => item.code != workerType.code)
                                  .toList();
                            });
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.strings.addCustomWorkerType,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: widget.strings.customWorkerTypeName,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _hoursCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: widget.strings.customWorkerTypeMaxHours,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: _addCustomWorkerType,
                  icon: const Icon(Icons.add),
                  label: Text(widget.strings.addCustomWorkerType),
                ),
              ),
              if (customWorkerTypes.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    widget.strings.noCustomWorkerTypes,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.strings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_workerTypes),
          child: Text(widget.strings.save),
        ),
      ],
    );
  }

  void _addCustomWorkerType() {
    final rawName = _nameCtrl.text.trim();
    if (rawName.isEmpty) {
      return;
    }
    final code = _buildUniqueCode(rawName);
    final maxHours = int.tryParse(_hoursCtrl.text.trim());
    setState(() {
      _workerTypes = [
        ..._workerTypes,
        PlanningWorkerTypeEntity(
          code: code,
          label: rawName,
          defaultMaxHoursPerDay: maxHours,
          isCustom: true,
        ),
      ];
    });
    _nameCtrl.clear();
    _hoursCtrl.clear();
  }

  String _buildUniqueCode(String value) {
    final base = value
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    var candidate = base.isEmpty ? 'CUSTOM_TYPE' : base;
    var suffix = 2;
    final existingCodes = _workerTypes.map((item) => item.code).toSet();
    while (existingCodes.contains(candidate)) {
      candidate = '${base.isEmpty ? 'CUSTOM_TYPE' : base}_$suffix';
      suffix++;
    }
    return candidate;
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.compact,
  });

  final TextEditingController controller;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 132 : 150,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontSize: compact ? 12.5 : 13),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 10 : 12,
          ),
        ),
      ),
    );
  }
}

class _StoredDateRange {
  const _StoredDateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  String get storageToken => '${_toIso(start)}|${_toIso(end)}';

  static _StoredDateRange? tryParse(String raw) {
    if (raw.trim().isEmpty) {
      return null;
    }
    final parts = raw.split('|');
    try {
      final start = DateTime.parse(parts.first.trim());
      final end = parts.length > 1 && parts[1].trim().isNotEmpty
          ? DateTime.parse(parts[1].trim())
          : start;
      return _StoredDateRange(
        DateTime(start.year, start.month, start.day),
        DateTime(end.year, end.month, end.day),
      );
    } catch (_) {
      return null;
    }
  }

  static String _toIso(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

class _PlanningConstraintsStrings {
  const _PlanningConstraintsStrings(this.languageCode);

  final String languageCode;

  bool get _it => languageCode == 'it';
  bool get _fr => languageCode == 'fr';
  bool get _es => languageCode == 'es';

  String get planningConstraintsTitle {
    if (_it) return 'Vincoli pianificazione';
    if (_fr) return 'Contraintes de planification';
    if (_es) return 'Restricciones de planificación';
    return 'Planning constraints';
  }

  String get dialogIntro {
    if (_it) {
      return 'Qui puoi definire regole ricorrenti, priorità e periodi di indisponibilità che l’Auto Planner deve rispettare per questo membro.';
    }
    if (_fr) {
      return 'Ici, vous pouvez définir des règles récurrentes, des priorités et des périodes d’indisponibilité que l’Auto Planner doit respecter pour ce membre.';
    }
    if (_es) {
      return 'Aquí puedes definir reglas recurrentes, prioridades y períodos de indisponibilidad que el Auto Planner debe respetar para este miembro.';
    }
    return 'Here you can define recurring rules, priorities, and unavailable periods that the Auto Planner must respect for this member.';
  }

  String get workerTypeLabel {
    if (_it) return 'Tipologia lavoratore';
    if (_fr) return 'Type de travailleur';
    if (_es) return 'Tipo de trabajador';
    return 'Worker type';
  }

  String get workerTypeEmptyHelper {
    if (_it) return 'Seleziona un tipo per vedere la descrizione operativa.';
    if (_fr)
      return 'Sélectionnez un type pour voir sa description opérationnelle.';
    if (_es) return 'Selecciona un tipo para ver su descripción operativa.';
    return 'Select a type to see its operational description.';
  }

  String workerTypeDisclaimer(
    PlanningWorkerTypeEntity? workerType, {
    required bool hasExplicitDailyHours,
  }) {
    final workerTypeHours = workerType?.defaultMaxHoursPerDay;
    if (hasExplicitDailyHours) {
      if (_it) {
        return 'Il valore inserito in "Max hours/day" ha priorità rispetto al limite predefinito del worker type.';
      }
      if (_fr) {
        return 'La valeur saisie dans "Max hours/day" est prioritaire sur la limite par défaut du type de travailleur.';
      }
      if (_es) {
        return 'El valor introducido en "Max hours/day" tiene prioridad sobre el límite predeterminado del tipo de trabajador.';
      }
      return 'The value entered in "Max hours/day" overrides the worker type default limit.';
    }
    if (workerTypeHours != null) {
      if (_it) {
        return 'Se lasci vuoto "Max hours/day", il planner userà il limite predefinito di $workerTypeHours ore/giorno del worker type selezionato.';
      }
      if (_fr) {
        return 'Si vous laissez "Max hours/day" vide, le planner utilisera la limite par défaut de $workerTypeHours h/jour du type de travailleur sélectionné.';
      }
      if (_es) {
        return 'Si dejas vacío "Max hours/day", el planner usará el límite predeterminado de $workerTypeHours h/día del tipo de trabajador seleccionado.';
      }
      return 'If you leave "Max hours/day" empty, the planner will use the selected worker type default limit of $workerTypeHours hours/day.';
    }
    if (_it) {
      return 'Puoi usare il worker type come preset gestionale del team e poi affinare i vincoli qui sotto.';
    }
    if (_fr) {
      return 'Vous pouvez utiliser le type de travailleur comme preset d’équipe puis affiner les contraintes ci-dessous.';
    }
    if (_es) {
      return 'Puedes usar el tipo de trabajador como preset del equipo y luego afinar las restricciones aquí abajo.';
    }
    return 'You can use worker type as a team preset and then refine the constraints below.';
  }

  String get manageWorkerTypes {
    if (_it) return 'Gestisci worker type del team';
    if (_fr) return 'Gérer les worker types de l’équipe';
    if (_es) return 'Gestionar los worker types del equipo';
    return 'Manage team worker types';
  }

  String get manageWorkerTypesHelper {
    if (_it) {
      return 'Qui puoi vedere i 4 tipi base e aggiungere preset custom con il loro limite orario giornaliero.';
    }
    if (_fr) {
      return 'Ici, vous pouvez voir les 4 types de base et ajouter des presets personnalisés avec leur limite horaire journalière.';
    }
    if (_es) {
      return 'Aquí puedes ver los 4 tipos base y añadir presets personalizados con su límite horario diario.';
    }
    return 'Here you can review the 4 base types and add custom presets with their daily hour limit.';
  }

  String get addCustomWorkerType {
    if (_it) return 'Aggiungi worker type custom';
    if (_fr) return 'Ajouter un worker type custom';
    if (_es) return 'Añadir worker type personalizado';
    return 'Add custom worker type';
  }

  String get customWorkerTypeName {
    if (_it) return 'Nome worker type';
    if (_fr) return 'Nom du worker type';
    if (_es) return 'Nombre del worker type';
    return 'Worker type name';
  }

  String get customWorkerTypeMaxHours {
    if (_it) return 'Max hours/day predefinito';
    if (_fr) return 'Max hours/day par défaut';
    if (_es) return 'Max hours/day predeterminado';
    return 'Default max hours/day';
  }

  String get noCustomWorkerTypes {
    if (_it) return 'Nessun worker type custom creato per questo team.';
    if (_fr) return 'Aucun worker type custom créé pour cette équipe.';
    if (_es)
      return 'No hay worker types personalizados creados para este equipo.';
    return 'No custom worker types created for this team.';
  }

  String get deleteCustomWorkerType {
    if (_it) return 'Elimina worker type custom';
    if (_fr) return 'Supprimer le worker type custom';
    if (_es) return 'Eliminar worker type personalizado';
    return 'Delete custom worker type';
  }

  String workerTypeLabelForEntity(PlanningWorkerTypeEntity workerType) {
    final baseLabel = switch (workerType.code) {
      'STANDARD_EMPLOYEE' =>
        _it
            ? 'Dipendente standard'
            : _fr
            ? 'Employé standard'
            : _es
            ? 'Empleado estándar'
            : 'Standard employee',
      'PART_TIME' =>
        _it
            ? 'Part-time'
            : _fr
            ? 'Temps partiel'
            : _es
            ? 'Medio tiempo'
            : 'Part-time',
      'FULL_TIME' =>
        _it
            ? 'Full-time'
            : _fr
            ? 'Temps plein'
            : _es
            ? 'Tiempo completo'
            : 'Full-time',
      'INTERN' =>
        _it
            ? 'Stagista'
            : _fr
            ? 'Stagiaire'
            : _es
            ? 'Practicante'
            : 'Intern',
      _ => workerType.label,
    };
    final suffix = workerType.defaultMaxHoursPerDay == null
        ? ''
        : ' (${workerType.defaultMaxHoursPerDay}h)';
    return '$baseLabel$suffix';
  }

  String workerTypeDescription(PlanningWorkerTypeEntity workerType) {
    switch (workerType.code) {
      case 'STANDARD_EMPLOYEE':
        if (_it)
          return 'Profilo operativo generico del team. Oggi impatta soprattutto come preset di ore massime giornaliere e come priorità neutra.';
        if (_fr)
          return 'Profil opérationnel générique de l’équipe. Aujourd’hui, il agit surtout comme preset d’heures max par jour avec une priorité neutre.';
        if (_es)
          return 'Perfil operativo genérico del equipo. Hoy impacta sobre todo como preset de horas máximas al día y con prioridad neutra.';
        return 'Generic operational team profile. Today it mainly acts as a daily max-hours preset with neutral priority.';
      case 'PART_TIME':
        if (_it)
          return 'Pensato per disponibilità ridotta: il planner lo usa con un limite giornaliero più basso e una priorità leggermente più prudente.';
        if (_fr)
          return 'Pensé pour une disponibilité réduite : le planner l’utilise avec une limite journalière plus basse et une priorité un peu plus prudente.';
        if (_es)
          return 'Pensado para disponibilidad reducida: el planner lo usa con un límite diario más bajo y una prioridad algo más prudente.';
        return 'Designed for reduced availability: the planner uses a lower daily cap and a slightly more conservative priority.';
      case 'FULL_TIME':
        if (_it)
          return 'Pensato per coperture più ampie: il planner tende a considerarlo più adatto quando serve continuità o una copertura lunga.';
        if (_fr)
          return 'Pensé pour des couvertures plus larges : le planner a tendance à le considérer comme plus adapté lorsqu’il faut de la continuité ou une longue couverture.';
        if (_es)
          return 'Pensado para coberturas más amplias: el planner tiende a considerarlo más adecuado cuando hace falta continuidad o una cobertura larga.';
        return 'Designed for broader coverage: the planner tends to consider it more suitable when continuity or longer coverage is needed.';
      case 'INTERN':
        if (_it)
          return 'Profilo formativo: il planner lo tratta in modo più prudente, con limite giornaliero più basso e priorità più conservativa.';
        if (_fr)
          return 'Profil de formation : le planner le traite de manière plus prudente, avec une limite journalière plus basse et une priorité plus conservatrice.';
        if (_es)
          return 'Perfil formativo: el planner lo trata de manera más prudente, con límite diario más bajo y prioridad más conservadora.';
        return 'Training profile: the planner treats it more cautiously, with a lower daily cap and a more conservative priority.';
      default:
        if (_it) {
          return 'Worker type custom del team. Il suo impatto principale oggi è il limite orario giornaliero predefinito.';
        }
        if (_fr) {
          return 'Worker type custom de l’équipe. Son principal impact aujourd’hui est la limite horaire journalière par défaut.';
        }
        if (_es) {
          return 'Worker type personalizado del equipo. Su impacto principal hoy es el límite horario diario predeterminado.';
        }
        return 'Custom team worker type. Its main impact today is the default daily hour limit.';
    }
  }

  String get weekdayAvailabilityTitle {
    if (_it) return 'Disponibilità settimanale';
    if (_fr) return 'Disponibilité hebdomadaire';
    if (_es) return 'Disponibilidad semanal';
    return 'Weekly availability';
  }

  String get weekdayAvailabilityHelper {
    if (_it)
      return 'Seleziona solo i giorni in cui questa persona può essere pianificata normalmente.';
    if (_fr)
      return 'Sélectionnez uniquement les jours où cette personne peut être planifiée normalement.';
    if (_es)
      return 'Selecciona solo los días en que esta persona puede planificarse normalmente.';
    return 'Select only the days when this person can normally be scheduled.';
  }

  String get preferredShiftTypesTitle {
    if (_it) return 'Turni preferiti';
    if (_fr) return 'Shifts préférés';
    if (_es) return 'Turnos preferidos';
    return 'Preferred shift types';
  }

  String get preferredShiftTypesHelper {
    if (_it)
      return 'Il planner userà queste preferenze come vantaggio in fase di scelta, senza renderle obbligatorie.';
    if (_fr)
      return 'Le planner utilisera ces préférences comme avantage au moment du choix, sans les rendre obligatoires.';
    if (_es)
      return 'El planner usará estas preferencias como ventaja al elegir, sin hacerlas obligatorias.';
    return 'The planner uses these preferences as a soft advantage during selection, not as hard requirements.';
  }

  String get blockedShiftTypesTitle {
    if (_it) return 'Turni bloccati';
    if (_fr) return 'Shifts bloqués';
    if (_es) return 'Turnos bloqueados';
    return 'Blocked shift types';
  }

  String get blockedShiftTypesHelper {
    if (_it)
      return 'Questi tipi di turno non verranno assegnati a questo membro.';
    if (_fr) return 'Ces types de shifts ne seront pas attribués à ce membre.';
    if (_es) return 'Estos tipos de turno no se asignarán a este miembro.';
    return 'These shift types will not be assigned to this member.';
  }

  String get unavailablePeriodsTitle {
    if (_it) return 'Ferie e periodi di indisponibilità';
    if (_fr) return 'Congés et périodes d’indisponibilité';
    if (_es) return 'Vacaciones y períodos de indisponibilidad';
    return 'Vacation and unavailable periods';
  }

  String get unavailablePeriodsHelper {
    if (_it) {
      return 'Usa questi intervalli per ferie, permessi, formazione o indisponibilità già note. Il planner escluderà il membro in tutte le date del periodo.';
    }
    if (_fr) {
      return 'Utilisez ces intervalles pour les congés, permissions, formation ou indisponibilités déjà connues. Le planner exclura le membre à toutes les dates de la période.';
    }
    if (_es) {
      return 'Usa estos intervalos para vacaciones, permisos, formación o indisponibilidades ya conocidas. El planner excluirá al miembro en todas las fechas del período.';
    }
    return 'Use these ranges for vacations, leave, training, or known unavailability. The planner will exclude the member on every date in the range.';
  }

  String get noUnavailablePeriods {
    if (_it) return 'Nessun periodo inserito.';
    if (_fr) return 'Aucune période enregistrée.';
    if (_es) return 'No hay períodos añadidos.';
    return 'No periods added yet.';
  }

  String get addUnavailablePeriod {
    if (_it) return 'Aggiungi periodo';
    if (_fr) return 'Ajouter une période';
    if (_es) return 'Añadir período';
    return 'Add period';
  }

  String get maxHoursDay {
    if (_it) return 'Max ore/giorno';
    if (_fr) return 'Max heures/jour';
    if (_es) return 'Máx horas/día';
    return 'Max hours/day';
  }

  String get minHoursDay {
    if (_it) return 'Min ore/giorno';
    if (_fr) return 'Min heures/jour';
    if (_es) return 'Mín horas/día';
    return 'Min hours/day';
  }

  String get maxHoursWeek {
    if (_it) return 'Max ore/settimana';
    if (_fr) return 'Max heures/semaine';
    if (_es) return 'Máx horas/semana';
    return 'Max hours/week';
  }

  String get maxHoursMonth {
    if (_it) return 'Max ore/mese';
    if (_fr) return 'Max heures/mois';
    if (_es) return 'Máx horas/mes';
    return 'Max hours/month';
  }

  String get minRestHours {
    if (_it) return 'Riposo minimo (h)';
    if (_fr) return 'Repos minimum (h)';
    if (_es) return 'Descanso mínimo (h)';
    return 'Min rest (h)';
  }

  String get maxConsecutiveNights {
    if (_it) return 'Max notti consecutive';
    if (_fr) return 'Max nuits consécutives';
    if (_es) return 'Máx noches consecutivas';
    return 'Max consecutive nights';
  }

  String get maxConsecutiveWeekends {
    if (_it) return 'Max weekend consecutivi';
    if (_fr) return 'Max week-ends consécutifs';
    if (_es) return 'Máx fines de semana consecutivos';
    return 'Max consecutive weekends';
  }

  String get overtimeAllowed {
    if (_it) return 'Straordinari consentiti';
    if (_fr) return 'Heures supplémentaires autorisées';
    if (_es) return 'Horas extra permitidas';
    return 'Overtime allowed';
  }

  String get avoidConsecutiveShifts {
    if (_it) return 'Evita turni consecutivi';
    if (_fr) return 'Éviter les shifts consécutifs';
    if (_es) return 'Evitar turnos consecutivos';
    return 'Avoid consecutive shifts';
  }

  String get operationalNotes {
    if (_it) return 'Note operative';
    if (_fr) return 'Notes opérationnelles';
    if (_es) return 'Notas operativas';
    return 'Operational notes';
  }

  String get cancel {
    if (_it) return 'Annulla';
    if (_fr) return 'Annuler';
    if (_es) return 'Cancelar';
    return 'Cancel';
  }

  String get save {
    if (_it) return 'Salva';
    if (_fr) return 'Enregistrer';
    if (_es) return 'Guardar';
    return 'Save';
  }

  String get selectStartDate {
    if (_it) return 'Seleziona la data iniziale';
    if (_fr) return 'Sélectionnez la date de début';
    if (_es) return 'Selecciona la fecha inicial';
    return 'Select the start date';
  }

  String get selectEndDate {
    if (_it) return 'Seleziona la data finale';
    if (_fr) return 'Sélectionnez la date de fin';
    if (_es) return 'Selecciona la fecha final';
    return 'Select the end date';
  }

  String weekdayLabel(String value) {
    return switch (value) {
      'MONDAY' =>
        _it
            ? 'Lun'
            : _fr
            ? 'Lun'
            : _es
            ? 'Lun'
            : 'Mon',
      'TUESDAY' =>
        _it
            ? 'Mar'
            : _fr
            ? 'Mar'
            : _es
            ? 'Mar'
            : 'Tue',
      'WEDNESDAY' =>
        _it
            ? 'Mer'
            : _fr
            ? 'Mer'
            : _es
            ? 'Mié'
            : 'Wed',
      'THURSDAY' =>
        _it
            ? 'Gio'
            : _fr
            ? 'Jeu'
            : _es
            ? 'Jue'
            : 'Thu',
      'FRIDAY' =>
        _it
            ? 'Ven'
            : _fr
            ? 'Ven'
            : _es
            ? 'Vie'
            : 'Fri',
      'SATURDAY' =>
        _it
            ? 'Sab'
            : _fr
            ? 'Sam'
            : _es
            ? 'Sáb'
            : 'Sat',
      'SUNDAY' =>
        _it
            ? 'Dom'
            : _fr
            ? 'Dim'
            : _es
            ? 'Dom'
            : 'Sun',
      _ => value,
    };
  }

  String shiftTypeLabel(String value) {
    return switch (value) {
      'MORNING' =>
        _it
            ? 'Mattina'
            : _fr
            ? 'Matin'
            : _es
            ? 'Mañana'
            : 'Morning',
      'AFTERNOON' =>
        _it
            ? 'Pomeriggio'
            : _fr
            ? 'Après-midi'
            : _es
            ? 'Tarde'
            : 'Afternoon',
      'NIGHT' =>
        _it
            ? 'Notte'
            : _fr
            ? 'Nuit'
            : _es
            ? 'Noche'
            : 'Night',
      'WEEKEND' =>
        _it
            ? 'Weekend'
            : _fr
            ? 'Week-end'
            : _es
            ? 'Fin de semana'
            : 'Weekend',
      _ => value,
    };
  }

  String formatDateRange(DateTime start, DateTime end) {
    final startText = _formatDate(start);
    final endText = _formatDate(end);
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return startText;
    }
    return '$startText - $endText';
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}
