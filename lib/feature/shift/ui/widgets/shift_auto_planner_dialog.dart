import 'package:flutter/material.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_auto_plan_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';

class ShiftAutoPlannerDialog extends StatefulWidget {
  const ShiftAutoPlannerDialog({
    super.key,
    required this.teams,
    required this.profiles,
    this.initialTeamId,
    this.initialFrom,
    this.initialTo,
    this.compact = false,
  });

  final List<TeamEntityForView> teams;
  final List<ShiftProfileEntity> profiles;
  final String? initialTeamId;
  final DateTime? initialFrom;
  final DateTime? initialTo;
  final bool compact;

  static Future<ShiftAutoPlanRequestEntity?> show(
    BuildContext context, {
    required List<TeamEntityForView> teams,
    required List<ShiftProfileEntity> profiles,
    String? initialTeamId,
    DateTime? initialFrom,
    DateTime? initialTo,
    bool compact = false,
  }) {
    return showDialog<ShiftAutoPlanRequestEntity>(
      context: context,
      builder: (context) => ShiftAutoPlannerDialog(
        teams: teams,
        profiles: profiles,
        initialTeamId: initialTeamId,
        initialFrom: initialFrom,
        initialTo: initialTo,
        compact: compact,
      ),
    );
  }

  @override
  State<ShiftAutoPlannerDialog> createState() => _ShiftAutoPlannerDialogState();
}

class _ShiftAutoPlannerDialogState extends State<ShiftAutoPlannerDialog> {
  late String? _selectedTeamId;
  late DateTime _from;
  late DateTime _to;
  bool _replaceExistingAssignments = false;
  final Map<String, int> _selectedProfileCounts = <String, int>{};

  bool get _isItalian => Localizations.localeOf(context).languageCode == 'it';

  @override
  void initState() {
    super.initState();
    _selectedTeamId =
        widget.initialTeamId ??
        (widget.teams.isNotEmpty ? widget.teams.first.team.id : null);
    final now = DateTime.now();
    _from = _normalizeDate(widget.initialFrom ?? now);
    _to = _normalizeDate(widget.initialTo ?? _from);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profiles = [...widget.profiles]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return AlertDialog(
      title: Text(_isItalian ? 'Shift Auto Planner' : 'Shift Auto Planner'),
      content: SizedBox(
        width: widget.compact ? 360 : 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isItalian
                    ? 'Genera automaticamente i turni del team usando i profili esistenti e una rotazione equa dei membri disponibili.'
                    : 'Automatically generate team shifts using existing profiles and a fair rotation of available members.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTeamId,
                decoration: InputDecoration(
                  labelText: _isItalian ? 'Team' : 'Team',
                  border: const OutlineInputBorder(),
                ),
                items: widget.teams
                    .where((entry) => entry.team.id != null)
                    .map(
                      (entry) => DropdownMenuItem<String>(
                        value: entry.team.id!,
                        child: Text(entry.team.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedTeamId = value),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _DateField(
                    label: _isItalian ? 'Dal' : 'From',
                    value: _from,
                    onTap: () => _pickDate(
                      initialDate: _from,
                      onSelected: (value) {
                        setState(() {
                          _from = value;
                          if (_to.isBefore(_from)) {
                            _to = _from;
                          }
                        });
                      },
                    ),
                  ),
                  _DateField(
                    label: _isItalian ? 'Al' : 'To',
                    value: _to,
                    onTap: () => _pickDate(
                      initialDate: _to,
                      firstDate: _from,
                      onSelected: (value) {
                        setState(() => _to = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _replaceExistingAssignments,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _isItalian
                      ? 'Sostituisci i turni gia presenti'
                      : 'Replace existing assignments',
                ),
                subtitle: Text(
                  _isItalian
                      ? 'Se attivo, i turni del team nell’intervallo scelto verranno rigenerati.'
                      : 'If enabled, the team assignments in the selected range will be regenerated.',
                ),
                onChanged: (value) {
                  setState(() => _replaceExistingAssignments = value);
                },
              ),
              const SizedBox(height: 8),
              Text(
                _isItalian ? 'Profili da pianificare' : 'Profiles to schedule',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (profiles.isEmpty)
                Text(
                  _isItalian
                      ? 'Nessun profilo turno disponibile.'
                      : 'No shift profiles available.',
                )
              else
                ...profiles.map(_buildProfileTile),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_isItalian ? 'Annulla' : 'Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isItalian ? 'Genera' : 'Generate'),
        ),
      ],
    );
  }

  Widget _buildProfileTile(ShiftProfileEntity profile) {
    final count = _selectedProfileCounts[profile.id];
    final selected = count != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: selected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedProfileCounts[profile.id] = count ?? 1;
                      } else {
                        _selectedProfileCounts.remove(profile.id);
                      }
                    });
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatTime(profile.startTime)} - ${_formatTime(profile.endTime)}${profile.overnight ? ' +1' : ''}',
                      ),
                    ],
                  ),
                ),
                if (selected)
                  DropdownButton<int>(
                    value: count ?? 1,
                    items: List.generate(
                      6,
                      (index) => DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedProfileCounts[profile.id] = value;
                      });
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({
    required DateTime initialDate,
    DateTime? firstDate,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onSelected(_normalizeDate(picked));
    }
  }

  void _submit() {
    if (_selectedTeamId == null || _selectedTeamId!.isEmpty) {
      _showError(_isItalian ? 'Seleziona un team.' : 'Please select a team.');
      return;
    }
    if (_selectedProfileCounts.isEmpty) {
      _showError(
        _isItalian
            ? 'Seleziona almeno un profilo turno.'
            : 'Select at least one shift profile.',
      );
      return;
    }
    if (_to.isBefore(_from)) {
      _showError(
        _isItalian
            ? 'La data finale deve essere successiva o uguale a quella iniziale.'
            : 'The end date must be after or equal to the start date.',
      );
      return;
    }

    Navigator.of(context).pop(
      ShiftAutoPlanRequestEntity(
        teamId: _selectedTeamId!,
        from: _from,
        to: _to,
        replaceExistingAssignments: _replaceExistingAssignments,
        templates: _selectedProfileCounts.entries
            .map(
              (entry) => ShiftAutoPlanTemplateEntity(
                profileId: entry.key,
                requiredMemberCount: entry.value,
              ),
            )
            .toList(),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _formatTime(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.event_outlined),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            Text(
              '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}',
            ),
          ],
        ),
      ),
    );
  }
}
