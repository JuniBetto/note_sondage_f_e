import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:note_sondage/feature/notification/realtime/team_realtime_coordinator.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_service.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/feature/team/ui/helper/user_form_data.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/list_checkbox.dart';
import 'package:note_sondage/feature/team/ui/web/widgets/add_user_web.dart';
import 'package:note_sondage/feature/team/ui/widgets/team_clocking_requirement_section.dart';
import 'package:note_sondage/feature/team/ui/widgets/team_members_section.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';
import 'package:uuid/uuid.dart';

class UpdateTeamWeb extends StatefulWidget {
  const UpdateTeamWeb({super.key, this.teamId, required bool readOnly});
  final String? teamId;

  @override
  State<UpdateTeamWeb> createState() => _UpdateTeamWebState();
}

class _UpdateTeamWebState extends State<UpdateTeamWeb> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameTeamController = TextEditingController();
  final TextEditingController focusTeamController = TextEditingController();

  final List<UserFormData> listUserFormData = [
    UserFormData(
      userId: Uuid().v4(),
      statusController: TextEditingController(),
      emailController: TextEditingController(),
      roleController: TextEditingController(),
    ),
  ];

  /// Used by AddUserWeb (invite flow — email + role only).
  final List<InviteFormData> listInviteFormData = [
    InviteFormData(
      emailController: TextEditingController(),
      roleController: TextEditingController(),
    ),
  ];

  List<String> selectedColor = [];
  bool _clockingRequired = false;
  String _clockingReminderTime = '09:00';
  String _clockingMissingAlertTime = '10:00';
  String _clockingOpenAlertTime = '18:00';
  TeamSectionPermissions _teamPermissions = TeamSectionPermissions.readOnly();
  late final TeamBloc _teamBloc;
  bool _isLoading = true;
  StreamSubscription<RealtimeNotification>? _realtimeSubscription;

  bool get _showClockingSection => _teamPermissions.canManageClockingSettings;

  @override
  void initState() {
    super.initState();
    _teamBloc = getIt<TeamBloc>();
    _teamBloc.add(LoadTeamByIdEvent(widget.teamId!));
    _realtimeSubscription = getIt<RealtimeNotificationService>().stream.listen(
      _handleRealtimeNotification,
    );
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    nameTeamController.dispose();
    focusTeamController.dispose();
    for (final data in listUserFormData) {
      data.dispose();
    }
    for (final data in listInviteFormData) {
      data.dispose();
    }
    super.dispose();
  }

  void _handleRealtimeNotification(RealtimeNotification notification) {
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
      context.go(RouterPaths.team);
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
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return BlocListener<TeamBloc, TeamState>(
      bloc: _teamBloc,
      listener: (context, teamState) {
        if (teamState is TeamLoaded) {
          final team = teamState.team;
          nameTeamController.text = team.name;
          focusTeamController.text = team.description;
          setState(() {
            selectedColor = team.color != null ? [team.color!] : [];
            _clockingRequired = team.clockingRequired;
            _clockingReminderTime = team.clockingReminderTime ?? '09:00';
            _clockingMissingAlertTime =
                team.clockingMissingAlertTime ?? '10:00';
            _clockingOpenAlertTime = team.clockingOpenAlertTime ?? '18:00';
            _isLoading = false;
          });
        } else if (teamState is TeamUpdated) {
          AppSnackBar.showWarning(
            context,
            'Aggiornamento del team in sincronizzazione...',
            title: 'Sync in corso',
          );
          context.go(RouterPaths.team, extra: widget.teamId);
        } else if (teamState is TeamError) {
          setState(() => _isLoading = false);
        }
      },
      child: Align(
        alignment: Alignment.topLeft,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.group_rounded,
                        color: Color(0xFF7C4DFF),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localization.editTeam,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Update team information, members and roles',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.descriptionColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Role Manager button
                    if (widget.teamId != null)
                      FilledButton.tonalIcon(
                        onPressed: () {
                          context.go(
                            RouterPaths.rolePage,
                            extra: widget.teamId,
                          );
                        },
                        icon: const Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 18,
                        ),
                        label: Text(localization.roleManager),
                      ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Team Info Section ──
                _buildSectionTitle(context, localization.teamName),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.homeSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.borderColor!.withValues(alpha: 0.3),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: CustomInputField(
                                hintText: localization.teamName,
                                controller: nameTeamController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Il nome del team è obbligatorio';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomInputField(
                                hintText: localization.teamDescription,
                                controller: focusTeamController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'La descrizione è obbligatoria';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 24),

                // ── Team Color Section ──
                _buildSectionTitle(context, localization.selectedTeamcolor),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.homeSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.borderColor!.withValues(alpha: 0.3),
                    ),
                  ),
                  child: ListCheckbox(
                    selectedColor: selectedColor,
                    isEditMode: true,
                    onColorChanged: (newColor) {
                      setState(() {
                        selectedColor = [newColor];
                      });
                    },
                  ),
                ),

                const SizedBox(height: 24),

                if (_showClockingSection) ...[
                  _buildSectionTitle(context, 'Clocking'),
                  const SizedBox(height: 12),
                  TeamClockingRequirementSection(
                    clockingRequired: _clockingRequired,
                    onClockingRequiredChanged: (value) {
                      setState(() => _clockingRequired = value);
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
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Members Section ──
                _buildSectionTitle(context, localization.userList),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.homeSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.borderColor!.withValues(alpha: 0.3),
                    ),
                  ),
                  child: widget.teamId != null
                      ? TeamMembersSection(
                          teamId: widget.teamId!,
                          onPermissionsChanged: (permissions) {
                            if (!mounted) return;
                            setState(() {
                              _teamPermissions = permissions;
                            });
                          },
                        )
                      : AddUserWeb(
                          listInviteFormData: listInviteFormData,
                          teamId: widget.teamId,
                        ),
                ),

                const SizedBox(height: 32),

                // ── Save Button ──
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _onSave,
                    icon: const Icon(Icons.save_rounded, size: 20),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Text(
                        localization.editTeam,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7C4DFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: theme.colorScheme.descriptionColor,
        ),
      ),
    );
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final listteamMember = <TeamMemberUpdateTeam>[];
      final dataToSave = listUserFormData.length > 1
          ? listUserFormData.sublist(0, listUserFormData.length - 1)
          : <UserFormData>[];

      for (var userData in dataToSave) {
        final teamMember = TeamMemberUpdateTeam(
          userId: userData.userId,
          email: userData.emailController.text,
          status: userData.statusController.text,
          teamMemberId: '',
          imageUrl: userData.avatarUrl ?? '',
          role: userData.roleController.text,
        );
        listteamMember.add(teamMember);
      }

      final team = TeamUpdate(
        false,
        id: widget.teamId,
        color: selectedColor.isNotEmpty ? selectedColor.first : '0xFF513387',
        name: nameTeamController.text,
        description: focusTeamController.text,
        createdByUserId: null,
        clockingRequired: _clockingRequired,
        clockingReminderTime: _clockingReminderTime,
        clockingMissingAlertTime: _clockingMissingAlertTime,
        clockingOpenAlertTime: _clockingOpenAlertTime,
        listMember: listteamMember,
      );

      _teamBloc.add(UpdateTeamEvent(team));
    }
  }
}
