import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/ui/bloc/sondage_bloc.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/infrastructure/data/team_mapper.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';
import 'package:note_sondage/ui/widgets/time_range_picker.dart';

const _kMaxWidth = 1200.0;

class CreateSondageWeb extends StatefulWidget {
  final String? sondageId;
  final Function()? onsondageCreated;

  const CreateSondageWeb({super.key, this.sondageId, this.onsondageCreated});

  @override
  State<CreateSondageWeb> createState() => _CreateSondageWebState();
}

class _CreateSondageWebState extends State<CreateSondageWeb> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late final List<TextEditingController> _optionControllers;
  bool _isSyncingOptions = false;

  bool _hasExpiry = false;
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 18, minute: 0);
  String? _selectedTeamId;
  late Future<List<TeamEntity>> _teamsFuture;

  @override
  void initState() {
    super.initState();
    _optionControllers = [_buildOptionController(), _buildOptionController()];
    _teamsFuture = _loadCreatableTeams();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _buildOptionController([String text = '']) {
    final controller = TextEditingController(text: text);
    controller.addListener(_syncOptionControllers);
    return controller;
  }

  void _syncOptionControllers() {
    if (_isSyncingOptions || !mounted) return;
    _isSyncingOptions = true;
    var changed = false;

    if (_optionControllers.isNotEmpty &&
        _optionControllers.last.text.trim().isNotEmpty &&
        _optionControllers.length < 10) {
      _optionControllers.add(_buildOptionController());
      changed = true;
    }

    while (_optionControllers.length > 2 &&
        _optionControllers.last.text.trim().isEmpty &&
        _optionControllers[_optionControllers.length - 2].text.trim().isEmpty) {
      final removed = _optionControllers.removeLast();
      removed.removeListener(_syncOptionControllers);
      removed.dispose();
      changed = true;
    }

    _isSyncingOptions = false;
    if (changed) {
      setState(() {});
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      _optionControllers[index].removeListener(_syncOptionControllers);
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
      _syncOptionControllers();
    });
  }

  DateTime? _resolveExpiryDate() {
    if (!_hasExpiry) return null;
    final now = DateTime.now();
    var date = DateTime(
      now.year,
      now.month,
      now.day,
      _end.hour,
      _end.minute,
    );
    if (date.isBefore(now)) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  List<String> _normalizedOptions() {
    return _optionControllers
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  void _submit() {
    final options = _normalizedOptions();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedTeamId == null || _selectedTeamId!.isEmpty || options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona un team e aggiungi almeno 2 opzioni.')),
      );
      return;
    }

    context.read<SondageBloc>().add(
      CreateSondageEvent(
        SondageEntity(
          id: '',
          name: _titleController.text.trim(),
          focus: _descriptionController.text.trim(),
          status: SondageStatus.draft,
          createdDate: DateTime.now(),
          expiryDate: _resolveExpiryDate(),
          teamId: _selectedTeamId,
          description: _descriptionController.text.trim(),
          options: List.generate(
            options.length,
            (index) => SondageOptionEntity(
              id: '',
              label: options[index],
              sortOrder: index,
            ),
          ),
        ),
      ),
    );
  }

  void _reloadTeams() {
    setState(() {
      _selectedTeamId = null;
      _teamsFuture = _loadCreatableTeams();
    });
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _resetOptionControllers();
    setState(() {
      _selectedTeamId = null;
      _hasExpiry = false;
    });
  }

  void _resetOptionControllers() {
    for (final controller in _optionControllers) {
      controller.removeListener(_syncOptionControllers);
      controller.dispose();
    }
    _optionControllers
      ..clear()
      ..add(_buildOptionController())
      ..add(_buildOptionController());
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required Widget child,
    String? title,
    IconData? icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.bgNavbarSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.borderColor?.withValues(alpha: 0.75) ??
              Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: colorScheme.selectionColor, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.iconLabel,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            child,
          ],
        ),
      ),
    );
  }

  Future<List<TeamEntity>> _loadCreatableTeams() async {
    try {
      final response = await DioClient().dio.get('/api/sondage/creatable-teams');
      if (response.data is! List) {
        return const <TeamEntity>[];
      }
      return (response.data as List)
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
          .map(TeamMapper.fromJson)
          .toList();
    } catch (e) {
      debugPrint('[CreateSondage] Errore caricamento team: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocListener<SondageBloc, SondageState>(
      listenWhen: (previous, current) => current is SondageCreated,
      listener: (context, state) {
        if (state is SondageCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localization.surveyCreatedSuccessfully),
              backgroundColor: colorScheme.secondary,
            ),
          );
          _resetForm();
          widget.onsondageCreated?.call();
          Navigator.of(context).maybePop();
        }
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxWidth),
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSectionCard(
                    context: context,
                    title: localization.sondage,
                    icon: Icons.poll_rounded,
                    child: Column(
                      children: [
                        CustomTextFieldImmersive(
                          hintText: localization.askQuestion,
                          maxLines: 2,
                          controller: _titleController,
                        ),
                        const SizedBox(height: 12),
                        CustomTextFieldImmersive(
                          hintText: 'Descrizione',
                          maxLines: 3,
                          controller: _descriptionController,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context: context,
                    title: localization.options,
                    icon: Icons.format_list_bulleted_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...List.generate(_optionControllers.length, (index) {
                          final isTrailingEmpty =
                              index == _optionControllers.length - 1 &&
                              _optionControllers[index].text.trim().isEmpty;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: CustomTextFieldImmersive(
                                    controller: _optionControllers[index],
                                    hintText: isTrailingEmpty
                                        ? '${localization.option} ${index + 1} - continua a scrivere per aggiungerne un’altra'
                                        : '${localization.option} ${index + 1}',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_optionControllers.length > 2 &&
                                    !isTrailingEmpty)
                                  IconButton(
                                    onPressed: () => _removeOption(index),
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: colorScheme.selectionColor,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        Text(
                          'L’ultimo campo crea automaticamente una nuova opzione.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.iconLabel?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSectionCard(
                    context: context,
                    title: 'Team',
                    icon: Icons.groups_rounded,
                    child: FutureBuilder<List<TeamEntity>>(
                      future: _teamsFuture,
                      builder: (context, snapshot) {
                        final teams = snapshot.data ?? const <TeamEntity>[];
                        final selectedStillExists = teams.any(
                          (team) => team.id == _selectedTeamId,
                        );
                        final dropdownValue = selectedStillExists
                            ? _selectedTeamId
                            : null;

                        if (snapshot.connectionState == ConnectionState.waiting &&
                            teams.isEmpty) {
                          return const LinearProgressIndicator(minHeight: 2);
                        }

                        if (snapshot.hasError) {
                          return Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Impossibile caricare i team disponibili.',
                                ),
                              ),
                              TextButton(
                                onPressed: _reloadTeams,
                                child: const Text('Riprova'),
                              ),
                            ],
                          );
                        }

                        if (teams.isEmpty) {
                          return Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Non hai ancora un team in cui puoi creare un sondaggio.',
                                ),
                              ),
                              TextButton(
                                onPressed: _reloadTeams,
                                child: const Text('Ricarica'),
                              ),
                            ],
                          );
                        }

                        return DropdownButtonFormField<String>(
                          value: dropdownValue,
                          decoration: InputDecoration(
                            labelText: 'Team',
                            filled: true,
                            fillColor: colorScheme.homeSecondary,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: teams
                              .where((team) => (team.id ?? '').isNotEmpty)
                              .map(
                                (team) => DropdownMenuItem<String>(
                                  value: team.id,
                                  child: Text(team.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedTeamId = value);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context: context,
                    title: 'Scadenza',
                    icon: Icons.schedule_rounded,
                    child: Column(
                      children: [
                        SwitchListTile(
                          activeThumbColor: colorScheme.selectionColor,
                          value: _hasExpiry,
                          onChanged: (value) {
                            setState(() => _hasExpiry = value);
                          },
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Imposta scadenza'),
                        ),
                        IgnorePointer(
                          ignoring: !_hasExpiry,
                          child: Opacity(
                            opacity: _hasExpiry ? 1 : 0.4,
                            child: TimeRangePicker(
                              start: _start,
                              end: _end,
                              onStartChanged: (val) =>
                                  setState(() => _start = val),
                              onEndChanged: (val) =>
                                  setState(() => _end = val),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _submit,
                      icon: const Icon(Icons.send_rounded, size: 20),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Text(
                          '${localization.create} ${localization.sondage}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
