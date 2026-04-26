import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/ui/bloc/role/role_bloc.dart';
import 'package:note_sondage/feature/team/ui/helper/user_form_data.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/action_on_user.dart';
import 'package:note_sondage/feature/team/ui/widgets/select_option_with_search.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';

class AddUserMobile extends StatefulWidget {
  final String? teamId;
  final List<InviteFormData> listInviteFormData;

  const AddUserMobile({
    super.key,
    this.teamId,
    required this.listInviteFormData,
  });

  @override
  State<AddUserMobile> createState() => _AddUserMobileState();
}

class _AddUserMobileState extends State<AddUserMobile> {
  late final RoleBloc _roleBloc;
  List<RoleEntity> selectedRoles = [];
  final GlobalKey<FormState> _userFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _roleBloc = getIt<RoleBloc>();
    // Roles are global in Spring — load all, no teamId needed.
    _roleBloc.add(LoadRolesEvent());
  }

  @override
  void dispose() {
    // I controller sono posseduti dal widget padre (UpdateTeamMobile),
    // non vanno disposti qui.
    super.dispose();
  }

  void _addEmptyInvite() {
    final lastIndex = widget.listInviteFormData.length - 1;
    final current = widget.listInviteFormData[lastIndex];
    if (current.emailController.text.isEmpty) return;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final localization = AppLocalizations.of(context)!;

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
        } else if (state is RolesLoaded) {
          setState(() {
            selectedRoles = state.roles;
          });
        }
      },
      builder: (context, state) {
        return Form(
          key: _userFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.listInviteFormData.length > 1) ...[
                buildInviteList(context, widget.listInviteFormData),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: colorScheme.borderColor!.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                localization.addUser.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: colorScheme.descriptionColor,
                ),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final currentIndex = widget.listInviteFormData.length - 1;
                  final current = widget
                      .listInviteFormData[currentIndex < 0 ? 0 : currentIndex];
                  return buildNewInviteForm(
                    context,
                    current,
                    selectedRoles,
                    _addEmptyInvite,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget buildNewInviteForm(
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
        GenericDropdownFormField<RoleEntity>(
          label: '',
          style: theme.textTheme.bodyMedium,
          items: roles,
          value: formData.roleController.text.isEmpty
              ? null
              : roles
                    .where((r) => r.id == formData.roleController.text)
                    .firstOrNull,
          displayText: (role) => role.name,
          valueGetter: (role) => role,
          onChanged: (role) => formData.roleController.text = role?.id ?? '',
          hintText: localization.role,
          validator: (value) {
            if (value == null) return 'Please select role';
            return null;
          },
        ),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: onPressed,
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: Text(localization.addUser),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildInviteList(BuildContext context, List<InviteFormData> list) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final themeText = theme.textTheme;

  Text headerText(String label) => Text(
    label,
    style: themeText.labelMedium!.copyWith(
      color: colorScheme.textInvertedColor,
      fontWeight: FontWeight.bold,
    ),
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
  );

  return Column(
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.tableHeaderUserTeam,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(flex: 3, child: headerText('Email')),
              Expanded(flex: 2, child: headerText('Role')),
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [headerText('Actions')],
                ),
              ),
            ],
          ),
        ),
      ),
      ...list.sublist(0, list.length - 1).asMap().entries.map((entry) {
        final data = entry.value;
        final index = entry.key;
        return Padding(
          key: ValueKey(index),
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.tableBodyUserTeam!,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      data.emailController.text,
                      style: themeText.labelSmall!.copyWith(
                        color: colorScheme.textInvertedColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      data.roleController.text,
                      style: themeText.labelSmall!.copyWith(
                        color: colorScheme.textInvertedColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ActionOnUser(
                          borderRadius: 8.0,
                          borderWidth: 2.0,
                          padding: const EdgeInsets.all(4.0),
                          iconSize: 14.0,
                          icon: Icons.delete_forever_outlined,
                          color: colorScheme.deleteCard,
                          onTap: () {
                            list.removeAt(index);
                            (context as Element).markNeedsBuild();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    ],
  );
}
