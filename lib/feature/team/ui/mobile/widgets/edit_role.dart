import 'package:flutter/material.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/core/utils/app_constant.dart';
import 'package:note_sondage/feature/team/domain/entities/permission_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/ui/bloc/role/role_bloc.dart';
import 'package:note_sondage/feature/team/ui/widgets/select_option_with_search.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';
import 'package:uuid/uuid.dart';

class EditRoleWidget extends StatefulWidget {
  const EditRoleWidget({super.key, this.role});
  final RoleEntity? role;

  @override
  State<EditRoleWidget> createState() => _EditRoleWidgetState();
}

class _EditRoleWidgetState extends State<EditRoleWidget> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameRoleController = TextEditingController();
  final TextEditingController descriptionRoleController =
      TextEditingController();
  final TextEditingController permissionsController = TextEditingController();
  String? selectedPermissionId;
  List<String> _selectedStatusList = [];
  late final RoleBloc _roleBloc;

  @override
  void initState() {
    // TODO: implement initState
    _roleBloc = getIt<RoleBloc>();
    _selectedStatusList = [...?widget.role?.permissions];
    super.initState();
  }

  @override
  void dispose() {
    nameRoleController.dispose();
    descriptionRoleController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textScheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    nameRoleController.text = widget.role?.name ?? '';
    descriptionRoleController.text = widget.role?.description ?? '';

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 24.0,
          bottom: MediaQuery.of(context).padding.bottom + 24.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              localization.editRoleManager,
              style: textScheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 24),
            CustomInputField(
              hintText: localization.roleName,
              controller: nameRoleController,
            ),
            SizedBox(height: 16),
            CustomInputField(
              hintText: localization.roleDescription,
              controller: descriptionRoleController,
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
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: CustomAppButton(
                type: ButtonType.text,
                isActive: true,
                child: Text(localization.save),
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    // Logica per creare il team
                    /* if (widget.onTeamCreated != null) {
                            widget.onTeamCreated!();
                          }*/

                    final newRole = widget.role!.copyWith(
                      name: nameRoleController.text,
                      description: descriptionRoleController.text,
                      permissions: _selectedStatusList,
                      teamId: widget.role!.teamId,
                    );
                    _roleBloc.add(UpdateRoleEvent(newRole));
                  }
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
