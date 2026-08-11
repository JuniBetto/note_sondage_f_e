import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_auto_plan_entity.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_auto_plan_preview/shift_auto_plan_preview_calendar_card.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_auto_plan_preview/shift_auto_plan_preview_day_sheet.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_auto_plan_preview/shift_auto_plan_preview_footer.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_auto_plan_preview/shift_auto_plan_preview_header_card.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_auto_plan_preview/shift_auto_plan_preview_legend_card.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_auto_plan_preview/shift_auto_plan_preview_summary_card.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_auto_plan_preview/shift_auto_plan_preview_warnings_card.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/theme.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';

class ShiftAutoPlanPreviewPage extends StatefulWidget {
  const ShiftAutoPlanPreviewPage({
    super.key,
    required this.request,
    required this.preview,
    required this.onConfirm,
    this.teamName,
    this.userLabelsById = const {},
    this.compact = false,
  });

  final ShiftAutoPlanRequestEntity request;
  final ShiftAutoPlanPreviewEntity preview;
  final Future<ShiftAutoPlanResultEntity> Function() onConfirm;
  final String? teamName;
  final Map<String, String> userLabelsById;
  final bool compact;

  static Future<ShiftAutoPlanResultEntity?> show(
    BuildContext context, {
    required ShiftAutoPlanRequestEntity request,
    required ShiftAutoPlanPreviewEntity preview,
    required Future<ShiftAutoPlanResultEntity> Function() onConfirm,
    String? teamName,
    Map<String, String> userLabelsById = const {},
    bool compact = false,
  }) {
    return Navigator.of(context).push<ShiftAutoPlanResultEntity>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ShiftAutoPlanPreviewPage(
          request: request,
          preview: preview,
          onConfirm: onConfirm,
          teamName: teamName,
          userLabelsById: userLabelsById,
          compact: compact,
        ),
      ),
    );
  }

  @override
  State<ShiftAutoPlanPreviewPage> createState() =>
      _ShiftAutoPlanPreviewPageState();
}

class _ShiftAutoPlanPreviewPageState extends State<ShiftAutoPlanPreviewPage> {
  bool _submitting = false;
  late DateTime _focusedMonth;

  bool get _compact =>
      widget.compact || MediaQuery.of(context).size.width < 720;

  AppLocalizations get _loc => AppLocalizations.of(context)!;

  String? get _displayTeamName {
    final trimmed = widget.teamName?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String get _requestTeamId => widget.request.teamId.trim();

  List<ShiftAutoPlanPreviewDayEntity> get _visiblePreviewDays {
    return widget.preview.days
        .map((day) {
          final items = day.items
              .where(_isVisiblePreviewItem)
              .toList(growable: false);
          if (items.isEmpty) {
            return null;
          }
          return ShiftAutoPlanPreviewDayEntity(date: day.date, items: items);
        })
        .whereType<ShiftAutoPlanPreviewDayEntity>()
        .toList(growable: false);
  }

  int get _visibleCreatedAssignmentsCount =>
      _countVisibleActions(ShiftAutoPlanPreviewAction.create);

  int get _visiblePreservedAssignmentsCount =>
      _countVisibleActions(ShiftAutoPlanPreviewAction.preserve);

  int get _visibleDeletedAssignmentsCount =>
      _countVisibleActions(ShiftAutoPlanPreviewAction.delete);

  List<ShiftAssignmentEntity> get _calendarAssignments {
    final items = _visiblePreviewDays
        .expand((day) => day.items)
        .map((item) => _resolveAssignmentUserLabel(item.assignment))
        .toList();
    items.sort((left, right) {
      final byDate = left.shiftDate.compareTo(right.shiftDate);
      if (byDate != 0) {
        return byDate;
      }
      final byStartHour = left.startTime.hour.compareTo(right.startTime.hour);
      if (byStartHour != 0) {
        return byStartHour;
      }
      return left.startTime.minute.compareTo(right.startTime.minute);
    });
    return items;
  }

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(
      widget.request.from.year,
      widget.request.from.month,
      1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = widget.preview;
    final colorScheme = theme.colorScheme;
    final appBarBackground =
        colorScheme.bgNavbarSurface ?? theme.scaffoldBackgroundColor;
    final appBarForeground = colorScheme.textColor ?? colorScheme.onSurface;

    return Scaffold(
      backgroundColor: colorScheme.bgSurface ?? theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appBarBackground,
        foregroundColor: appBarForeground,
        systemOverlayStyle: AppTheme.overlayStyleForBackground(
          appBarBackground,
        ),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leadingWidth: 56,
        centerTitle: true,
        title: Text(
          _loc.shiftAutoPlanPreviewTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            color: appBarForeground,
            fontWeight: FontWeight.w700,
            fontSize: _compact ? 20 : 22,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      _compact ? 12 : 24,
                      _compact ? 12 : 20,
                      _compact ? 12 : 24,
                      12,
                    ),
                    children: [
                      ShiftAutoPlanPreviewHeaderCard(
                        compact: _compact,
                        fullyFeasible: preview.fullyFeasible,
                        statusLabel: preview.fullyFeasible
                            ? _loc.shiftAutoPlanPreviewStatusFeasible
                            : _loc.shiftAutoPlanPreviewStatusNeedsReview,
                        dateRangeLabel: _formatDateRange(
                          widget.request.from,
                          widget.request.to,
                        ),
                        description: preview.fullyFeasible
                            ? _loc.shiftAutoPlanPreviewReadyDescription
                            : _loc.shiftAutoPlanPreviewNeedsReviewDescription,
                      ),
                      const SizedBox(height: 12),
                      ShiftAutoPlanPreviewSummaryCard(
                        compact: _compact,
                        title: _loc.shiftAutoPlanPreviewSummaryTitle,
                        metrics: [
                          ShiftAutoPlanPreviewSummaryMetric(
                            label: _loc.shiftAutoPlanPreviewNewShifts,
                            value: _visibleCreatedAssignmentsCount,
                          ),
                          ShiftAutoPlanPreviewSummaryMetric(
                            label: _loc.shiftAutoPlanPreviewPreserved,
                            value: _visiblePreservedAssignmentsCount,
                          ),
                          ShiftAutoPlanPreviewSummaryMetric(
                            label: _loc.shiftAutoPlanPreviewToRemove,
                            value: _visibleDeletedAssignmentsCount,
                          ),
                          ShiftAutoPlanPreviewSummaryMetric(
                            label: _loc.shiftAutoPlanPreviewUncoveredSlots,
                            value: preview.uncoveredSlotsCount,
                            emphasize: preview.uncoveredSlotsCount > 0,
                          ),
                        ],
                      ),
                      if (preview.warnings.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ShiftAutoPlanPreviewWarningsCard(
                          compact: _compact,
                          title: _loc.shiftAutoPlanPreviewWarningsTitle,
                          warnings: preview.warnings
                              .map(_formatWarning)
                              .toList(growable: false),
                        ),
                      ],
                      const SizedBox(height: 12),
                      ShiftAutoPlanPreviewLegendCard(
                        compact: _compact,
                        title: _loc.shiftAutoPlanPreviewCalendarTitle,
                        description:
                            _loc.shiftAutoPlanPreviewCalendarDescription,
                        createLabel: _actionLabel(
                          ShiftAutoPlanPreviewAction.create,
                        ),
                        preserveLabel: _actionLabel(
                          ShiftAutoPlanPreviewAction.preserve,
                        ),
                        deleteLabel: _actionLabel(
                          ShiftAutoPlanPreviewAction.delete,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ShiftAutoPlanPreviewCalendarCard(
                        compact: _compact,
                        assignments: _calendarAssignments,
                        focusedMonth: _focusedMonth,
                        onMonthChanged: (value) {
                          setState(() {
                            _focusedMonth = DateTime(
                              value.year,
                              value.month,
                              1,
                            );
                          });
                        },
                        onDayTap: _openDayPreview,
                        emptyMessage: _loc.shiftAutoPlanPreviewEmpty,
                      ),
                    ],
                  ),
                ),
                ShiftAutoPlanPreviewFooter(
                  compact: _compact,
                  submitting: _submitting,
                  canConfirm: preview.fullyFeasible,
                  backLabel: _loc.shiftAutoPlanPreviewBack,
                  confirmLabel: _loc.shiftAutoPlanPreviewConfirmCreate,
                  onBack: () {
                    Navigator.of(context).maybePop();
                  },
                  onConfirm: _confirm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    if (_submitting) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await widget.onConfirm();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showResolvedError(
        context,
        error,
        fallback: _loc.shiftAutoPlanPreviewConfirmError,
      );
      setState(() => _submitting = false);
    }
  }

  Future<void> _openDayPreview(DateTime date) async {
    final items = _itemsForDate(date);
    if (items.isEmpty) {
      return;
    }

    await showShiftAutoPlanPreviewDaySheet(
      context,
      compact: _compact,
      title: _formatDay(date),
      description: _loc.shiftAutoPlanPreviewDayDescription,
      items: items
          .map(
            (item) => ShiftAutoPlanPreviewDaySheetItem(
              title: ((item.assignment.profileName ?? '').trim().isEmpty)
                  ? _loc.shiftAutoPlanPreviewDefaultShiftTitle
                  : item.assignment.profileName!.trim(),
              subtitle: [
                if ((_resolvedUserLabel(item.assignment) ?? '').isNotEmpty)
                  _resolvedUserLabel(item.assignment)!,
                _formatTimeRange(_resolveAssignmentUserLabel(item.assignment)),
              ].join(' • '),
              action: item.action,
            ),
          )
          .toList(growable: false),
      actionLabelBuilder: _actionLabel,
    );
  }

  List<ShiftAutoPlanPreviewAssignmentEntity> _itemsForDate(DateTime date) {
    for (final day in _visiblePreviewDays) {
      if (_isSameDay(day.date, date)) {
        final items = day.items
            .map(
              (item) => ShiftAutoPlanPreviewAssignmentEntity(
                action: item.action,
                assignment: _resolveAssignmentUserLabel(item.assignment),
              ),
            )
            .toList();
        items.sort((left, right) {
          final byStartHour = left.assignment.startTime.hour.compareTo(
            right.assignment.startTime.hour,
          );
          if (byStartHour != 0) {
            return byStartHour;
          }
          final byStartMinute = left.assignment.startTime.minute.compareTo(
            right.assignment.startTime.minute,
          );
          if (byStartMinute != 0) {
            return byStartMinute;
          }
          return left.assignment.endTime.hour.compareTo(
            right.assignment.endTime.hour,
          );
        });
        return items;
      }
    }
    return const [];
  }

  bool _isVisiblePreviewItem(ShiftAutoPlanPreviewAssignmentEntity item) {
    if (item.action == ShiftAutoPlanPreviewAction.create) {
      return true;
    }
    final assignmentTeamId = item.assignment.teamId?.trim();
    if (assignmentTeamId == null || assignmentTeamId.isEmpty) {
      return false;
    }
    return assignmentTeamId == _requestTeamId;
  }

  int _countVisibleActions(ShiftAutoPlanPreviewAction action) {
    var total = 0;
    for (final day in _visiblePreviewDays) {
      for (final item in day.items) {
        if (item.action == action) {
          total++;
        }
      }
    }
    return total;
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String _actionLabel(ShiftAutoPlanPreviewAction action) {
    return switch (action) {
      ShiftAutoPlanPreviewAction.create => _loc.shiftAutoPlanPreviewActionNew,
      ShiftAutoPlanPreviewAction.preserve =>
        _loc.shiftAutoPlanPreviewActionKeep,
      ShiftAutoPlanPreviewAction.delete =>
        _loc.shiftAutoPlanPreviewActionRemove,
    };
  }

  String _formatDateRange(DateTime from, DateTime to) {
    final format = DateFormat('dd/MM/yyyy');
    return '${format.format(from)} - ${format.format(to)}';
  }

  String _formatWarning(String warning) {
    var formatted = warning;
    final teamName = _displayTeamName;
    if (teamName != null) {
      formatted = formatted.replaceAll(widget.request.teamId, teamName);
    }
    for (final entry in widget.userLabelsById.entries) {
      if (entry.key.trim().isEmpty || entry.value.trim().isEmpty) {
        continue;
      }
      formatted = formatted.replaceAll(entry.key, entry.value);
    }
    return formatted;
  }

  String _formatDay(DateTime date) {
    final format = DateFormat.yMMMMEEEEd(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final value = format.format(date);
    return value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
  }

  String _formatTimeRange(ShiftAssignmentEntity assignment) {
    final material = MaterialLocalizations.of(context);
    final start = material.formatTimeOfDay(
      assignment.startTime,
      alwaysUse24HourFormat: true,
    );
    final end = material.formatTimeOfDay(
      assignment.endTime,
      alwaysUse24HourFormat: true,
    );
    final suffix = assignment.overnight ? ' +1' : '';
    return '$start - $end$suffix';
  }

  ShiftAssignmentEntity _resolveAssignmentUserLabel(
    ShiftAssignmentEntity assignment,
  ) {
    final resolvedLabel = _resolvedUserLabel(assignment);
    if (resolvedLabel == null) {
      return assignment;
    }
    return assignment.copyWith(userName: resolvedLabel);
  }

  String? _resolvedUserLabel(ShiftAssignmentEntity assignment) {
    final existingName = assignment.userName?.trim();
    if (existingName != null && existingName.isNotEmpty) {
      return existingName;
    }

    final mappedLabel = widget.userLabelsById[assignment.userId]?.trim();
    if (mappedLabel != null && mappedLabel.isNotEmpty) {
      return mappedLabel;
    }

    return null;
  }
}
