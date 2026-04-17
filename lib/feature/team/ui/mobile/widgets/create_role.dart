import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/core/utils/app_constant.dart'
    show listPermissionsUser;
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';

import 'package:note_sondage/feature/team/ui/bloc/role/role_bloc.dart';
import 'package:note_sondage/feature/team/ui/widgets/select_option_with_search.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class CreateRoleWidget extends StatefulWidget {
  const CreateRoleWidget({super.key, this.teamId});
  final String? teamId;

  @override
  State<CreateRoleWidget> createState() => _CreateRoleWidgetState();
}

class _CreateRoleWidgetState extends State<CreateRoleWidget> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController permissionsController = TextEditingController();
  String? selectedPermissionId;
  late final RoleBloc _roleBloc;

  // Lista per tracciare gli elementi selezionati nel multi-select
  List<String> _selectedStatusList = [];

  @override
  void initState() {
    super.initState();
    // Carica i permessi all'inizio
    //context.read<PermissionBloc>().add(LoadPermissionsEvent());
    // Ottieni il bloc da getIt
    _roleBloc = getIt<RoleBloc>();
    //_roleBloc.add(LoadPermissionsEvent());

    // Aggiungi listener per aggiornare la UI quando i controller cambiano
    nameController.addListener(_onFieldChanged);
    descriptionController.addListener(_onFieldChanged);
    permissionsController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    nameController.removeListener(_onFieldChanged);
    descriptionController.removeListener(_onFieldChanged);
    permissionsController.removeListener(_onFieldChanged);
    nameController.dispose();
    descriptionController.dispose();
    permissionsController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() {});
  }

  bool get isFormValid {
    return nameController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        _selectedStatusList.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return BlocConsumer<RoleBloc, RoleState>(
      bloc: _roleBloc,
      listener: (context, state) {
        if (state is RoleError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${localization.errorPrefix} ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is RoleCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localization.roleCreatedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
          // Reset form dopo creazione
          nameController.clear();
          descriptionController.clear();
          setState(() {
            _selectedStatusList = [];
          });
          // Opzionale: chiudi il widget o naviga indietro
          // Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        // Usa lo stato caricato per popolare la UI

        return Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.disabled,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Role Info Section ──
                _buildSectionHeader(
                  context,
                  localization.roleName,
                  Icons.badge_rounded,
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
                        hintText: localization.roleName,
                        controller: nameController,
                      ),
                      const SizedBox(height: 14),
                      CustomInputField(
                        hintText: localization.roleDescription,
                        controller: descriptionController,
                        minLines: 3,
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Permissions Section ──
                _buildSectionHeader(
                  context,
                  localization.selectedPermission,
                  Icons.security_rounded,
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
                  child: GenericMultiSelectDropdown<String>(
                    label: '',
                    items: listPermissionsUser,
                    selectedItems: _selectedStatusList,
                    displayText: (item) => item,
                    valueGetter: (item) => item,
                    onChanged: (List<String> selectedItems) {
                      setState(() {
                        _selectedStatusList = selectedItems;
                      });
                    },
                    hintText: localization.selectedPermission,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Create Button ──
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isFormValid
                        ? () {
                            if (_formKey.currentState?.validate() ?? false) {
                              final role = RoleEntity(
                                null,
                                name: nameController.text,
                                description: descriptionController.text,
                                permissions: _selectedStatusList,
                                teamId: widget.teamId ?? '',
                              );
                              _roleBloc.add(
                                CreateRoleEvent(
                                  role,
                                  teamId: widget.teamId ?? '',
                                ),
                              );
                            }
                          }
                        : null,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        localization.createRole,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7C4DFF),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(
                        0xFF7C4DFF,
                      ).withValues(alpha: 0.3),
                      disabledForegroundColor: Colors.white60,
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
        );
      },
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
