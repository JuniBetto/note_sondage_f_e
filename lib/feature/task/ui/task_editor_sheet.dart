import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:note_sondage/core/utils/app_error_message_resolver.dart';
import 'package:note_sondage/feature/task/domain/entities/task_create_request_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_priority.dart';
import 'package:note_sondage/feature/task/domain/entities/task_reminder_anchor.dart';
import 'package:note_sondage/feature/task/domain/entities/task_update_request_entity.dart';
import 'package:note_sondage/feature/task/ui/task_ui_support.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_editor_section_card.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/ui/widgets/select_option_with_search.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';

class TaskAssigneeOption {
  const TaskAssigneeOption({
    required this.userId,
    required this.label,
    this.secondaryLabel,
  });

  final String userId;
  final String label;
  final String? secondaryLabel;
}

typedef TaskAssigneeLoader =
    Future<List<TaskAssigneeOption>> Function(String teamId);
typedef TaskCreateHandler =
    Future<TaskEntity> Function(TaskCreateRequestEntity request);
typedef TaskUpdateHandler =
    Future<TaskEntity> Function(
      TaskEntity existingTask,
      TaskUpdateRequestEntity request,
    );

Future<TaskEntity?> showTaskEditorSheet({
  required BuildContext context,
  required List<TeamEntity> availableTeams,
  required TaskAssigneeLoader loadAssignees,
  required TaskCreateHandler onCreate,
  required TaskUpdateHandler onUpdate,
  required String actorUserId,
  required String actorDisplayName,
  TaskCreateRequestEntity? initialDraft,
  TaskEntity? existingTask,
  bool lockTeamSelection = false,
}) {
  final child = _TaskEditorSheet(
    availableTeams: availableTeams,
    loadAssignees: loadAssignees,
    onCreate: onCreate,
    onUpdate: onUpdate,
    actorUserId: actorUserId,
    actorDisplayName: actorDisplayName,
    initialDraft: initialDraft,
    existingTask: existingTask,
    lockTeamSelection: lockTeamSelection,
  );

  if (_isCompact(context)) {
    return showModalBottomSheet<TaskEntity>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.94,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(sheetContext).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }

  return showDialog<TaskEntity>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
          child: child,
        ),
      );
    },
  );
}

class _TaskEditorSheet extends StatefulWidget {
  const _TaskEditorSheet({
    required this.availableTeams,
    required this.loadAssignees,
    required this.onCreate,
    required this.onUpdate,
    required this.actorUserId,
    required this.actorDisplayName,
    this.initialDraft,
    this.existingTask,
    this.lockTeamSelection = false,
  });

  final List<TeamEntity> availableTeams;
  final TaskAssigneeLoader loadAssignees;
  final TaskCreateHandler onCreate;
  final TaskUpdateHandler onUpdate;
  final String actorUserId;
  final String actorDisplayName;
  final TaskCreateRequestEntity? initialDraft;
  final TaskEntity? existingTask;
  final bool lockTeamSelection;

  @override
  State<_TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<_TaskEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String? _selectedTeamId;
  bool _isPersonal = false;
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime? _selectedStartAt;
  DateTime? _selectedDueAt;
  List<int> _reminderOffsets = const <int>[];
  TaskReminderAnchor _reminderAnchor = TaskReminderAnchor.dueAt;
  String? _selectedAssigneeUserId;
  String? _selectedAssigneeLabel;
  List<TaskAssigneeOption> _assignees = const <TaskAssigneeOption>[];
  bool _loadingAssignees = false;
  bool _saving = false;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTask;
    final draft = widget.initialDraft;
    _titleController = TextEditingController(
      text: existing?.title ?? draft?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: existing?.description ?? draft?.description ?? '',
    );
    if (existing != null) {
      _selectedTeamId = existing.teamId;
    } else if (draft != null) {
      // draft.teamId may legitimately be null (a personal task), which is
      // different from "no draft at all" — don't fall through to the
      // first-available-team default in that case.
      _selectedTeamId = draft.teamId;
    } else {
      _selectedTeamId = widget.availableTeams.firstOrNull?.id?.trim();
    }
    _isPersonal = _selectedTeamId == null;
    _selectedPriority =
        existing?.priority ?? draft?.priority ?? TaskPriority.medium;
    _selectedStartAt = existing?.startAt ?? draft?.startAt;
    _selectedDueAt = existing?.dueAt ?? draft?.dueAt;
    _reminderOffsets = List<int>.from(
      existing?.reminderOffsets ?? draft?.reminderOffsets ?? const <int>[],
    );
    _reminderAnchor =
        existing?.reminderAnchor ??
        draft?.reminderAnchor ??
        TaskReminderAnchor.dueAt;
    _selectedAssigneeUserId = existing?.assigneeUserId ?? draft?.assigneeUserId;
    _selectedAssigneeLabel =
        existing?.assigneeDisplayName ?? draft?.assigneeDisplayName;
    unawaited(_loadAssigneesForSelectedTeam());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAssigneesForSelectedTeam() async {
    final teamId = _selectedTeamId?.trim();
    if (teamId == null || teamId.isEmpty) {
      setState(() {
        _assignees = const <TaskAssigneeOption>[];
        _selectedAssigneeUserId = null;
        _selectedAssigneeLabel = null;
      });
      return;
    }

    setState(() {
      _loadingAssignees = true;
    });

    try {
      final assignees = await widget.loadAssignees(teamId);
      if (!mounted) {
        return;
      }
      final hasSelected = assignees.any(
        (option) => option.userId == _selectedAssigneeUserId,
      );
      setState(() {
        _assignees = assignees;
        if (!hasSelected) {
          _selectedAssigneeUserId = null;
          _selectedAssigneeLabel = null;
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingAssignees = false;
        });
      }
    }
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final initial = _selectedStartAt ?? _selectedDueAt ?? now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (!mounted || pickedDate == null) {
      return;
    }
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedStartAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? initial.hour,
        pickedTime?.minute ?? initial.minute,
      );
    });
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initial = _selectedDueAt ?? now.add(const Duration(hours: 2));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (!mounted || pickedDate == null) {
      return;
    }
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedDueAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? initial.hour,
        pickedTime?.minute ?? initial.minute,
      );
    });
  }

  Future<void> _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final teamId = _isPersonal ? null : _selectedTeamId?.trim();
    if (!_isPersonal && (teamId == null || teamId.isEmpty)) {
      return;
    }
    if (_selectedStartAt != null &&
        _selectedDueAt != null &&
        _selectedStartAt!.isAfter(_selectedDueAt!)) {
      AppSnackBar.showWarning(context, l10n.taskStartAfterDueError);
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final assignee = _assignees.firstWhere(
        (option) => option.userId == _selectedAssigneeUserId,
        orElse: () => TaskAssigneeOption(
          userId: _selectedAssigneeUserId ?? '',
          label: _selectedAssigneeLabel ?? '',
        ),
      );
      final result = _isEditing
          ? await widget.onUpdate(
              widget.existingTask!,
              TaskUpdateRequestEntity(
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                priority: _selectedPriority,
                startAt: _selectedStartAt,
                dueAt: _selectedDueAt,
                assigneeUserId: _selectedAssigneeUserId,
                assigneeDisplayName: _selectedAssigneeUserId == null
                    ? null
                    : assignee.label,
                clearStartAt: _selectedStartAt == null,
                clearDueAt: _selectedDueAt == null,
                clearAssignee: _selectedAssigneeUserId == null,
                reminderOffsets: _reminderOffsets,
                reminderAnchor: _reminderAnchor,
              ),
            )
          : await widget.onCreate(
              TaskCreateRequestEntity(
                teamId: teamId,
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                priority: _selectedPriority,
                startAt: _selectedStartAt,
                dueAt: _selectedDueAt,
                assigneeUserId: _selectedAssigneeUserId,
                assigneeDisplayName: _selectedAssigneeUserId == null
                    ? null
                    : assignee.label,
                createdByUserId: widget.actorUserId,
                createdByDisplayName: widget.actorDisplayName,
                workflowMetadata: widget.initialDraft?.workflowMetadata,
                reminderOffsets: _reminderOffsets,
                reminderAnchor: _reminderAnchor,
              ),
            );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(
        context,
        AppErrorMessageResolver.resolve(
          error,
          fallback: l10n.taskSaveError,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isCompact = _isCompact(context);
    final teamItems = widget.availableTeams
        .where((team) => team.id != null && team.id!.trim().isNotEmpty)
        .toList(growable: false);
    final selectedTeam = teamItems
        .where((team) => team.id!.trim() == _selectedTeamId)
        .firstOrNull;
    final assigneeOptions = [
      TaskAssigneeOption(userId: '', label: l10n.taskUnassignedOption),
      ..._assignees,
    ];
    final selectedAssigneeOption = assigneeOptions
        .where((option) => option.userId == (_selectedAssigneeUserId ?? ''))
        .firstOrNull;
    final dateFormat = DateFormat(
      'dd/MM/yyyy HH:mm',
      Localizations.localeOf(context).toLanguageTag(),
    );
    final startDateLabel = _selectedStartAt == null
        ? l10n.taskDueDateNotSet
        : dateFormat.format(_selectedStartAt!);
    final dueDateLabel = _selectedDueAt == null
        ? l10n.taskNoDueDate
        : dateFormat.format(_selectedDueAt!);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (isCompact) ...[
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
            Padding(
              padding: EdgeInsets.fromLTRB(20, isCompact ? 12 : 20, 8, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? l10n.taskEditAction : l10n.taskNewTaskAction,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
              TaskEditorSectionCard(
                title: l10n.taskContextSectionTitle,
                subtitle: l10n.taskContextSectionSubtitle,
                child: Column(
                  children: [
                    IgnorePointer(
                      ignoring: widget.lockTeamSelection,
                      child: Opacity(
                        opacity: widget.lockTeamSelection ? 0.6 : 1,
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.taskPersonalToggleLabel),
                          subtitle: Text(l10n.taskPersonalToggleSubtitle),
                          value: _isPersonal,
                          onChanged: (value) {
                            setState(() {
                              _isPersonal = value;
                              _selectedAssigneeUserId = null;
                              _selectedAssigneeLabel = null;
                              if (value) {
                                _selectedTeamId = null;
                              } else {
                                _selectedTeamId ??=
                                    widget.availableTeams.firstOrNull?.id
                                        ?.trim();
                                unawaited(_loadAssigneesForSelectedTeam());
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    if (!_isPersonal) ...[
                      const SizedBox(height: 14),
                      IgnorePointer(
                        ignoring: widget.lockTeamSelection,
                        child: Opacity(
                          opacity: widget.lockTeamSelection ? 0.6 : 1,
                          child: GenericDropdownFormField<TeamEntity>(
                            label: l10n.taskTeamLabel,
                            hintText: l10n.taskTeamLabel,
                            prefixIcon: const Icon(
                              Icons.groups_outlined,
                              size: 18,
                            ),
                            items: teamItems,
                            value: selectedTeam,
                            displayText: (team) => team.name,
                            valueGetter: (team) => team.id!.trim(),
                            onChanged: (value) {
                              setState(() {
                                _selectedTeamId = value as String?;
                                _selectedAssigneeUserId = null;
                                _selectedAssigneeLabel = null;
                              });
                              unawaited(_loadAssigneesForSelectedTeam());
                            },
                            validator: (value) {
                              if (_isPersonal) {
                                return null;
                              }
                              if (value == null) {
                                return l10n.taskSelectTeamError;
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    CustomInputField(
                      hintText: l10n.taskTitleLabel,
                      controller: _titleController,
                      toLowerCase: false,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.taskTitleRequiredError;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomInputField(
                      hintText: l10n.taskDescriptionLabel,
                      controller: _descriptionController,
                      toLowerCase: false,
                      minLines: 3,
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TaskEditorSectionCard(
                title: l10n.taskPlanningSectionTitle,
                subtitle: l10n.taskPlanningSectionSubtitle,
                child: Column(
                  children: [
                    GenericDropdownFormField<TaskPriority>(
                      label: l10n.taskPriorityLabel,
                      hintText: l10n.taskPriorityLabel,
                      prefixIcon: const Icon(
                        Icons.flag_outlined,
                        size: 18,
                      ),
                      items: TaskPriority.values,
                      value: _selectedPriority,
                      displayText: (priority) =>
                          taskPriorityLabel(priority, context),
                      valueGetter: (priority) => priority,
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _selectedPriority = value as TaskPriority;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.taskStartDateLabel),
                      subtitle: Text(startDateLabel),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            onPressed: _pickStartDate,
                            icon: const Icon(Icons.event_rounded),
                          ),
                          if (_selectedStartAt != null)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _selectedStartAt = null;
                                });
                              },
                              icon: const Icon(Icons.clear_rounded),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.taskDueDateLabel),
                      subtitle: Text(dueDateLabel),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            onPressed: _pickDueDate,
                            icon: const Icon(Icons.event_rounded),
                          ),
                          if (_selectedDueAt != null)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _selectedDueAt = null;
                                });
                              },
                              icon: const Icon(Icons.clear_rounded),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _remindersLabel(context),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _TaskReminderOffsetEditor(
                      offsets: _reminderOffsets,
                      onChanged: (offsets) {
                        setState(() {
                          _reminderOffsets = offsets;
                        });
                      },
                    ),
                    if (_reminderOffsets.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SegmentedButton<TaskReminderAnchor>(
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          textStyle: theme.textTheme.labelSmall,
                        ),
                        selected: {_reminderAnchor},
                        segments: [
                          ButtonSegment(
                            value: TaskReminderAnchor.dueAt,
                            label: Text(_reminderAnchorDueAtLabel(context)),
                          ),
                          ButtonSegment(
                            value: TaskReminderAnchor.startAt,
                            label: Text(_reminderAnchorStartAtLabel(context)),
                          ),
                        ],
                        onSelectionChanged: (selection) {
                          setState(() {
                            _reminderAnchor = selection.first;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              if (!_isPersonal) ...[
                const SizedBox(height: 16),
                TaskEditorSectionCard(
                  title: l10n.taskAssignmentSectionTitle,
                  subtitle: l10n.taskAssignmentSectionSubtitle,
                  child: Column(
                    children: [
                      if (_loadingAssignees)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                      GenericDropdownFormField<TaskAssigneeOption>(
                        label: l10n.taskAssignToLabel,
                        hintText: l10n.taskAssignToLabel,
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          size: 18,
                        ),
                        items: assigneeOptions,
                        value: selectedAssigneeOption,
                        displayText: (option) => option.label,
                        valueGetter: (option) => option.userId,
                        onChanged: (value) {
                          final selected = _assignees
                              .where((option) => option.userId == value)
                              .firstOrNull;
                          setState(() {
                            _selectedAssigneeUserId = selected?.userId;
                            _selectedAssigneeLabel = selected?.label;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
              if (widget.initialDraft?.workflowMetadata?.sourceMessageId !=
                  null)
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.22,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        l10n.taskSourceChatBanner,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _handleSubmit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  _isEditing
                      ? l10n.taskSaveChangesAction
                      : l10n.taskCreateAction,
                ),
              ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isCompact(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  return mediaQuery.size.width < 760 ||
      defaultTargetPlatform != TargetPlatform.macOS;
}

/// Chip editor per gli offset dei promemoria del task — stesso pattern UI
/// dell'`_AlarmOffsetEditor` di Shift (minuti relativi, negativi = prima).
class _TaskReminderOffsetEditor extends StatelessWidget {
  const _TaskReminderOffsetEditor({
    required this.offsets,
    required this.onChanged,
  });

  final List<int> offsets;
  final ValueChanged<List<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        ...offsets.map((offset) {
          final label = offset < 0 ? '$offset min' : '+$offset min';
          return Chip(
            label: Text(label, style: theme.textTheme.bodySmall),
            deleteIcon: const Icon(Icons.close, size: 14),
            onDeleted: () {
              final updated = List<int>.from(offsets)..remove(offset);
              onChanged(updated);
            },
          );
        }),
        ActionChip(
          avatar: const Icon(Icons.add, size: 14),
          label: Text(_addLabel(context)),
          onPressed: () => _addOffset(context),
        ),
      ],
    );
  }

  Future<void> _addOffset(BuildContext context) async {
    final ctrl = TextEditingController(text: '-30');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_addReminderTitle(ctx)),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: InputDecoration(
            labelText: _reminderMinutesLabel(ctx),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              if (v != null) Navigator.of(ctx).pop(v);
            },
            child: Text(_addLabel(ctx)),
          ),
        ],
      ),
    );
    if (result != null && !offsets.contains(result)) {
      final updated = List<int>.from(offsets)
        ..add(result)
        ..sort();
      onChanged(updated);
    }
  }
}

String _localizedTaskEditorText(
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

String _remindersLabel(BuildContext context) => _localizedTaskEditorText(
  context,
  it: 'Promemoria',
  en: 'Reminders',
  fr: 'Rappels',
  es: 'Recordatorios',
);

String _addReminderTitle(BuildContext context) => _localizedTaskEditorText(
  context,
  it: 'Aggiungi promemoria',
  en: 'Add reminder',
  fr: 'Ajouter un rappel',
  es: 'Agregar recordatorio',
);

String _reminderMinutesLabel(BuildContext context) => _localizedTaskEditorText(
  context,
  it: 'Minuti (negativi = prima)',
  en: 'Minutes (negative = before)',
  fr: 'Minutes (negatif = avant)',
  es: 'Minutos (negativo = antes)',
);

String _addLabel(BuildContext context) => _localizedTaskEditorText(
  context,
  it: 'Aggiungi',
  en: 'Add',
  fr: 'Ajouter',
  es: 'Agregar',
);

String _reminderAnchorDueAtLabel(BuildContext context) =>
    _localizedTaskEditorText(
      context,
      it: 'Alla scadenza',
      en: 'At due date',
      fr: 'A l\'echeance',
      es: 'En la fecha limite',
    );

String _reminderAnchorStartAtLabel(BuildContext context) =>
    _localizedTaskEditorText(
      context,
      it: 'All\'inizio',
      en: 'At start date',
      fr: 'Au debut',
      es: 'Al inicio',
    );
