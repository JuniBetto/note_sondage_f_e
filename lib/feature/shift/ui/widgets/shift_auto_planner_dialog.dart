import 'package:flutter/material.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_auto_plan_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_calendar_team_picker.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

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
  ShiftAutoPlannerMode _plannerMode = ShiftAutoPlannerMode.rotation;
  final Map<String, int> _selectedProfileCounts = <String, int>{};
  final Map<String, int> _selectedProfileSimultaneousCounts = <String, int>{};

  String get _languageCode =>
      Localizations.localeOf(context).languageCode.toLowerCase();

  int get _selectedTeamMaxPeople {
    final selectedTeam = widget.teams.cast<TeamEntityForView?>().firstWhere(
      (entry) => entry?.team.id == _selectedTeamId,
      orElse: () => null,
    );
    if (selectedTeam == null) {
      return 1;
    }
    if (selectedTeam.members.isNotEmpty) {
      return selectedTeam.members.length;
    }
    return selectedTeam.team.memberCount > 0
        ? selectedTeam.team.memberCount
        : 1;
  }

  void _clampProfileCountsToSelectedTeam() {
    final maxPeople = _selectedTeamMaxPeople;
    _selectedProfileCounts.updateAll((_, value) {
      if (value < 1) {
        return 1;
      }
      if (value > maxPeople) {
        return maxPeople;
      }
      return value;
    });
    _selectedProfileSimultaneousCounts.updateAll((profileId, value) {
      final minimum = _selectedProfileCounts[profileId] ?? 1;
      if (value < minimum) {
        return minimum;
      }
      if (value > maxPeople) {
        return maxPeople;
      }
      return value;
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedTeamId =
        widget.initialTeamId ??
        (widget.teams.isNotEmpty ? widget.teams.first.team.id : null);
    final now = DateTime.now();
    _from = _normalizeDate(widget.initialFrom ?? now);
    _to = _normalizeDate(widget.initialTo ?? _from);
    _clampProfileCountsToSelectedTeam();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final compact = widget.compact || MediaQuery.of(context).size.width < 720;
    final profiles = [...widget.profiles]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 24,
        vertical: compact ? 16 : 24,
      ),
      title: Text(
        _t(
          it: 'Shift Auto Planner',
          en: 'Shift Auto Planner',
          fr: 'Shift Auto Planner',
          es: 'Shift Auto Planner',
        ),
      ),
      content: SizedBox(
        width: compact ? 340 : 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _plannerMode == ShiftAutoPlannerMode.rotation
                    ? _t(
                        it: 'Genera automaticamente i turni del team usando i profili esistenti e una rotazione equa dei membri disponibili.',
                        en: 'Automatically generate team shifts using existing profiles and a fair rotation of available members.',
                        fr: 'Générez automatiquement les shifts de l’équipe à partir des profils existants et d’une rotation équitable des membres disponibles.',
                        es: 'Genera automáticamente los turnos del equipo usando los perfiles existentes y una rotación equilibrada de los miembros disponibles.',
                      )
                    : _t(
                        it: 'Copre l’intero profilo turno usando più membri del team in sequenza o in parallelo, rispettando i vincoli disponibili.',
                        en: 'Cover the whole shift profile by combining multiple team members sequentially or in parallel while respecting available constraints.',
                        fr: 'Couvrez tout le profil de shift en combinant plusieurs membres de l’équipe de façon séquentielle ou parallèle tout en respectant les contraintes disponibles.',
                        es: 'Cubre todo el perfil de turno combinando varios miembros del equipo de forma secuencial o en paralelo respetando las restricciones disponibles.',
                      ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: compact ? 12.5 : 14,
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<ShiftAutoPlannerMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment<ShiftAutoPlannerMode>(
                    value: ShiftAutoPlannerMode.rotation,
                    label: Text(
                      _t(
                        it: 'Rotazione',
                        en: 'Rotation',
                        fr: 'Rotation',
                        es: 'Rotación',
                      ),
                    ),
                  ),
                  ButtonSegment<ShiftAutoPlannerMode>(
                    value: ShiftAutoPlannerMode.coverage,
                    label: Text(
                      _t(
                        it: 'Copertura',
                        en: 'Coverage',
                        fr: 'Couverture',
                        es: 'Cobertura',
                      ),
                    ),
                  ),
                ],
                selected: {_plannerMode},
                onSelectionChanged: (selection) {
                  final nextMode = selection.first;
                  setState(() {
                    _plannerMode = nextMode;
                    if (_plannerMode == ShiftAutoPlannerMode.coverage) {
                      _replaceExistingAssignments = true;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              ShiftCalendarTeamPicker(
                teams: widget.teams
                    .where((entry) => entry.team.id != null)
                    .toList(),
                selectedTeamId: _selectedTeamId,
                includePersonalOption: false,
                unselectedTitle: _t(
                  it: 'Team',
                  en: 'Team',
                  fr: 'Équipe',
                  es: 'Equipo',
                ),
                triggerSubtitle: loc.changeOrSearchTeam,
                onChanged: (value) {
                  setState(() {
                    _selectedTeamId = value;
                    _clampProfileCountsToSelectedTeam();
                  });
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _DateField(
                    label: _t(it: 'Dal', en: 'From', fr: 'Du', es: 'Desde'),
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
                    label: _t(it: 'Al', en: 'To', fr: 'Au', es: 'Hasta'),
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
                value: _plannerMode == ShiftAutoPlannerMode.coverage
                    ? true
                    : _replaceExistingAssignments,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _t(
                    it: 'Sostituisci i turni già presenti',
                    en: 'Replace existing assignments',
                    fr: 'Remplacer les shifts existants',
                    es: 'Reemplazar los turnos existentes',
                  ),
                ),
                subtitle: Text(
                  _plannerMode == ShiftAutoPlannerMode.coverage
                      ? _t(
                          it: 'Nella modalità copertura è sempre attivo per poter ricostruire la copertura completa del turno.',
                          en: 'In coverage mode this is always enabled so the full shift coverage can be rebuilt.',
                          fr: 'En mode couverture, cette option reste toujours active pour reconstruire toute la couverture du shift.',
                          es: 'En modo cobertura siempre está activo para reconstruir toda la cobertura del turno.',
                        )
                      : _t(
                          it: 'Se attivo, i turni del team nell’intervallo scelto verranno rigenerati.',
                          en: 'If enabled, the team assignments in the selected range will be regenerated.',
                          fr: 'Si activé, les affectations de l’équipe dans la période choisie seront régénérées.',
                          es: 'Si está activo, los turnos del equipo en el intervalo seleccionado se regenerarán.',
                        ),
                ),
                onChanged: _plannerMode == ShiftAutoPlannerMode.coverage
                    ? null
                    : (value) {
                        setState(() => _replaceExistingAssignments = value);
                      },
              ),
              const SizedBox(height: 8),
              Text(
                _t(
                  it: 'Profili da pianificare',
                  en: 'Profiles to schedule',
                  fr: 'Profils à planifier',
                  es: 'Perfiles a planificar',
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _plannerMode == ShiftAutoPlannerMode.rotation
                    ? _t(
                        it: 'Il numero a destra indica quante persone devono coprire quel profilo turno ogni giorno selezionato.',
                        en: 'The number on the right indicates how many people should cover that shift profile on each selected day.',
                        fr: 'Le nombre à droite indique combien de personnes doivent couvrir ce profil de shift chaque jour sélectionné.',
                        es: 'El número de la derecha indica cuántas personas deben cubrir ese perfil de turno en cada día seleccionado.',
                      )
                    : _t(
                        it: 'Il numero a destra indica quante linee di copertura complete vuoi creare su quel profilo. Ogni linea può essere coperta da più membri sommati tra loro.',
                        en: 'The number on the right indicates how many full coverage lanes you want for that profile. Each lane can be covered by multiple members combined together.',
                        fr: 'Le nombre à droite indique combien de lignes de couverture complètes vous voulez pour ce profil. Chaque ligne peut être couverte par plusieurs membres combinés.',
                        es: 'El número de la derecha indica cuántas líneas de cobertura completas quieres para ese perfil. Cada línea puede ser cubierta por varios miembros combinados.',
                      ),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: compact ? 11.5 : 12,
                ),
              ),
              const SizedBox(height: 8),
              if (profiles.isEmpty)
                Text(
                  _t(
                    it: 'Nessun profilo turno disponibile.',
                    en: 'No shift profiles available.',
                    fr: 'Aucun profil de shift disponible.',
                    es: 'No hay perfiles de turno disponibles.',
                  ),
                )
              else
                ...profiles.map(
                  (profile) => _buildProfileTile(profile, compact),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primaryColor,
          ),
          child: Text(
            _t(it: 'Annulla', en: 'Cancel', fr: 'Annuler', es: 'Cancelar'),
            style: textTheme.bodyMedium!.copyWith(
              color: colorScheme.textInvertedColor,
            ),
          ),
        ),
        FilledButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primaryColor,
          ),
          child: Text(
            _t(it: 'Genera', en: 'Generate', fr: 'Générer', es: 'Generar'),
            style: textTheme.bodyMedium!.copyWith(
              color: colorScheme.textInvertedColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTile(ShiftProfileEntity profile, bool compact) {
    final count = _selectedProfileCounts[profile.id];
    final simultaneousCount = _selectedProfileSimultaneousCounts[profile.id];
    final selected = count != null;
    final maxPeople = _selectedTeamMaxPeople;
    final safeCount = count == null
        ? 1
        : (count > maxPeople ? maxPeople : (count < 1 ? 1 : count));
    final safeSimultaneousCount = simultaneousCount == null
        ? safeCount
        : (simultaneousCount > maxPeople
              ? maxPeople
              : (simultaneousCount < safeCount
                    ? safeCount
                    : simultaneousCount));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: selected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedProfileCounts[profile.id] = safeCount;
                        _selectedProfileSimultaneousCounts[profile.id] =
                            safeSimultaneousCount;
                      } else {
                        _selectedProfileCounts.remove(profile.id);
                        _selectedProfileSimultaneousCounts.remove(profile.id);
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
                          fontSize: compact ? 13 : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatTime(profile.startTime)} - ${_formatTime(profile.endTime)}${profile.overnight ? ' +1' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: compact ? 11.5 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _plannerMode == ShiftAutoPlannerMode.rotation
                            ? _t(
                                it: 'Persone',
                                en: 'People',
                                fr: 'Personnes',
                                es: 'Personas',
                              )
                            : _t(
                                it: 'Coperture',
                                en: 'Coverage',
                                fr: 'Couvertures',
                                es: 'Coberturas',
                              ),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      DropdownButton<int>(
                        value: safeCount,
                        items: List.generate(
                          maxPeople,
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
                            final currentSimultaneous =
                                _selectedProfileSimultaneousCounts[profile
                                    .id] ??
                                value;
                            _selectedProfileSimultaneousCounts[profile.id] =
                                currentSimultaneous < value
                                ? value
                                : currentSimultaneous;
                          });
                        },
                      ),
                    ],
                  ),
              ],
            ),
            if (selected && _plannerMode == ShiftAutoPlannerMode.coverage) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _t(
                        it: 'Compresenza',
                        en: 'Overlap',
                        fr: 'Présence simultanée',
                        es: 'Coincidencia',
                      ),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      _t(
                        it: 'Numero totale di persone che possono stare in turno nello stesso momento per questo profilo.',
                        en: 'Total number of people allowed on this profile at the same time.',
                        fr: 'Nombre total de personnes autorisées en même temps sur ce profil.',
                        es: 'Número total de personas permitidas al mismo tiempo en este perfil.',
                      ),
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: compact ? 10.5 : 11,
                      ),
                    ),
                    DropdownButton<int>(
                      value: safeSimultaneousCount,
                      items: List.generate(
                        maxPeople - safeCount + 1,
                        (index) => DropdownMenuItem<int>(
                          value: safeCount + index,
                          child: Text('${safeCount + index}'),
                        ),
                      ),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _selectedProfileSimultaneousCounts[profile.id] =
                              value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
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
      _showError(
        _t(
          it: 'Seleziona un team.',
          en: 'Please select a team.',
          fr: 'Veuillez sélectionner une équipe.',
          es: 'Selecciona un equipo.',
        ),
      );
      return;
    }
    if (_selectedProfileCounts.isEmpty) {
      _showError(
        _t(
          it: 'Seleziona almeno un profilo turno.',
          en: 'Select at least one shift profile.',
          fr: 'Sélectionnez au moins un profil de shift.',
          es: 'Selecciona al menos un perfil de turno.',
        ),
      );
      return;
    }
    if (_to.isBefore(_from)) {
      _showError(
        _t(
          it: 'La data finale deve essere successiva o uguale a quella iniziale.',
          en: 'The end date must be after or equal to the start date.',
          fr: 'La date de fin doit être postérieure ou égale à la date de début.',
          es: 'La fecha final debe ser posterior o igual a la fecha inicial.',
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      ShiftAutoPlanRequestEntity(
        teamId: _selectedTeamId!,
        from: _from,
        to: _to,
        plannerMode: _plannerMode,
        replaceExistingAssignments:
            _plannerMode == ShiftAutoPlannerMode.coverage
            ? true
            : _replaceExistingAssignments,
        templates: _selectedProfileCounts.entries
            .map(
              (entry) => ShiftAutoPlanTemplateEntity(
                profileId: entry.key,
                requiredMemberCount: entry.value,
                simultaneousMemberCount:
                    _plannerMode == ShiftAutoPlannerMode.coverage
                    ? (_selectedProfileSimultaneousCounts[entry.key] ??
                          entry.value)
                    : null,
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

  String _t({required String it, required String en, String? fr, String? es}) {
    switch (_languageCode) {
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
