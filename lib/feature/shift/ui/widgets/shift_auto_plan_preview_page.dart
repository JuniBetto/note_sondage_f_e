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
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/theme/theme.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';

class ShiftAutoPlanPreviewPage extends StatefulWidget {
  const ShiftAutoPlanPreviewPage({
    super.key,
    required this.request,
    required this.preview,
    required this.onConfirm,
    this.teamName,
    this.compact = false,
  });

  final ShiftAutoPlanRequestEntity request;
  final ShiftAutoPlanPreviewEntity preview;
  final Future<ShiftAutoPlanResultEntity> Function() onConfirm;
  final String? teamName;
  final bool compact;

  static Future<ShiftAutoPlanResultEntity?> show(
    BuildContext context, {
    required ShiftAutoPlanRequestEntity request,
    required ShiftAutoPlanPreviewEntity preview,
    required Future<ShiftAutoPlanResultEntity> Function() onConfirm,
    String? teamName,
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

  String get _languageCode =>
      Localizations.localeOf(context).languageCode.toLowerCase();

  bool get _compact =>
      widget.compact || MediaQuery.of(context).size.width < 720;

  String? get _displayTeamName {
    final trimmed = widget.teamName?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  List<ShiftAssignmentEntity> get _calendarAssignments {
    final items = widget.preview.days
        .expand((day) => day.items)
        .map((item) => item.assignment)
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
          _t(
            it: 'Anteprima Auto Planner',
            en: 'Auto Planner preview',
            fr: 'Apercu Auto Planner',
            es: 'Vista previa Auto Planner',
          ),
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
                            ? _t(
                                it: 'Fattibile',
                                en: 'Feasible',
                                fr: 'Faisable',
                                es: 'Factible',
                              )
                            : _t(
                                it: 'Da correggere',
                                en: 'Needs review',
                                fr: 'A verifier',
                                es: 'Revisar',
                              ),
                        dateRangeLabel: _formatDateRange(
                          widget.request.from,
                          widget.request.to,
                        ),
                        description: preview.fullyFeasible
                            ? _t(
                                it: 'Questa anteprima e pronta: il calendario qui sotto mostra i turni previsti prima della conferma finale.',
                                en: 'This preview is ready: the calendar below shows the planned shifts before final confirmation.',
                                fr: 'Cet apercu est pret : le calendrier ci-dessous montre les shifts prevus avant la confirmation finale.',
                                es: 'Esta vista previa esta lista: el calendario de abajo muestra los turnos previstos antes de la confirmacion final.',
                              )
                            : _t(
                                it: 'L anteprima mostra problemi di copertura o vincoli. Finche non e fattibile, la conferma resta bloccata.',
                                en: 'This preview shows coverage or constraint issues. Confirmation stays disabled until it is fully feasible.',
                                fr: 'Cet apercu montre des problemes de couverture ou de contraintes. La confirmation reste desactivee tant que ce n est pas faisable.',
                                es: 'Esta vista previa muestra problemas de cobertura o restricciones. La confirmacion queda deshabilitada hasta que sea totalmente factible.',
                              ),
                      ),
                      const SizedBox(height: 12),
                      ShiftAutoPlanPreviewSummaryCard(
                        compact: _compact,
                        title: _t(
                          it: 'Riepilogo',
                          en: 'Summary',
                          fr: 'Resume',
                          es: 'Resumen',
                        ),
                        metrics: [
                          ShiftAutoPlanPreviewSummaryMetric(
                            label: _t(
                              it: 'Nuovi turni',
                              en: 'New shifts',
                              fr: 'Nouveaux shifts',
                              es: 'Turnos nuevos',
                            ),
                            value: preview.createdAssignmentsCountPreview,
                          ),
                          ShiftAutoPlanPreviewSummaryMetric(
                            label: _t(
                              it: 'Preservati',
                              en: 'Preserved',
                              fr: 'Conserves',
                              es: 'Conservados',
                            ),
                            value: preview.preservedAssignmentsCount,
                          ),
                          ShiftAutoPlanPreviewSummaryMetric(
                            label: _t(
                              it: 'Da rimuovere',
                              en: 'To remove',
                              fr: 'A supprimer',
                              es: 'A eliminar',
                            ),
                            value: preview.deletedAssignmentsCountPreview,
                          ),
                          ShiftAutoPlanPreviewSummaryMetric(
                            label: _t(
                              it: 'Coperture mancanti',
                              en: 'Uncovered slots',
                              fr: 'Couvertures manquantes',
                              es: 'Coberturas faltantes',
                            ),
                            value: preview.uncoveredSlotsCount,
                            emphasize: preview.uncoveredSlotsCount > 0,
                          ),
                        ],
                      ),
                      if (preview.warnings.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ShiftAutoPlanPreviewWarningsCard(
                          compact: _compact,
                          title: _t(
                            it: 'Warning planner',
                            en: 'Planner warnings',
                            fr: 'Avertissements du planner',
                            es: 'Advertencias del planner',
                          ),
                          warnings: preview.warnings
                              .map(_formatWarning)
                              .toList(growable: false),
                        ),
                      ],
                      const SizedBox(height: 12),
                      ShiftAutoPlanPreviewLegendCard(
                        compact: _compact,
                        title: _t(
                          it: 'Calendario preview',
                          en: 'Preview calendar',
                          fr: 'Calendrier preview',
                          es: 'Calendario preview',
                        ),
                        description: _t(
                          it: 'Tocca un giorno per vedere il dettaglio dei presunti turni e delle azioni previste.',
                          en: 'Tap a day to inspect the tentative shifts and their planned actions.',
                          fr: 'Touchez un jour pour voir le detail des shifts prevus et des actions planifiees.',
                          es: 'Toca un dia para ver el detalle de los turnos previstos y sus acciones.',
                        ),
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
                        emptyMessage: _t(
                          it: 'Nessuna modifica proposta per questo intervallo.',
                          en: 'No changes were proposed for this range.',
                          fr: 'Aucune modification proposee pour cette periode.',
                          es: 'No se propusieron cambios para este intervalo.',
                        ),
                      ),
                    ],
                  ),
                ),
                ShiftAutoPlanPreviewFooter(
                  compact: _compact,
                  submitting: _submitting,
                  canConfirm: preview.fullyFeasible,
                  backLabel: _t(
                    it: 'Indietro',
                    en: 'Back',
                    fr: 'Retour',
                    es: 'Volver',
                  ),
                  confirmLabel: _t(
                    it: 'Conferma e crea',
                    en: 'Confirm and create',
                    fr: 'Confirmer et creer',
                    es: 'Confirmar y crear',
                  ),
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
        fallback: _t(
          it: 'Non siamo riusciti a confermare questa anteprima del planner.',
          en: 'We could not confirm this planner preview.',
          fr: 'Nous n avons pas pu confirmer cet apercu du planner.',
          es: 'No pudimos confirmar esta vista previa del planner.',
        ),
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
      description: _t(
        it: 'Presunti turni di questa giornata.',
        en: 'Tentative shifts for this day.',
        fr: 'Shifts prevus pour cette journee.',
        es: 'Turnos previstos para este dia.',
      ),
      items: items
          .map(
            (item) => ShiftAutoPlanPreviewDaySheetItem(
              title: ((item.assignment.profileName ?? '').trim().isEmpty)
                  ? _t(it: 'Turno', en: 'Shift', fr: 'Shift', es: 'Turno')
                  : item.assignment.profileName!.trim(),
              subtitle: [
                if ((item.assignment.userName ?? '').trim().isNotEmpty)
                  item.assignment.userName!.trim(),
                _formatTimeRange(item.assignment),
              ].join(' • '),
              action: item.action,
            ),
          )
          .toList(growable: false),
      actionLabelBuilder: _actionLabel,
    );
  }

  List<ShiftAutoPlanPreviewAssignmentEntity> _itemsForDate(DateTime date) {
    for (final day in widget.preview.days) {
      if (_isSameDay(day.date, date)) {
        final items = [...day.items];
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

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String _actionLabel(ShiftAutoPlanPreviewAction action) {
    return switch (action) {
      ShiftAutoPlanPreviewAction.create => _t(
        it: 'Nuovo',
        en: 'New',
        fr: 'Nouveau',
        es: 'Nuevo',
      ),
      ShiftAutoPlanPreviewAction.preserve => _t(
        it: 'Tieni',
        en: 'Keep',
        fr: 'Garder',
        es: 'Mantener',
      ),
      ShiftAutoPlanPreviewAction.delete => _t(
        it: 'Rimuovi',
        en: 'Remove',
        fr: 'Supprimer',
        es: 'Quitar',
      ),
    };
  }

  String _formatDateRange(DateTime from, DateTime to) {
    final format = DateFormat('dd/MM/yyyy');
    return '${format.format(from)} - ${format.format(to)}';
  }

  String _formatWarning(String warning) {
    final teamName = _displayTeamName;
    if (teamName == null) {
      return warning;
    }
    return warning.replaceAll(widget.request.teamId, teamName);
  }

  String _formatDay(DateTime date) {
    final format = DateFormat.yMMMMEEEEd(_languageCode);
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

  String _t({
    required String it,
    required String en,
    required String fr,
    required String es,
  }) {
    switch (_languageCode) {
      case 'it':
        return it;
      case 'fr':
        return fr;
      case 'es':
        return es;
      default:
        return en;
    }
  }
}
