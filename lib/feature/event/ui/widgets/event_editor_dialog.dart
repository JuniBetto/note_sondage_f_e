import 'package:flutter/material.dart';
import 'package:note_sondage/feature/event/domain/entities/event_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_toggle_switch.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';

class EventEditorResult {
  const EventEditorResult({
    this.teamId,
    required this.title,
    required this.description,
    required this.startsAt,
    required this.endsAt,
    required this.allDay,
    required this.location,
    required this.participantUserIds,
    required this.participantDisplayNames,
  });

  /// `null` means this is a personal event — not attached to any team.
  final String? teamId;
  final String title;
  final String? description;
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool allDay;
  final String? location;
  final List<String> participantUserIds;
  final List<String> participantDisplayNames;
}

Future<EventEditorResult?> showEventEditorDialog(
  BuildContext context, {
  required String? initialTeamId,
  required List<TeamMemberforView> teamMembers,
  EventEntity? initialEvent,
}) {
  return showDialog<EventEditorResult>(
    context: context,
    builder: (context) => _EventEditorDialog(
      initialTeamId: initialTeamId,
      teamMembers: teamMembers,
      initialEvent: initialEvent,
    ),
  );
}

class _EventEditorDialog extends StatefulWidget {
  const _EventEditorDialog({
    required this.initialTeamId,
    required this.teamMembers,
    this.initialEvent,
  });

  /// `null` means this dialog creates/edits a personal event (no team).
  final String? initialTeamId;
  final List<TeamMemberforView> teamMembers;
  final EventEntity? initialEvent;

  @override
  State<_EventEditorDialog> createState() => _EventEditorDialogState();
}

class _EventEditorDialogState extends State<_EventEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final Set<String> _selectedParticipantUserIds;
  late DateTime _startsAt;
  DateTime? _endsAt;
  late bool _allDay;

  @override
  void initState() {
    super.initState();
    final event = widget.initialEvent;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    _locationController = TextEditingController(text: event?.location ?? '');
    _selectedParticipantUserIds = <String>{...?event?.participantUserIds};
    _startsAt = event?.startsAt ?? DateTime.now().add(const Duration(hours: 1));
    _endsAt = event?.endsAt ?? _startsAt.add(const Duration(hours: 1));
    _allDay = event?.allDay ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String labelText,
    String? hintText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = colorScheme.bottomOutline ?? colorScheme.outlineVariant;
    final focusColor = colorScheme.selectionColor ?? colorScheme.primary;
    final radius = BorderRadius.circular(12);
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: colorScheme.textfieldFillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: borderColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: focusColor, width: 2),
      ),
    );
  }

  String _memberLabel(TeamMemberforView member) {
    final fullName = member.user?.fullName.trim();
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }
    final initialName = member.teamMember.initialName?.trim();
    if (initialName != null && initialName.isNotEmpty) {
      return initialName;
    }
    final email = member.teamMember.userEmail.trim();
    if (email.isNotEmpty) {
      return email;
    }
    return member.teamMember.userId?.trim() ?? '';
  }

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = _allDay
        ? const TimeOfDay(hour: 9, minute: 0)
        : await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_startsAt),
              ) ??
              TimeOfDay.fromDateTime(_startsAt);

    setState(() {
      _startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (_endsAt != null && _endsAt!.isBefore(_startsAt)) {
        _endsAt = _startsAt.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEnd() async {
    final initial = _endsAt ?? _startsAt.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = _allDay
        ? const TimeOfDay(hour: 18, minute: 0)
        : await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(initial),
              ) ??
              TimeOfDay.fromDateTime(initial);
    setState(() {
      _endsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.eventTitleRequiredError),
        ),
      );
      return;
    }

    final selectedMembers = widget.teamMembers.where(
      (member) =>
          member.teamMember.userId != null &&
          _selectedParticipantUserIds.contains(member.teamMember.userId),
    );

    Navigator.of(context).pop(
      EventEditorResult(
        teamId: widget.initialTeamId,
        title: title,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        startsAt: _startsAt,
        endsAt: _endsAt,
        allDay: _allDay,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        participantUserIds: selectedMembers
            .map((member) => member.teamMember.userId!)
            .toList(growable: false),
        participantDisplayNames: selectedMembers
            .map(_memberLabel)
            .where((label) => label.isNotEmpty)
            .toList(growable: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final materialLocalizations = MaterialLocalizations.of(context);
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final appPrimary = colorScheme.primaryColor ?? colorScheme.primary;
    return AlertDialog(
      backgroundColor: colorScheme.dialogBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.initialEvent == null
            ? loc.eventNewEventAction
            : loc.eventEditEventTitle,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.initialTeamId == null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: appPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: appPrimary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline, size: 16, color: appPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.eventPersonalEventNotice,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: appPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _titleController,
                decoration: _fieldDecoration(
                  context,
                  labelText: loc.eventTitleLabel,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _fieldDecoration(
                  context,
                  labelText: loc.eventDescriptionLabel,
                ),
              ),
              const SizedBox(height: 12),
              AppSwitchListTile(
                value: _allDay,
                onChanged: (value) => setState(() => _allDay = value),
                title: Text(loc.eventAllDayLabel),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickStart,
                    icon: const Icon(Icons.event_outlined),
                    label: Text(
                      loc.eventStartLabel(
                        '${materialLocalizations.formatShortDate(_startsAt)} ${materialLocalizations.formatTimeOfDay(TimeOfDay.fromDateTime(_startsAt))}',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickEnd,
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text(
                      _endsAt == null
                          ? loc.eventEndNotSet
                          : loc.eventEndLabel(
                              '${materialLocalizations.formatShortDate(_endsAt!)} ${materialLocalizations.formatTimeOfDay(TimeOfDay.fromDateTime(_endsAt!))}',
                            ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _endsAt = null),
                    child: Text(loc.eventRemoveEndAction),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                decoration: _fieldDecoration(
                  context,
                  labelText: loc.eventLocationLabel,
                ),
              ),
              if (widget.initialTeamId != null) ...[
                const SizedBox(height: 12),
                Text(
                  loc.eventParticipantsLabel,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                if (widget.teamMembers.isEmpty)
                  Text(
                    loc.eventParticipantsEmptyTeam,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.descriptionColor,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.teamMembers
                        .where((member) => member.teamMember.userId != null)
                        .map((member) {
                          final userId = member.teamMember.userId!;
                          final selected = _selectedParticipantUserIds.contains(
                            userId,
                          );
                          return FilterChip(
                            label: Text(_memberLabel(member)),
                            selected: selected,
                            backgroundColor: colorScheme.homeSecondary,
                            selectedColor: appPrimary.withValues(alpha: 0.14),
                            checkmarkColor: appPrimary,
                            side: BorderSide(
                              color: selected
                                  ? appPrimary
                                  : (colorScheme.borderColor ?? appPrimary),
                            ),
                            onSelected: (value) {
                              setState(() {
                                if (value) {
                                  _selectedParticipantUserIds.add(userId);
                                } else {
                                  _selectedParticipantUserIds.remove(userId);
                                }
                              });
                            },
                          );
                        })
                        .toList(growable: false),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        CustomAppButton(
          onPressed: () => Navigator.of(context).pop(),
          isActive: false,
          type: ButtonType.text,
          child: Text(loc.cancel),
        ),
        CustomAppButton(
          onPressed: _submit,
          isActive: true,
          type: ButtonType.filled,
          child: Text(loc.save),
        ),
      ],
    );
  }
}
