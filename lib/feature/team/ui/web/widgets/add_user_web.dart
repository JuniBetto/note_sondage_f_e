import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/ui/bloc/role/role_bloc.dart';
import 'package:note_sondage/feature/team/ui/helper/user_form_data.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/add_user_mobile.dart';
import 'package:note_sondage/feature/team/ui/widgets/select_option_with_search.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';
import 'package:note_sondage/ui/widgets/submit_on_enter_scope.dart';

class AddUserWeb extends StatefulWidget {
  const AddUserWeb({super.key, this.teamId, required this.listInviteFormData});

  final String? teamId;
  final List<InviteFormData> listInviteFormData;

  @override
  State<AddUserWeb> createState() => _AddUserWebState();
}

class _AddUserWebState extends State<AddUserWeb> {
  late final RoleBloc _roleBloc;
  List<RoleEntity> selectedRoles = [];
  final GlobalKey<FormState> _userFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _roleBloc = getIt<RoleBloc>();
    _roleBloc.add(LoadRolesEvent());
  }

  @override
  void dispose() {
    // I controller sono posseduti dal widget padre e possono essere riusati
    // durante il teardown della pagina; non vanno disposti qui.
    super.dispose();
  }

  void _addEmptyInvite() {
    if (_userFormKey.currentState?.validate() ?? false) {
      setState(() {
        widget.listInviteFormData.add(
          InviteFormData(
            emailController: TextEditingController(),
            roleController: TextEditingController(),
          ),
        );
      });
    }
  }

  List<RoleEntity> _assignableRoles(List<RoleEntity> roles) {
    return roles
        .where((role) => (role.id ?? '').trim().toUpperCase() != 'OWNER')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final localization = AppLocalizations.of(context)!;

    return BlocConsumer<RoleBloc, RoleState>(
      bloc: _roleBloc,
      listener: (context, roleState) {
        if (roleState is RoleError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${localization.errorPrefix} ${roleState.message}'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (roleState is RolesLoaded) {
          setState(() {
            selectedRoles = _assignableRoles(roleState.roles);
          });
        }
      },
      builder: (context, roleState) {
        return SubmitOnEnterScope(
          onSubmit: _addEmptyInvite,
          child: Form(
            key: _userFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.listInviteFormData.length > 1) ...[
                  Text(localization.userList, style: textTheme.labelMedium),
                  const SizedBox(height: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.bgNavbarSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: buildInviteList(context, widget.listInviteFormData),
                  ),
                  const SizedBox(height: 16),
                ],
                Text('  Add New Member', style: textTheme.labelMedium),
                const SizedBox(height: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.bgDialogSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Builder(
                    builder: (context) {
                      final currentIndex = widget.listInviteFormData.length - 1;
                      final current = widget.listInviteFormData[currentIndex];
                      return _buildNewInviteFormWeb(
                        context,
                        current,
                        selectedRoles,
                        _addEmptyInvite,
                      );
                    },
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

Widget _buildNewInviteFormWeb(
  BuildContext context,
  InviteFormData formData,
  List<RoleEntity> roles,
  void Function()? onPressed,
) {
  final theme = Theme.of(context);
  final localization = AppLocalizations.of(context)!;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
    child: Column(
      spacing: 16.0,
      children: [
        CustomInputField(
          hintText: localization.email,
          controller: formData.emailController,
          validator: emailValidator,
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final roleFieldWidth = constraints.maxWidth < 420
                ? constraints.maxWidth
                : 320.0;
            return SizedBox(
              width: roleFieldWidth,
              child: GenericDropdownFormField<RoleEntity>(
                label: '',
                style: theme.textTheme.bodyMedium,
                prefixIcon: Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 18,
                  color: theme.colorScheme.cursorColor,
                ),
                items: roles,
                value: formData.roleController.text.isEmpty
                    ? null
                    : roles
                          .where((r) => r.id == formData.roleController.text)
                          .firstOrNull,
                displayText: (role) => role.name,
                valueGetter: (role) => role,
                onChanged: (role) =>
                    formData.roleController.text = role?.id ?? '',
                hintText: localization.role,
                validator: (value) {
                  if (value == null) return localization.selectRole;
                  return null;
                },
              ),
            );
          },
        ),
        CustomAppButton(
          onPressed: () => onPressed?.call(),
          type: ButtonType.text,
          isActive: true,
          child: Text(localization.addUser),
        ),
      ],
    ),
  );
}
