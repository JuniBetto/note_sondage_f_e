import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/ui/bloc/sondage_bloc.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/infrastructure/data/team_mapper.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';
import 'package:note_sondage/ui/widgets/time_range_picker.dart';
import 'package:showcaseview/showcaseview.dart';

class SondageCreateForm extends StatefulWidget {
  const SondageCreateForm({
    super.key,
    this.onCreated,
    this.onCloseRequested,
    this.showHeader = true,
    this.initialSondage,
    this.tutorialId,
  });

  final VoidCallback? onCreated;
  final VoidCallback? onCloseRequested;
  final bool showHeader;
  final SondageEntity? initialSondage;
  final String? tutorialId;

  @override
  State<SondageCreateForm> createState() => _SondageCreateFormState();
}

class _SondageCreateFormState extends State<SondageCreateForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey _questionSectionKey = GlobalKey();
  final GlobalKey _optionsSectionKey = GlobalKey();
  final GlobalKey _settingsSectionKey = GlobalKey();
  final GlobalKey _teamSectionKey = GlobalKey();
  final GlobalKey _submitSectionKey = GlobalKey();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late final List<TextEditingController> _optionControllers;

  bool _isSyncingOptions = false;
  bool _allowMultipleResponses = false;
  bool _hasExpiry = false;
  bool _isSubmitting = false;
  bool _tutorialScheduled = false;
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 18, minute: 0);
  String? _selectedTeamId;
  late Future<List<TeamEntity>> _teamsFuture;
  bool get _isEditing => widget.initialSondage != null;
  bool get _canEditCurrentSondage {
    final initial = widget.initialSondage;
    if (initial == null) {
      return true;
    }
    return initial.canEdit && initial.status == SondageStatus.draft;
  }

  @override
  void initState() {
    super.initState();
    _optionControllers = <TextEditingController>[];
    _hydrateForm();
    _teamsFuture = _loadCreatableTeams();
  }

  @override
  void dispose() {
    _questionController.dispose();
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
    if (_isSyncingOptions || !mounted) {
      return;
    }

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
    if (_optionControllers.length <= 2) {
      return;
    }

    setState(() {
      _optionControllers[index].removeListener(_syncOptionControllers);
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
      _syncOptionControllers();
    });
  }

  List<String> _normalizedOptions() {
    return _optionControllers
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  void _hydrateForm() {
    final initial = widget.initialSondage;
    if (initial == null) {
      _optionControllers.add(_buildOptionController());
      _optionControllers.add(_buildOptionController());
      return;
    }

    _questionController.text = initial.name;
    _descriptionController.text = initial.description ?? initial.focus;
    _selectedTeamId = initial.teamId;
    _allowMultipleResponses = initial.allowMultipleResponses;
    _hasExpiry = initial.expiryDate != null;
    if (initial.expiryDate != null) {
      final expiry = initial.expiryDate!;
      _end = TimeOfDay(hour: expiry.hour, minute: expiry.minute);
    }

    final labels = initial.options.map((option) => option.label).toList();
    final seededLabels = labels.isEmpty
        ? <String>['', '']
        : <String>[...labels, if (labels.length < 10) ''];
    for (final label in seededLabels) {
      _optionControllers.add(_buildOptionController(label));
    }
    while (_optionControllers.length < 2) {
      _optionControllers.add(_buildOptionController());
    }
  }

  DateTime? _resolveExpiryDate() {
    if (!_hasExpiry) {
      return null;
    }

    final now = DateTime.now();
    var expiry = DateTime(now.year, now.month, now.day, _end.hour, _end.minute);
    if (!expiry.isAfter(now)) {
      expiry = expiry.add(const Duration(days: 1));
    }
    return expiry;
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

  void _resetForm() {
    _questionController.clear();
    _descriptionController.clear();
    _resetOptionControllers();
    setState(() {
      _selectedTeamId = null;
      _allowMultipleResponses = false;
      _hasExpiry = false;
      _start = const TimeOfDay(hour: 9, minute: 0);
      _end = const TimeOfDay(hour: 18, minute: 0);
    });
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) {
      return;
    }
    if (backgroundColor == Colors.red) {
      AppSnackBar.showResolvedError(context, message);
      return;
    }
    if (backgroundColor != null) {
      AppSnackBar.showSuccess(context, message);
      return;
    }
    AppSnackBar.showWarning(context, message);
  }

  Future<List<TeamEntity>> _loadCreatableTeams() async {
    final response = await DioClient().dio.get('/api/sondage/creatable-teams');
    if (response.data is! List) {
      return const <TeamEntity>[];
    }

    return (response.data as List)
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .map(TeamMapper.fromJson)
        .toList();
  }

  void _reloadTeams() {
    setState(() {
      _selectedTeamId = null;
      _teamsFuture = _loadCreatableTeams();
    });
  }

  void _submit() {
    if (_isSubmitting) {
      return;
    }
    if (_isEditing && !_canEditCurrentSondage) {
      _showSnackBar('Solo i sondaggi in bozza possono essere modificati.');
      return;
    }

    final question = _questionController.text.trim();
    final description = _descriptionController.text.trim();
    final options = _normalizedOptions();
    final teamId = _selectedTeamId ?? '';

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (question.isEmpty) {
      _showSnackBar('Inserisci la domanda del sondaggio.');
      return;
    }
    if (teamId.isEmpty) {
      _showSnackBar('Seleziona un team prima di creare il sondaggio.');
      return;
    }
    if (options.length < 2) {
      _showSnackBar('Aggiungi almeno 2 opzioni.');
      return;
    }

    setState(() => _isSubmitting = true);
    final initial = widget.initialSondage;
    final payload = SondageEntity(
      id: initial?.id ?? '',
      name: question,
      focus: description,
      status: initial?.status ?? SondageStatus.draft,
      responses: initial?.responses ?? 0,
      totalVotes: initial?.totalVotes ?? 0,
      totalQuestions: options.length,
      createdDate: initial?.createdDate ?? DateTime.now(),
      expiryDate: _resolveExpiryDate(),
      color: initial?.color ?? Colors.blue,
      createdByUserId: initial?.createdByUserId,
      teamId: teamId,
      teamName: initial?.teamName,
      description: description.isEmpty ? null : description,
      allowMultipleResponses: _allowMultipleResponses,
      options: List.generate(
        options.length,
        (index) => SondageOptionEntity(
          id: index < (initial?.options.length ?? 0)
              ? initial!.options[index].id
              : '',
          label: options[index],
          sortOrder: index,
        ),
      ),
      currentUserOptionId: initial?.currentUserOptionId,
      currentUserOptionIds: initial?.currentUserOptionIds ?? const [],
      canEdit: initial?.canEdit ?? false,
      canDelete: initial?.canDelete ?? false,
      canPublish: initial?.canPublish ?? false,
      canVote: initial?.canVote ?? false,
      canClose: initial?.canClose ?? false,
    );

    context.read<SondageBloc>().add(
      _isEditing ? UpdateSondageEvent(payload) : CreateSondageEvent(payload),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.homeSecondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              colorScheme.borderColor?.withValues(alpha: 0.35) ??
              Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.selectionColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.iconLabel,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsSelector(
    BuildContext context,
    AppLocalizations localization,
    ColorScheme colorScheme,
  ) {
    return FutureBuilder<List<TeamEntity>>(
      future: _teamsFuture,
      builder: (context, snapshot) {
        final teams = snapshot.data ?? const <TeamEntity>[];
        final selectedStillExists = teams.any(
          (team) => team.id == _selectedTeamId,
        );
        final dropdownValue = selectedStillExists ? _selectedTeamId : null;

        if (snapshot.connectionState == ConnectionState.waiting &&
            teams.isEmpty) {
          return const LinearProgressIndicator(minHeight: 2);
        }

        if (snapshot.hasError) {
          return Row(
            children: [
              const Expanded(
                child: Text('Impossibile caricare i team disponibili.'),
              ),
              TextButton(onPressed: _reloadTeams, child: const Text('Riprova')),
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
            labelText: localization.selectTeam,
            filled: true,
            fillColor: Colors.white,
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
          dropdownColor: colorScheme.dialogBackgroundColor,
          onChanged: (value) {
            setState(() => _selectedTeamId = value);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (widget.tutorialId != null && !_isEditing) {
      final tutorialKeys = <GlobalKey>[
        _questionSectionKey,
        _optionsSectionKey,
        _settingsSectionKey,
        _teamSectionKey,
        _submitSectionKey,
      ];
      AppTutorialController.registerTargets(
        tutorialId: widget.tutorialId!,
        keys: tutorialKeys,
      );
      AppTutorialController.registerReplayAction(
        tutorialId: widget.tutorialId!,
        action: () =>
            AppTutorialController.replay(context: context, keys: tutorialKeys),
      );
      _scheduleTutorial(tutorialKeys);
    }

    return BlocListener<SondageBloc, SondageState>(
      listenWhen: (_, current) =>
          current is SondageCreated ||
          current is SondageUpdated ||
          (_isSubmitting && current is SondageError),
      listener: (context, state) {
        if (!mounted) {
          return;
        }
        setState(() => _isSubmitting = false);
        if (state is SondageCreated) {
          widget.onCreated?.call();
          if (!mounted) {
            return;
          }
          if (widget.onCloseRequested != null) {
            widget.onCloseRequested!.call();
          } else {
            _resetForm();
            _showSnackBar(
              localization.surveyCreatedSuccessfully,
              backgroundColor: colorScheme.secondary,
            );
          }
          return;
        }

        if (state is SondageUpdated) {
          widget.onCreated?.call();
          if (!mounted) {
            return;
          }
          widget.onCloseRequested?.call();
          return;
        }

        if (state is SondageError) {
          _showSnackBar(state.message, backgroundColor: Colors.red);
        }
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showHeader) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.bgNavbarSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.poll_rounded,
                          color: colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing
                                  ? 'Modifica ${localization.sondage}'
                                  : localization.sondage,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.iconLabel,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isEditing
                                  ? 'Aggiorna domanda, descrizione, opzioni e team del sondaggio.'
                                  : 'Crea una bozza con domanda, descrizione, opzioni e team di destinazione.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.descriptionColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.tutorialId != null && !_isEditing)
                        IconButton(
                          tooltip: localization.reviewTutorial,
                          onPressed: () =>
                              AppTutorialController.replayRegistered(
                                context: context,
                                tutorialId: widget.tutorialId!,
                              ),
                          icon: const Icon(Icons.help_outline_rounded),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            Showcase(
              key: _questionSectionKey,
              title: _isItalian(context)
                  ? 'Domanda del sondaggio'
                  : 'Survey question',
              description: _isItalian(context)
                  ? 'Qui scrivi la domanda principale e, se serve, una breve descrizione per dare contesto.'
                  : 'Write the main question here and add a short description when you want to give more context.',
              child: _buildSection(
                context: context,
                title: localization.askQuestion,
                icon: Icons.edit_outlined,
                child: Column(
                  children: [
                    CustomTextFieldImmersive(
                      hintText: localization.askQuestion,
                      maxLines: 3,
                      controller: _questionController,
                    ),
                    const SizedBox(height: 12),
                    CustomTextFieldImmersive(
                      hintText: 'Descrizione (opzionale)',
                      maxLines: 4,
                      controller: _descriptionController,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Showcase(
              key: _optionsSectionKey,
              title: _isItalian(context)
                  ? 'Opzioni di risposta'
                  : 'Answer options',
              description: _isItalian(context)
                  ? 'Aggiungi qui le possibili risposte del sondaggio. Puoi riordinarle e tenerne almeno due.'
                  : 'Add the survey answer choices here. You can reorder them and you should keep at least two.',
              child: _buildSection(
                context: context,
                title: localization.options,
                icon: Icons.format_list_bulleted_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aggiungi da 2 a 10 opzioni. Puoi riordinarle trascinando.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.descriptionColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ReorderableListView.builder(
                      itemCount: _optionControllers.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex--;
                          }
                          final item = _optionControllers.removeAt(oldIndex);
                          _optionControllers.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final isTrailingEmpty =
                            index == _optionControllers.length - 1 &&
                            _optionControllers[index].text.trim().isEmpty;
                        return Padding(
                          key: ValueKey(_optionControllers[index]),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: CustomTextFieldImmersive(
                                  controller: _optionControllers[index],
                                  hintText:
                                      '${localization.option} ${index + 1}',
                                ),
                              ),
                              const SizedBox(width: 8),
                              ReorderableDragStartListener(
                                index: index,
                                child: Icon(
                                  Icons.drag_handle_rounded,
                                  color: colorScheme.selectionColor,
                                ),
                              ),
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
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Showcase(
              key: _settingsSectionKey,
              title: _isItalian(context)
                  ? 'Impostazioni del sondaggio'
                  : 'Survey settings',
              description: _isItalian(context)
                  ? 'Qui decidi se permettere risposte multiple e se il sondaggio deve scadere a un orario preciso.'
                  : 'Choose here whether multiple answers are allowed and whether the survey should expire at a specific time.',
              child: _buildSection(
                context: context,
                title: 'Impostazioni',
                icon: Icons.tune_rounded,
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(localization.allowMultipleResponses),
                      value: _allowMultipleResponses,
                      activeColor: colorScheme.selectionColor,
                      onChanged: (value) {
                        setState(() => _allowMultipleResponses = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _hasExpiry,
                      onChanged: (value) {
                        setState(() => _hasExpiry = value ?? false);
                      },
                      activeColor: colorScheme.selectionColor,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: Text(localization.setExpiry),
                    ),
                    IgnorePointer(
                      ignoring: !_hasExpiry,
                      child: Opacity(
                        opacity: _hasExpiry ? 1 : 0.4,
                        child: TimeRangePicker(
                          start: _start,
                          end: _end,
                          onStartChanged: (value) {
                            setState(() => _start = value);
                          },
                          onEndChanged: (value) {
                            setState(() => _end = value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Showcase(
              key: _teamSectionKey,
              title: _isItalian(context) ? 'Team destinatario' : 'Target team',
              description: _isItalian(context)
                  ? 'Seleziona qui la squadra che riceverà il sondaggio.'
                  : 'Select here which team should receive this survey.',
              child: _buildSection(
                context: context,
                title: localization.selectTeam,
                icon: Icons.groups_rounded,
                child: _buildTeamsSelector(context, localization, colorScheme),
              ),
            ),
            if (_isEditing && !_canEditCurrentSondage) ...[
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.25),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline, color: Colors.orange),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Questo sondaggio non e\' piu modificabile. Solo i draft possono essere aggiornati.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Showcase(
              key: _submitSectionKey,
              title: _isItalian(context)
                  ? 'Crea il sondaggio'
                  : 'Create survey',
              description: _isItalian(context)
                  ? 'Quando domanda, opzioni e team sono pronti, usa questo pulsante per creare la bozza del sondaggio.'
                  : 'Once the question, options, and team are ready, use this button to create the survey draft.',
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed:
                    _isSubmitting || (_isEditing && !_canEditCurrentSondage)
                    ? null
                    : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing
                            ? 'Aggiorna ${localization.sondage}'
                            : '${localization.create} ${localization.sondage}',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleTutorial(List<GlobalKey> tutorialKeys) {
    if (_tutorialScheduled) {
      return;
    }
    _tutorialScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || widget.tutorialId == null) {
        return;
      }
      await AppTutorialController.showIfNeeded(
        context: context,
        tutorialId: widget.tutorialId!,
        userId: context.read<AuthBloc>().state.user.uid,
        keys: tutorialKeys,
      );
    });
  }

  bool _isItalian(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'it';
  }
}
