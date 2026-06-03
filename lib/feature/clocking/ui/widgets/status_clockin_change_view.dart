import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:note_sondage/core/archive/user_archive_service.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';
import 'package:note_sondage/feature/clocking/domain/use_case/clocking_use_case.dart';
import 'package:note_sondage/feature/clocking/ui/bloc/clocking_bloc.dart';
import 'package:note_sondage/feature/clocking/ui/utils/clocking_access_resolver.dart';
import 'package:note_sondage/feature/clocking/ui/utils/clocking_pdf_export_service.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/role/role_use_case.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/archive_view_toggle.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';

class StatusClockInChangeView extends StatefulWidget {
  const StatusClockInChangeView({
    super.key,
    this.isMobile = false,
    this.selectedTeamId,
    this.selectedDate,
  });

  final bool isMobile;
  final String? selectedTeamId;
  final DateTime? selectedDate;

  @override
  State<StatusClockInChangeView> createState() =>
      _StatusClockInChangeViewState();
}

class _StatusClockInChangeViewState extends State<StatusClockInChangeView> {
  final UserArchiveService _archiveService = getIt<UserArchiveService>();
  final TeamMemberUseCase _teamMemberUseCase = getIt<TeamMemberUseCase>();
  final RoleUseCase _roleUseCase = getIt<RoleUseCase>();
  final ClockingUseCase _clockingUseCase = getIt<ClockingUseCase>();
  late final TextEditingController _searchController;
  DateTime? _selectedDateFilter;
  String? _selectedUserIdFilter;
  final Set<ClockingStatus> _selectedStatusFilters = <ClockingStatus>{};
  Set<String> _archivedRecordIds = <String>{};
  bool _showArchivedOnly = false;
  bool _canManageClocking = false;
  String? _resolvedTeamId;

  @override
  void initState() {
    super.initState();
    _selectedDateFilter = widget.selectedDate == null
        ? null
        : DateTime(
            widget.selectedDate!.year,
            widget.selectedDate!.month,
            widget.selectedDate!.day,
          );
    _searchController = TextEditingController();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadArchivedRecords();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncClockingAccess());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _currentUserId => context.read<AuthBloc>().state.user.uid;
  String get _currentUserEmail => context.read<AuthBloc>().state.user.email;

  @override
  void didUpdateWidget(covariant StatusClockInChangeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTeamId != widget.selectedTeamId) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _syncClockingAccess(),
      );
    }
    if (!_isSameDayOrNull(oldWidget.selectedDate, widget.selectedDate)) {
      setState(() {
        _selectedDateFilter = widget.selectedDate == null
            ? null
            : DateTime(
                widget.selectedDate!.year,
                widget.selectedDate!.month,
                widget.selectedDate!.day,
              );
      });
    }
  }

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

  Future<void> _syncClockingAccess() async {
    final teamId = widget.selectedTeamId;
    if (!mounted) {
      return;
    }
    if (teamId == null || teamId.isEmpty) {
      if (_canManageClocking || _resolvedTeamId != null) {
        setState(() {
          _canManageClocking = false;
          _resolvedTeamId = null;
        });
      }
      return;
    }

    final teamState = context.read<TeamBloc>().state;
    TeamEntity? team;
    if (teamState is TeamsLoaded) {
      team = teamState.teams.cast<TeamEntity?>().firstWhere(
        (item) => item?.id == teamId,
        orElse: () => null,
      );
    }

    bool nextCanManage = false;
    try {
      nextCanManage = await ClockingAccessResolver.canManageClocking(
        team: team,
        currentUserId: _currentUserId,
        currentUserEmail: _currentUserEmail,
        teamMemberUseCase: _teamMemberUseCase,
        roleUseCase: _roleUseCase,
      );
    } catch (_) {}

    if (!mounted) {
      return;
    }
    setState(() {
      _canManageClocking = nextCanManage;
      _resolvedTeamId = teamId;
    });
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
          final availableUsers = _availableUsers(records);
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
          final canManageClocking =
              !showingPersonalHistory && _canManageClocking;

          final col = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                showingPersonalHistory
                    ? localization.clockingInOut
                    : localization.teamClockings,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.iconLabel,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  SizedBox(
                    width: widget.isMobile ? double.infinity : null,
                    child: IntrinsicWidth(
                      child: CustomAppButton(
                        onPressed: displayedRecords.isNotEmpty
                            ? () => _exportPdf(displayedRecords, selectedTeam)
                            : null,
                        type: ButtonType.outlined,
                        isActive: true,
                        fullWidth: widget.isMobile,
                        leadingIcon: const Icon(Icons.download_rounded),
                        child: Text(
                          localization.downloadPdf,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!showingPersonalHistory) ...[
                    IntrinsicWidth(
                      child: CustomAppButton(
                        onPressed:
                            widget.selectedTeamId == null || !canManageClocking
                            ? null
                            : _assignVacationToTeamMember,
                        type: ButtonType.outlined,
                        isActive: true,
                        fullWidth: false,
                        leadingIcon: const Icon(Icons.beach_access_rounded),
                        child: Text(
                          localization.markVacation,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    IntrinsicWidth(
                      child: CustomAppButton(
                        onPressed:
                            widget.selectedTeamId == null || canManageClocking
                            ? null
                            : _requestClockingForTeamMember,
                        type: ButtonType.outlined,
                        isActive: true,
                        fullWidth: false,
                        leadingIcon: const Icon(Icons.notification_add_rounded),
                        child: Text(
                          localization.requestClocking,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    IntrinsicWidth(
                      child: CustomAppButton(
                        onPressed: widget.selectedTeamId == null
                            ? null
                            : canManageClocking
                            ? _assignPermissionToTeamMember
                            : _requestPermissionForSelf,
                        type: ButtonType.outlined,
                        isActive: true,
                        fullWidth: false,
                        leadingIcon: const Icon(Icons.schedule_rounded),
                        child: Text(
                          canManageClocking
                              ? localization.permission
                              : localization.requestPermission,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    if (!canManageClocking)
                      IntrinsicWidth(
                        child: CustomAppButton(
                          onPressed: widget.selectedTeamId == null
                              ? null
                              : _requestVacationForSelf,
                          type: ButtonType.outlined,
                          isActive: true,
                          fullWidth: false,
                          leadingIcon: const Icon(Icons.beach_access_rounded),
                          child: Text(
                            localization.requestVacation,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              if (!showingPersonalHistory)
                Text(
                  canManageClocking
                      ? localization.clockingOwnerHint
                      : localization.clockingApprovalRequestHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              if (!showingPersonalHistory && widget.isMobile) ...[],
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
                        if (!showingPersonalHistory) ...[
                          const SizedBox(height: 12),
                          _buildUserFilterButton(theme, availableUsers),
                        ],
                        if (_hasActiveFilters) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: CustomAppButton(
                              onPressed: _clearFilters,
                              type: ButtonType.text,
                              isActive: false,
                              leadingIcon: const Icon(
                                Icons.restart_alt_rounded,
                              ),
                              child: Text(localization.resetFilters),
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
                        if (!showingPersonalHistory) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: _buildUserFilterButton(
                              theme,
                              availableUsers,
                            ),
                          ),
                        ],
                        if (_hasActiveFilters) ...[
                          const SizedBox(width: 16),
                          CustomAppButton(
                            onPressed: _clearFilters,
                            type: ButtonType.text,
                            isActive: false,
                            leadingIcon: const Icon(Icons.restart_alt_rounded),
                            child: Text(localization.reset),
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
                            isSyncing: context
                                .read<ClockingBloc>()
                                .syncingRecordIds
                                .contains(record.id),
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
                            isSyncing: context
                                .read<ClockingBloc>()
                                .syncingRecordIds
                                .contains(record.id),
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
          return col;
        },
      ),
    );

    return content;
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

    if (_selectedUserIdFilter != null && _selectedUserIdFilter!.isNotEmpty) {
      filtered = filtered
          .where((record) => record.userId == _selectedUserIdFilter)
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

  List<_ClockingUserFilterOption> _availableUsers(
    List<ClockingRecordEntity> records,
  ) {
    final mapped = <String, _ClockingUserFilterOption>{};
    for (final record in records) {
      final userId = record.userId.trim();
      if (userId.isEmpty) continue;
      mapped[userId] = _ClockingUserFilterOption(
        userId: userId,
        label: record.userName.trim().isNotEmpty ? record.userName : userId,
      );
    }
    final values = mapped.values.toList()
      ..sort(
        (left, right) =>
            left.label.toLowerCase().compareTo(right.label.toLowerCase()),
      );
    return values;
  }

  Widget _buildDateFilterButton(ThemeData theme, String label) {
    return CustomAppButton(
      onPressed: _selectDateFilter,
      type: ButtonType.outlined,
      isActive: true,
      fullWidth: true,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      leadingIcon: const Icon(Icons.calendar_month_rounded),
      minHeight: 54,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
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
        _statusFilterChip(
          theme,
          ClockingStatus.vacation,
          localization.vacationStatus,
        ),
        _statusFilterChip(
          theme,
          ClockingStatus.permission,
          localization.permission,
        ),
      ],
    );
  }

  Widget _buildUserFilterButton(
    ThemeData theme,
    List<_ClockingUserFilterOption> availableUsers,
  ) {
    final localization = AppLocalizations.of(context)!;
    String selectedLabel = localization.allUsers;
    if (_selectedUserIdFilter != null) {
      for (final option in availableUsers) {
        if (option.userId == _selectedUserIdFilter) {
          selectedLabel = option.label;
          break;
        }
      }
    }
    return CustomAppButton(
      onPressed: availableUsers.isEmpty
          ? null
          : () => _selectUserFilter(availableUsers),
      type: ButtonType.outlined,
      isActive: true,
      fullWidth: true,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      leadingIcon: const Icon(Icons.person_search_rounded),
      minHeight: 54,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          selectedLabel,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
      _selectedDateFilter != null ||
      _selectedUserIdFilter != null ||
      _selectedStatusFilters.isNotEmpty;

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

  Future<void> _selectUserFilter(
    List<_ClockingUserFilterOption> availableUsers,
  ) async {
    final selectedUserId = await showModalBottomSheet<String?>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => Navigator.of(sheetContext).pop(''),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.group_rounded, size: 20),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(sheetContext)!.allUsers,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              SizedBox(
                height: 320,
                child: ListView(
                  shrinkWrap: true,
                  children: availableUsers
                      .map(
                        (option) => InkWell(
                          onTap: () =>
                              Navigator.of(sheetContext).pop(option.userId),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person_outline_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    option.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || selectedUserId == null) return;
    setState(() {
      _selectedUserIdFilter = selectedUserId.isEmpty ? null : selectedUserId;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedDateFilter = null;
      _selectedUserIdFilter = null;
      _selectedStatusFilters.clear();
    });
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  bool _isSameDayOrNull(DateTime? left, DateTime? right) {
    if (left == null && right == null) {
      return true;
    }
    if (left == null || right == null) {
      return false;
    }
    return _isSameDay(left, right);
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
                  decoration: InputDecoration(
                    labelText: loc.clockInDateTimeLabel,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: clockOutController,
                  decoration: InputDecoration(
                    labelText: loc.clockOutDateTimeLabel,
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
            CustomAppButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              type: ButtonType.text,
              isActive: false,
              child: Text(loc.cancel),
            ),
            CustomAppButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              type: ButtonType.filled,
              isActive: true,
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

  Future<void> _assignVacationToTeamMember() async {
    final localization = AppLocalizations.of(context)!;
    final teamId = widget.selectedTeamId;
    if (teamId == null || teamId.isEmpty) {
      _showSnackBar(localization.selectTeamFirst, Colors.orange);
      return;
    }

    List<TeamMemberEntity> members;
    try {
      members = await _teamMemberUseCase.getAllMembersByTeamId(teamId);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString(), Colors.red);
      return;
    }

    final assignableMembers =
        members
            .where(
              (member) =>
                  member.userId != null && member.userId!.trim().isNotEmpty,
            )
            .map(
              (member) => _ClockingAssignableMember(
                userId: member.userId!.trim(),
                label: member.initialName?.trim().isNotEmpty == true
                    ? member.initialName!.trim()
                    : member.userEmail,
                email: member.userEmail,
              ),
            )
            .toList()
          ..sort(
            (left, right) =>
                left.label.toLowerCase().compareTo(right.label.toLowerCase()),
          );

    if (assignableMembers.isEmpty) {
      _showSnackBar(localization.noAssignableMembersForTeam, Colors.orange);
      return;
    }

    final selectedUser = ValueNotifier<String>(assignableMembers.first.userId);
    final selectedDate = ValueNotifier<DateTime>(
      DateTime(
        (widget.selectedDate ?? DateTime.now()).year,
        (widget.selectedDate ?? DateTime.now()).month,
        (widget.selectedDate ?? DateTime.now()).day,
      ),
    );
    final noteController = TextEditingController();
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(localization.assignVacationToMember),
          content: StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              final activeMember = assignableMembers.firstWhere(
                (member) => member.userId == selectedUser.value,
                orElse: () => assignableMembers.first,
              );
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedUser.value,
                      decoration: InputDecoration(
                        labelText: localization.userLabel,
                      ),
                      items: assignableMembers
                          .map(
                            (member) => DropdownMenuItem<String>(
                              value: member.userId,
                              child: Text('${member.label} (${member.email})'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedUser.value = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomAppButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedDate.value,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked == null) return;
                        setDialogState(() => selectedDate.value = picked);
                      },
                      type: ButtonType.outlined,
                      isActive: true,
                      fullWidth: true,
                      leadingIcon: const Icon(Icons.calendar_month_rounded),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(selectedDate.value),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: localization.note,
                        hintText: localization.optionalNoteFor(
                          activeMember.label,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            CustomAppButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              type: ButtonType.text,
              isActive: false,
              child: Text(localization.cancel),
            ),
            CustomAppButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              type: ButtonType.filled,
              isActive: true,
              child: Text(localization.confirm),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    context.read<ClockingBloc>().add(
      MarkVacationEvent(
        teamId: teamId,
        targetUserId: selectedUser.value,
        date: selectedDate.value,
        note: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
      ),
    );
  }

  Future<void> _requestClockingForTeamMember() async {
    final localization = AppLocalizations.of(context)!;
    final teamId = widget.selectedTeamId;
    if (teamId == null || teamId.isEmpty) {
      _showSnackBar(localization.selectTeamFirst, Colors.orange);
      return;
    }
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(localization.requestClocking),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localization.requestClockingForSelectedDate(
                    DateFormat(
                      'dd/MM/yyyy',
                    ).format(widget.selectedDate ?? DateTime.now()),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: localization.note,
                    hintText: localization.optionalRequestNoteHint,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            CustomAppButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              type: ButtonType.text,
              isActive: false,
              child: Text(localization.cancel),
            ),
            CustomAppButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              type: ButtonType.filled,
              isActive: true,
              child: Text(localization.sendRequest),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await _clockingUseCase.requestTeamMemberClocking(
        teamId: teamId,
        targetUserId: _currentUserId,
        date: widget.selectedDate ?? DateTime.now(),
        note: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
      );
      if (!mounted) return;
      AppSnackBar.showSuccess(context, localization.clockingRequestSentSuccess);
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.showResolvedError(
        context,
        error,
        fallback: localization.clockingRequestSentError,
      );
    }
  }

  Future<void> _requestVacationForSelf() async {
    final localization = AppLocalizations.of(context)!;
    final teamId = widget.selectedTeamId;
    if (teamId == null || teamId.isEmpty) {
      _showSnackBar(localization.selectTeamFirst, Colors.orange);
      return;
    }

    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(localization.requestVacation),
        content: TextField(
          controller: noteController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: localization.note,
            hintText: localization.optionalRequestNoteHint,
          ),
        ),
        actions: [
          CustomAppButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            type: ButtonType.text,
            isActive: false,
            child: Text(localization.cancel),
          ),
          CustomAppButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            type: ButtonType.filled,
            isActive: true,
            child: Text(localization.sendRequest),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await _clockingUseCase.requestVacation(
        teamId: teamId,
        date: widget.selectedDate ?? DateTime.now(),
        note: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
      );
      if (!mounted) return;
      AppSnackBar.showSuccess(context, localization.vacationRequestSentSuccess);
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.showResolvedError(
        context,
        error,
        fallback: localization.vacationRequestSentError,
      );
    }
  }

  Future<void> _requestPermissionForSelf() async {
    final localization = AppLocalizations.of(context)!;
    final teamId = widget.selectedTeamId;
    if (teamId == null || teamId.isEmpty) {
      _showSnackBar(localization.selectTeamFirst, Colors.orange);
      return;
    }

    final window = await _showPermissionDialog(
      title: localization.requestPermission,
    );
    if (window == null || !mounted) return;

    try {
      await _clockingUseCase.requestPermission(
        teamId: teamId,
        date: widget.selectedDate ?? DateTime.now(),
        startTime: window.startTime,
        endTime: window.endTime,
        note: window.note,
      );
      if (!mounted) return;
      AppSnackBar.showSuccess(
        context,
        localization.permissionRequestSentSuccess,
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.showResolvedError(
        context,
        error,
        fallback: localization.permissionRequestSentError,
      );
    }
  }

  Future<void> _assignPermissionToTeamMember() async {
    final localization = AppLocalizations.of(context)!;
    final teamId = widget.selectedTeamId;
    if (teamId == null || teamId.isEmpty) {
      _showSnackBar(localization.selectTeamFirst, Colors.orange);
      return;
    }

    List<TeamMemberEntity> members;
    try {
      members = await _teamMemberUseCase.getAllMembersByTeamId(teamId);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString(), Colors.red);
      return;
    }

    final assignableMembers =
        members
            .where(
              (member) =>
                  member.userId != null && member.userId!.trim().isNotEmpty,
            )
            .map(
              (member) => _ClockingAssignableMember(
                userId: member.userId!.trim(),
                label: member.initialName?.trim().isNotEmpty == true
                    ? member.initialName!.trim()
                    : member.userEmail,
                email: member.userEmail,
              ),
            )
            .toList()
          ..sort(
            (left, right) =>
                left.label.toLowerCase().compareTo(right.label.toLowerCase()),
          );
    if (assignableMembers.isEmpty) {
      _showSnackBar(localization.noAssignableMembersForTeam, Colors.orange);
      return;
    }

    final selectedUser = ValueNotifier<String>(assignableMembers.first.userId);
    final selectedDate = ValueNotifier<DateTime>(
      DateTime(
        (widget.selectedDate ?? DateTime.now()).year,
        (widget.selectedDate ?? DateTime.now()).month,
        (widget.selectedDate ?? DateTime.now()).day,
      ),
    );
    if (!mounted) return;
    final window = await _showPermissionDialog(
      title: localization.permission,
      builderPrefix: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedUser.value,
                decoration: InputDecoration(labelText: localization.userLabel),
                items: assignableMembers
                    .map(
                      (member) => DropdownMenuItem<String>(
                        value: member.userId,
                        child: Text('${member.label} (${member.email})'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => selectedUser.value = value);
                },
              ),
              const SizedBox(height: 12),
              CustomAppButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: selectedDate.value,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked == null) return;
                  setDialogState(() => selectedDate.value = picked);
                },
                type: ButtonType.outlined,
                isActive: true,
                fullWidth: true,
                leadingIcon: const Icon(Icons.calendar_month_rounded),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(selectedDate.value),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
    if (window == null || !mounted) return;

    context.read<ClockingBloc>().add(
      MarkPermissionEvent(
        teamId: teamId,
        targetUserId: selectedUser.value,
        date: selectedDate.value,
        startTime: window.startTime,
        endTime: window.endTime,
        note: window.note,
      ),
    );
  }

  Future<_PermissionDialogResult?> _showPermissionDialog({
    required String title,
    Widget Function(BuildContext dialogContext)? builderPrefix,
  }) async {
    final localization = AppLocalizations.of(context)!;
    TimeOfDay start = const TimeOfDay(hour: 12, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 14, minute: 0);
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (builderPrefix != null) builderPrefix(dialogContext),
                Row(
                  children: [
                    Expanded(
                      child: CustomAppButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: dialogContext,
                            initialTime: start,
                          );
                          if (picked == null) return;
                          setDialogState(() => start = picked);
                        },
                        type: ButtonType.outlined,
                        isActive: true,
                        fullWidth: true,
                        child: Text(
                          '${localization.start}: ${start.format(dialogContext)}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomAppButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: dialogContext,
                            initialTime: end,
                          );
                          if (picked == null) return;
                          setDialogState(() => end = picked);
                        },
                        type: ButtonType.outlined,
                        isActive: true,
                        fullWidth: true,
                        child: Text(
                          '${localization.end}: ${end.format(dialogContext)}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: localization.note,
                    hintText: localization.optionalRequestNoteHint,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            CustomAppButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              type: ButtonType.text,
              isActive: false,
              child: Text(localization.cancel),
            ),
            CustomAppButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              type: ButtonType.filled,
              isActive: true,
              child: Text(localization.save),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) {
      return null;
    }
    if (!mounted) return null;

    final startMinutes = (start.hour * 60) + start.minute;
    final endMinutes = (end.hour * 60) + end.minute;
    if (endMinutes <= startMinutes) {
      AppSnackBar.showWarning(context, localization.permissionInvalidRange);
      return null;
    }

    return _PermissionDialogResult(
      startTime:
          '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}:00',
      endTime:
          '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}:00',
      note: noteController.text.trim().isEmpty
          ? null
          : noteController.text.trim(),
    );
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
    this.isSyncing = false,
    required this.isOwner,
    required this.isArchived,
    required this.onDecommit,
    required this.onCommit,
    required this.onEdit,
    required this.onArchive,
  });

  final ClockingRecordEntity record;
  final bool isSyncing;
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final useStackedLayout =
            !constraints.hasBoundedWidth || constraints.maxWidth < 1180;

        if (useStackedLayout) {
          return _MobileRecordCard(
            record: record,
            isSyncing: isSyncing,
            isOwner: isOwner,
            isArchived: isArchived,
            onDecommit: onDecommit,
            onCommit: onCommit,
            onEdit: onEdit,
            onArchive: onArchive,
          );
        }

        return Opacity(
          opacity: isSyncing ? 0.78 : 1,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _RecordSummary(record: record, isSyncing: isSyncing),
                ),
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
                if (record.note != null && record.note!.trim().isNotEmpty)
                  Expanded(
                    child: _RecordTimeColumn(
                      label: AppLocalizations.of(context)!.note,
                      value: record.note!.trim(),
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
                    isSyncing: isSyncing,
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
                    isArchived
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MobileRecordCard extends StatelessWidget {
  const _MobileRecordCard({
    required this.record,
    this.isSyncing = false,
    required this.isOwner,
    required this.isArchived,
    required this.onDecommit,
    required this.onCommit,
    required this.onEdit,
    required this.onArchive,
  });

  final ClockingRecordEntity record;
  final bool isSyncing;
  final bool isOwner;
  final bool isArchived;
  final VoidCallback onDecommit;
  final VoidCallback onCommit;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: isSyncing ? 0.78 : 1,
      child: Container(
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
                Expanded(
                  child: _RecordSummary(record: record, isSyncing: isSyncing),
                ),
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
                if (record.note != null && record.note!.trim().isNotEmpty)
                  _MiniInfo(
                    label: AppLocalizations.of(context)!.note,
                    value: record.note!.trim(),
                  ),
                _MiniInfo(label: 'Break', value: record.breakWorkedFormatted),
              ],
            ),
            const SizedBox(height: 12),
            _OwnerActions(
              record: record,
              isSyncing: isSyncing,
              isOwner: isOwner,
              onDecommit: onDecommit,
              onCommit: onCommit,
              onEdit: onEdit,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordSummary extends StatelessWidget {
  const _RecordSummary({required this.record, this.isSyncing = false});

  final ClockingRecordEntity record;
  final bool isSyncing;

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
            if (isSyncing) _StatusBadge(label: 'Syncing', color: Colors.amber),
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
    this.isSyncing = false,
    required this.isOwner,
    required this.onDecommit,
    required this.onCommit,
    required this.onEdit,
    this.compact = false,
  });

  final ClockingRecordEntity record;
  final bool isSyncing;
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
        CustomAppButton(
          onPressed: isSyncing ? null : onDecommit,
          type: ButtonType.outlined,
          isActive: !isSyncing,
          child: Text(loc.decommit),
        ),
      if (record.canCommit)
        CustomAppButton(
          onPressed: isSyncing ? null : onCommit,
          type: ButtonType.filledTonal,
          isActive: !isSyncing,
          child: Text(loc.commit),
        ),
      if (record.ownerEditable)
        CustomAppButton(
          onPressed: isSyncing ? null : onEdit,
          type: ButtonType.filled,
          isActive: !isSyncing,
          child: Text(loc.editAction),
        ),
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
    case ClockingStatus.vacation:
      return Colors.teal;
    case ClockingStatus.permission:
      return Colors.indigo;
    case ClockingStatus.absent:
      return Colors.grey;
    case ClockingStatus.late:
      return Colors.red;
  }
}

class _ClockingUserFilterOption {
  const _ClockingUserFilterOption({required this.userId, required this.label});

  final String userId;
  final String label;
}

class _ClockingAssignableMember {
  const _ClockingAssignableMember({
    required this.userId,
    required this.label,
    required this.email,
  });

  final String userId;
  final String label;
  final String email;
}

class _PermissionDialogResult {
  const _PermissionDialogResult({
    required this.startTime,
    required this.endTime,
    this.note,
  });

  final String startTime;
  final String endTime;
  final String? note;
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
