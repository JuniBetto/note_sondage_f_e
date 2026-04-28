import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_service.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/feature/team/ui/helper/user_form_data.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/add_user_mobile.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/list_checkbox.dart';
import 'package:note_sondage/feature/team/ui/widgets/team_members_section.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';

class CreateTeamMobile extends StatefulWidget {
  final String? teamId;
  final Function()? onTeamCreated;

  const CreateTeamMobile({super.key, this.onTeamCreated, this.teamId});

  @override
  State<CreateTeamMobile> createState() => _CreateTeamMobileState();
}

class _CreateTeamMobileState extends State<CreateTeamMobile> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
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
  StreamSubscription<RealtimeNotification>? _realtimeSubscription;

  bool get _isEditMode => widget.teamId != null;

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
    if (notification.sourceService != 'team-service') return;
    if (notification.metadata['teamId'] != widget.teamId) return;

    if (notification.eventType == 'TEAM_UPDATED' ||
        notification.eventType == 'TEAM_MEMBER_JOINED' ||
        notification.eventType == 'TEAM_MEMBER_REMOVED' ||
        notification.eventType == 'TEAM_MEMBER_ROLE_UPDATED' ||
        notification.eventType == 'TEAM_MEMBER_INVITED' ||
        notification.eventType == 'TEAM_INVITATION_CANCELLED') {
      _teamBloc.add(LoadTeamByIdEvent(widget.teamId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            _isLoading = false;
          });
        } else if (teamState is TeamUpdated && _isEditMode) {
          _teamBloc.add(LoadTeamsEvent());
          context.read<NavigationBloc>().add(NavigationPositionChanged(1));
          context.go(RouterPaths.home);
        } else if (teamState is TeamCreated) {
          _teamBloc.add(LoadTeamsEvent());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localization.teamCreatedSuccessfully),
              backgroundColor: Colors.green,
            ),
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
          });
          if (widget.onTeamCreated != null) {
            widget.onTeamCreated!();
          }
        } else if (teamState is TeamError) {
          if (_isLoading) setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${localization.errorPrefix} ${teamState.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
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
                      child: Column(
                        children: [
                          CustomInputField(
                            hintText: localization.teamName,
                            controller: nameTeamController,
                          ),
                          const SizedBox(height: 14),
                          CustomInputField(
                            hintText: localization.teamDescription,
                            controller: descriptionTeamController,
                          ),
                        ],
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
                    Container(
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
                    Container(
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
                            )
                          : AddUserMobile(
                              listInviteFormData: listInviteFormData,
                              teamId: widget.teamId,
                            ),
                    ),

                    const SizedBox(height: 32),

                    // ── Save / Create Button ──
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _onSave,
                        icon: Icon(
                          _isEditMode
                              ? Icons.save_rounded
                              : Icons.check_rounded,
                          size: 20,
                        ),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
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
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF7C4DFF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _onSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

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
        listMember: [],
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
      );
      _teamBloc.add(CreateTeamEvent(team, userId: currentUserId));
    }
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
}
