import 'package:flutter/material.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_auto_plan_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';

String _localizedPreviewEditorText(
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

class ShiftAutoPlanPreviewAssignmentEditorResult {
  const ShiftAutoPlanPreviewAssignmentEditorResult({required this.assignment});

  final ShiftAutoPlanDraftAssignmentEntity assignment;
}

Future<ShiftAutoPlanPreviewAssignmentEditorResult?>
showShiftAutoPlanPreviewAssignmentEditorDialog(
  BuildContext context, {
  required List<TeamMemberforView> teamMembers,
  required List<ShiftProfileEntity> profiles,
  required DateTime shiftDate,
  ShiftAutoPlanDraftAssignmentEntity? initialAssignment,
}) {
  return showDialog<ShiftAutoPlanPreviewAssignmentEditorResult>(
    context: context,
    builder: (context) => _ShiftAutoPlanPreviewAssignmentEditorDialog(
      teamMembers: teamMembers,
      profiles: profiles,
      shiftDate: shiftDate,
      initialAssignment: initialAssignment,
    ),
  );
}

class _ShiftAutoPlanPreviewAssignmentEditorDialog extends StatefulWidget {
  const _ShiftAutoPlanPreviewAssignmentEditorDialog({
    required this.teamMembers,
    required this.profiles,
    required this.shiftDate,
    this.initialAssignment,
  });

  final List<TeamMemberforView> teamMembers;
  final List<ShiftProfileEntity> profiles;
  final DateTime shiftDate;
  final ShiftAutoPlanDraftAssignmentEntity? initialAssignment;

  @override
  State<_ShiftAutoPlanPreviewAssignmentEditorDialog> createState() =>
      _ShiftAutoPlanPreviewAssignmentEditorDialogState();
}

class _ShiftAutoPlanPreviewAssignmentEditorDialogState
    extends State<_ShiftAutoPlanPreviewAssignmentEditorDialog> {
  late String? _selectedUserId;
  late ShiftProfileEntity? _selectedProfile;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _overnight;
  late final TextEditingController _noteController;

  bool get _compact => MediaQuery.of(context).size.width < 720;

  List<_PreviewMemberOption> get _memberOptions => widget.teamMembers
      .where((member) => member.teamMember.userId != null)
      .map((member) {
        final user = member.user;
        final fallbackEmail = member.teamMember.userEmail.trim();
        final fullName = user?.fullName.trim() ?? '';
        final email = user?.email.trim().isNotEmpty == true
            ? user!.email.trim()
            : fallbackEmail;
        final label = fullName.isNotEmpty ? fullName : email;
        final subtitle = fullName.isNotEmpty && email.isNotEmpty ? email : null;
        return _PreviewMemberOption(
          userId: member.teamMember.userId!,
          label: label,
          subtitle: subtitle,
        );
      })
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAssignment?.assignment;
    _selectedUserId = initial?.userId ?? _memberOptions.firstOrNull?.userId;
    _selectedProfile = widget.profiles
        .where((profile) => profile.id == initial?.profileId)
        .firstOrNull;
    _startTime =
        initial?.startTime ??
        _selectedProfile?.startTime ??
        const TimeOfDay(hour: 9, minute: 0);
    _endTime =
        initial?.endTime ??
        _selectedProfile?.endTime ??
        const TimeOfDay(hour: 18, minute: 0);
    _overnight = initial?.overnight ?? (_selectedProfile?.overnight ?? false);
    _noteController = TextEditingController(text: initial?.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        widget.initialAssignment == null
            ? _localizedPreviewEditorText(
                context,
                it: 'Aggiungi turno alla bozza',
                en: 'Add draft shift',
                fr: 'Ajouter un quart au brouillon',
                es: 'Agregar turno al borrador',
              )
            : _localizedPreviewEditorText(
                context,
                it: 'Modifica turno della bozza',
                en: 'Edit draft shift',
                fr: 'Modifier le quart du brouillon',
                es: 'Editar turno del borrador',
              ),
      ),
      content: SizedBox(
        width: _compact ? 320 : 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedUserId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: _localizedPreviewEditorText(
                    context,
                    it: 'Membro del team',
                    en: 'Team member',
                    fr: 'Membre de l\'equipe',
                    es: 'Miembro del equipo',
                  ),
                ),
                items: _memberOptions
                    .map(
                      (member) => DropdownMenuItem<String>(
                        value: member.userId,
                        child: Text(
                          member.subtitle == null
                              ? member.label
                              : '${member.label} - ${member.subtitle}',
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  setState(() => _selectedUserId = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ShiftProfileEntity>(
                initialValue: _selectedProfile,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: _localizedPreviewEditorText(
                    context,
                    it: 'Profilo turno',
                    en: 'Shift profile',
                    fr: 'Profil de quart',
                    es: 'Perfil de turno',
                  ),
                ),
                items: widget.profiles
                    .map(
                      (profile) => DropdownMenuItem<ShiftProfileEntity>(
                        value: profile,
                        child: Text(profile.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  setState(() {
                    _selectedProfile = value;
                    if (value != null) {
                      _startTime = value.startTime;
                      _endTime = value.endTime;
                      _overnight = value.overnight;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              Text(
                _localizedPreviewEditorText(
                  context,
                  it: 'Orario',
                  en: 'Time range',
                  fr: 'Horaire',
                  es: 'Horario',
                ),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(isStart: true),
                      child: Text(_formatTime(_startTime)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(isStart: false),
                      child: Text(_formatTime(_endTime)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _localizedPreviewEditorText(
                    context,
                    it: 'Turno notturno',
                    en: 'Overnight shift',
                    fr: 'Quart de nuit',
                    es: 'Turno nocturno',
                  ),
                ),
                value: _overnight,
                onChanged: (value) => setState(() => _overnight = value),
              ),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: _localizedPreviewEditorText(
                    context,
                    it: 'Nota opzionale',
                    en: 'Optional note',
                    fr: 'Note facultative',
                    es: 'Nota opcional',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            _localizedPreviewEditorText(
              context,
              it: 'Annulla',
              en: 'Cancel',
              fr: 'Annuler',
              es: 'Cancelar',
            ),
          ),
        ),
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          child: Text(
            _localizedPreviewEditorText(
              context,
              it: 'Salva bozza',
              en: 'Save draft',
              fr: 'Enregistrer',
              es: 'Guardar borrador',
            ),
          ),
        ),
      ],
    );
  }

  bool get _canSubmit => _selectedUserId != null;

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  void _submit() {
    final selectedProfile = _selectedProfile;
    final existing = widget.initialAssignment;
    final assignment = ShiftAssignmentEntity(
      id: existing?.assignment.id ?? UniqueKey().toString(),
      userId: _selectedUserId!,
      userName: existing?.assignment.userName,
      shiftDate: DateTime(
        widget.shiftDate.year,
        widget.shiftDate.month,
        widget.shiftDate.day,
      ),
      teamId: existing?.assignment.teamId,
      teamShiftGroupId:
          existing?.assignment.teamShiftGroupId ?? selectedProfile?.id,
      profileId: selectedProfile?.id ?? existing?.assignment.profileId,
      profileName: selectedProfile?.name ?? existing?.assignment.profileName,
      profileColor: selectedProfile?.color ?? existing?.assignment.profileColor,
      startTime: _startTime,
      endTime: _endTime,
      overnight: _overnight,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      alarmOffsets:
          selectedProfile?.alarmOffsets ??
          existing?.assignment.alarmOffsets ??
          const <int>[],
      isPublic: true,
      memberEditUnlocked: existing?.assignment.memberEditUnlocked ?? false,
      memberChangeRequestPending:
          existing?.assignment.memberChangeRequestPending ?? false,
    );
    Navigator.of(context).pop(
      ShiftAutoPlanPreviewAssignmentEditorResult(
        assignment: ShiftAutoPlanDraftAssignmentEntity(
          previewItemId:
              existing?.previewItemId ??
              'draft-${DateTime.now().microsecondsSinceEpoch}',
          sourceAssignmentId: existing?.sourceAssignmentId,
          assignment: assignment,
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

class _PreviewMemberOption {
  const _PreviewMemberOption({
    required this.userId,
    required this.label,
    this.subtitle,
  });

  final String userId;
  final String label;
  final String? subtitle;
}

extension on List<_PreviewMemberOption> {
  _PreviewMemberOption? get firstOrNull => isEmpty ? null : first;
}

extension on Iterable<ShiftProfileEntity> {
  ShiftProfileEntity? get firstOrNull => isEmpty ? null : first;
}
