import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/repositories/shift_repository.dart';
import 'package:note_sondage/core/export/report_table_data.dart';
import 'package:note_sondage/core/export/report_table_file_export_service.dart';
import 'package:note_sondage/feature/shift/ui/utils/shift_report_pdf_export_service.dart';
import 'package:note_sondage/feature/shift/ui/utils/shift_report_table_data.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_calendar_widget.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_calendar_team_picker.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/user_status.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/report_export_dialog.dart';

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
  // Ordine delle colonne della tabella, condiviso con l'esportazione.
  List<ShiftReportColumn> _columnOrder = ShiftReportColumn.values;
  // L'account (email) e' disattivato di default: si aggiunge solo al download.
  Set<ShiftReportColumn> _exportSelected = ShiftReportColumn.defaultExport
      .toSet();
  ReportExportFormat _exportFormat = ReportExportFormat.pdf;

  // Zoom della tabella su mobile: 1.0 = dimensione normale.
  double _tableScale = 1.0;

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

  Map<ShiftReportColumn, String> _columnLabels(AppLocalizations loc) => {
    ShiftReportColumn.date: loc.shiftReportDateColumn,
    ShiftReportColumn.user: loc.shiftReportUserColumn,
    ShiftReportColumn.account: loc.shiftReportAccountColumn,
    ShiftReportColumn.profile: loc.shiftReportProfileColumn,
    ShiftReportColumn.start: loc.start,
    ShiftReportColumn.end: loc.end,
    ShiftReportColumn.duration: loc.shiftReportDurationColumn,
    ShiftReportColumn.type: loc.shiftReportTypeColumn,
    ShiftReportColumn.note: loc.note,
  };

  void _moveColumn(ShiftReportColumn from, ShiftReportColumn to) {
    if (from == to) {
      return;
    }
    setState(() {
      final order = List<ShiftReportColumn>.of(_columnOrder)..remove(from);
      order.insert(_columnOrder.indexOf(to), from);
      _columnOrder = order;
    });
  }

  Future<void> _openExportDialog() async {
    final team = _selectedTeamView;
    if (team == null || _filteredAssignments.isEmpty) {
      return;
    }
    final dateFormat = DateFormat('dd/MM/yyyy');
    final labels = _columnLabels(AppLocalizations.of(context)!);
    final selection = await ReportExportDialog.show<ShiftReportColumn>(
      context,
      allColumns: ShiftReportColumn.values,
      labelOf: (column) => labels[column] ?? '',
      subtitle:
          '${team.team.name} · ${dateFormat.format(_rangeStart)} - ${dateFormat.format(_rangeEnd)} · ${_filteredAssignments.length}',
      initialColumns: _columnOrder.where(_exportSelected.contains).toList(),
      initialOrder: _columnOrder,
      initialFormat: _exportFormat,
    );
    if (selection == null || selection.columns.isEmpty || !mounted) {
      return;
    }
    setState(() {
      _columnOrder = selection.order;
      _exportSelected = selection.columns.toSet();
    });
    _exportFormat = selection.format;
    await _export(selection);
  }

  Future<void> _export(
    ReportExportSelection<ShiftReportColumn> selection,
  ) async {
    final columns = selection.columns;
    final team = _selectedTeamView;
    final assignments = _filteredAssignments;
    if (team == null || assignments.isEmpty) {
      return;
    }
    setState(() => _exporting = true);
    try {
      final loc = AppLocalizations.of(context)!;
      final emailByUserId = <String, String>{
        for (final member in _availableMembers)
          if ((member.teamMember.userId ?? '').isNotEmpty)
            member.teamMember.userId!: member.teamMember.userEmail,
      };
      final selectedNames = _availableMembers
          .where(
            (member) => _selectedUserIds.contains(member.teamMember.userId),
          )
          .map(_memberLabel)
          .toList();
      if (selection.format != ReportExportFormat.pdf) {
        await ReportTableFileExportService.export(
          format: selection.format,
          teamName: team.team.name,
          filePrefix: 'shift_report',
          sheetName: loc.shiftTeamReportTitle,
          data: buildShiftReportTable(
            assignments: assignments,
            columns: columns,
            headerByColumn: _columnLabels(loc),
            teamLabel: loc.team,
            defaultProfileLabel: loc.shiftReportDefaultProfile,
            privateTypeLabel: loc.shiftReportPrivateType,
            emailByUserId: emailByUserId,
          ),
        );
        return;
      }
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
        accountColumn: loc.shiftReportAccountColumn,
        durationColumn: loc.shiftReportDurationColumn,
        emailByUserId: emailByUserId,
        columns: columns,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(
        context,
        AppLocalizations.of(context)!.shiftReportExportError(e.toString()),
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
    final previewBox = DecoratedBox(
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
    );

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
                else if (widget.compact)
                  // Su mobile tutta la pagina scorre in verticale, anche
                  // fuori dalla tabella.
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                      unselectedTitle:
                                          loc.shiftReportSelectTeam,
                                      triggerSubtitle: loc.changeOrSearchTeam,
                                      teamFallbackSubtitle:
                                          loc.shiftReportSelectTeam,
                                      onChanged: (value) {
                                        if (value == null ||
                                            value == _selectedTeamId) {
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
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
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
                                    : _openExportDialog,
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
                                  loc.shiftReportDownload,
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
                          previewBox,
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
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
                            : _openExportDialog,
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
                          loc.shiftReportDownload,
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
                  Expanded(child: previewBox),
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
    Widget placeholder(Widget child) => widget.compact
        ? SizedBox(height: 160, child: Center(child: child))
        : Center(child: child);

    if (_loading) {
      return placeholder(const CircularProgressIndicator());
    }
    if (team == null) {
      return placeholder(Text(loc.shiftReportSelectTeam));
    }
    if (!hasAssignments) {
      return placeholder(Text(loc.shiftReportNoResults));
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
            columnOrder: _columnOrder
                .where((column) => column.isShownInTable)
                .toList(),
            onMoveColumn: _moveColumn,
            labels: _columnLabels(loc),
            defaultProfileLabel: loc.shiftReportDefaultProfile,
            privateTypeLabel: loc.shiftReportPrivateType,
            teamLabel: loc.team,
            embedded: widget.compact,
            scale: widget.compact ? _tableScale : 1.0,
          );

    if (!widget.compact || _showCalendarPreview) {
      return preview;
    }

    // Su mobile la tabella si puo' rimpicciolire per vederne di piu'.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: _TableSizeButton(
            scale: _tableScale,
            tooltip: loc.shiftReportTableSize,
            onChanged: (value) => setState(() => _tableScale = value),
          ),
        ),
        const SizedBox(height: 8),
        preview,
      ],
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

class _ShiftReportTable extends StatefulWidget {
  static const double _rowGap = 16;

  static double widthOf(ShiftReportColumn column) {
    switch (column) {
      case ShiftReportColumn.date:
        return 120;
      case ShiftReportColumn.user:
        return 220;
      case ShiftReportColumn.account:
        return 200;
      case ShiftReportColumn.duration:
        return 120;
      case ShiftReportColumn.profile:
        return 170;
      case ShiftReportColumn.start:
      case ShiftReportColumn.end:
        return 92;
      case ShiftReportColumn.type:
        return 120;
      case ShiftReportColumn.note:
        return 190;
    }
  }

  const _ShiftReportTable({
    required this.assignments,
    required this.columnOrder,
    required this.onMoveColumn,
    required this.labels,
    required this.defaultProfileLabel,
    required this.privateTypeLabel,
    required this.teamLabel,
    this.embedded = false,
    this.scale = 1.0,
  });

  /// Fattore di zoom: tabella e contenuto vengono ridotti in proporzione.
  final double scale;

  /// `true` quando la tabella e' dentro una pagina che scorre gia' in verticale.
  final bool embedded;
  final List<ShiftAssignmentEntity> assignments;
  final List<ShiftReportColumn> columnOrder;

  /// Sposta la colonna [from] nella posizione occupata da [to].
  final void Function(ShiftReportColumn from, ShiftReportColumn to)
  onMoveColumn;
  final Map<ShiftReportColumn, String> labels;
  final String defaultProfileLabel;
  final String privateTypeLabel;
  final String teamLabel;

  @override
  State<_ShiftReportTable> createState() => _ShiftReportTableState();
}

class _ShiftReportTableState extends State<_ShiftReportTable> {
  static const double _autoScrollEdge = 64;
  static const double _autoScrollMaxStep = 14;

  final ScrollController _horizontalController = ScrollController();
  final GlobalKey _viewportKey = GlobalKey();
  final ValueNotifier<ShiftReportColumn?> _draggingColumn =
      ValueNotifier<ShiftReportColumn?>(null);
  Timer? _autoScrollTimer;
  double? _dragGlobalX;

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _draggingColumn.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  void _onDragStarted(ShiftReportColumn column) {
    _draggingColumn.value = column;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _autoScrollStep(),
    );
  }

  void _onDragUpdate(Offset globalPosition) {
    _dragGlobalX = globalPosition.dx;
  }

  void _onDragEnded() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _dragGlobalX = null;
    _draggingColumn.value = null;
  }

  /// Mentre si trascina una colonna vicino al bordo la tabella scorre da sola:
  /// su telefono la tabella e' piu' larga dello schermo e senza questo non si
  /// potrebbero raggiungere le colonne fuori vista.
  void _autoScrollStep() {
    final x = _dragGlobalX;
    if (x == null || !_horizontalController.hasClients) {
      return;
    }
    final box = _viewportKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) {
      return;
    }
    final left = box.localToGlobal(Offset.zero).dx;
    final right = left + box.size.width;
    double step = 0;
    if (x < left + _autoScrollEdge) {
      step =
          -_autoScrollMaxStep *
          ((left + _autoScrollEdge - x) / _autoScrollEdge);
    } else if (x > right - _autoScrollEdge) {
      step =
          _autoScrollMaxStep *
          ((x - (right - _autoScrollEdge)) / _autoScrollEdge);
    }
    if (step == 0) {
      return;
    }
    final position = _horizontalController.position;
    final target =
        (position.pixels +
                step.clamp(-_autoScrollMaxStep * 1.5, _autoScrollMaxStep * 1.5))
            .clamp(position.minScrollExtent, position.maxScrollExtent);
    if (target != position.pixels) {
      _horizontalController.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final minTableWidth =
        widget.columnOrder.fold<double>(
          0,
          (sum, c) => sum + _ShiftReportTable.widthOf(c),
        ) +
        (_ShiftReportTable._rowGap * widget.columnOrder.length) +
        32;
    final tableWidth = math.max(
      MediaQuery.sizeOf(context).width * 0.68,
      minTableWidth,
    );

    final table = SizedBox(
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
              columnOrder: widget.columnOrder,
              labels: widget.labels,
              onMoveColumn: widget.onMoveColumn,
              draggingColumn: _draggingColumn,
              onDragStarted: _onDragStarted,
              onDragUpdate: _onDragUpdate,
              onDragEnded: _onDragEnded,
            ),
            const SizedBox(height: 12),
            for (final assignment in widget.assignments) ...[
              _ShiftReportTableRow(
                assignment: assignment,
                columnOrder: widget.columnOrder,
                dateLabel: dateFormat.format(assignment.shiftDate),
                userLabel: _displayUserName(assignment),
                profileLabel:
                    assignment.profileName ?? widget.defaultProfileLabel,
                startLabel: _formatTime(assignment.startTime),
                endLabel: _formatTime(assignment.endTime),
                typeLabel: assignment.isPublic
                    ? widget.teamLabel
                    : widget.privateTypeLabel,
              ),
              if (assignment != widget.assignments.last)
                const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );

    final scaledTable = widget.scale == 1.0
        ? table
        : SizedBox(
            width: tableWidth * widget.scale,
            child: FittedBox(
              fit: BoxFit.fitWidth,
              alignment: Alignment.topLeft,
              child: table,
            ),
          );

    if (widget.embedded) {
      return KeyedSubtree(
        key: _viewportKey,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: scaledTable,
        ),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        child: KeyedSubtree(
          key: _viewportKey,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: scaledTable,
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

/// Intestazione della tabella: ogni colonna si puo' trascinare su un'altra per
/// cambiare l'ordine.
///
/// - Web/desktop: si afferra l'intestazione e si trascina.
/// - Touch: si trascina subito dalla maniglia (⠿), oppure si tiene premuto
///   un attimo il titolo. Il resto dell'intestazione continua a far scorrere
///   la tabella in orizzontale.
class _ShiftReportTableHeader extends StatelessWidget {
  const _ShiftReportTableHeader({
    required this.columnOrder,
    required this.labels,
    required this.onMoveColumn,
    required this.draggingColumn,
    required this.onDragStarted,
    required this.onDragUpdate,
    required this.onDragEnded,
  });

  final List<ShiftReportColumn> columnOrder;
  final Map<ShiftReportColumn, String> labels;
  final void Function(ShiftReportColumn from, ShiftReportColumn to)
  onMoveColumn;
  final ValueNotifier<ShiftReportColumn?> draggingColumn;
  final ValueChanged<ShiftReportColumn> onDragStarted;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnded;

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
          for (final column in columnOrder)
            _ShiftHeaderCell(
              column: column,
              label: labels[column] ?? '',
              width: _ShiftReportTable.widthOf(column),
              onMoveColumn: onMoveColumn,
              draggingColumn: draggingColumn,
              onDragStarted: onDragStarted,
              onDragUpdate: onDragUpdate,
              onDragEnded: onDragEnded,
            ),
        ],
      ),
    );
  }
}

class _ShiftHeaderCell extends StatelessWidget {
  const _ShiftHeaderCell({
    required this.column,
    required this.label,
    required this.width,
    required this.onMoveColumn,
    required this.draggingColumn,
    required this.onDragStarted,
    required this.onDragUpdate,
    required this.onDragEnded,
  });

  /// Tempo di pressione per iniziare il trascinamento dal titolo su touch.
  static const Duration _touchHoldDelay = Duration(milliseconds: 250);

  final ShiftReportColumn column;
  final String label;
  final double width;
  final void Function(ShiftReportColumn from, ShiftReportColumn to)
  onMoveColumn;
  final ValueNotifier<ShiftReportColumn?> draggingColumn;
  final ValueChanged<ShiftReportColumn> onDragStarted;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnded;

  static bool get _isTouch {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return true;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return false;
    }
  }

  Widget _feedback(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: theme.colorScheme.bgNavbarSurface ?? theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          label.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.textColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _handle(BuildContext context, {required bool draggable}) {
    final icon = Padding(
      // Area di tocco piu' ampia della sola icona, per il dito.
      padding: EdgeInsets.symmetric(
        horizontal: draggable ? 6 : 0,
        vertical: draggable ? 6 : 0,
      ),
      child: Icon(
        Icons.drag_indicator_rounded,
        size: 16,
        color: Theme.of(context).colorScheme.descriptionColor,
      ),
    );
    if (!draggable) {
      return icon;
    }
    return Draggable<ShiftReportColumn>(
      data: column,
      feedback: _feedback(context),
      onDragStarted: () => onDragStarted(column),
      onDragUpdate: (details) => onDragUpdate(details.globalPosition),
      onDragEnd: (_) => onDragEnded(),
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final accent = colorScheme.bgNavbarbutton ?? colorScheme.primary;
    final touch = _isTouch;

    final title = Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textTheme.labelLarge?.copyWith(
        color: colorScheme.textColor,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.45,
      ),
    );

    Widget content() => SizedBox(
      width: width,
      child: Row(
        children: [
          // Su touch la maniglia e' l'unico punto che trascina subito.
          _handle(context, draggable: touch),
          const SizedBox(width: 2),
          Expanded(child: title),
        ],
      ),
    );

    return DragTarget<ShiftReportColumn>(
      onWillAcceptWithDetails: (details) => details.data != column,
      onAcceptWithDetails: (details) => onMoveColumn(details.data, column),
      builder: (context, candidates, _) {
        final highlighted = candidates.isNotEmpty;
        final cell = ValueListenableBuilder<ShiftReportColumn?>(
          valueListenable: draggingColumn,
          builder: (context, dragging, child) =>
              Opacity(opacity: dragging == column ? 0.3 : 1, child: child),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: highlighted ? accent : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: content(),
          ),
        );

        if (touch) {
          return LongPressDraggable<ShiftReportColumn>(
            data: column,
            delay: _touchHoldDelay,
            feedback: _feedback(context),
            onDragStarted: () => onDragStarted(column),
            onDragUpdate: (details) => onDragUpdate(details.globalPosition),
            onDragEnd: (_) => onDragEnded(),
            child: cell,
          );
        }
        return MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: Draggable<ShiftReportColumn>(
            data: column,
            feedback: _feedback(context),
            onDragStarted: () => onDragStarted(column),
            onDragUpdate: (details) => onDragUpdate(details.globalPosition),
            onDragEnd: (_) => onDragEnded(),
            child: cell,
          ),
        );
      },
    );
  }
}

class _ShiftReportTableRow extends StatelessWidget {
  const _ShiftReportTableRow({
    required this.assignment,
    required this.columnOrder,
    required this.dateLabel,
    required this.userLabel,
    required this.profileLabel,
    required this.startLabel,
    required this.endLabel,
    required this.typeLabel,
  });

  final ShiftAssignmentEntity assignment;
  final List<ShiftReportColumn> columnOrder;
  final String dateLabel;
  final String userLabel;
  final String profileLabel;
  final String startLabel;
  final String endLabel;
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

    Widget timeText(String value) => Text(
      value,
      style: textTheme.bodyMedium?.copyWith(
        color: colorScheme.textColor,
        fontWeight: FontWeight.w700,
      ),
    );

    Widget cellFor(ShiftReportColumn column) {
      switch (column) {
        case ShiftReportColumn.date:
          return Text(
            dateLabel,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.descriptionColor,
              fontWeight: FontWeight.w600,
            ),
          );
        case ShiftReportColumn.user:
          return Row(
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
          );
        case ShiftReportColumn.account:
        case ShiftReportColumn.duration:
          // Presenti solo nell'esportazione, non nella tabella a schermo.
          return const SizedBox.shrink();
        case ShiftReportColumn.profile:
          return _SoftBadge(
            label: profileLabel,
            foreground: colorScheme.textColor ?? Colors.black87,
            background: (colorScheme.textInvertedColor ?? Colors.white)
                .withValues(alpha: 0.92),
          );
        case ShiftReportColumn.start:
          return timeText(startLabel);
        case ShiftReportColumn.end:
          return timeText(endLabel);
        case ShiftReportColumn.type:
          return _SoftBadge(
            label: typeLabel,
            foreground: badgeColor,
            background: badgeColor.withValues(alpha: 0.14),
          );
        case ShiftReportColumn.note:
          return Text(
            hasNote ? note : '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.descriptionColor,
            ),
          );
      }
    }

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
          for (final column in columnOrder)
            _ShiftValueCell(
              width: _ShiftReportTable.widthOf(column),
              child: cellFor(column),
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
  const _UserInitialsBadge({required this.label});

  static const double size = 34;

  final String label;

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

/// Pulsante "dimensione testo" (icona TT + freccia) che apre il menu con i
/// livelli di zoom della tabella.
class _TableSizeButton extends StatelessWidget {
  const _TableSizeButton({
    required this.scale,
    required this.tooltip,
    required this.onChanged,
  });

  static const List<double> options = [1.0, 0.85, 0.7, 0.55, 0.35];

  final double scale;
  final String tooltip;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return PopupMenuButton<double>(
      tooltip: tooltip,
      initialValue: scale,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => [
        for (final option in options)
          CheckedPopupMenuItem<double>(
            value: option,
            checked: option == scale,
            child: Text('${(option * 100).round()}%'),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.bgNavbarSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                colorScheme.borderColor?.withValues(alpha: 0.5) ??
                Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.format_size_rounded,
              size: 20,
              color: colorScheme.textColor,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: colorScheme.descriptionColor,
            ),
          ],
        ),
      ),
    );
  }
}
