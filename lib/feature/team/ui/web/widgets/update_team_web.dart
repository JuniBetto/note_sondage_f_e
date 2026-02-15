import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/feature/team/ui/bloc/team_member/team_member_bloc.dart';
import 'package:note_sondage/feature/team/ui/helper/user_form_data.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/list_checkbox.dart';
import 'package:note_sondage/feature/team/ui/web/widgets/add_user_web.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

// Aggiungi in cima al file
const _kMaxWidth = 700.0;
const _kHeightRatio = 0.88;
const _kPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);

class UpdateTeamWeb extends StatefulWidget {
  const UpdateTeamWeb({super.key, this.teamId});
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
  List<String> selectedColor = [];
  late final TeamBloc _teamBloc;

  @override
  void initState() {
    super.initState();
    _teamBloc = getIt<TeamBloc>();
    _teamBloc.add(LoadTeamByIdEvent(widget.teamId!));
  }

  @override
  void dispose() {
    nameTeamController.dispose();
    focusTeamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return BlocListener<TeamBloc, TeamState>(
      bloc: _teamBloc,
      listener: (context, teamState) {
        if (teamState is TeamLoaded) {
          final team = teamState.team;

          nameTeamController.text = team.name;
          focusTeamController.text = team.description;

          setState(() {
            selectedColor = team.color != null ? [team.color!] : [];
          });
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: _kMaxWidth,
              maxHeight: constraints.maxHeight * _kHeightRatio,
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxHeight * _kHeightRatio,
                    ),
                    child: Padding(
                      padding: _kPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // Qui metti il form per creare un nuovo team
                          /* Text(
                            localization.createNewTeam,
                            style: theme.textTheme.headlineSmall,
                          ),*/
                          if (widget.teamId != null) ...[
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                CustomAppButton(
                                  type: ButtonType.text,
                                  isActive: true,
                                  child: Text(localization.roleManager),
                                  onPressed: () {
                                    context.go(
                                      RouterPaths.rolePage,
                                      extra: widget.teamId,
                                    );
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 14),
                            Divider(height: 4),
                            SizedBox(height: 14),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                SizedBox(width: 16),
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

                          // Aggiungi qui i campi del form (TextField, Dropdown, ecc.)
                          // Esempio:
                          Text(localization.selectedTeamcolor),
                          ListCheckbox(
                            selectedColor: selectedColor,
                            isEditMode: true,
                          ),

                          SizedBox(height: 16),
                          AddUserWeb(
                            listUserFormData: listUserFormData,
                            teamId: widget.teamId,
                          ),

                          SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: () {
                              // Logica per creare il team
                              /* if (widget.onTeamCreated != null) {
                                widget.onTeamCreated!();
                              } */
                              if (_formKey.currentState?.validate() ?? false) {
                                // Logica per creare il team
                                /* if (widget.onTeamCreated != null) {
                                widget.onTeamCreated!();
                              } */

                                print(
                                  "Team modificato con successo $selectedColor",
                                );
                                final listteamMember = <TeamMemberUpdateTeam>[];
                                listUserFormData.removeLast();
                                for (var userData in listUserFormData) {
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
                                  color: selectedColor.isNotEmpty
                                      ? selectedColor.first
                                      : '0xFF513387',
                                  name: nameTeamController.text,
                                  description: focusTeamController.text,
                                  createdByUserId: null,
                                  listMember: listteamMember,
                                );

                                _teamBloc.add(UpdateTeamEvent(team));
                                context.go(
                                  RouterPaths.team,
                                  extra: widget.teamId,
                                );
                              }
                            },
                            child: Text(localization.editTeam),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
