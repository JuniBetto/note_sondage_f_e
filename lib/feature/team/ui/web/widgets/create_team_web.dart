import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/feature/team/ui/helper/user_form_data.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/list_checkbox.dart';
import 'package:note_sondage/feature/team/ui/web/widgets/add_user_web.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';
import 'package:note_sondage/ui/widgets/submit_on_enter_scope.dart';
import 'package:showcaseview/showcaseview.dart';

class CreateTeamWeb extends StatefulWidget {
  const CreateTeamWeb({super.key, this.onTeamCreated});

  final VoidCallback? onTeamCreated;

  @override
  State<CreateTeamWeb> createState() => _CreateTeamWebState();
}

class _CreateTeamWebState extends State<CreateTeamWeb> {
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
  bool _tutorialScheduled = false;

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

    AppTutorialController.registerTargets(
      tutorialId: 'web-team-create',
      keys: <GlobalKey>[
        _teamInfoKey,
        _teamColorKey,
        _teamMembersKey,
        _teamActionKey,
      ],
    );
    AppTutorialController.registerReplayAction(
      tutorialId: 'web-team-create',
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

    return BlocListener<TeamBloc, TeamState>(
      bloc: _teamBloc,
      listener: (context, teamState) {
        if (teamState is TeamCreated) {
          AppSnackBar.showSuccess(
            context,
            localization.teamCreatedSuccessfully,
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
          widget.onTeamCreated?.call();
          _teamBloc.add(LoadTeamsEvent());
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else if (teamState is TeamError) {
          AppSnackBar.showError(context, teamState.message);
        }
      },
      child: Align(
        alignment: Alignment.topLeft,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: SubmitOnEnterScope(
            onSubmit: _onSave,
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
                      Tooltip(
                        message: localization.reviewTutorial,
                        child: IconButton(
                          onPressed: () =>
                              AppTutorialController.replayRegistered(
                                context: context,
                                tutorialId: 'web-team-create',
                              ),
                          icon: const Icon(Icons.help_outline_rounded),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Team Info Section ──
                  _buildSectionTitle(context, localization.teamName),
                  const SizedBox(height: 12),
                  Showcase(
                    key: _teamInfoKey,
                    title: _isItalian(context)
                        ? 'Nome e descrizione'
                        : 'Name and description',
                    description: _isItalian(context)
                        ? 'Qui definisci l\'identità della nuova squadra: nome chiaro e descrizione del gruppo.'
                        : 'Use this section to define the new team identity with a clear name and a short description.',
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.homeSecondary,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.borderColor!.withValues(
                            alpha: 0.3,
                          ),
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
                  ),

                  const SizedBox(height: 24),

                  // ── Team Color Section ──
                  _buildSectionTitle(context, localization.selectedTeamcolor),
                  const SizedBox(height: 12),
                  Showcase(
                    key: _teamColorKey,
                    title: _isItalian(context) ? 'Colore' : 'Color',
                    description: _isItalian(context)
                        ? 'Scegli un colore distintivo per riconoscere la squadra più velocemente.'
                        : 'Choose a distinctive color so the team is easier to recognize across the app.',
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.homeSecondary,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.borderColor!.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: ListCheckbox(selectedColor: selectedColor),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Members Section ──
                  _buildSectionTitle(context, localization.userList),
                  const SizedBox(height: 12),
                  Showcase(
                    key: _teamMembersKey,
                    title: _isItalian(context) ? 'Membri' : 'Members',
                    description: _isItalian(context)
                        ? 'Aggiungi qui le persone da invitare e prepara la squadra prima del salvataggio finale.'
                        : 'Add the people you want to invite here so the team is ready before the final save.',
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.homeSecondary,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.borderColor!.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: AddUserWeb(listInviteFormData: listInviteFormData),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Create Button ──
                  Showcase(
                    key: _teamActionKey,
                    title: _isItalian(context)
                        ? 'Conferma creazione'
                        : 'Create action',
                    description: _isItalian(context)
                        ? 'Quando tutto è pronto, questo pulsante crea la squadra e invia gli inviti preparati.'
                        : 'Once everything is ready, use this button to create the team and send the prepared invitations.',
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: CustomAppButton(
                        onPressed: _onSave,
                        type: ButtonType.filled,
                        backgroundColor: const Color(0xFF7C4DFF),
                        foregroundColor: Colors.white,
                        borderRadius: 12,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        isActive: true,
                        leadingIcon: const Icon(
                          Icons.group_add_rounded,
                          size: 20,
                        ),
                        child: Padding(
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
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
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

  void _scheduleTutorial() {
    if (_tutorialScheduled) {
      return;
    }
    _tutorialScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await AppTutorialController.showIfNeeded(
        context: context,
        tutorialId: 'web-team-create',
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
}
