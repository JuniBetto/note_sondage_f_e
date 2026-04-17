import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/user_status.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/feature/team/ui/bloc/team_member/team_member_bloc.dart';
import 'package:note_sondage/feature/team/ui/helper/user_form_data.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/list_checkbox.dart';
import 'package:note_sondage/feature/team/ui/web/widgets/add_user_web.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';

class CreateTeamWeb extends StatefulWidget {
  const CreateTeamWeb({super.key});

  @override
  State<CreateTeamWeb> createState() => _CreateTeamWebState();
}

class _CreateTeamWebState extends State<CreateTeamWeb> {
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
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return BlocListener<TeamBloc, TeamState>(
      bloc: _teamBloc,
      listener: (context, teamState) {
        if (teamState is TeamCreated) {
          // Team creato con successo, ora aggiungi i membri
          final createdTeamId = teamState.team.id;

          if (createdTeamId != null) {
            // Crea i TeamMember per ogni utente nel form
            for (final userFormData in listUserFormData) {
              // Verifica che l'email non sia vuota
              if (userFormData.emailController.text.isNotEmpty) {
                // Convert status string to UserStatus, default to UserStatus.pending
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
                  id: null, // id sarà generato dal backend
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
                listUserFormData.clear();
                nameTeamController.clear();
                descriptionTeamController.clear();
              }
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localization.teamCreatedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
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
                          color: const Color(
                            0xFF7C4DFF,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.group_add_rounded,
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
                              localization.createTeam,
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Set up a new team with members and roles',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.descriptionColor,
                              ),
                            ),
                          ],
                        ),
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
                    child: Row(
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
                            controller: descriptionTeamController,
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
                    child: ListCheckbox(selectedColor: selectedColor),
                  ),

                  const SizedBox(height: 24),

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
                    child: AddUserWeb(listUserFormData: listUserFormData),
                  ),

                  const SizedBox(height: 32),

                  // ── Create Button ──
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _onSave,
                      icon: const Icon(Icons.group_add_rounded, size: 20),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
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
      const currentUserId = '7f49a0ab-d27e-462d-89d6-e10494c5b3da';

      final team = TeamEntity(
        null,
        selectedColor.isNotEmpty ? selectedColor.first : '0xFF513387',
        name: nameTeamController.text,
        description: descriptionTeamController.text,
        createdByUserId: currentUserId,
      );
      _teamBloc.add(CreateTeamEvent(team, userId: currentUserId));
    }
  }
}
