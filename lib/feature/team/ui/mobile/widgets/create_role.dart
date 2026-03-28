import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/core/utils/app_constant.dart'
    show listPermissionsUser;
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';

import 'package:note_sondage/feature/team/ui/bloc/role/role_bloc.dart';
import 'package:note_sondage/feature/team/ui/widgets/select_option_with_search.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomInputField(
                          hintText: localization.roleName,
                          controller: nameController,
                        ),
                        SizedBox(height: 16),
                        CustomInputField(
                          hintText: localization.roleDescription,
                          controller: descriptionController,
                          minLines: 3,
                          maxLines: 5,
                        ),
                        SizedBox(height: 16),
                        GenericMultiSelectDropdown<String>(
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

                        SizedBox(height: 24),
                        CustomAppButton(
                          type: ButtonType.text,
                          isActive: isFormValid,
                          child: Text(localization.createRole),
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              // Logica per creare il team
                              /* if (widget.onTeamCreated != null) {
                                      widget.onTeamCreated!();
                                    }*/
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
                          },
                        ),
                      ],
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
}
