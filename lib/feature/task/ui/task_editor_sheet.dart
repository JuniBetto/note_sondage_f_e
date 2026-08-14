import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:note_sondage/core/utils/app_error_message_resolver.dart';
import 'package:note_sondage/feature/task/domain/entities/task_create_request_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_entity.dart';
import 'package:note_sondage/feature/task/domain/entities/task_priority.dart';
import 'package:note_sondage/feature/task/domain/entities/task_update_request_entity.dart';
import 'package:note_sondage/feature/task/ui/task_ui_support.dart';
import 'package:note_sondage/feature/task/ui/widgets/task_editor_section_card.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';

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
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime? _selectedDueAt;
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
    _selectedTeamId =
        existing?.teamId ??
        draft?.teamId ??
        widget.availableTeams.firstOrNull?.id?.trim();
    _selectedPriority =
        existing?.priority ?? draft?.priority ?? TaskPriority.medium;
    _selectedDueAt = existing?.dueAt ?? draft?.dueAt;
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
    final locale = Localizations.localeOf(context).languageCode;
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final teamId = _selectedTeamId?.trim();
    if (teamId == null || teamId.isEmpty) {
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
                dueAt: _selectedDueAt,
                assigneeUserId: _selectedAssigneeUserId,
                assigneeDisplayName: _selectedAssigneeUserId == null
                    ? null
                    : assignee.label,
                clearDueAt: _selectedDueAt == null,
                clearAssignee: _selectedAssigneeUserId == null,
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
                dueAt: _selectedDueAt,
                assigneeUserId: _selectedAssigneeUserId,
                assigneeDisplayName: _selectedAssigneeUserId == null
                    ? null
                    : assignee.label,
                createdByUserId: widget.actorUserId,
                createdByDisplayName: widget.actorDisplayName,
                workflowMetadata: widget.initialDraft?.workflowMetadata,
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
          fallback: taskText(
            locale,
            it: 'Impossibile salvare il task. Riprova tra poco.',
            en: 'Unable to save the task. Please try again shortly.',
          ),
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
    final locale = Localizations.localeOf(context).languageCode;
    final teamItems = widget.availableTeams
        .where((team) => team.id != null && team.id!.trim().isNotEmpty)
        .toList(growable: false);
    final dueDateLabel = _selectedDueAt == null
        ? _text(locale, it: 'Nessuna scadenza', en: 'No due date')
        : DateFormat(
            'dd/MM/yyyy HH:mm',
            Localizations.localeOf(context).toLanguageTag(),
          ).format(_selectedDueAt!);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isEditing
              ? _text(locale, it: 'Modifica task', en: 'Edit task')
              : _text(locale, it: 'Nuovo task', en: 'New task'),
        ),
        actions: [
          IconButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              TaskEditorSectionCard(
                title: taskText(locale, it: 'Contesto', en: 'Context'),
                subtitle: taskText(
                  locale,
                  it: 'Definisci team e contenuto del task.',
                  en: 'Define the team and the task content.',
                ),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTeamId,
                      decoration: InputDecoration(
                        labelText: _text(locale, it: 'Team', en: 'Team'),
                      ),
                      items: teamItems
                          .map(
                            (team) => DropdownMenuItem<String>(
                              value: team.id!.trim(),
                              child: Text(team.name),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: widget.lockTeamSelection
                          ? null
                          : (value) {
                              setState(() {
                                _selectedTeamId = value;
                                _selectedAssigneeUserId = null;
                                _selectedAssigneeLabel = null;
                              });
                              unawaited(_loadAssigneesForSelectedTeam());
                            },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return _text(
                            locale,
                            it: 'Seleziona un team',
                            en: 'Select a team',
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: _text(locale, it: 'Titolo', en: 'Title'),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return _text(
                            locale,
                            it: 'Il titolo e obbligatorio',
                            en: 'Title is required',
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: _text(
                          locale,
                          it: 'Descrizione',
                          en: 'Description',
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TaskEditorSectionCard(
                title: taskText(locale, it: 'Pianificazione', en: 'Planning'),
                subtitle: taskText(
                  locale,
                  it: 'Imposta priorita e scadenza.',
                  en: 'Set priority and due date.',
                ),
                child: Column(
                  children: [
                    DropdownButtonFormField<TaskPriority>(
                      initialValue: _selectedPriority,
                      decoration: InputDecoration(
                        labelText: _text(
                          locale,
                          it: 'Priorita',
                          en: 'Priority',
                        ),
                      ),
                      items: TaskPriority.values
                          .map(
                            (priority) => DropdownMenuItem<TaskPriority>(
                              value: priority,
                              child: Text(_priorityLabel(priority, locale)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _selectedPriority = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _text(locale, it: 'Scadenza', en: 'Due date'),
                      ),
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
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TaskEditorSectionCard(
                title: taskText(locale, it: 'Assegnazione', en: 'Assignment'),
                subtitle: taskText(
                  locale,
                  it: 'Scegli chi segue il task.',
                  en: 'Choose who owns the task.',
                ),
                child: Column(
                  children: [
                    if (_loadingAssignees)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedAssigneeUserId,
                      decoration: InputDecoration(
                        labelText: _text(
                          locale,
                          it: 'Assegna a',
                          en: 'Assign to',
                        ),
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            _text(
                              locale,
                              it: 'Non assegnato',
                              en: 'Unassigned',
                            ),
                          ),
                        ),
                        ..._assignees.map(
                          (assignee) => DropdownMenuItem<String>(
                            value: assignee.userId,
                            child: Text(assignee.label),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        final selected = _assignees
                            .where((option) => option.userId == value)
                            .firstOrNull;
                        setState(() {
                          _selectedAssigneeUserId = value;
                          _selectedAssigneeLabel = selected?.label;
                        });
                      },
                    ),
                  ],
                ),
              ),
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
                        _text(
                          locale,
                          it: 'Questo task manterra il collegamento al messaggio chat sorgente.',
                          en: 'This task will keep the link to the source chat message.',
                        ),
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
                      ? _text(locale, it: 'Salva modifiche', en: 'Save changes')
                      : _text(locale, it: 'Crea task', en: 'Create task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _priorityLabel(TaskPriority priority, String locale) {
  return switch (priority) {
    TaskPriority.low => _text(locale, it: 'Bassa', en: 'Low'),
    TaskPriority.medium => _text(locale, it: 'Media', en: 'Medium'),
    TaskPriority.high => _text(locale, it: 'Alta', en: 'High'),
  };
}

bool _isCompact(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  return mediaQuery.size.width < 760 ||
      defaultTargetPlatform != TargetPlatform.macOS;
}

String _text(
  String locale, {
  required String it,
  required String en,
  String? fr,
  String? es,
}) {
  return switch (locale) {
    'it' => it,
    'fr' => fr ?? en,
    'es' => es ?? en,
    _ => en,
  };
}
