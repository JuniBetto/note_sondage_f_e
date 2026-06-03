import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/repositories/shift_repository.dart';
import 'package:note_sondage/feature/shift/ui/utils/shift_report_pdf_export_service.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_calendar_widget.dart';
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
        if (_selectedUserIds.isEmpty) {
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
    final colorScheme = Theme.of(context).colorScheme;
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
                      ),
                  ],
                ),
                if (!widget.compact) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded),
                      label: Text(loc.close),
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
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedTeamId,
                              decoration: InputDecoration(
                                labelText: loc.team,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              items: widget.teams
                                  .where((team) => team.team.id != null)
                                  .map(
                                    (team) => DropdownMenuItem<String>(
                                      value: team.team.id!,
                                      child: Text(
                                        team.team.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
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
                        onSelected: (_) {
                          setState(_selectAllUsersForCurrentTeam);
                        },
                      ),
                      for (final member in _availableMembers)
                        FilterChip(
                          label: Text(_memberLabel(member)),
                          selected: _selectedUserIds.contains(
                            member.teamMember.userId,
                          ),
                          onSelected: (_) {
                            final userId = member.teamMember.userId;
                            if (userId == null || userId.isEmpty) {
                              return;
                            }
                            _toggleUser(userId);
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
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: Text(loc.shiftReportRefresh),
                      ),
                      FilledButton.icon(
                        onPressed: !hasAssignments || _exporting
                            ? null
                            : _exportPdf,
                        icon: _exporting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download_rounded),
                        label: Text(loc.downloadPdf),
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
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : team == null
                            ? Center(child: Text(loc.shiftReportSelectTeam))
                            : !hasAssignments
                            ? Center(child: Text(loc.shiftReportNoResults))
                            : _showCalendarPreview
                            ? ShiftCalendarWidget(
                                assignments: filteredAssignments,
                                focusedMonth: _focusedMonth,
                                onMonthChanged: (month) {
                                  setState(() {
                                    _focusedMonth = DateTime(
                                      month.year,
                                      month.month,
                                      1,
                                    );
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
                                defaultProfileLabel:
                                    loc.shiftReportDefaultProfile,
                                privateTypeLabel: loc.shiftReportPrivateType,
                                teamLabel: loc.team,
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
    final dateFormat = DateFormat('dd/MM/yyyy');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(
            theme.colorScheme.cursorColor!.withValues(alpha: 0.08),
          ),
          columns: [
            DataColumn(label: Text(dateColumn)),
            DataColumn(label: Text(userColumn)),
            DataColumn(label: Text(profileColumn)),
            DataColumn(label: Text(startColumn)),
            DataColumn(label: Text(endColumn)),
            DataColumn(label: Text(typeColumn)),
            DataColumn(label: Text(noteColumn)),
          ],
          rows: assignments.map((assignment) {
            return DataRow(
              cells: [
                DataCell(Text(dateFormat.format(assignment.shiftDate))),
                DataCell(
                  Text(
                    assignment.userName?.trim().isNotEmpty ?? false
                        ? assignment.userName!.trim()
                        : assignment.userId,
                  ),
                ),
                DataCell(Text(assignment.profileName ?? defaultProfileLabel)),
                DataCell(Text(_formatTime(assignment.startTime))),
                DataCell(Text(_formatTime(assignment.endTime))),
                DataCell(
                  Text(assignment.isPublic ? teamLabel : privateTypeLabel),
                ),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Text(
                      assignment.note?.trim().isNotEmpty ?? false
                          ? assignment.note!.trim()
                          : '—',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  static String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
