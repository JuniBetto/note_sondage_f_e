import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/repositories/shift_repository.dart';
import 'package:note_sondage/feature/shift/ui/utils/shift_report_pdf_export_service.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_calendar_widget.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_calendar_team_picker.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/user_status.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

import 'package:note_sondage/ui/widgets/app_snackbar.dart';

class ShiftTeamReportDialog extends StatefulWidget {
  const ShiftTeamReportDialog({
    super.key,
    required this.teams,
    this.compact = false,
  });

  final List<TeamEntityForView> teams;
  final bool compact;

  static Future<void> show(
    BuildContext context, {
    required List<TeamEntityForView> teams,
    bool compact = false,
  }) async {
    final useBottomSheet = compact || MediaQuery.sizeOf(context).width < 900;
    if (useBottomSheet) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.94,
          child: ShiftTeamReportDialog(teams: teams, compact: true),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        backgroundColor: Colors.transparent,
        child: SizedBox(
          width: math.min(MediaQuery.sizeOf(context).width - 64, 1180),
          height: math.min(MediaQuery.sizeOf(context).height - 48, 860),
          child: ShiftTeamReportDialog(teams: teams),
        ),
      ),
    );
  }

  @override
  State<ShiftTeamReportDialog> createState() => _ShiftTeamReportDialogState();
}

class _ShiftTeamReportDialogState extends State<ShiftTeamReportDialog> {
  final ShiftRepository _shiftRepository = GetIt.instance<ShiftRepository>();
  final TeamMemberUseCase _teamMemberUseCase =
      GetIt.instance<TeamMemberUseCase>();

  late DateTime _rangeStart;
  late DateTime _rangeEnd;
  late DateTime _focusedMonth;
  String? _selectedTeamId;
  final Map<String, List<TeamMemberforView>> _membersByTeamId =
      <String, List<TeamMemberforView>>{};
  final Set<String> _selectedUserIds = <String>{};
  List<ShiftAssignmentEntity> _reportAssignments = <ShiftAssignmentEntity>[];
  bool _loading = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _rangeStart = DateTime(now.year, now.month, 1);
    _rangeEnd = DateTime(now.year, now.month + 1, 0);
    _focusedMonth = _rangeStart;

    for (final team in widget.teams) {
      final teamId = team.team.id;
      if (teamId == null || teamId.isEmpty) {
        continue;
      }
      _membersByTeamId[teamId] = _activeMembers(team.members);
    }

    if (widget.teams.isNotEmpty) {
      _selectedTeamId = widget.teams.first.team.id;
      _selectAllUsersForCurrentTeam();
      _refreshMembersForSelectedTeam();
      _loadReport();
    }
  }

  TeamEntityForView? get _selectedTeamView {
    final teamId = _selectedTeamId;
    if (teamId == null) {
      return null;
    }
    return widget.teams.where((team) => team.team.id == teamId).firstOrNull;
  }

  List<TeamMemberforView> get _availableMembers {
    final teamId = _selectedTeamId;
    if (teamId == null) {
      return const <TeamMemberforView>[];
    }
    return _membersByTeamId[teamId] ?? const <TeamMemberforView>[];
  }

  List<ShiftAssignmentEntity> get _filteredAssignments {
    final teamId = _selectedTeamId;
    if (teamId == null) {
      return const <ShiftAssignmentEntity>[];
    }

    final filtered =
        _reportAssignments.where((assignment) {
          if (assignment.teamId != teamId) {
            return false;
          }
          if (_selectedUserIds.isEmpty) {
            return true;
          }
          return _selectedUserIds.contains(assignment.userId);
        }).toList()..sort((a, b) {
          final byDate = a.shiftDate.compareTo(b.shiftDate);
          if (byDate != 0) {
            return byDate;
          }
          return _displayUserName(
            a,
          ).toLowerCase().compareTo(_displayUserName(b).toLowerCase());
        });
    return filtered;
  }

  bool get _showCalendarPreview => _selectedUserIds.length == 1;

  bool get _allUsersSelected =>
      _availableMembers.isNotEmpty &&
      _selectedUserIds.length == _availableMembers.length;

  Future<void> _refreshMembersForSelectedTeam() async {
    final teamId = _selectedTeamId;
    if (teamId == null || teamId.isEmpty) {
      return;
    }
    final shouldKeepAllSelected = _allUsersSelected;

    try {
      final members = await _teamMemberUseCase.getAllMembersByTeamId(teamId);
      if (!mounted) {
        return;
      }
      setState(() {
        _membersByTeamId[teamId] =
            members
                .where((member) => member.status == UserStatus.active)
                .map((member) => TeamMemberforView(teamMember: member))
                .toList()
              ..sort((a, b) => _memberLabel(a).compareTo(_memberLabel(b)));
        _selectedUserIds.removeWhere(
          (userId) => !_membersByTeamId[teamId]!.any(
            (member) => (member.teamMember.userId ?? '') == userId,
          ),
        );
        if (shouldKeepAllSelected || _selectedUserIds.isEmpty) {
          _selectAllUsersForCurrentTeam();
        }
      });
    } catch (_) {
      // Keep the optimistic local member context if the refresh fails.
    }
  }

  Future<void> _loadReport() async {
    if (_selectedTeamId == null) {
      return;
    }
    setState(() => _loading = true);
    try {
      final assignments = await _shiftRepository.getAssignments(
        from: _rangeStart,
        to: _rangeEnd,
        visibleTeamIds: _selectedTeamId == null
            ? null
            : <String>[_selectedTeamId!],
        visibleUserIds: _selectedUserIds.isEmpty
            ? null
            : _selectedUserIds.toList(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _reportAssignments = assignments;
        _focusedMonth = DateTime(_rangeStart.year, _rangeStart.month, 1);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(
        context,
        AppLocalizations.of(context)!.shiftReportLoadError,
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _rangeStart = DateTime(picked.year, picked.month, picked.day);
      if (_rangeEnd.isBefore(_rangeStart)) {
        _rangeEnd = _rangeStart;
      }
      _focusedMonth = DateTime(_rangeStart.year, _rangeStart.month, 1);
    });
    await _loadReport();
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeEnd,
      firstDate: _rangeStart,
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _rangeEnd = DateTime(picked.year, picked.month, picked.day);
    });
    await _loadReport();
  }

  void _selectAllUsersForCurrentTeam() {
    _selectedUserIds
      ..clear()
      ..addAll(
        _availableMembers
            .map((member) => member.teamMember.userId ?? '')
            .where((userId) => userId.isNotEmpty),
      );
  }

  void _toggleUser(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        if (_selectedUserIds.length > 1) {
          _selectedUserIds.remove(userId);
        }
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  Future<void> _exportPdf() async {
    final team = _selectedTeamView;
    final assignments = _filteredAssignments;
    if (team == null || assignments.isEmpty) {
      return;
    }
    setState(() => _exporting = true);
    try {
      final loc = AppLocalizations.of(context)!;
      final selectedNames = _availableMembers
          .where(
            (member) => _selectedUserIds.contains(member.teamMember.userId),
          )
          .map(_memberLabel)
          .toList();
      await ShiftReportPdfExportService.exportCurrentView(
        teamName: team.team.name,
        from: _rangeStart,
        to: _rangeEnd,
        selectedUserNames: selectedNames,
        assignments: assignments,
        title: loc.shiftTeamReportTitle,
        generatedAtLabel: loc.shiftReportGeneratedAt,
        teamLabel: loc.team,
        periodLabel: loc.shiftReportPeriod,
        usersLabel: loc.shiftReportUsers,
        shiftsLabel: loc.shiftReportShifts,
        allUsersLabel: loc.allUsers,
        dateColumn: loc.shiftReportDateColumn,
        userColumn: loc.shiftReportUserColumn,
        profileColumn: loc.shiftReportProfileColumn,
        startColumn: loc.start,
        endColumn: loc.end,
        typeColumn: loc.shiftReportTypeColumn,
        noteColumn: loc.note,
        defaultProfileLabel: loc.shiftReportDefaultProfile,
        privateTypeLabel: loc.shiftReportPrivateType,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(
        context,
        AppLocalizations.of(context)!.exportPdfError(e.toString()),
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final filteredAssignments = _filteredAssignments;
    final team = _selectedTeamView;
    final hasAssignments = filteredAssignments.isNotEmpty;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.bgNavbarSurface ?? Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: !widget.compact,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.assessment_rounded,
                      color: colorScheme.cursorColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.shiftTeamReportTitle,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            loc.shiftTeamReportSubtitle,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.descriptionColor),
                          ),
                        ],
                      ),
                    ),
                    if (widget.compact)
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close_rounded),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.bgNavbarbutton,
                        ),
                      ),
                  ],
                ),
                if (!widget.compact) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: colorScheme.textInvertedColor,
                      ),
                      label: Text(
                        loc.close,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.textInvertedColor,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.bgNavbarbutton,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (widget.teams.isEmpty)
                  Expanded(
                    child: Center(child: Text(loc.shiftReportUnavailable)),
                  )
                else ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final teamFieldWidth = widget.compact
                          ? constraints.maxWidth
                          : 260.0;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: teamFieldWidth,
                            child: ShiftCalendarTeamPicker(
                              teams: widget.teams,
                              selectedTeamId: _selectedTeamId,
                              includePersonalOption: false,
                              unselectedTitle: loc.shiftReportSelectTeam,
                              triggerSubtitle: loc.changeOrSearchTeam,
                              teamFallbackSubtitle: loc.shiftReportSelectTeam,
                              onChanged: (value) {
                                if (value == null || value == _selectedTeamId) {
                                  return;
                                }
                                setState(() {
                                  _selectedTeamId = value;
                                  _selectAllUsersForCurrentTeam();
                                });
                                _refreshMembersForSelectedTeam();
                                _loadReport();
                              },
                            ),
                          ),
                          _DateButton(
                            label: loc.shiftReportStartDate,
                            value: dateFormat.format(_rangeStart),
                            onTap: _pickStartDate,
                          ),
                          _DateButton(
                            label: loc.shiftReportEndDate,
                            value: dateFormat.format(_rangeEnd),
                            onTap: _pickEndDate,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.shiftReportUsers,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: Text(loc.allUsers),
                        selected: _allUsersSelected,
                        onSelected: (_) async {
                          setState(_selectAllUsersForCurrentTeam);
                          await _loadReport();
                        },
                      ),
                      for (final member in _availableMembers)
                        FilterChip(
                          label: Text(_memberLabel(member)),
                          selected: _selectedUserIds.contains(
                            member.teamMember.userId,
                          ),
                          onSelected: (_) async {
                            final userId = member.teamMember.userId;
                            if (userId == null || userId.isEmpty) {
                              return;
                            }
                            _toggleUser(userId);
                            await _loadReport();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: _loading ? null : _loadReport,
                        icon: _loading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.textInvertedColor,
                                ),
                              )
                            : Icon(
                                Icons.refresh_rounded,
                                color: colorScheme.textInvertedColor,
                              ),
                        label: Text(
                          loc.shiftReportRefresh,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.textInvertedColor,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.bgNavbarbutton,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: !hasAssignments || _exporting
                            ? null
                            : _exportPdf,
                        icon: _exporting
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.textInvertedColor,
                                ),
                              )
                            : Icon(
                                Icons.download_rounded,
                                color: colorScheme.textInvertedColor,
                              ),
                        label: Text(
                          loc.downloadPdf,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.textInvertedColor,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.bgNavbarbutton,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        label: loc.shiftReportPeriod,
                        value:
                            '${dateFormat.format(_rangeStart)} - ${dateFormat.format(_rangeEnd)}',
                      ),
                      _InfoChip(
                        label: loc.shiftReportShifts,
                        value: '${filteredAssignments.length}',
                      ),
                      _InfoChip(
                        label: loc.shiftReportMode,
                        value: _showCalendarPreview
                            ? loc.shiftReportCalendarMode
                            : loc.shiftReportTableMode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.borderColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: _buildPreviewContent(
                          loc,
                          team,
                          filteredAssignments,
                          hasAssignments,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<TeamMemberforView> _activeMembers(List<TeamMemberforView> members) {
    final activeMembers =
        members
            .where((member) => member.teamMember.status == UserStatus.active)
            .toList()
          ..sort((a, b) => _memberLabel(a).compareTo(_memberLabel(b)));
    return activeMembers;
  }

  String _memberLabel(TeamMemberforView member) {
    final initialName = member.teamMember.initialName?.trim();
    if (initialName != null && initialName.isNotEmpty) {
      return initialName;
    }
    final email = member.teamMember.userEmail.trim();
    return email.isEmpty ? (member.teamMember.userId ?? 'Utente') : email;
  }

  String _displayUserName(ShiftAssignmentEntity assignment) {
    final name = assignment.userName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    final matchingMember = _availableMembers.where((member) {
      return member.teamMember.userId == assignment.userId;
    }).firstOrNull;
    if (matchingMember != null) {
      return _memberLabel(matchingMember);
    }
    return assignment.userId;
  }

  Widget _buildPreviewContent(
    AppLocalizations loc,
    TeamEntityForView? team,
    List<ShiftAssignmentEntity> filteredAssignments,
    bool hasAssignments,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (team == null) {
      return Center(child: Text(loc.shiftReportSelectTeam));
    }
    if (!hasAssignments) {
      return Center(child: Text(loc.shiftReportNoResults));
    }

    final preview = _showCalendarPreview
        ? ShiftCalendarWidget(
            assignments: filteredAssignments,
            focusedMonth: _focusedMonth,
            onMonthChanged: (month) {
              setState(() {
                _focusedMonth = DateTime(month.year, month.month, 1);
              });
            },
            onDayTap: (_, __) {},
          )
        : _ShiftReportTable(
            assignments: filteredAssignments,
            dateColumn: loc.shiftReportDateColumn,
            userColumn: loc.shiftReportUserColumn,
            profileColumn: loc.shiftReportProfileColumn,
            startColumn: loc.start,
            endColumn: loc.end,
            typeColumn: loc.shiftReportTypeColumn,
            noteColumn: loc.note,
            defaultProfileLabel: loc.shiftReportDefaultProfile,
            privateTypeLabel: loc.shiftReportPrivateType,
            teamLabel: loc.team,
          );

    if (!widget.compact) {
      return preview;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: preview,
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.bgNavbarSurface?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ShiftReportTable extends StatelessWidget {
  static const double _dateColumnWidth = 120;
  static const double _userColumnWidth = 220;
  static const double _profileColumnWidth = 170;
  static const double _timeColumnWidth = 92;
  static const double _typeColumnWidth = 120;
  static const double _noteColumnWidth = 190;
  static const double _rowGap = 16;

  const _ShiftReportTable({
    required this.assignments,
    required this.dateColumn,
    required this.userColumn,
    required this.profileColumn,
    required this.startColumn,
    required this.endColumn,
    required this.typeColumn,
    required this.noteColumn,
    required this.defaultProfileLabel,
    required this.privateTypeLabel,
    required this.teamLabel,
  });

  final List<ShiftAssignmentEntity> assignments;
  final String dateColumn;
  final String userColumn;
  final String profileColumn;
  final String startColumn;
  final String endColumn;
  final String typeColumn;
  final String noteColumn;
  final String defaultProfileLabel;
  final String privateTypeLabel;
  final String teamLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isCompact = MediaQuery.sizeOf(context).width < 760;
    final minTableWidth =
        _dateColumnWidth +
        _userColumnWidth +
        _profileColumnWidth +
        (_timeColumnWidth * 2) +
        _typeColumnWidth +
        _noteColumnWidth +
        (_rowGap * 6) +
        32;
    final tableWidth = math.max(
      MediaQuery.sizeOf(context).width * 0.68,
      minTableWidth,
    );

    if (isCompact) {
      return Column(
        children: [
          for (final assignment in assignments) ...[
            _ShiftReportMobileCard(
              assignment: assignment,
              dateLabel: dateFormat.format(assignment.shiftDate),
              userLabel: _displayUserName(assignment),
              profileLabel: assignment.profileName ?? defaultProfileLabel,
              timeRangeLabel:
                  '${_formatTime(assignment.startTime)} - ${_formatTime(assignment.endTime)}',
              typeLabel: assignment.isPublic ? teamLabel : privateTypeLabel,
            ),
            if (assignment != assignments.last) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.bgNavbarSurface?.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color:
                      colorScheme.borderColor?.withValues(alpha: 0.55) ??
                      Colors.black.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ShiftReportTableHeader(
                    dateColumn: dateColumn,
                    userColumn: userColumn,
                    profileColumn: profileColumn,
                    startColumn: startColumn,
                    endColumn: endColumn,
                    typeColumn: typeColumn,
                    noteColumn: noteColumn,
                    dateColumnWidth: _dateColumnWidth,
                    userColumnWidth: _userColumnWidth,
                    profileColumnWidth: _profileColumnWidth,
                    timeColumnWidth: _timeColumnWidth,
                    typeColumnWidth: _typeColumnWidth,
                    noteColumnWidth: _noteColumnWidth,
                  ),
                  const SizedBox(height: 12),
                  for (final assignment in assignments) ...[
                    _ShiftReportTableRow(
                      assignment: assignment,
                      dateLabel: dateFormat.format(assignment.shiftDate),
                      userLabel: _displayUserName(assignment),
                      profileLabel:
                          assignment.profileName ?? defaultProfileLabel,
                      startLabel: _formatTime(assignment.startTime),
                      endLabel: _formatTime(assignment.endTime),
                      typeLabel: assignment.isPublic
                          ? teamLabel
                          : privateTypeLabel,
                      dateColumnWidth: _dateColumnWidth,
                      userColumnWidth: _userColumnWidth,
                      profileColumnWidth: _profileColumnWidth,
                      timeColumnWidth: _timeColumnWidth,
                      typeColumnWidth: _typeColumnWidth,
                      noteColumnWidth: _noteColumnWidth,
                    ),
                    if (assignment != assignments.last)
                      const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _displayUserName(ShiftAssignmentEntity assignment) {
    final userName = assignment.userName?.trim();
    if (userName != null && userName.isNotEmpty) {
      return userName;
    }
    return assignment.userId;
  }

  static String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ShiftReportTableHeader extends StatelessWidget {
  const _ShiftReportTableHeader({
    required this.dateColumn,
    required this.userColumn,
    required this.profileColumn,
    required this.startColumn,
    required this.endColumn,
    required this.typeColumn,
    required this.noteColumn,
    required this.dateColumnWidth,
    required this.userColumnWidth,
    required this.profileColumnWidth,
    required this.timeColumnWidth,
    required this.typeColumnWidth,
    required this.noteColumnWidth,
  });

  final String dateColumn;
  final String userColumn;
  final String profileColumn;
  final String startColumn;
  final String endColumn;
  final String typeColumn;
  final String noteColumn;
  final double dateColumnWidth;
  final double userColumnWidth;
  final double profileColumnWidth;
  final double timeColumnWidth;
  final double typeColumnWidth;
  final double noteColumnWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.textInvertedColor?.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              colorScheme.borderColor?.withValues(alpha: 0.35) ??
              Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ShiftHeaderCell(label: dateColumn, width: dateColumnWidth),
          _ShiftHeaderCell(label: userColumn, width: userColumnWidth),
          _ShiftHeaderCell(label: profileColumn, width: profileColumnWidth),
          _ShiftHeaderCell(label: startColumn, width: timeColumnWidth),
          _ShiftHeaderCell(label: endColumn, width: timeColumnWidth),
          _ShiftHeaderCell(label: typeColumn, width: typeColumnWidth),
          _ShiftHeaderCell(label: noteColumn, width: noteColumnWidth),
        ],
      ),
    );
  }
}

class _ShiftHeaderCell extends StatelessWidget {
  const _ShiftHeaderCell({required this.label, required this.width});

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: Text(
        label.toUpperCase(),
        style: textTheme.labelLarge?.copyWith(
          color: colorScheme.textColor,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.45,
        ),
      ),
    );
  }
}

class _ShiftReportTableRow extends StatelessWidget {
  const _ShiftReportTableRow({
    required this.assignment,
    required this.dateLabel,
    required this.userLabel,
    required this.profileLabel,
    required this.startLabel,
    required this.endLabel,
    required this.typeLabel,
    required this.dateColumnWidth,
    required this.userColumnWidth,
    required this.profileColumnWidth,
    required this.timeColumnWidth,
    required this.typeColumnWidth,
    required this.noteColumnWidth,
  });

  final ShiftAssignmentEntity assignment;
  final String dateLabel;
  final String userLabel;
  final String profileLabel;
  final String startLabel;
  final String endLabel;
  final String typeLabel;
  final double dateColumnWidth;
  final double userColumnWidth;
  final double profileColumnWidth;
  final double timeColumnWidth;
  final double typeColumnWidth;
  final double noteColumnWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final note = assignment.note?.trim();
    final hasNote = note != null && note.isNotEmpty;
    final badgeColor = assignment.isPublic
        ? colorScheme.bgNavbarbutton ?? colorScheme.primary
        : Colors.orange.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.bgNavbarSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              colorScheme.borderColor?.withValues(alpha: 0.5) ??
              Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ShiftValueCell(
            width: dateColumnWidth,
            child: Text(
              dateLabel,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.descriptionColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _ShiftValueCell(
            width: userColumnWidth,
            child: Row(
              children: [
                _UserInitialsBadge(label: _initialsFrom(userLabel)),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    userLabel,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _ShiftValueCell(
            width: profileColumnWidth,
            child: _SoftBadge(
              label: profileLabel,
              foreground: colorScheme.textColor ?? Colors.black87,
              background: (colorScheme.textInvertedColor ?? Colors.white)
                  .withValues(alpha: 0.92),
            ),
          ),
          _ShiftValueCell(
            width: timeColumnWidth,
            child: Text(
              startLabel,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _ShiftValueCell(
            width: timeColumnWidth,
            child: Text(
              endLabel,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _ShiftValueCell(
            width: typeColumnWidth,
            child: _SoftBadge(
              label: typeLabel,
              foreground: Colors.white,
              background: badgeColor,
            ),
          ),
          _ShiftValueCell(
            width: noteColumnWidth,
            child: Text(
              hasNote ? note : '—',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: hasNote
                    ? colorScheme.descriptionColor
                    : colorScheme.descriptionColor?.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initialsFrom(String value) {
    final parts = value
        .split(RegExp(r'\s+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '--';
    }
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}

class _ShiftValueCell extends StatelessWidget {
  const _ShiftValueCell({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}

class _ShiftReportMobileCard extends StatelessWidget {
  const _ShiftReportMobileCard({
    required this.assignment,
    required this.dateLabel,
    required this.userLabel,
    required this.profileLabel,
    required this.timeRangeLabel,
    required this.typeLabel,
  });

  final ShiftAssignmentEntity assignment;
  final String dateLabel;
  final String userLabel;
  final String profileLabel;
  final String timeRangeLabel;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final note = assignment.note?.trim();
    final hasNote = note != null && note.isNotEmpty;
    final badgeColor = assignment.isPublic
        ? colorScheme.bgNavbarbutton ?? colorScheme.primary
        : Colors.orange.shade700;

    return LayoutBuilder(
      builder: (context, constraints) {
        final ultraCompact = constraints.maxWidth < 380;
        final gap = ultraCompact ? 4.0 : 6.0;
        final compactTextStyle =
            (ultraCompact ? textTheme.labelSmall : textTheme.bodySmall)
                ?.copyWith(
                  color: colorScheme.textColor,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                );

        return Container(
          padding: EdgeInsets.all(ultraCompact ? 10 : 12),
          decoration: BoxDecoration(
            color: colorScheme.bgNavbarSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  colorScheme.borderColor?.withValues(alpha: 0.5) ??
                  Colors.black.withValues(alpha: 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 12,
                child: Text(
                  dateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: compactTextStyle?.copyWith(
                    color: colorScheme.descriptionColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                flex: 24,
                child: Row(
                  children: [
                    _UserInitialsBadge(
                      label: _initialsFrom(userLabel),
                      size: ultraCompact ? 22 : 24,
                    ),
                    SizedBox(width: ultraCompact ? 4 : 6),
                    Expanded(
                      child: Text(
                        userLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: compactTextStyle?.copyWith(
                          color: colorScheme.textColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                flex: 16,
                child: Text(
                  profileLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: compactTextStyle,
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                flex: 14,
                child: Text(
                  timeRangeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: compactTextStyle?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                flex: 12,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ultraCompact ? 4 : 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    typeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style:
                        (ultraCompact
                                ? textTheme.labelSmall
                                : textTheme.bodySmall)
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                            ),
                  ),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                flex: 16,
                child: Text(
                  hasNote ? note : '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: compactTextStyle?.copyWith(
                    color: hasNote
                        ? colorScheme.descriptionColor
                        : colorScheme.descriptionColor?.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _initialsFrom(String value) {
    final parts = value
        .split(RegExp(r'\s+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '--';
    }
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}

class _SoftBadge extends StatelessWidget {
  const _SoftBadge({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;
  //final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style:
           // textStyle ??
            Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _UserInitialsBadge extends StatelessWidget {
  const _UserInitialsBadge({required this.label, this.size = 34});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.bgNavbarbutton ?? colorScheme.primary,
            (colorScheme.bgNavbarbutton ?? colorScheme.primary).withValues(
              alpha: 0.78,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.textInvertedColor ?? Colors.white,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
