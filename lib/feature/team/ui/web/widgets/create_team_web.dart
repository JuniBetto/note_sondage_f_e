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

    /* if (widget.userFormData != null) {
      listUserFormData.clear();
      listUserFormData.add(widget.userFormData!);
    }*/
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
                // selectedColor.clear();
                listUserFormData.clear();
                nameTeamController.clear();
                descriptionTeamController.clear();
                /**_teamMemberBloc.add(
                  CreateTeamMemberByEmailEvent(
                    email: userFormData.emailController.text,
                    teamId: createdTeamId,
                    roleId: userFormData.roleController.text,
                    status: status,
                    imageFile: userFormData.avatarFile,
                    imageBytes: userFormData.avatarBytes,
                    fileName: userFormData.avatarFile?.path.split('/').last,
                  ),
                ); */
              }
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team creato con successo!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (teamState is TeamError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore: ${teamState.message}'),
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
              const SnackBar(
                content: Text('Membro aggiunto con successo!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (memberState is TeamMemberError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Errore membro: ${memberState.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 0.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Qui metti il form per creare un nuovo team
                  SizedBox(height: 24),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: CustomInputField(
                          hintText: localization.teamName,
                          controller: nameTeamController,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: CustomInputField(
                          hintText: localization.teamDescription,
                          controller: descriptionTeamController,
                        ),
                      ),
                    ],
                  ),

                  // Aggiungi qui i campi del form (TextField, Dropdown, ecc.)
                  const SizedBox(height: 8),
                  Text(localization.selectedTeamcolor),
                  SizedBox(
                    height: 80,
                    child: ListCheckbox(selectedColor: selectedColor),
                  ),

                  const SizedBox(height: 8),
                  AddUserWeb(listUserFormData: listUserFormData),

                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        // TODO: sostituire con userId reale (preso da auth)
                        const currentUserId =
                            '7f49a0ab-d27e-462d-89d6-e10494c5b3da';

                        // Crea il team
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
                      }
                    },
                    child: Text(localization.createTeam),
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
