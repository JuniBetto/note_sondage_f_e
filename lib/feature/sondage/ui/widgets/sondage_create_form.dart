import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/utils/app_error_message_resolver.dart';
import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/ui/bloc/sondage_bloc.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/infrastructure/data/team_mapper.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/anchored_dropdown_overlay.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';
import 'package:note_sondage/ui/widgets/submit_on_enter_scope.dart';
import 'package:note_sondage/ui/widgets/time_range_picker.dart';
import 'package:note_sondage/core/tutorial/debug_showcase.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/sondage_create_prefill.dart';

const double _kSondageTeamDropdownMaxHeight = 360;

class SondageCreateForm extends StatefulWidget {
  const SondageCreateForm({
    super.key,
    this.onCreated,
    this.onCloseRequested,
    this.showHeader = true,
    this.initialSondage,
    this.initialPrefill,
    this.tutorialId,
  });

  final VoidCallback? onCreated;
  final VoidCallback? onCloseRequested;
  final bool showHeader;
  final SondageEntity? initialSondage;
  final SondageCreatePrefill? initialPrefill;
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
  final TextEditingController _teamSearchController = TextEditingController();
  final ScrollController _teamScrollController = ScrollController();
  late final List<TextEditingController> _optionControllers;

  bool _isSyncingOptions = false;
  bool _allowMultipleResponses = false;
  bool _hasExpiry = false;
  bool _isSubmitting = false;
  bool _isPublishingAfterSave = false;
  bool _tutorialScheduled = false;
  bool _expiryEdited = false;
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 18, minute: 0);
  DateTime? _expiryAnchorDate;
  String? _selectedTeamId;
  late Future<List<TeamEntity>> _teamsFuture;
  bool get _isEditing => widget.initialSondage != null;
  bool get _isShiftGapWorkflowDraft {
    final initial = widget.initialSondage;
    if (initial == null) {
      return false;
    }
    return initial.isShiftGapAvailabilityWorkflow;
  }

  bool get _canSaveAndPublishWorkflowDraft =>
      _isEditing &&
      _isShiftGapWorkflowDraft &&
      _canEditCurrentSondage &&
      (widget.initialSondage?.canPublish ?? false);

  bool get _canEditCurrentSondage {
    final initial = widget.initialSondage;
    if (initial == null) {
      return true;
    }
    return initial.canEdit;
  }

  _SondageCreateStrings get _strings => _SondageCreateStrings.of(context);

  @override
  void initState() {
    super.initState();
    _optionControllers = <TextEditingController>[];
    _hydrateForm();
    _teamsFuture = _loadCreatableTeams();
  }

  @override
  void didUpdateWidget(covariant SondageCreateForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousId = oldWidget.initialSondage?.id;
    final currentId = widget.initialSondage?.id;
    if (previousId != currentId ||
        oldWidget.initialPrefill != widget.initialPrefill) {
      _replaceFormWithInitialData();
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _descriptionController.dispose();
    _teamSearchController.dispose();
    _teamScrollController.dispose();
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
      final prefill = widget.initialPrefill;
      if (prefill != null) {
        _questionController.text = prefill.question;
        _descriptionController.text = prefill.description ?? '';
        _selectedTeamId = prefill.teamId?.trim().isEmpty == true
            ? null
            : prefill.teamId?.trim();
        _allowMultipleResponses = prefill.allowMultipleResponses;
        _hasExpiry = prefill.expiryDate != null;
        if (prefill.expiryDate != null) {
          final expiry = prefill.expiryDate!;
          _expiryAnchorDate = DateTime(expiry.year, expiry.month, expiry.day);
          final suggestedStartMinutes = (expiry.hour * 60 + expiry.minute) - 60;
          final normalizedStartMinutes = suggestedStartMinutes < 0
              ? 0
              : suggestedStartMinutes;
          _start = TimeOfDay(
            hour: normalizedStartMinutes ~/ 60,
            minute: normalizedStartMinutes % 60,
          );
          _end = TimeOfDay(hour: expiry.hour, minute: expiry.minute);
          _expiryEdited = true;
        }

        final prefilledOptions = prefill.options
            .map((option) => option.trim())
            .where((option) => option.isNotEmpty)
            .toList();
        final seededOptions = prefilledOptions.isEmpty
            ? <String>['', '']
            : <String>[
                ...prefilledOptions.take(10),
                if (prefilledOptions.length < 10) '',
              ];
        for (final option in seededOptions) {
          _optionControllers.add(_buildOptionController(option));
        }
        while (_optionControllers.length < 2) {
          _optionControllers.add(_buildOptionController());
        }
        return;
      }

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
      _expiryAnchorDate = DateTime(expiry.year, expiry.month, expiry.day);
      final suggestedStartMinutes = (expiry.hour * 60 + expiry.minute) - 60;
      final normalizedStartMinutes = suggestedStartMinutes < 0
          ? 0
          : suggestedStartMinutes;
      _start = TimeOfDay(
        hour: normalizedStartMinutes ~/ 60,
        minute: normalizedStartMinutes % 60,
      );
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

  void _replaceFormWithInitialData() {
    _questionController.clear();
    _descriptionController.clear();
    _teamSearchController.clear();
    _clearOptionControllers();
    setState(() {
      _selectedTeamId = null;
      _allowMultipleResponses = false;
      _hasExpiry = false;
      _start = const TimeOfDay(hour: 9, minute: 0);
      _end = const TimeOfDay(hour: 18, minute: 0);
      _expiryAnchorDate = null;
      _expiryEdited = false;
      _isSubmitting = false;
    });
    _hydrateForm();
  }

  DateTime? _resolveExpiryDate() {
    if (!_hasExpiry) {
      return null;
    }

    if (_isEditing && !_expiryEdited) {
      return widget.initialSondage?.expiryDate;
    }

    final now = DateTime.now();
    final anchor = _expiryAnchorDate ?? DateTime(now.year, now.month, now.day);
    var expiry = DateTime(
      anchor.year,
      anchor.month,
      anchor.day,
      _end.hour,
      _end.minute,
    );
    if (!_isEditing && !expiry.isAfter(now)) {
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

  void _clearOptionControllers() {
    for (final controller in _optionControllers) {
      controller.removeListener(_syncOptionControllers);
      controller.dispose();
    }
    _optionControllers.clear();
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
      _expiryAnchorDate = null;
      _expiryEdited = false;
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
      _teamSearchController.clear();
      _teamsFuture = _loadCreatableTeams();
    });
  }

  List<TeamEntity> _filterTeams(List<TeamEntity> teams) {
    final query = _teamSearchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return teams;
    }
    return teams
        .where((team) {
          final name = team.name.toLowerCase();
          final description = team.description.toLowerCase();
          return name.contains(query) || description.contains(query);
        })
        .toList(growable: false);
  }

  int _timeToMinutes(TimeOfDay value) => value.hour * 60 + value.minute;

  bool _isValidTimeRange() => _timeToMinutes(_end) > _timeToMinutes(_start);

  void _clearPublishAfterSaveIntent() {
    if (_isPublishingAfterSave && mounted) {
      setState(() => _isPublishingAfterSave = false);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    if (_isEditing && !_canEditCurrentSondage) {
      _clearPublishAfterSaveIntent();
      _showSnackBar(_strings.onlyDraftSurveysCanBeEdited);
      return;
    }

    final question = _questionController.text.trim();
    final description = _descriptionController.text.trim();
    final options = _normalizedOptions();
    final teamId = _selectedTeamId ?? '';

    if (!(_formKey.currentState?.validate() ?? false)) {
      _clearPublishAfterSaveIntent();
      return;
    }
    if (question.isEmpty) {
      _clearPublishAfterSaveIntent();
      _showSnackBar(_strings.enterSurveyQuestion);
      return;
    }
    if (teamId.isEmpty) {
      _clearPublishAfterSaveIntent();
      _showSnackBar(_strings.selectTeamBeforeCreatingSurvey);
      return;
    }
    if (options.length < 2) {
      _clearPublishAfterSaveIntent();
      _showSnackBar(_strings.addAtLeastTwoOptions);
      return;
    }
    if (_hasExpiry && !_isValidTimeRange()) {
      _clearPublishAfterSaveIntent();
      _showSnackBar(_strings.endTimeMustBeAfterStartTime);
      return;
    }

    final resolvedExpiry = _resolveExpiryDate();
    final initialExpiry = widget.initialSondage?.expiryDate;
    final isChangedPastExpiry =
        _isEditing &&
        resolvedExpiry != null &&
        resolvedExpiry.isBefore(DateTime.now()) &&
        (initialExpiry == null ||
            !resolvedExpiry.isAtSameMomentAs(initialExpiry));
    if (isChangedPastExpiry) {
      _clearPublishAfterSaveIntent();
      _showSnackBar('La nuova scadenza deve essere nel futuro.');
      return;
    }

    setState(() => _isSubmitting = true);
    final initial = widget.initialSondage;
    final prefill = widget.initialPrefill;
    final payload = SondageEntity(
      id: initial?.id ?? '',
      name: question,
      focus: description,
      status: initial?.status ?? SondageStatus.draft,
      responses: initial?.responses ?? 0,
      totalVotes: initial?.totalVotes ?? 0,
      totalQuestions: options.length,
      createdDate: initial?.createdDate ?? DateTime.now(),
      expiryDate: resolvedExpiry,
      color: initial?.color ?? Colors.blue,
      createdByUserId: initial?.createdByUserId,
      teamId: teamId,
      teamName: initial?.teamName,
      description: description.isEmpty ? null : description,
      allowMultipleResponses: _allowMultipleResponses,
      contextType: initial?.contextType ?? prefill?.contextType,
      contextId: initial?.contextId ?? prefill?.contextId,
      sourceType: initial?.sourceType ?? prefill?.sourceType,
      sourceId: initial?.sourceId ?? prefill?.sourceId,
      sourceMessageId: initial?.sourceMessageId ?? prefill?.sourceMessageId,
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
      voterUserIds: initial?.voterUserIds ?? const [],
      canEdit: initial?.canEdit ?? false,
      canDelete: initial?.canDelete ?? false,
      canPublish: initial?.canPublish ?? false,
      canVote: initial?.canVote ?? false,
      canClose: initial?.canClose ?? false,
      canReopen: initial?.canReopen ?? false,
    );

    if (_canSaveAndPublishWorkflowDraft && _isPublishingAfterSave) {
      await _submitAndPublish(payload);
      return;
    }

    context.read<SondageBloc>().add(
      _isEditing ? UpdateSondageEvent(payload) : CreateSondageEvent(payload),
    );
  }

  Future<void> _submitAndPublish(SondageEntity payload) async {
    final bloc = context.read<SondageBloc>();
    try {
      final updated = await bloc.sondageUseCase.updateSondage(payload);
      if (!mounted) {
        return;
      }
      bloc.add(SyncCachedSondageEvent(updated));

      final published = await bloc.sondageUseCase.publishSondage(updated.id);
      if (!mounted) {
        return;
      }
      bloc.add(SyncCachedSondageEvent(published));
      if (!bloc.isClosed) {
        bloc.add(LoadSondagesEvent());
      }
      setState(() {
        _isSubmitting = false;
        _isPublishingAfterSave = false;
      });
      _showSnackBar(
        _strings.shiftGapPublishSuccessMessage,
        backgroundColor: Theme.of(context).colorScheme.secondary,
      );
      if (widget.onCloseRequested != null) {
        widget.onCloseRequested!.call();
        final onCreated = widget.onCreated;
        if (onCreated != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onCreated();
          });
        }
      } else {
        widget.onCreated?.call();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _isPublishingAfterSave = false;
      });
      _showSnackBar(
        AppErrorMessageResolver.resolve(
          e,
          fallback: _strings.shiftGapPublishErrorMessage,
        ),
        backgroundColor: Colors.red,
      );
    }
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
              Expanded(child: Text(_strings.unableToLoadAvailableTeams)),
              CustomAppButton(
                onPressed: _reloadTeams,
                type: ButtonType.text,
                isActive: false,
                child: Text(_strings.retry),
              ),
            ],
          );
        }

        if (teams.isEmpty) {
          return Row(
            children: [
              Expanded(child: Text(_strings.noCreatableTeamYet)),
              CustomAppButton(
                onPressed: _reloadTeams,
                type: ButtonType.text,
                isActive: false,
                child: Text(_strings.reload),
              ),
            ],
          );
        }

        final validTeams = teams
            .where((team) => (team.id ?? '').isNotEmpty)
            .toList(growable: false);
        final filteredTeams = _filterTeams(validTeams);
        final selectedTeam = validTeams.where(
          (team) => team.id == dropdownValue,
        );
        final selected = selectedTeam.isEmpty ? null : selectedTeam.first;

        return AnchoredDropdownOverlay(
          triggerBuilder: (context, isOpen, toggle) =>
              _SondageTeamDropdownTrigger(
                label: '',
                title: selected?.name ?? localization.selectTeam,
                subtitle: selected == null
                    ? _strings.chooseTeamToReceiveSurvey
                    : (selected.description.trim().isNotEmpty
                          ? selected.description
                          : _strings.selectedSurveyTeam),
                isOpen: isOpen,
                onTap: toggle,
              ),
          overlayBuilder: (context, width, maxHeight, close) => ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Container(
              width: width,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _teamSearchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: _strings.searchTeams,
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: _kSondageTeamDropdownMaxHeight,
                      ),
                      child: Scrollbar(
                        controller: _teamScrollController,
                        thumbVisibility: filteredTeams.length > 4,
                        child: ListView.separated(
                          controller: _teamScrollController,
                          shrinkWrap: true,
                          itemCount: filteredTeams.isEmpty
                              ? 1
                              : filteredTeams.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            if (filteredTeams.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant,
                                  ),
                                  color: colorScheme.surface,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 18,
                                      color: colorScheme.descriptionColor,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _strings.noTeamFound,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.descriptionColor,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            final team = filteredTeams[index];
                            return _SondageTeamOptionTile(
                              label: team.name,
                              subtitle: team.description.trim().isNotEmpty
                                  ? team.description
                                  : _strings.teamAvailableForSurvey,
                              isSelected: dropdownValue == team.id,
                              onTap: () {
                                setState(() {
                                  _selectedTeamId = team.id;
                                  _teamSearchController.clear();
                                });
                                close();
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    final strings = _strings;

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
        setState(() {
          _isSubmitting = false;
          _isPublishingAfterSave = false;
        });
        if (state is SondageCreated) {
          _showSnackBar(
            'Creazione del sondaggio in sincronizzazione...',
            backgroundColor: const Color(0xFFFFC107),
          );
          if (widget.onCloseRequested != null) {
            widget.onCloseRequested!.call();
            final onCreated = widget.onCreated;
            if (onCreated != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onCreated();
              });
            }
          } else {
            widget.onCreated?.call();
            _resetForm();
            _showSnackBar(
              localization.surveyCreatedSuccessfully,
              backgroundColor: colorScheme.secondary,
            );
          }
          return;
        }

        if (state is SondageUpdated) {
          _showSnackBar(
            'Aggiornamento del sondaggio in sincronizzazione...',
            backgroundColor: const Color(0xFFFFC107),
          );
          if (widget.onCloseRequested != null) {
            widget.onCloseRequested!.call();
            final onCreated = widget.onCreated;
            if (onCreated != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onCreated();
              });
            }
          } else {
            widget.onCreated?.call();
          }
          return;
        }

        if (state is SondageError) {
          _showSnackBar(state.message, backgroundColor: Colors.red);
        }
      },
      child: SubmitOnEnterScope(
        onSubmit: _isSubmitting || (_isEditing && !_canEditCurrentSondage)
            ? null
            : _submit,
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
                            color: colorScheme.secondary.withValues(
                              alpha: 0.14,
                            ),
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
                                    ? strings.editSurveyHeader(
                                        localization.sondage,
                                      )
                                    : localization.sondage,
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.iconLabel,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isEditing
                                    ? strings.editSurveyIntro
                                    : strings.createSurveyIntro,
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
              if (_isShiftGapWorkflowDraft) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colorScheme.secondary.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: colorScheme.secondary.withValues(
                              alpha: 0.16,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 20,
                            color: colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.shiftGapWorkflowTitle,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.iconLabel,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                strings.shiftGapWorkflowDescription,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.descriptionColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Showcase(
                key: _questionSectionKey,
                title: strings.surveyQuestionTitle,
                description: strings.surveyQuestionDescription,
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
                        hintText: strings.optionalDescription,
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
                title: strings.answerOptionsTitle,
                description: strings.answerOptionsDescription,
                child: _buildSection(
                  context: context,
                  title: localization.options,
                  icon: Icons.format_list_bulleted_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.optionsHelper,
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
                        // ignore: deprecated_member_use
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
                title: strings.surveySettingsTitle,
                description: strings.surveySettingsDescription,
                child: _buildSection(
                  context: context,
                  title: strings.settingsSectionTitle,
                  icon: Icons.tune_rounded,
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text(localization.allowMultipleResponses),
                          value: _allowMultipleResponses,
                          activeThumbColor: colorScheme.selectionColor,
                          onChanged: (value) {
                            setState(() => _allowMultipleResponses = value);
                          },
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          value: _hasExpiry,
                          onChanged: (value) {
                            setState(() {
                              _hasExpiry = value ?? false;
                              _expiryEdited = true;
                              if (_hasExpiry && _expiryAnchorDate == null) {
                                final now = DateTime.now();
                                _expiryAnchorDate = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                );
                              }
                            });
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
                              date:
                                  _expiryAnchorDate ??
                                  DateTime(
                                    DateTime.now().year,
                                    DateTime.now().month,
                                    DateTime.now().day,
                                  ),
                              start: _start,
                              end: _end,
                              onDateChanged: (value) {
                                setState(() {
                                  _expiryAnchorDate = DateTime(
                                    value.year,
                                    value.month,
                                    value.day,
                                  );
                                  _expiryEdited = true;
                                });
                              },
                              onStartChanged: (value) {
                                setState(() {
                                  _start = value;
                                  _expiryEdited = true;
                                });
                              },
                              onEndChanged: (value) {
                                setState(() {
                                  _end = value;
                                  _expiryEdited = true;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Showcase(
                key: _teamSectionKey,
                title: strings.targetTeamTitle,
                description: strings.targetTeamDescription,
                child: _buildSection(
                  context: context,
                  title: localization.selectTeam,
                  icon: Icons.groups_rounded,
                  child: _buildTeamsSelector(
                    context,
                    localization,
                    colorScheme,
                  ),
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
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline, color: Colors.orange),
                        const SizedBox(width: 10),
                        Expanded(child: Text(strings.surveyNoLongerEditable)),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Showcase(
                key: _submitSectionKey,
                title: strings.createSurveyTitle,
                description: strings.createSurveyDescription,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_canSaveAndPublishWorkflowDraft) ...[
                      Row(
                        children: [
                          Expanded(
                            child: CustomAppButton(
                              onPressed:
                                  _isSubmitting ||
                                      (_isEditing && !_canEditCurrentSondage)
                                  ? null
                                  : _submit,
                              type: ButtonType.outlined,
                              foregroundColor: colorScheme.secondary,
                              borderColor: colorScheme.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              borderRadius: 16,
                              isActive: true,
                              fullWidth: true,
                              child: Text(
                                strings.updateSurveyAction(
                                  localization.sondage,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomAppButton(
                              onPressed:
                                  _isSubmitting ||
                                      (_isEditing && !_canEditCurrentSondage)
                                  ? null
                                  : () {
                                      setState(
                                        () => _isPublishingAfterSave = true,
                                      );
                                      _submit();
                                    },
                              type: ButtonType.filled,
                              backgroundColor: colorScheme.secondary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              borderRadius: 16,
                              isActive: true,
                              fullWidth: true,
                              isLoading: _isSubmitting,
                              child: Text(strings.shiftGapSaveAndPublishAction),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        strings.shiftGapSaveAndPublishHelper,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.descriptionColor,
                        ),
                      ),
                    ] else
                      CustomAppButton(
                        onPressed:
                            _isSubmitting ||
                                (_isEditing && !_canEditCurrentSondage)
                            ? null
                            : _submit,
                        type: ButtonType.filled,
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        borderRadius: 16,
                        isActive: true,
                        fullWidth: true,
                        isLoading: _isSubmitting,
                        child: Text(
                          _isEditing
                              ? strings.updateSurveyAction(localization.sondage)
                              : '${localization.create} ${localization.sondage}',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
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
}

class _SondageCreateStrings {
  const _SondageCreateStrings._({
    required this.onlyDraftSurveysCanBeEdited,
    required this.endTimeMustBeAfterStartTime,
    required this.enterSurveyQuestion,
    required this.selectTeamBeforeCreatingSurvey,
    required this.addAtLeastTwoOptions,
    required this.unableToLoadAvailableTeams,
    required this.retry,
    required this.noCreatableTeamYet,
    required this.reload,
    required this.chooseTeamToReceiveSurvey,
    required this.selectedSurveyTeam,
    required this.searchTeams,
    required this.noTeamFound,
    required this.teamAvailableForSurvey,
    required this.editSurveyIntro,
    required this.createSurveyIntro,
    required this.shiftGapWorkflowTitle,
    required this.shiftGapWorkflowDescription,
    required this.surveyQuestionTitle,
    required this.surveyQuestionDescription,
    required this.optionalDescription,
    required this.answerOptionsTitle,
    required this.answerOptionsDescription,
    required this.optionsHelper,
    required this.surveySettingsTitle,
    required this.surveySettingsDescription,
    required this.settingsSectionTitle,
    required this.targetTeamTitle,
    required this.targetTeamDescription,
    required this.surveyNoLongerEditable,
    required this.createSurveyTitle,
    required this.createSurveyDescription,
    required this.shiftGapSaveAndPublishAction,
    required this.shiftGapSaveAndPublishHelper,
    required this.shiftGapPublishSuccessMessage,
    required this.shiftGapPublishErrorMessage,
    required this.editSurveyHeaderBuilder,
    required this.updateSurveyActionBuilder,
  });

  final String onlyDraftSurveysCanBeEdited;
  final String endTimeMustBeAfterStartTime;
  final String enterSurveyQuestion;
  final String selectTeamBeforeCreatingSurvey;
  final String addAtLeastTwoOptions;
  final String unableToLoadAvailableTeams;
  final String retry;
  final String noCreatableTeamYet;
  final String reload;
  final String chooseTeamToReceiveSurvey;
  final String selectedSurveyTeam;
  final String searchTeams;
  final String noTeamFound;
  final String teamAvailableForSurvey;
  final String editSurveyIntro;
  final String createSurveyIntro;
  final String shiftGapWorkflowTitle;
  final String shiftGapWorkflowDescription;
  final String surveyQuestionTitle;
  final String surveyQuestionDescription;
  final String optionalDescription;
  final String answerOptionsTitle;
  final String answerOptionsDescription;
  final String optionsHelper;
  final String surveySettingsTitle;
  final String surveySettingsDescription;
  final String settingsSectionTitle;
  final String targetTeamTitle;
  final String targetTeamDescription;
  final String surveyNoLongerEditable;
  final String createSurveyTitle;
  final String createSurveyDescription;
  final String shiftGapSaveAndPublishAction;
  final String shiftGapSaveAndPublishHelper;
  final String shiftGapPublishSuccessMessage;
  final String shiftGapPublishErrorMessage;
  final String Function(String surveyLabel) editSurveyHeaderBuilder;
  final String Function(String surveyLabel) updateSurveyActionBuilder;

  String editSurveyHeader(String surveyLabel) =>
      editSurveyHeaderBuilder(surveyLabel);
  String updateSurveyAction(String surveyLabel) =>
      updateSurveyActionBuilder(surveyLabel);

  static _SondageCreateStrings of(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'it':
        return _it;
      case 'fr':
        return _fr;
      case 'es':
        return _es;
      default:
        return _en;
    }
  }

  static const _SondageCreateStrings _en = _SondageCreateStrings._(
    onlyDraftSurveysCanBeEdited:
        'You do not have permission to edit this survey.',
    endTimeMustBeAfterStartTime: 'End time must be later than start time.',
    enterSurveyQuestion: 'Enter the survey question.',
    selectTeamBeforeCreatingSurvey: 'Select a team before creating the survey.',
    addAtLeastTwoOptions: 'Add at least 2 options.',
    unableToLoadAvailableTeams: 'Unable to load the available teams.',
    retry: 'Retry',
    noCreatableTeamYet:
        'You do not have a team yet where you can create a survey.',
    reload: 'Reload',
    chooseTeamToReceiveSurvey: 'Choose the team that will receive the survey',
    selectedSurveyTeam: 'Selected survey team',
    searchTeams: 'Search team...',
    noTeamFound: 'No team found',
    teamAvailableForSurvey: 'Team available for this survey',
    editSurveyIntro:
        'Update the question, description, options, and target team for this survey.',
    createSurveyIntro:
        'Create a draft with the question, description, options, and target team.',
    shiftGapWorkflowTitle: 'Shift coverage smart action',
    shiftGapWorkflowDescription:
        'This draft was generated to help cover an open shift. You can adjust the survey before publishing it to the team.',
    surveyQuestionTitle: 'Survey question',
    surveyQuestionDescription:
        'Write the main question here and add a short description when you want to give more context.',
    optionalDescription: 'Description (optional)',
    answerOptionsTitle: 'Answer options',
    answerOptionsDescription:
        'Add the survey answer choices here. You can reorder them and you should keep at least two.',
    optionsHelper:
        'Add from 2 to 10 options. You can reorder them by dragging.',
    surveySettingsTitle: 'Survey settings',
    surveySettingsDescription:
        'Choose here whether multiple answers are allowed and whether the survey should expire at a specific time.',
    settingsSectionTitle: 'Settings',
    targetTeamTitle: 'Target team',
    targetTeamDescription: 'Select here which team should receive this survey.',
    surveyNoLongerEditable:
        'This survey cannot be edited with your current permissions.',
    createSurveyTitle: 'Create survey',
    createSurveyDescription:
        'Once the question, options, and team are ready, use this button to create the survey draft.',
    shiftGapSaveAndPublishAction: 'Save and publish',
    shiftGapSaveAndPublishHelper:
        'Use this action when the survey is ready to be sent to the team for shift coverage.',
    shiftGapPublishSuccessMessage:
        'Shift coverage survey published successfully.',
    shiftGapPublishErrorMessage:
        'We could not save and publish the survey right now.',
    editSurveyHeaderBuilder: _editHeaderEn,
    updateSurveyActionBuilder: _updateActionEn,
  );

  static const _SondageCreateStrings _it = _SondageCreateStrings._(
    onlyDraftSurveysCanBeEdited:
        'Non hai i permessi per modificare questo sondaggio.',
    endTimeMustBeAfterStartTime:
        'L\'orario di fine deve essere successivo all\'orario di inizio.',
    enterSurveyQuestion: 'Inserisci la domanda del sondaggio.',
    selectTeamBeforeCreatingSurvey:
        'Seleziona un team prima di creare il sondaggio.',
    addAtLeastTwoOptions: 'Aggiungi almeno 2 opzioni.',
    unableToLoadAvailableTeams: 'Impossibile caricare i team disponibili.',
    retry: 'Riprova',
    noCreatableTeamYet:
        'Non hai ancora un team in cui puoi creare un sondaggio.',
    reload: 'Ricarica',
    chooseTeamToReceiveSurvey: 'Scegli il team che riceverà il sondaggio',
    selectedSurveyTeam: 'Team selezionato per il sondaggio',
    searchTeams: 'Cerca team...',
    noTeamFound: 'Nessun team trovato',
    teamAvailableForSurvey: 'Team disponibile per ricevere il sondaggio',
    editSurveyIntro:
        'Aggiorna domanda, descrizione, opzioni e team del sondaggio.',
    createSurveyIntro:
        'Crea una bozza con domanda, descrizione, opzioni e team di destinazione.',
    shiftGapWorkflowTitle: 'Smart Action copertura turno',
    shiftGapWorkflowDescription:
        'Questa bozza e stata generata per aiutare a coprire un turno scoperto. Puoi modificarla prima di pubblicarla al team.',
    surveyQuestionTitle: 'Domanda del sondaggio',
    surveyQuestionDescription:
        'Qui scrivi la domanda principale e, se serve, una breve descrizione per dare contesto.',
    optionalDescription: 'Descrizione (opzionale)',
    answerOptionsTitle: 'Opzioni di risposta',
    answerOptionsDescription:
        'Aggiungi qui le possibili risposte del sondaggio. Puoi riordinarle e tenerne almeno due.',
    optionsHelper: 'Aggiungi da 2 a 10 opzioni. Puoi riordinarle trascinando.',
    surveySettingsTitle: 'Impostazioni del sondaggio',
    surveySettingsDescription:
        'Qui decidi se permettere risposte multiple e se il sondaggio deve scadere a un orario preciso.',
    settingsSectionTitle: 'Impostazioni',
    targetTeamTitle: 'Team destinatario',
    targetTeamDescription:
        'Seleziona qui la squadra che riceverà il sondaggio.',
    surveyNoLongerEditable:
        'Questo sondaggio non può essere modificato con i tuoi permessi attuali.',
    createSurveyTitle: 'Crea il sondaggio',
    createSurveyDescription:
        'Quando domanda, opzioni e team sono pronti, usa questo pulsante per creare la bozza del sondaggio.',
    shiftGapSaveAndPublishAction: 'Salva e pubblica',
    shiftGapSaveAndPublishHelper:
        'Usa questa azione quando il sondaggio e pronto per essere inviato al team e coprire il turno.',
    shiftGapPublishSuccessMessage:
        'Sondaggio di copertura turno pubblicato con successo.',
    shiftGapPublishErrorMessage:
        'Impossibile salvare e pubblicare il sondaggio in questo momento.',
    editSurveyHeaderBuilder: _editHeaderIt,
    updateSurveyActionBuilder: _updateActionIt,
  );

  static const _SondageCreateStrings _fr = _SondageCreateStrings._(
    onlyDraftSurveysCanBeEdited:
        'Vous n\'avez pas l\'autorisation de modifier ce sondage.',
    endTimeMustBeAfterStartTime:
        'L\'heure de fin doit être postérieure à l\'heure de début.',
    enterSurveyQuestion: 'Saisissez la question du sondage.',
    selectTeamBeforeCreatingSurvey:
        'Sélectionnez une équipe avant de créer le sondage.',
    addAtLeastTwoOptions: 'Ajoutez au moins 2 options.',
    unableToLoadAvailableTeams:
        'Impossible de charger les équipes disponibles.',
    retry: 'Réessayer',
    noCreatableTeamYet:
        'Vous n’avez pas encore d’équipe dans laquelle créer un sondage.',
    reload: 'Recharger',
    chooseTeamToReceiveSurvey: 'Choisissez l’équipe qui recevra le sondage',
    selectedSurveyTeam: 'Équipe sélectionnée pour le sondage',
    searchTeams: 'Rechercher une équipe...',
    noTeamFound: 'Aucune équipe trouvée',
    teamAvailableForSurvey: 'Équipe disponible pour ce sondage',
    editSurveyIntro:
        'Mettez à jour la question, la description, les options et l’équipe cible du sondage.',
    createSurveyIntro:
        'Créez un brouillon avec la question, la description, les options et l’équipe cible.',
    shiftGapWorkflowTitle: 'Action intelligente de couverture',
    shiftGapWorkflowDescription:
        'Ce brouillon a ete genere pour aider a couvrir un quart ouvert. Vous pouvez le modifier avant de le publier a l equipe.',
    surveyQuestionTitle: 'Question du sondage',
    surveyQuestionDescription:
        'Saisissez ici la question principale et ajoutez une courte description si vous souhaitez donner plus de contexte.',
    optionalDescription: 'Description (facultative)',
    answerOptionsTitle: 'Options de réponse',
    answerOptionsDescription:
        'Ajoutez ici les réponses possibles du sondage. Vous pouvez les réorganiser et en conserver au moins deux.',
    optionsHelper:
        'Ajoutez de 2 à 10 options. Vous pouvez les réorganiser par glisser-déposer.',
    surveySettingsTitle: 'Paramètres du sondage',
    surveySettingsDescription:
        'Choisissez ici si plusieurs réponses sont autorisées et si le sondage doit expirer à une heure précise.',
    settingsSectionTitle: 'Paramètres',
    targetTeamTitle: 'Équipe cible',
    targetTeamDescription: 'Sélectionnez ici l’équipe qui recevra ce sondage.',
    surveyNoLongerEditable:
        'Ce sondage ne peut pas être modifié avec vos autorisations actuelles.',
    createSurveyTitle: 'Créer le sondage',
    createSurveyDescription:
        'Quand la question, les options et l’équipe sont prêtes, utilisez ce bouton pour créer le brouillon du sondage.',
    shiftGapSaveAndPublishAction: 'Enregistrer et publier',
    shiftGapSaveAndPublishHelper:
        'Utilisez cette action lorsque le sondage est pret a etre envoye a l equipe pour couvrir le quart.',
    shiftGapPublishSuccessMessage:
        'Le sondage de couverture a ete publie avec succes.',
    shiftGapPublishErrorMessage:
        'Impossible d enregistrer et publier le sondage pour le moment.',
    editSurveyHeaderBuilder: _editHeaderFr,
    updateSurveyActionBuilder: _updateActionFr,
  );

  static const _SondageCreateStrings _es = _SondageCreateStrings._(
    onlyDraftSurveysCanBeEdited: 'No tienes permiso para editar esta encuesta.',
    endTimeMustBeAfterStartTime:
        'La hora de fin debe ser posterior a la hora de inicio.',
    enterSurveyQuestion: 'Introduce la pregunta de la encuesta.',
    selectTeamBeforeCreatingSurvey:
        'Selecciona un equipo antes de crear la encuesta.',
    addAtLeastTwoOptions: 'Añade al menos 2 opciones.',
    unableToLoadAvailableTeams:
        'No se pudieron cargar los equipos disponibles.',
    retry: 'Reintentar',
    noCreatableTeamYet:
        'Todavía no tienes un equipo donde puedas crear una encuesta.',
    reload: 'Recargar',
    chooseTeamToReceiveSurvey: 'Elige el equipo que recibirá la encuesta',
    selectedSurveyTeam: 'Equipo seleccionado para la encuesta',
    searchTeams: 'Buscar equipo...',
    noTeamFound: 'No se encontró ningún equipo',
    teamAvailableForSurvey: 'Equipo disponible para esta encuesta',
    editSurveyIntro:
        'Actualiza la pregunta, la descripción, las opciones y el equipo de destino de la encuesta.',
    createSurveyIntro:
        'Crea un borrador con la pregunta, la descripción, las opciones y el equipo de destino.',
    shiftGapWorkflowTitle: 'Smart Action de cobertura',
    shiftGapWorkflowDescription:
        'Este borrador se genero para ayudar a cubrir un turno abierto. Puedes ajustarlo antes de publicarlo al equipo.',
    surveyQuestionTitle: 'Pregunta de la encuesta',
    surveyQuestionDescription:
        'Escribe aquí la pregunta principal y añade una breve descripción si quieres dar más contexto.',
    optionalDescription: 'Descripción (opcional)',
    answerOptionsTitle: 'Opciones de respuesta',
    answerOptionsDescription:
        'Añade aquí las posibles respuestas de la encuesta. Puedes reordenarlas y deberías mantener al menos dos.',
    optionsHelper:
        'Añade de 2 a 10 opciones. Puedes reordenarlas arrastrándolas.',
    surveySettingsTitle: 'Configuración de la encuesta',
    surveySettingsDescription:
        'Elige aquí si se permiten respuestas múltiples y si la encuesta debe caducar a una hora específica.',
    settingsSectionTitle: 'Configuración',
    targetTeamTitle: 'Equipo de destino',
    targetTeamDescription:
        'Selecciona aquí el equipo que recibirá esta encuesta.',
    surveyNoLongerEditable:
        'Esta encuesta no se puede editar con tus permisos actuales.',
    createSurveyTitle: 'Crear encuesta',
    createSurveyDescription:
        'Cuando la pregunta, las opciones y el equipo estén listos, usa este botón para crear el borrador de la encuesta.',
    shiftGapSaveAndPublishAction: 'Guardar y publicar',
    shiftGapSaveAndPublishHelper:
        'Usa esta accion cuando la encuesta este lista para enviarse al equipo y cubrir el turno.',
    shiftGapPublishSuccessMessage:
        'Encuesta de cobertura de turno publicada correctamente.',
    shiftGapPublishErrorMessage:
        'No se pudo guardar y publicar la encuesta en este momento.',
    editSurveyHeaderBuilder: _editHeaderEs,
    updateSurveyActionBuilder: _updateActionEs,
  );

  static String _editHeaderEn(String surveyLabel) => 'Edit $surveyLabel';
  static String _editHeaderIt(String surveyLabel) => 'Modifica $surveyLabel';
  static String _editHeaderFr(String surveyLabel) => 'Modifier $surveyLabel';
  static String _editHeaderEs(String surveyLabel) => 'Editar $surveyLabel';

  static String _updateActionEn(String surveyLabel) => 'Update $surveyLabel';
  static String _updateActionIt(String surveyLabel) => 'Aggiorna $surveyLabel';
  static String _updateActionFr(String surveyLabel) =>
      'Mettre à jour $surveyLabel';
  static String _updateActionEs(String surveyLabel) =>
      'Actualizar $surveyLabel';
}

class _SondageTeamDropdownTrigger extends StatelessWidget {
  const _SondageTeamDropdownTrigger({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.isOpen,
    required this.onTap,
  });

  final String label;
  final String title;
  final String subtitle;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          suffixIcon: Icon(
            isOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.selectionColor!.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.groups_rounded,
                size: 18,
                color: colorScheme.selectionColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.descriptionColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SondageTeamOptionTile extends StatelessWidget {
  const _SondageTeamOptionTile({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
          ),
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : colorScheme.surface,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colorScheme.selectionColor!.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                Icons.groups_rounded,
                size: 16,
                color: colorScheme.selectionColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.descriptionColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
