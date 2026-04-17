import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/user_status.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/feature/team/ui/bloc/team_member/team_member_bloc.dart';
import 'package:note_sondage/feature/team/ui/helper/user_form_data.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/add_user_mobile.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/list_checkbox.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
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

  final List<UserFormData> listUserFormData = [
    UserFormData(
      userId: '',
      statusController: TextEditingController(),
      emailController: TextEditingController(),
      roleController: TextEditingController(),
    ),
  ];
  List<String> selectedColor = [];

  late final TeamBloc _teamBloc;
  late final TeamMemberBloc _teamMemberBloc;

  @override
  void initState() {
    super.initState();
    _teamBloc = getIt<TeamBloc>();
    _teamMemberBloc = getIt<TeamMemberBloc>();
  }

  @override
  void dispose() {
    nameTeamController.dispose();
    descriptionTeamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocListener<TeamBloc, TeamState>(
      bloc: _teamBloc,
      listener: (context, teamState) {
        if (teamState is TeamCreated) {
          final createdTeamId = teamState.team.id;

          if (createdTeamId != null) {
            for (final userFormData in listUserFormData) {
              if (userFormData.emailController.text.isNotEmpty) {
                UserStatus status;
                try {
                  status = UserStatus.values.firstWhere(
                    (e) =>
                        e.toString().split('.').last.toLowerCase() ==
                        userFormData.statusController.text.toLowerCase(),
                  );
                } catch (_) {
                  status = UserStatus.pending;
                }

                final member = TeamMemberEntity(
                  id: null,
                  userEmail: userFormData.emailController.text,
                  teamId: createdTeamId,
                  status: status,
                  roleId: userFormData.roleController.text,
                  imageFile: userFormData.avatarFile,
                  imageBytes: userFormData.avatarBytes,
                  fileName:
                      userFormData.avatarFile?.path.split('/').last ??
                      (userFormData.avatarBytes != null
                          ? 'profile_image.png'
                          : null),
                );
                _teamMemberBloc.add(
                  CreateTeamMemberEvent(member, teamId: createdTeamId),
                );
              }
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localization.teamCreatedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );

          if (widget.onTeamCreated != null) {
            widget.onTeamCreated!();
          }
        } else if (teamState is TeamError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${localization.errorPrefix} ${teamState.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocListener<TeamMemberBloc, TeamMemberState>(
        bloc: _teamMemberBloc,
        listener: (context, memberState) {
          if (memberState is TeamMemberCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localization.memberAddedSuccessfully),
                backgroundColor: Colors.green,
              ),
            );
          } else if (memberState is TeamMemberError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${localization.memberErrorPrefix} ${memberState.message}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                      color: colorScheme.borderColor!.withValues(alpha: 0.3),
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
                      color: colorScheme.borderColor!.withValues(alpha: 0.3),
                    ),
                  ),
                  child: ListCheckbox(selectedColor: selectedColor),
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
                      color: colorScheme.borderColor!.withValues(alpha: 0.3),
                    ),
                  ),
                  child: AddUserMobile(
                    listUserFormData: listUserFormData,
                    teamId: widget.teamId,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Save / Create Button ──
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        const currentUserId =
                            '7f49a0ab-d27e-462d-89d6-e10494c5b3da';

                        final team = TeamEntity(
                          null,
                          selectedColor.isNotEmpty
                              ? selectedColor.first
                              : '0xFF513387',
                          name: nameTeamController.text,
                          description: descriptionTeamController.text,
                          createdByUserId: currentUserId,
                        );
                        _teamBloc.add(
                          CreateTeamEvent(team, userId: currentUserId),
                        );
                        listUserFormData.clear();
                        nameTeamController.clear();
                        descriptionTeamController.clear();
                      }
                    },
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        localization.createTeam,
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
      ),
    );
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
