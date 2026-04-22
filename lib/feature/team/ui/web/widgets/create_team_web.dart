import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
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
  final TextEditingController descriptionTeamController = TextEditingController();

  final List<InviteFormData> listInviteFormData = [
    InviteFormData(
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
  }

  @override
  void dispose() {
    nameTeamController.dispose();
    descriptionTeamController.dispose();
    for (final d in listInviteFormData) {
      d.dispose();
    }
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
        } else if (teamState is TeamError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${localization.errorPrefix} ${teamState.message}'),
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
                        color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
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
                            style: textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Set up a new team with members and roles',
                            style: textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.descriptionColor),
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
                  child: AddUserWeb(listInviteFormData: listInviteFormData),
                ),

                const SizedBox(height: 32),

                // ── Create Button ──
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _onSave,
                    icon: const Icon(Icons.group_add_rounded, size: 20),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text(
                        localization.createTeam,
                        style:
                            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7C4DFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
      const currentUserId = '7f49a0ab-d27e-462d-89d6-e10494c5b3da';
      final name = nameTeamController.text.trim();

      final pendingInvitations = listInviteFormData
          .where((d) => d.emailController.text.trim().isNotEmpty)
          .map((d) => d.toEntity())
          .toList();

      final team = TeamEntity(
        null,
        selectedColor.isNotEmpty ? selectedColor.first : '0xFF513387',
        pendingInvitations.isNotEmpty ? pendingInvitations : null,
        name: name,
        description: descriptionTeamController.text,
        createdByUserId: currentUserId,
      );
      _teamBloc.add(CreateTeamEvent(team, userId: currentUserId));
    }
  }
}
