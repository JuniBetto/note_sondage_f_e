import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:note_sondage/feature/notification/realtime/team_realtime_coordinator.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_service.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/feature/team/ui/helper/self_admin_invite_guard.dart';
import 'package:note_sondage/feature/team/ui/helper/user_form_data.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/add_user_mobile.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/list_checkbox.dart';
import 'package:note_sondage/feature/team/ui/widgets/team_clocking_requirement_section.dart';
import 'package:note_sondage/feature/team/ui/widgets/team_members_section.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/app_toggle_switch.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';
import 'package:note_sondage/ui/widgets/submit_on_enter_scope.dart';
import 'package:note_sondage/core/tutorial/debug_showcase.dart';

class CreateTeamMobile extends StatefulWidget {
  final String? teamId;
  final bool readOnly;
  final Function()? onTeamCreated;
  final ValueChanged<TeamSectionPermissions>? onPermissionsChanged;

  const CreateTeamMobile({
    super.key,
    this.onTeamCreated,
    this.teamId,
    this.readOnly = false,
    this.onPermissionsChanged,
  });

  @override
  State<CreateTeamMobile> createState() => _CreateTeamMobileState();
}

class _CreateTeamMobileState extends State<CreateTeamMobile> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey _teamInfoKey = GlobalKey();
  final GlobalKey _teamColorKey = GlobalKey();
  final GlobalKey _teamMembersKey = GlobalKey();
  final GlobalKey _teamActionKey = GlobalKey();
  final TextEditingController nameTeamController = TextEditingController();
  final TextEditingController descriptionTeamController =
      TextEditingController();

  final List<InviteFormData> listInviteFormData = [
    InviteFormData(
      emailController: TextEditingController(),
      roleController: TextEditingController(),
    ),
  ];

  List<String> selectedColor = [];
  late final TeamBloc _teamBloc;
  bool _isLoading = false;
  String? _ownerUserId;
  bool _clockingRequired = false;
  String _clockingRequiredStartDate = _todayDateIso();
  String? _clockingRequiredEndDate;
  String? _initialClockingRequiredEndDate;
  String _clockingReminderTime = '09:00';
  String _clockingMissingAlertTime = '10:00';
  String _clockingOpenAlertTime = '18:00';
  bool _workflowAiEnabled = false;
  TeamSectionPermissions _teamPermissions = TeamSectionPermissions.readOnly();
  StreamSubscription<RealtimeNotification>? _realtimeSubscription;
  bool _tutorialScheduled = false;

  bool get _isEditMode => widget.teamId != null;
  bool get _supportsCreateTutorial => !_isEditMode && !widget.readOnly;
  bool get _showClockingSection =>
      !_isEditMode || _teamPermissions.canManageClockingSettings;
  bool get _isWorkflowAiOnlyManagerUpdate =>
      _isEditMode &&
      !widget.readOnly &&
      !_teamPermissions.isOwner &&
      _teamPermissions.canAccessRoleManager;

  @override
  void initState() {
    super.initState();
    _teamBloc = getIt<TeamBloc>();
    if (_isEditMode) {
      _isLoading = true;
      _teamBloc.add(LoadTeamByIdEvent(widget.teamId!));
      _realtimeSubscription = getIt<RealtimeNotificationService>().stream
          .listen(_handleRealtimeNotification);
    }
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    nameTeamController.dispose();
    descriptionTeamController.dispose();
    for (final d in listInviteFormData) {
      d.dispose();
    }
    super.dispose();
  }

  void _handleRealtimeNotification(RealtimeNotification notification) {
    if (!_isEditMode) return;
    final decision = getIt<TeamRealtimeCoordinator>().resolveScreenDecision(
      notification,
      teamId: widget.teamId ?? '',
      currentUserId: getIt<AuthBloc>().state.user.uid,
    );

    if (decision.shouldLeaveCurrentTeam) {
      final teamId = widget.teamId?.trim();
      if (teamId != null && teamId.isNotEmpty) {
        _teamBloc.add(RemoveTeamFromCacheEvent(teamId));
      }
      if (!mounted) return;
      final message = notification.eventType == 'TEAM_MEMBER_REMOVED'
          ? 'Non fai piu parte di questo team.'
          : 'Questo team non e piu disponibile.';
      AppSnackBar.showWarning(context, message, title: 'Team aggiornato');
      context.read<NavigationBloc>().add(NavigationPositionChanged(1));
      context.go(RouterPaths.home);
      return;
    }

    if (decision.refreshTeam) {
      _teamBloc.add(LoadTeamByIdEvent(widget.teamId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (_supportsCreateTutorial) {
      AppTutorialController.registerTargets(
        tutorialId: 'mobile-team-create',
        keys: <GlobalKey>[
          _teamInfoKey,
          _teamColorKey,
          _teamMembersKey,
          _teamActionKey,
        ],
      );
      AppTutorialController.registerReplayAction(
        tutorialId: 'mobile-team-create',
        action: () => AppTutorialController.replay(
          context: context,
          keys: <GlobalKey>[
            _teamInfoKey,
            _teamColorKey,
            _teamMembersKey,
            _teamActionKey,
          ],
        ),
      );
      _scheduleTutorial();
    }

    return BlocListener<TeamBloc, TeamState>(
      bloc: _teamBloc,
      listener: (context, teamState) {
        if (teamState is TeamLoaded && _isEditMode) {
          final team = teamState.team;
          nameTeamController.text = team.name;
          descriptionTeamController.text = team.description;
          setState(() {
            selectedColor = team.color != null ? [team.color!] : [];
            _ownerUserId = team.createdByUserId;
            _clockingRequired = team.clockingRequired;
            _clockingRequiredStartDate =
                team.clockingRequiredStartDate ?? _todayDateIso();
            _clockingRequiredEndDate = team.clockingRequiredEndDate;
            _initialClockingRequiredEndDate = team.clockingRequiredEndDate;
            _clockingReminderTime = team.clockingReminderTime ?? '09:00';
            _clockingMissingAlertTime =
                team.clockingMissingAlertTime ?? '10:00';
            _clockingOpenAlertTime = team.clockingOpenAlertTime ?? '18:00';
            _workflowAiEnabled = team.workflowAiEnabled;
            _isLoading = false;
          });
        } else if (teamState is TeamUpdated && _isEditMode) {
          AppSnackBar.showWarning(
            context,
            'Aggiornamento del team in sincronizzazione...',
            title: 'Sync in corso',
          );
          context.read<NavigationBloc>().add(NavigationPositionChanged(1));
          context.go(RouterPaths.home);
        } else if (teamState is TeamCreated) {
          AppSnackBar.showWarning(
            context,
            'Creazione del team in sincronizzazione...',
            title: 'Sync in corso',
          );
          setState(() {
            listInviteFormData.clear();
            listInviteFormData.add(
              InviteFormData(
                emailController: TextEditingController(),
                roleController: TextEditingController(),
              ),
            );
            nameTeamController.clear();
            descriptionTeamController.clear();
            selectedColor = [];
            _clockingRequired = false;
            _clockingRequiredStartDate = _todayDateIso();
            _clockingRequiredEndDate = null;
            _initialClockingRequiredEndDate = null;
            _clockingReminderTime = '09:00';
            _clockingMissingAlertTime = '10:00';
            _clockingOpenAlertTime = '18:00';
            _workflowAiEnabled = false;
          });
          if (widget.onTeamCreated != null) {
            widget.onTeamCreated!();
          }
        } else if (teamState is TeamError) {
          if (_isLoading) setState(() => _isLoading = false);
        }
      },
      child: SubmitOnEnterScope(
        onSubmit: widget.readOnly ? null : _onSave,
        child: Form(
          key: _formKey,
          child: _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(),
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Team Info Section ──
                      _buildSectionHeader(
                        context,
                        localization.teamName,
                        Icons.info_outline_rounded,
                      ),
                      const SizedBox(height: 10),
                      Showcase(
                        key: _teamInfoKey,
                        title: _isItalian(context)
                            ? 'Nome e descrizione'
                            : 'Name and description',
                        description: _isItalian(context)
                            ? 'Inizia da qui: dai un nome chiaro alla squadra e, se vuoi, aggiungi una descrizione per spiegare lo scopo del gruppo.'
                            : 'Start here by giving the team a clear name and, if useful, a short description so everyone understands the purpose.',
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.homeSecondary,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.borderColor!.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              CustomInputField(
                                hintText: localization.teamName,
                                controller: nameTeamController,
                                enabled: !widget.readOnly,
                              ),
                              const SizedBox(height: 14),
                              CustomInputField(
                                hintText: localization.teamDescription,
                                controller: descriptionTeamController,
                                enabled: !widget.readOnly,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Team Color Section ──
                      _buildSectionHeader(
                        context,
                        localization.selectedTeamcolor,
                        Icons.palette_rounded,
                      ),
                      const SizedBox(height: 10),
                      Showcase(
                        key: _teamColorKey,
                        title: _isItalian(context)
                            ? 'Colore della squadra'
                            : 'Team color',
                        description: _isItalian(context)
                            ? 'Scegli il colore che renderà la squadra riconoscibile nelle liste e nelle altre schermate dell\'app.'
                            : 'Pick the color that will make this team easy to recognize throughout the app.',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.homeSecondary,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.borderColor!.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: ListCheckbox(
                            selectedColor: selectedColor,
                            isEditMode: _isEditMode,
                            isEnabled: !widget.readOnly,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      if (_showClockingSection) ...[
                        _buildSectionHeader(
                          context,
                          'Clocking',
                          Icons.alarm_on_rounded,
                        ),
                        const SizedBox(height: 10),
                        TeamClockingRequirementSection(
                          clockingRequired: _clockingRequired,
                          onClockingRequiredChanged: (value) {
                            setState(() => _clockingRequired = value);
                          },
                          requiredStartDate: _clockingRequiredStartDate,
                          onRequiredStartDateChanged: (value) {
                            setState(() => _clockingRequiredStartDate = value);
                          },
                          requiredEndDate: _clockingRequiredEndDate,
                          onRequiredEndDateChanged: (value) {
                            setState(() => _clockingRequiredEndDate = value);
                          },
                          reminderTime: _clockingReminderTime,
                          onReminderTimeChanged: (value) {
                            setState(() => _clockingReminderTime = value);
                          },
                          missingAlertTime: _clockingMissingAlertTime,
                          onMissingAlertTimeChanged: (value) {
                            setState(() => _clockingMissingAlertTime = value);
                          },
                          openAlertTime: _clockingOpenAlertTime,
                          onOpenAlertTimeChanged: (value) {
                            setState(() => _clockingOpenAlertTime = value);
                          },
                          readOnly: widget.readOnly,
                        ),
                        const SizedBox(height: 24),
                      ],

                      _buildSectionHeader(
                        context,
                        _isItalian(context) ? 'AI workflow' : 'Workflow AI',
                        Icons.auto_awesome_rounded,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.homeSecondary,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.borderColor!.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: AppSwitchListTile(
                          value: _workflowAiEnabled,
                          onChanged:
                              widget.readOnly ||
                                  (_isEditMode &&
                                      !_teamPermissions.canAccessRoleManager)
                              ? null
                              : (value) {
                                  setState(() {
                                    _workflowAiEnabled = value;
                                  });
                                },
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _isItalian(context)
                                ? 'Abilita AI per questo team'
                                : 'Enable AI for this team',
                          ),
                          subtitle: Text(
                            _isItalian(context)
                                ? 'Richiede anche l attivazione globale nelle impostazioni generali dell app.'
                                : 'Also requires the global AI setting to be enabled in the app settings.',
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Members Section ──
                      _buildSectionHeader(
                        context,
                        localization.userList,
                        Icons.people_rounded,
                      ),
                      const SizedBox(height: 10),
                      Showcase(
                        key: _teamMembersKey,
                        title: _isItalian(context)
                            ? 'Membri della squadra'
                            : 'Team members',
                        description: _isItalian(context)
                            ? 'Qui scegli chi invitare nella squadra. Puoi aggiungere utenti e prepararli prima di creare il team.'
                            : 'Use this section to choose who should join the team and prepare the invitations before creating it.',
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.homeSecondary,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.borderColor!.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: _isEditMode
                              ? TeamMembersSection(
                                  teamId: widget.teamId!,
                                  ownerUserId: _ownerUserId,
                                  forceReadOnly: widget.readOnly,
                                  onPermissionsChanged: (permissions) {
                                    if (!mounted) return;
                                    setState(() {
                                      _teamPermissions = permissions;
                                    });
                                    widget.onPermissionsChanged?.call(
                                      permissions,
                                    );
                                  },
                                )
                              : AddUserMobile(
                                  listInviteFormData: listInviteFormData,
                                  teamId: widget.teamId,
                                ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Save / Create Button ──
                      if (widget.readOnly)
                        Center(
                          child: Text(
                            'This team is in read-only mode.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.descriptionColor,
                            ),
                          ),
                        )
                      else
                        Showcase(
                          key: _teamActionKey,
                          title: _isItalian(context)
                              ? 'Crea la squadra'
                              : 'Create the team',
                          description: _isItalian(context)
                              ? 'Quando nome, colore e membri sono pronti, usa questo pulsante per creare la squadra e inviare gli eventuali inviti.'
                              : 'Once the name, color, and members are ready, use this button to create the team and send any invitations.',
                          child: SizedBox(
                            width: double.infinity,
                            child: CustomAppButton(
                              onPressed: _onSave,
                              type: ButtonType.filled,
                              backgroundColor: const Color(0xFF7C4DFF),
                              foregroundColor: Colors.white,
                              borderRadius: 14,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              isActive: true,
                              fullWidth: true,
                              leadingIcon: Icon(
                                _isEditMode
                                    ? Icons.save_rounded
                                    : Icons.check_rounded,
                                size: 20,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  _isEditMode
                                      ? localization.editTeam
                                      : localization.createTeam,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  void _onSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final clockingDateRangeError = _clockingDateRangeError();
    if (clockingDateRangeError != null) {
      AppSnackBar.showWarning(context, clockingDateRangeError);
      return;
    }

    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final hasBlockedSelfTeamInvite = listInviteFormData.any(
      (invite) =>
          invite.emailController.text.trim().isNotEmpty &&
          isSelfTeamInviteBlocked(
            currentUserIsOwner: true,
            currentUserEmail: currentUserEmail,
            invitedEmail: invite.emailController.text,
          ),
    );
    if (hasBlockedSelfTeamInvite) {
      AppSnackBar.showError(context, selfTeamInviteBlockedMessage(context));
      return;
    }

    final pendingInvitations = listInviteFormData
        .where((d) => d.emailController.text.trim().isNotEmpty)
        .map((d) => d.toEntity())
        .toList();

    if (_isEditMode) {
      final team = TeamUpdate(
        false,
        id: widget.teamId,
        color: selectedColor.isNotEmpty ? selectedColor.first : '0xFF513387',
        name: nameTeamController.text.trim(),
        description: descriptionTeamController.text.trim(),
        createdByUserId: null,
        clockingRequired: _clockingRequired,
        clockingRequiredStartDate: _clockingRequiredStartDate,
        clockingRequiredEndDate: _clockingRequiredEndDate,
        clockingReminderTime: _clockingReminderTime,
        clockingMissingAlertTime: _clockingMissingAlertTime,
        clockingOpenAlertTime: _clockingOpenAlertTime,
        workflowAiEnabled: _workflowAiEnabled,
        workflowAiEnabledChanged: true,
        workflowAiOnlyUpdate: _isWorkflowAiOnlyManagerUpdate,
        clearClockingRequiredEndDate: _isWorkflowAiOnlyManagerUpdate
            ? false
            : _initialClockingRequiredEndDate != null &&
                  _clockingRequiredEndDate == null,
        listMember: const [],
      );
      _teamBloc.add(UpdateTeamEvent(team));
    } else {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final team = TeamEntity(
        null,
        selectedColor.isNotEmpty ? selectedColor.first : '0xFF513387',
        pendingInvitations.isNotEmpty ? pendingInvitations : null,
        name: nameTeamController.text.trim(),
        description: descriptionTeamController.text.trim(),
        createdByUserId: currentUserId,
        clockingRequired: _clockingRequired,
        clockingRequiredStartDate: _clockingRequiredStartDate,
        clockingRequiredEndDate: _clockingRequiredEndDate,
        clockingReminderTime: _clockingReminderTime,
        clockingMissingAlertTime: _clockingMissingAlertTime,
        clockingOpenAlertTime: _clockingOpenAlertTime,
        workflowAiEnabled: _workflowAiEnabled,
      );
      _teamBloc.add(CreateTeamEvent(team, userId: currentUserId));
    }
  }

  String? _clockingDateRangeError() {
    final endDate = _clockingRequiredEndDate;
    if (endDate == null || endDate.trim().isEmpty) {
      return null;
    }
    final start = DateTime.tryParse(_clockingRequiredStartDate);
    final end = DateTime.tryParse(endDate);
    if (start == null || end == null || !end.isBefore(start)) {
      return null;
    }
    return _isItalian(context)
        ? 'La data di fine deve essere uguale o successiva alla data di inizio.'
        : 'The end date must be after or equal to the start date.';
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.descriptionColor),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: theme.colorScheme.descriptionColor,
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleTutorial() {
    if (_tutorialScheduled) {
      return;
    }
    _tutorialScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_supportsCreateTutorial) {
        return;
      }
      await AppTutorialController.showIfNeeded(
        context: context,
        tutorialId: 'mobile-team-create',
        userId: context.read<AuthBloc>().state.user.uid,
        keys: <GlobalKey>[
          _teamInfoKey,
          _teamColorKey,
          _teamMembersKey,
          _teamActionKey,
        ],
      );
    });
  }

  bool _isItalian(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'it';
  }

  static String _todayDateIso() {
    final today = DateTime.now();
    final month = today.month.toString().padLeft(2, '0');
    final day = today.day.toString().padLeft(2, '0');
    return '${today.year}-$month-$day';
  }
}
