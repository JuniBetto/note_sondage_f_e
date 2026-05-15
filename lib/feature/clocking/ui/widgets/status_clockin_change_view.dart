import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:note_sondage/core/archive/user_archive_service.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';
import 'package:note_sondage/feature/clocking/ui/bloc/clocking_bloc.dart';
import 'package:note_sondage/feature/clocking/ui/utils/clocking_pdf_export_service.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/archive_view_toggle.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';

class StatusClockInChangeView extends StatefulWidget {
  const StatusClockInChangeView({
    super.key,
    this.isMobile = false,
    this.selectedTeamId,
  });

  final bool isMobile;
  final String? selectedTeamId;

  @override
  State<StatusClockInChangeView> createState() =>
      _StatusClockInChangeViewState();
}

class _StatusClockInChangeViewState extends State<StatusClockInChangeView> {
  final UserArchiveService _archiveService = getIt<UserArchiveService>();
  late final TextEditingController _searchController;
  DateTime? _selectedDateFilter;
  final Set<ClockingStatus> _selectedStatusFilters = <ClockingStatus>{};
  Set<String> _archivedRecordIds = <String>{};
  bool _showArchivedOnly = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadArchivedRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _currentUserId => context.read<AuthBloc>().state.user.uid;

  Future<void> _loadArchivedRecords() async {
    final archived = await _archiveService.loadArchivedIds(
      userId: _currentUserId,
      bucket: ArchiveBuckets.clockingRecords,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _archivedRecordIds = archived;
    });
  }

  Future<void> _toggleArchiveRecord(String recordId) async {
    await _archiveService.toggleArchived(
      userId: _currentUserId,
      bucket: ArchiveBuckets.clockingRecords,
      itemId: recordId,
    );
    await _loadArchivedRecords();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localization = AppLocalizations.of(context)!;
    final dateFilterLabel = _selectedDateFilter == null
        ? localization.allDates
        : DateFormat('dd/MM/yyyy').format(_selectedDateFilter!);

    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.bgNavbarSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BlocBuilder<ClockingBloc, ClockingState>(
        builder: (context, clockingState) {
          final showingPersonalHistory = widget.selectedTeamId == null;
          final records = _extractVisibleRecords(
            clockingState,
            showingPersonalHistory: showingPersonalHistory,
          );
          final filteredRecords = _filterRecords(records);
          final foregroundRecords = filteredRecords
              .where((record) => !_archivedRecordIds.contains(record.id))
              .toList();
          final archivedRecords = filteredRecords
              .where((record) => _archivedRecordIds.contains(record.id))
              .toList();
          final displayedRecords = _showArchivedOnly
              ? archivedRecords
              : foregroundRecords;
          final teamState = context.watch<TeamBloc>().state;
          final selectedTeam = _selectedTeam(teamState, widget.selectedTeamId);
          final authState = context.watch<AuthBloc>().state;
          final isOwner =
              authState.user.isNotEmpty &&
              selectedTeam?.createdByUserId == authState.user.uid;

          final col = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      showingPersonalHistory
                          ? localization.clockingInOut
                          : localization.teamClockings,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.iconLabel,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: displayedRecords.isNotEmpty
                        ? () => _exportPdf(displayedRecords, selectedTeam)
                        : null,
                    icon: const Icon(Icons.download_rounded),
                    label: Text(localization.downloadPdf),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (!showingPersonalHistory)
                Text(
                  localization.clockingOwnerHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              const SizedBox(height: 16),
              ArchiveViewToggle(
                showArchivedOnly: _showArchivedOnly,
                primaryCount: foregroundRecords.length,
                archivedCount: archivedRecords.length,
                onChanged: (value) {
                  setState(() => _showArchivedOnly = value);
                },
              ),
              const SizedBox(height: 16),
              widget.isMobile
                  ? Column(
                      children: [
                        CustomInputField(
                          hintText: localization.searchByNameOrTeam,
                          controller: _searchController,
                          isSearch: true,
                          onSearchPressed: () => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        _buildDateFilterButton(theme, dateFilterLabel),
                        const SizedBox(height: 12),
                        _buildStatusFilters(theme),
                        if (_hasActiveFilters) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.restart_alt_rounded),
                              label: Text(localization.resetFilters),
                            ),
                          ),
                        ],
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: CustomInputField(
                            hintText: localization.searchByNameOrTeam,
                            controller: _searchController,
                            isSearch: true,
                            onSearchPressed: () => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _buildDateFilterButton(theme, dateFilterLabel),
                        ),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: _buildStatusFilters(theme)),
                        if (_hasActiveFilters) ...[
                          const SizedBox(width: 16),
                          TextButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.restart_alt_rounded),
                            label: Text(localization.reset),
                          ),
                        ],
                      ],
                    ),
              const SizedBox(height: 16),
              if (displayedRecords.isEmpty)
                _InfoState(
                  message: _showArchivedOnly
                      ? 'Nessun record archiviato.'
                      : (showingPersonalHistory
                            ? localization.noClockingsForFilter
                            : localization.noClockingsForTeam),
                )
              else if (widget.isMobile)
                Column(
                  children: displayedRecords
                      .map(
                        (record) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MobileRecordCard(
                            record: record,
                            isOwner: isOwner,
                            isArchived: _archivedRecordIds.contains(record.id),
                            onDecommit: () => _decommitRecord(record),
                            onCommit: () => _commitRecord(record),
                            onEdit: () => _editRecord(record),
                            onArchive: () => _toggleArchiveRecord(record.id),
                          ),
                        ),
                      )
                      .toList(),
                )
              else
                Column(
                  children: displayedRecords
                      .map(
                        (record) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _WebRecordRow(
                            record: record,
                            isOwner: isOwner,
                            isArchived: _archivedRecordIds.contains(record.id),
                            onDecommit: () => _decommitRecord(record),
                            onCommit: () => _commitRecord(record),
                            onEdit: () => _editRecord(record),
                            onArchive: () => _toggleArchiveRecord(record.id),
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          );
          return widget.isMobile ? col : SingleChildScrollView(child: col);
        },
      ),
    );

    if (widget.isMobile) {
      return content;
    }
    return Expanded(child: content);
  }

  List<ClockingRecordEntity> _extractVisibleRecords(
    ClockingState state, {
    required bool showingPersonalHistory,
  }) {
    if (state is ClockingRecordsLoaded) {
      return showingPersonalHistory ? state.myRecords : state.teamRecords;
    }
    if (state is ClockingActionInProgress) {
      return showingPersonalHistory ? state.myRecords : state.teamRecords;
    }
    if (state is ClockingActionSuccess) {
      return showingPersonalHistory ? state.myRecords : state.teamRecords;
    }
    return const [];
  }

  TeamEntity? _selectedTeam(TeamState teamState, String? selectedTeamId) {
    if (teamState is! TeamsLoaded || selectedTeamId == null) return null;
    for (final team in teamState.teams) {
      if (team.id == selectedTeamId) return team;
    }
    return null;
  }

  List<ClockingRecordEntity> _filterRecords(
    List<ClockingRecordEntity> records,
  ) {
    var filtered = records;

    if (_selectedDateFilter != null) {
      filtered = filtered
          .where((record) => _isSameDay(record.date, _selectedDateFilter!))
          .toList();
    }

    if (_selectedStatusFilters.isNotEmpty) {
      filtered = filtered
          .where((record) => _selectedStatusFilters.contains(record.status))
          .toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return filtered;

    return filtered.where((record) {
      return record.userName.toLowerCase().contains(query) ||
          record.teamName.toLowerCase().contains(query) ||
          record.statusLabel.toLowerCase().contains(query) ||
          DateFormat('dd/MM/yyyy').format(record.date).contains(query);
    }).toList();
  }

  Widget _buildDateFilterButton(ThemeData theme, String label) {
    return OutlinedButton.icon(
      onPressed: _selectDateFilter,
      icon: const Icon(Icons.calendar_month_rounded),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        alignment: Alignment.centerLeft,
        minimumSize: const Size.fromHeight(54),
      ),
    );
  }

  Widget _buildStatusFilters(ThemeData theme) {
    final localization = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _statusFilterChip(
          theme,
          ClockingStatus.committed,
          localization.committed,
        ),
        _statusFilterChip(
          theme,
          ClockingStatus.decommitted,
          localization.decommitted,
        ),
      ],
    );
  }

  Widget _statusFilterChip(
    ThemeData theme,
    ClockingStatus status,
    String label,
  ) {
    final selected = _selectedStatusFilters.contains(status);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        setState(() {
          if (value) {
            _selectedStatusFilters.add(status);
          } else {
            _selectedStatusFilters.remove(status);
          }
        });
      },
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }

  bool get _hasActiveFilters =>
      _selectedDateFilter != null || _selectedStatusFilters.isNotEmpty;

  Future<void> _selectDateFilter() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateFilter ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDateFilter = picked);
  }

  void _clearFilters() {
    setState(() {
      _selectedDateFilter = null;
      _selectedStatusFilters.clear();
    });
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  void _decommitRecord(ClockingRecordEntity record) {
    context.read<ClockingBloc>().add(DecommitClockingRecordEvent(record.id));
  }

  void _commitRecord(ClockingRecordEntity record) {
    context.read<ClockingBloc>().add(CommitClockingRecordEvent(record.id));
  }

  Future<void> _editRecord(ClockingRecordEntity record) async {
    final clockInController = TextEditingController(
      text: _formatDateTime(record.clockInTime),
    );
    final clockOutController = TextEditingController(
      text: _formatDateTime(record.clockOutTime),
    );
    final breakMinutesController = TextEditingController(
      text: (record.totalBreakMinutes ?? 0).toString(),
    );
    final noteController = TextEditingController(text: record.note ?? '');

    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final loc = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(loc.editClocking),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: clockInController,
                  decoration: const InputDecoration(
                    labelText: 'Clock-in (YYYY-MM-DD HH:MM)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: clockOutController,
                  decoration: const InputDecoration(
                    labelText: 'Clock-out (YYYY-MM-DD HH:MM)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: breakMinutesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: loc.breakMinutes),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: loc.note),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(loc.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(loc.save),
            ),
          ],
        );
      },
    );

    if (updated != true || !mounted) return;

    final parsedClockIn = _parseDateTime(clockInController.text);
    final parsedClockOut = _parseDateTime(clockOutController.text);
    final parsedBreakMinutes = int.tryParse(breakMinutesController.text.trim());

    if (parsedClockIn == null || parsedClockOut == null) {
      _showSnackBar(
        AppLocalizations.of(context)!.invalidDateFormat,
        Colors.orange,
      );
      return;
    }

    context.read<ClockingBloc>().add(
      UpdateClockingRecordEvent(
        id: record.id,
        clockInAt: parsedClockIn,
        clockOutAt: parsedClockOut,
        totalBreakMinutes: parsedBreakMinutes,
        note: noteController.text.trim(),
      ),
    );
  }

  DateTime? _parseDateTime(String raw) {
    final normalized = raw.trim().replaceFirst(' ', 'T');
    if (normalized.isEmpty) return null;
    return DateTime.tryParse(normalized);
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '';
    final yyyy = value.year.toString().padLeft(4, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final dd = value.day.toString().padLeft(2, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd $hh:$min';
  }

  void _showSnackBar(String message, Color color) {
    if (color == Colors.red) {
      AppSnackBar.showResolvedError(context, message);
      return;
    }
    AppSnackBar.showWarning(context, message);
  }

  Future<void> _exportPdf(
    List<ClockingRecordEntity> records,
    TeamEntity? selectedTeam,
  ) async {
    if (records.isEmpty) {
      _showSnackBar(
        AppLocalizations.of(context)!.noClockingsToExport,
        Colors.orange,
      );
      return;
    }

    try {
      await ClockingPdfExportService.exportCurrentView(
        records: records,
        teamName: selectedTeam?.name ?? 'Team',
        searchQuery: _searchController.text.trim(),
        selectedDate: _selectedDateFilter,
        selectedStatuses: Set<ClockingStatus>.from(_selectedStatusFilters),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        AppLocalizations.of(context)!.exportPdfError(e.toString()),
        Colors.red,
      );
    }
  }
}

class _InfoState extends StatelessWidget {
  const _InfoState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.grey.withValues(alpha: 0.05),
      ),
      child: Text(
        message,
        style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _WebRecordRow extends StatelessWidget {
  const _WebRecordRow({
    required this.record,
    required this.isOwner,
    required this.isArchived,
    required this.onDecommit,
    required this.onCommit,
    required this.onEdit,
    required this.onArchive,
  });

  final ClockingRecordEntity record;
  final bool isOwner;
  final bool isArchived;
  final VoidCallback onDecommit;
  final VoidCallback onCommit;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _RecordSummary(record: record)),
          Expanded(
            child: _RecordTimeColumn(
              label: 'Date',
              value: DateFormat('dd/MM/yyyy').format(record.date),
            ),
          ),
          Expanded(
            child: _RecordTimeColumn(
              label: 'Clock-in',
              value: record.clockInFormatted,
            ),
          ),
          Expanded(
            child: _RecordTimeColumn(
              label: 'Clock-out',
              value: record.clockOutFormatted,
            ),
          ),
          Expanded(
            child: _RecordTimeColumn(
              label: 'Worked',
              value: record.timeWorkedFormatted,
            ),
          ),
          Expanded(
            child: _RecordTimeColumn(
              label: 'Break',
              value: record.breakWorkedFormatted,
            ),
          ),
          SizedBox(
            width: 210,
            child: _OwnerActions(
              record: record,
              isOwner: isOwner,
              onDecommit: onDecommit,
              onCommit: onCommit,
              onEdit: onEdit,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: isArchived ? 'Ripristina record' : 'Archivia record',
            onPressed: onArchive,
            icon: Icon(
              isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileRecordCard extends StatelessWidget {
  const _MobileRecordCard({
    required this.record,
    required this.isOwner,
    required this.isArchived,
    required this.onDecommit,
    required this.onCommit,
    required this.onEdit,
    required this.onArchive,
  });

  final ClockingRecordEntity record;
  final bool isOwner;
  final bool isArchived;
  final VoidCallback onDecommit;
  final VoidCallback onCommit;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _RecordSummary(record: record)),
              IconButton(
                tooltip: isArchived ? 'Ripristina record' : 'Archivia record',
                onPressed: onArchive,
                icon: Icon(
                  isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _MiniInfo(
                label: 'Date',
                value: DateFormat('dd/MM/yyyy').format(record.date),
              ),
              _MiniInfo(label: 'Clock-in', value: record.clockInFormatted),
              _MiniInfo(label: 'Clock-out', value: record.clockOutFormatted),
              _MiniInfo(label: 'Worked', value: record.timeWorkedFormatted),
              _MiniInfo(label: 'Break', value: record.breakWorkedFormatted),
            ],
          ),
          const SizedBox(height: 12),
          _OwnerActions(
            record: record,
            isOwner: isOwner,
            onDecommit: onDecommit,
            onCommit: onCommit,
            onEdit: onEdit,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _RecordSummary extends StatelessWidget {
  const _RecordSummary({required this.record});

  final ClockingRecordEntity record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _statusColor(
                record.status,
              ).withValues(alpha: 0.12),
              child: Text(
                _initials(record.userName),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _statusColor(record.status),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.userName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    record.teamName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusBadge(
              label: DateFormat('dd/MM/yyyy').format(record.date),
              color: Colors.teal,
            ),
            _StatusBadge(
              label: record.statusLabel,
              color: _statusColor(record.status),
            ),
            if (record.note != null && record.note!.trim().isNotEmpty)
              _StatusBadge(
                label: AppLocalizations.of(context)!.note,
                color: Colors.blueGrey,
              ),
          ],
        ),
      ],
    );
  }
}

class _OwnerActions extends StatelessWidget {
  const _OwnerActions({
    required this.record,
    required this.isOwner,
    required this.onDecommit,
    required this.onCommit,
    required this.onEdit,
    this.compact = false,
  });

  final ClockingRecordEntity record;
  final bool isOwner;
  final VoidCallback onDecommit;
  final VoidCallback onCommit;
  final VoidCallback onEdit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!isOwner) {
      return Text(
        AppLocalizations.of(context)!.ownerOnly,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
      );
    }

    final loc = AppLocalizations.of(context)!;
    final buttons = <Widget>[
      if (record.canDecommit)
        OutlinedButton(onPressed: onDecommit, child: Text(loc.decommit)),
      if (record.canCommit)
        FilledButton.tonal(onPressed: onCommit, child: Text(loc.commit)),
      if (record.ownerEditable)
        FilledButton(onPressed: onEdit, child: Text(loc.editAction)),
    ];

    if (buttons.isEmpty) {
      return Text(
        loc.noActionAvailable,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
      );
    }

    if (compact) {
      return Wrap(spacing: 8, runSpacing: 8, children: buttons);
    }
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: buttons,
    );
  }
}

class _RecordTimeColumn extends StatelessWidget {
  const _RecordTimeColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _statusColor(ClockingStatus status) {
  switch (status) {
    case ClockingStatus.clockedIn:
      return Colors.green;
    case ClockingStatus.onBreak:
      return Colors.orange;
    case ClockingStatus.committed:
      return Colors.blue;
    case ClockingStatus.decommitted:
      return Colors.deepPurple;
    case ClockingStatus.absent:
      return Colors.grey;
    case ClockingStatus.late:
      return Colors.red;
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(' ')
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return parts.isNotEmpty ? parts.first[0].toUpperCase() : '?';
}
