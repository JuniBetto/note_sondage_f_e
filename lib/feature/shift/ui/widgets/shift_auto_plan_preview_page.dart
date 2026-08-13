import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_auto_plan_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_auto_plan_preview/shift_auto_plan_preview_assignment_editor_dialog.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_auto_plan_preview/shift_auto_plan_preview_calendar_card.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_auto_plan_preview/shift_auto_plan_preview_day_sheet.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_auto_plan_preview/shift_auto_plan_preview_footer.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_auto_plan_preview/shift_auto_plan_preview_header_card.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_auto_plan_preview/shift_auto_plan_preview_legend_card.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_auto_plan_preview/shift_auto_plan_preview_summary_card.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_auto_plan_preview/shift_auto_plan_preview_warnings_card.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/theme.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';

String _localizedPreviewPageText(
  BuildContext context, {
  required String it,
  required String en,
  String? fr,
  String? es,
}) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'it':
      return it;
    case 'fr':
      return fr ?? en;
    case 'es':
      return es ?? en;
    default:
      return en;
  }
}

class ShiftAutoPlanPreviewPage extends StatefulWidget {
  const ShiftAutoPlanPreviewPage({
    super.key,
    required this.request,
    required this.preview,
    required this.availableProfiles,
    required this.availableTeamMembers,
    required this.onRecalculate,
    required this.onConfirm,
    this.teamName,
    this.userLabelsById = const {},
    this.compact = false,
  });

  final ShiftAutoPlanRequestEntity request;
  final ShiftAutoPlanPreviewEntity preview;
  final List<ShiftProfileEntity> availableProfiles;
  final List<TeamMemberforView> availableTeamMembers;
  final Future<ShiftAutoPlanPreviewEntity> Function(
    String snapshotToken,
    List<ShiftAutoPlanDraftAssignmentEntity> draftAssignments,
  )
  onRecalculate;
  final Future<ShiftAutoPlanResultEntity> Function(String snapshotToken)
  onConfirm;
  final String? teamName;
  final Map<String, String> userLabelsById;
  final bool compact;

  static Future<ShiftAutoPlanPreviewConfirmationResult?> show(
    BuildContext context, {
    required ShiftAutoPlanRequestEntity request,
    required ShiftAutoPlanPreviewEntity preview,
    required List<ShiftProfileEntity> availableProfiles,
    required List<TeamMemberforView> availableTeamMembers,
    required Future<ShiftAutoPlanPreviewEntity> Function(
      String snapshotToken,
      List<ShiftAutoPlanDraftAssignmentEntity> draftAssignments,
    )
    onRecalculate,
    required Future<ShiftAutoPlanResultEntity> Function(String snapshotToken)
    onConfirm,
    String? teamName,
    Map<String, String> userLabelsById = const {},
    bool compact = false,
  }) {
    return Navigator.of(context).push<ShiftAutoPlanPreviewConfirmationResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ShiftAutoPlanPreviewPage(
          request: request,
          preview: preview,
          availableProfiles: availableProfiles,
          availableTeamMembers: availableTeamMembers,
          onRecalculate: onRecalculate,
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
  bool _recalculating = false;
  bool _hasPendingManualChanges = false;
  late DateTime _focusedMonth;
  late ShiftAutoPlanPreviewEntity _currentPreview;
  late String _currentSnapshotToken;
  late List<ShiftAutoPlanDraftAssignmentEntity> _draftAssignments;

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
    return _effectivePreviewDays
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

  List<ShiftAutoPlanPreviewDayEntity> get _effectivePreviewDays {
    final sourceItems = _currentPreview.days.expand((day) => day.items);
    final remainingDrafts = <String, ShiftAutoPlanDraftAssignmentEntity>{
      for (final draft in _draftAssignments) draft.previewItemId: draft,
    };
    final itemsByDay = <String, List<ShiftAutoPlanPreviewAssignmentEntity>>{};
    final dayDates = <String, DateTime>{};

    void addItem(ShiftAutoPlanPreviewAssignmentEntity item) {
      final date = DateTime(
        item.assignment.shiftDate.year,
        item.assignment.shiftDate.month,
        item.assignment.shiftDate.day,
      );
      final key = '${date.year}-${date.month}-${date.day}';
      dayDates[key] = date;
      itemsByDay
          .putIfAbsent(key, () => <ShiftAutoPlanPreviewAssignmentEntity>[])
          .add(item);
    }

    for (final sourceItem in sourceItems) {
      final draft = remainingDrafts.remove(sourceItem.previewItemId);
      if (draft != null) {
        addItem(
          ShiftAutoPlanPreviewAssignmentEntity(
            previewItemId: draft.previewItemId,
            sourceAssignmentId:
                draft.sourceAssignmentId ?? sourceItem.sourceAssignmentId,
            action: _effectiveActionForDraftItem(sourceItem),
            assignment: _resolveAssignmentUserLabel(draft.assignment),
          ),
        );
        continue;
      }

      final removedItem = _removedSourceItem(sourceItem);
      if (removedItem != null) {
        addItem(removedItem);
      }
    }

    for (final draft in remainingDrafts.values) {
      addItem(
        ShiftAutoPlanPreviewAssignmentEntity(
          previewItemId: draft.previewItemId,
          sourceAssignmentId: draft.sourceAssignmentId,
          action: ShiftAutoPlanPreviewAction.create,
          assignment: _resolveAssignmentUserLabel(draft.assignment),
        ),
      );
    }

    final sortedKeys = dayDates.keys.toList()
      ..sort((left, right) => dayDates[left]!.compareTo(dayDates[right]!));
    return sortedKeys
        .map((key) {
          final items =
              itemsByDay[key] ?? const <ShiftAutoPlanPreviewAssignmentEntity>[];
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
            final byAction = left.action.index.compareTo(right.action.index);
            if (byAction != 0) {
              return byAction;
            }
            return left.previewItemId.compareTo(right.previewItemId);
          });
          return ShiftAutoPlanPreviewDayEntity(
            date: dayDates[key]!,
            items: List<ShiftAutoPlanPreviewAssignmentEntity>.unmodifiable(
              items,
            ),
          );
        })
        .toList(growable: false);
  }

  List<ShiftAutoPlanIssueEntity> get _blockingIssues => _currentPreview.issues
      .where((issue) => issue.severity == ShiftAutoPlanIssueSeverity.blocking)
      .toList(growable: false);

  List<ShiftAutoPlanIssueEntity> get _warningIssues => _currentPreview.issues
      .where((issue) => issue.severity == ShiftAutoPlanIssueSeverity.warning)
      .toList(growable: false);

  int get _visibleCreatedAssignmentsCount =>
      _countVisibleActions(ShiftAutoPlanPreviewAction.create);

  int get _visiblePreservedAssignmentsCount =>
      _countVisibleActions(ShiftAutoPlanPreviewAction.preserve);

  int get _visibleDeletedAssignmentsCount =>
      _countVisibleActions(ShiftAutoPlanPreviewAction.delete);

  bool get _canConfirm =>
      !_hasPendingManualChanges &&
      !_submitting &&
      _currentPreview.fullyFeasible;

  bool get _canRecalculate =>
      _hasPendingManualChanges && !_recalculating && !_submitting;

  String get _confirmLabel {
    if (_warningIssues.isNotEmpty && _blockingIssues.isEmpty) {
      return _localizedPreviewPageText(
        context,
        it: 'Conferma con discrepanze',
        en: 'Confirm with warnings',
        fr: 'Confirmer avec ecarts',
        es: 'Confirmar con discrepancias',
      );
    }
    return _loc.shiftAutoPlanPreviewConfirmCreate;
  }

  List<ShiftAssignmentEntity> get _calendarAssignments {
    final items = _visiblePreviewDays
        .expand((day) => day.items)
        .where((item) => item.action != ShiftAutoPlanPreviewAction.delete)
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

  ShiftAutoPlanPreviewAction _effectiveActionForDraftItem(
    ShiftAutoPlanPreviewAssignmentEntity sourceItem,
  ) {
    if (sourceItem.action == ShiftAutoPlanPreviewAction.delete) {
      return ShiftAutoPlanPreviewAction.preserve;
    }
    return sourceItem.action;
  }

  ShiftAutoPlanPreviewAssignmentEntity? _removedSourceItem(
    ShiftAutoPlanPreviewAssignmentEntity sourceItem,
  ) {
    if (sourceItem.action == ShiftAutoPlanPreviewAction.delete) {
      return ShiftAutoPlanPreviewAssignmentEntity(
        previewItemId: sourceItem.previewItemId,
        sourceAssignmentId: sourceItem.sourceAssignmentId,
        action: ShiftAutoPlanPreviewAction.delete,
        assignment: _resolveAssignmentUserLabel(sourceItem.assignment),
      );
    }

    final hasPersistedSource =
        (sourceItem.sourceAssignmentId?.trim().isNotEmpty ?? false) ||
        sourceItem.action == ShiftAutoPlanPreviewAction.preserve;
    if (!hasPersistedSource) {
      return null;
    }

    return ShiftAutoPlanPreviewAssignmentEntity(
      previewItemId: sourceItem.previewItemId,
      sourceAssignmentId: sourceItem.sourceAssignmentId,
      action: ShiftAutoPlanPreviewAction.delete,
      assignment: _resolveAssignmentUserLabel(sourceItem.assignment),
    );
  }

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(
      widget.request.from.year,
      widget.request.from.month,
      1,
    );
    _currentPreview = widget.preview;
    _currentSnapshotToken = widget.preview.snapshotToken;
    _draftAssignments = _draftAssignmentsFromPreview(widget.preview);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                        fullyFeasible: _currentPreview.fullyFeasible,
                        statusLabel: _currentPreview.fullyFeasible
                            ? _loc.shiftAutoPlanPreviewStatusFeasible
                            : _loc.shiftAutoPlanPreviewStatusNeedsReview,
                        dateRangeLabel: _formatDateRange(
                          widget.request.from,
                          widget.request.to,
                        ),
                        description: _hasPendingManualChanges
                            ? _localizedPreviewPageText(
                                context,
                                it: 'Hai modifiche manuali in bozza. Ricalcola la preview per verificare il nuovo snapshot prima della conferma.',
                                en: 'You have pending manual edits. Recalculate the preview to validate the new snapshot before confirming.',
                                fr: 'Des modifications manuelles sont en attente. Recalculez l\'aperçu avant de confirmer.',
                                es: 'Hay cambios manuales pendientes. Recalcula la vista previa antes de confirmar.',
                              )
                            : (_currentPreview.fullyFeasible
                                  ? _loc.shiftAutoPlanPreviewReadyDescription
                                  : _loc.shiftAutoPlanPreviewNeedsReviewDescription),
                      ),
                      if (_hasPendingManualChanges) ...[
                        const SizedBox(height: 12),
                        _PendingChangesCard(
                          compact: _compact,
                          title: _localizedPreviewPageText(
                            context,
                            it: 'Modifiche manuali in attesa',
                            en: 'Pending manual changes',
                            fr: 'Modifications en attente',
                            es: 'Cambios manuales pendientes',
                          ),
                          description: _localizedPreviewPageText(
                            context,
                            it: 'Le modifiche locali non sono ancora state validate. Usa "Ricalcola" per generare un nuovo snapshot coerente.',
                            en: 'Local edits have not been validated yet. Use "Recalculate" to generate a new consistent snapshot.',
                            fr: 'Les modifications locales ne sont pas encore validees. Utilisez "Recalculer".',
                            es: 'Los cambios locales aun no han sido validados. Usa "Recalcular".',
                          ),
                        ),
                      ],
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
                            value: _currentPreview.uncoveredSlotsCount,
                            emphasize: _currentPreview.uncoveredSlotsCount > 0,
                          ),
                        ],
                      ),
                      if (_blockingIssues.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ShiftAutoPlanPreviewWarningsCard(
                          compact: _compact,
                          title: _localizedPreviewPageText(
                            context,
                            it: 'Problemi bloccanti',
                            en: 'Blocking issues',
                            fr: 'Problemes bloquants',
                            es: 'Problemas bloqueantes',
                          ),
                          warnings: _blockingIssues
                              .map((issue) => _formatMessage(issue.message))
                              .toList(growable: false),
                        ),
                      ],
                      if (_warningIssues.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ShiftAutoPlanPreviewWarningsCard(
                          compact: _compact,
                          title: _localizedPreviewPageText(
                            context,
                            it: 'Discrepanze e warning',
                            en: 'Warnings and discrepancies',
                            fr: 'Avertissements et ecarts',
                            es: 'Advertencias y discrepancias',
                          ),
                          warnings: _warningIssues
                              .map((issue) => _formatMessage(issue.message))
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
                  submitting: _submitting || _recalculating,
                  canConfirm: _canConfirm,
                  canRecalculate: _canRecalculate,
                  backLabel: _loc.shiftAutoPlanPreviewBack,
                  recalculateLabel: _localizedPreviewPageText(
                    context,
                    it: 'Ricalcola',
                    en: 'Recalculate',
                    fr: 'Recalculer',
                    es: 'Recalcular',
                  ),
                  confirmLabel: _confirmLabel,
                  onBack: () {
                    Navigator.of(context).maybePop();
                  },
                  onRecalculate: _recalculatePreview,
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
    if (!_canConfirm) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await widget.onConfirm(_currentSnapshotToken);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(
        ShiftAutoPlanPreviewConfirmationResult(
          result: result,
          assignments: List<ShiftAssignmentEntity>.unmodifiable(
            _calendarAssignments,
          ),
        ),
      );
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

  Future<void> _recalculatePreview() async {
    if (!_canRecalculate) {
      return;
    }
    setState(() => _recalculating = true);
    try {
      final preview = await widget.onRecalculate(
        _currentSnapshotToken,
        _draftAssignments,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _currentPreview = preview;
        _currentSnapshotToken = preview.snapshotToken;
        _draftAssignments = _draftAssignmentsFromPreview(preview);
        _hasPendingManualChanges = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showResolvedError(
        context,
        error,
        fallback: _localizedPreviewPageText(
          context,
          it: 'Impossibile ricalcolare la preview manuale.',
          en: 'Unable to recalculate the edited preview.',
          fr: 'Impossible de recalculer l\'aperçu.',
          es: 'No se pudo recalcular la vista previa.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _recalculating = false);
      }
    }
  }

  Future<void> _openDayPreview(DateTime date) async {
    final items = _itemsForDate(date);
    if (items.isEmpty && !_isDateInsideRequest(date)) {
      return;
    }

    await showShiftAutoPlanPreviewDaySheet(
      context,
      compact: _compact,
      title: _formatDay(date),
      description: _localizedPreviewPageText(
        context,
        it: 'Puoi modificare la proposta locale del giorno, poi ricalcolare la preview per validarla.',
        en: 'You can edit the local proposal for this day, then recalculate the preview to validate it.',
        fr: 'Vous pouvez modifier la proposition locale puis recalculer l\'aperçu.',
        es: 'Puedes editar la propuesta local y luego recalcular la vista previa.',
      ),
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
              onEdit: item.action == ShiftAutoPlanPreviewAction.delete
                  ? null
                  : () => unawaited(_editPreviewItemFromDaySheet(item, date)),
              onRemove: item.action == ShiftAutoPlanPreviewAction.delete
                  ? null
                  : () => unawaited(
                      _removePreviewItemFromDaySheet(item.previewItemId, date),
                    ),
              onRestore: item.action == ShiftAutoPlanPreviewAction.delete
                  ? () => unawaited(_restorePreviewItemFromDaySheet(item, date))
                  : null,
              editLabel: _localizedPreviewPageText(
                context,
                it: 'Modifica',
                en: 'Edit',
                fr: 'Modifier',
                es: 'Editar',
              ),
              removeLabel: _localizedPreviewPageText(
                context,
                it: 'Rimuovi',
                en: 'Remove',
                fr: 'Retirer',
                es: 'Quitar',
              ),
              restoreLabel: _localizedPreviewPageText(
                context,
                it: 'Ripristina',
                en: 'Restore',
                fr: 'Restaurer',
                es: 'Restaurar',
              ),
            ),
          )
          .toList(growable: false),
      actionLabelBuilder: _actionLabel,
      primaryActionLabel: _isDateInsideRequest(date)
          ? _localizedPreviewPageText(
              context,
              it: 'Aggiungi turno alla bozza',
              en: 'Add draft shift',
              fr: 'Ajouter un quart',
              es: 'Agregar turno',
            )
          : null,
      onPrimaryAction: _isDateInsideRequest(date)
          ? () => unawaited(_addDraftShiftForDateFromDaySheet(date))
          : null,
    );
  }

  Future<void> _editPreviewItemFromDaySheet(
    ShiftAutoPlanPreviewAssignmentEntity item,
    DateTime date,
  ) async {
    await _runDaySheetAction(date, () => _editPreviewItem(item, date));
  }

  Future<void> _removePreviewItemFromDaySheet(
    String previewItemId,
    DateTime date,
  ) async {
    await _runDaySheetAction(date, () async {
      _removePreviewItem(previewItemId);
    });
  }

  Future<void> _restorePreviewItemFromDaySheet(
    ShiftAutoPlanPreviewAssignmentEntity item,
    DateTime date,
  ) async {
    await _runDaySheetAction(date, () async {
      _restoreDeletedItem(item);
    });
  }

  Future<void> _addDraftShiftForDateFromDaySheet(DateTime date) async {
    await _runDaySheetAction(date, () => _addDraftShiftForDate(date));
  }

  Future<void> _runDaySheetAction(
    DateTime date,
    Future<void> Function() action,
  ) async {
    await Navigator.of(context).maybePop();
    if (!mounted) {
      return;
    }
    await Future<void>.delayed(Duration.zero);
    await action();
    if (!mounted) {
      return;
    }
    if (_itemsForDate(date).isEmpty && !_isDateInsideRequest(date)) {
      return;
    }
    await _openDayPreview(date);
  }

  Future<void> _editPreviewItem(
    ShiftAutoPlanPreviewAssignmentEntity item,
    DateTime date,
  ) async {
    final existingDraft = _draftAssignments
        .where((draft) => draft.previewItemId == item.previewItemId)
        .firstOrNull;
    final initialDraft =
        existingDraft ??
        ShiftAutoPlanDraftAssignmentEntity(
          previewItemId: item.previewItemId,
          sourceAssignmentId: item.sourceAssignmentId,
          assignment: _resolveAssignmentUserLabel(item.assignment),
        );
    final result = await showShiftAutoPlanPreviewAssignmentEditorDialog(
      context,
      teamMembers: widget.availableTeamMembers,
      profiles: widget.availableProfiles,
      shiftDate: date,
      initialAssignment: initialDraft,
    );
    if (result == null || !mounted) {
      return;
    }
    _upsertDraftAssignment(result.assignment);
  }

  Future<void> _addDraftShiftForDate(DateTime date) async {
    final result = await showShiftAutoPlanPreviewAssignmentEditorDialog(
      context,
      teamMembers: widget.availableTeamMembers,
      profiles: widget.availableProfiles,
      shiftDate: date,
    );
    if (result == null || !mounted) {
      return;
    }
    _upsertDraftAssignment(
      result.assignment.copyWith(
        assignment: result.assignment.assignment.copyWith(
          teamId: widget.request.teamId,
        ),
      ),
    );
  }

  void _removePreviewItem(String previewItemId) {
    setState(() {
      _draftAssignments = _draftAssignments
          .where((draft) => draft.previewItemId != previewItemId)
          .toList(growable: false);
      _hasPendingManualChanges = true;
    });
  }

  void _restoreDeletedItem(ShiftAutoPlanPreviewAssignmentEntity item) {
    final restored = ShiftAutoPlanDraftAssignmentEntity(
      previewItemId: item.previewItemId,
      sourceAssignmentId: item.sourceAssignmentId,
      assignment: _resolveAssignmentUserLabel(item.assignment),
    );
    _upsertDraftAssignment(restored);
  }

  void _upsertDraftAssignment(ShiftAutoPlanDraftAssignmentEntity assignment) {
    setState(() {
      _draftAssignments =
          [
            ..._draftAssignments.where(
              (draft) => draft.previewItemId != assignment.previewItemId,
            ),
            assignment,
          ]..sort((left, right) {
            final byDate = left.assignment.shiftDate.compareTo(
              right.assignment.shiftDate,
            );
            if (byDate != 0) {
              return byDate;
            }
            final byHour = left.assignment.startTime.hour.compareTo(
              right.assignment.startTime.hour,
            );
            if (byHour != 0) {
              return byHour;
            }
            return left.assignment.startTime.minute.compareTo(
              right.assignment.startTime.minute,
            );
          });
      _hasPendingManualChanges = true;
    });
  }

  List<ShiftAutoPlanDraftAssignmentEntity> _draftAssignmentsFromPreview(
    ShiftAutoPlanPreviewEntity preview,
  ) {
    return preview.days
        .expand((day) => day.items)
        .where((item) => item.action != ShiftAutoPlanPreviewAction.delete)
        .map(
          (item) => ShiftAutoPlanDraftAssignmentEntity(
            previewItemId: item.previewItemId,
            sourceAssignmentId: item.sourceAssignmentId,
            assignment: _resolveAssignmentUserLabel(item.assignment),
          ),
        )
        .toList(growable: false);
  }

  List<ShiftAutoPlanPreviewAssignmentEntity> _itemsForDate(DateTime date) {
    for (final day in _visiblePreviewDays) {
      if (_isSameDay(day.date, date)) {
        final items = day.items
            .map(
              (item) => ShiftAutoPlanPreviewAssignmentEntity(
                previewItemId: item.previewItemId,
                sourceAssignmentId: item.sourceAssignmentId,
                action: item.action,
                assignment: _resolveAssignmentUserLabel(item.assignment),
              ),
            )
            .toList(growable: false);
        return items..sort((left, right) {
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
      }
    }
    return const <ShiftAutoPlanPreviewAssignmentEntity>[];
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

  bool _isDateInsideRequest(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final from = DateTime(
      widget.request.from.year,
      widget.request.from.month,
      widget.request.from.day,
    );
    final to = DateTime(
      widget.request.to.year,
      widget.request.to.month,
      widget.request.to.day,
    );
    return !normalized.isBefore(from) && !normalized.isAfter(to);
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

  String _formatMessage(String message) {
    var formatted = message;
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

class ShiftAutoPlanPreviewConfirmationResult {
  const ShiftAutoPlanPreviewConfirmationResult({
    required this.result,
    required this.assignments,
  });

  final ShiftAutoPlanResultEntity result;
  final List<ShiftAssignmentEntity> assignments;
}

class _PendingChangesCard extends StatelessWidget {
  const _PendingChangesCard({
    required this.compact,
    required this.title,
    required this.description,
  });

  final bool compact;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(description, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

extension on Iterable<ShiftAutoPlanDraftAssignmentEntity> {
  ShiftAutoPlanDraftAssignmentEntity? get firstOrNull => isEmpty ? null : first;
}
