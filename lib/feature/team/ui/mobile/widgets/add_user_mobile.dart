import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/core/utils/app_constant.dart' show listStatusUser;
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/ui/bloc/role/role_bloc.dart';
import 'package:note_sondage/feature/team/ui/helper/user_form_data.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/action_on_user.dart';
import 'package:note_sondage/feature/team/ui/widgets/select_option_with_search.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/avatar_input.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';
import 'package:note_sondage/ui/widgets/user_status_widget.dart';

class AddUserMobile extends StatefulWidget {
  final String? teamId;
  final List<UserFormData> listUserFormData;

  const AddUserMobile({super.key, this.teamId, required this.listUserFormData});

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
    // TODO: sostituire con teamId reale quando disponibile
    final teamId = widget.teamId ?? '11111111-1111-1111-1111-111111111111';
    _roleBloc = getIt<RoleBloc>();
    _roleBloc.add(LoadRolesEventByTeamId(teamId));
  }

  @override
  void dispose() {
    for (var userData in widget.listUserFormData) {
      userData.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    Widget buildAvatarInput(UserFormData userFormData, int index) {
      return AvatarInput(
        key: ValueKey('avatar_$index'),
        size: 50,
        initialImageFile: userFormData.avatarFile,
        initialImageBytes: userFormData.avatarBytes,
        onImageChanged: (file) {
          setState(() {
            userFormData.avatarFile = file;
            userFormData.avatarBytes = null;
          });
        },
        onImageBytesChanged: (bytes) {
          setState(() {
            userFormData.avatarBytes = bytes;
            userFormData.avatarFile = null;
          });
        },
        placeholder: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(Icons.person, color: Colors.blue.shade600),
        ),
        borderColor: Colors.blue,
        borderWidth: 3,
      );
    }

    void _addEmptyUser() {
      final lastIndex = widget.listUserFormData.length - 1;
      final currentUser = widget.listUserFormData[lastIndex];

      if (currentUser.emailController.text.isEmpty) {
        return;
      }

      if (_userFormKey.currentState?.validate() ?? false) {
        setState(() {
          widget.listUserFormData.add(
            UserFormData(
              userId: '',
              statusController: TextEditingController(),
              emailController: TextEditingController(),
              roleController: TextEditingController(),
            ),
          );
        });
      }
    }

    return BlocConsumer<RoleBloc, RoleState>(
      bloc: _roleBloc,
      listener: (context, state) {
        if (state is RoleError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
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
              Text("User List"),
              widget.listUserFormData.length > 1
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.bgNavbarSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: buildListUserForm(
                        context,
                        widget.listUserFormData,
                      ),
                    )
                  : SizedBox(),
              SizedBox(height: 16),
              Text("  Add New User", style: textTheme.labelMedium),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.bgNavbarSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Builder(
                  builder: (context) {
                    final currentIndex = widget.listUserFormData.length - 1;
                    final currentUser = widget
                        .listUserFormData[currentIndex < 0 ? 0 : currentIndex];
                    return buildNewUserForm(
                      context,
                      currentUser,
                      selectedRoles,
                      buildAvatarInput(currentUser, currentIndex),
                      _addEmptyUser,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget buildNewUserForm(
  BuildContext context,
  UserFormData userFormData,
  List<RoleEntity> selectedRoles,
  Widget avatar,
  void Function()? onPressed,
) {
  final theme = Theme.of(context);
  final localization = AppLocalizations.of(context)!;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
    child: Column(
      spacing: 16.0,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [avatar],
        ),
        CustomInputField(
          hintText: localization.email,
          controller: userFormData.emailController,
          validator: emailValidator,
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          spacing: 4.0,
          children: [
            Expanded(
              child: GenericDropdownFormField<String>(
                label: "",
                style: theme.textTheme.bodyMedium,
                items: listStatusUser,
                value: userFormData.statusController.text.isEmpty
                    ? null
                    : userFormData.statusController.text,
                displayText: (status) => status,
                valueGetter: (status) => status,
                onChanged: (value) {
                  userFormData.statusController.text = value ?? '';
                },
                hintText: localization.status,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a status';
                  }
                  return null;
                },
              ),
            ),
            Expanded(
              child: GenericDropdownFormField<String>(
                label: "",
                style: theme.textTheme.bodyMedium,
                items: selectedRoles.map((e) => e.name).toList(),
                value: userFormData.roleController.text.isEmpty
                    ? null
                    : userFormData.roleController.text,
                displayText: (role) => role,
                valueGetter: (role) => role,
                onChanged: (value) {
                  userFormData.roleController.text = value ?? '';
                },
                hintText: localization.role,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select role';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        CustomAppButton(
          onPressed: () {
            if (onPressed != null) {
              onPressed();
            }
          },
          type: ButtonType.text,
          isActive: true,
          child: Text("Add user"),
        ),
      ],
    ),
  );
}

Widget buildListUserForm(
  BuildContext context,
  List<UserFormData> userFormData,
) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final themeText = theme.textTheme;
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
    child: Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.tableHeaderUserTeam,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    child: Text(
                      "Status",
                      style: themeText.labelMedium!.copyWith(
                        color: colorScheme.textInvertedColor,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                      softWrap: true,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    child: Text(
                      "Email",
                      style: themeText.labelMedium!.copyWith(
                        color: colorScheme.textInvertedColor,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                      softWrap: true,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    child: Text(
                      "Role",
                      style: themeText.labelMedium!.copyWith(
                        color: colorScheme.textInvertedColor,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                      softWrap: true,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Actions",
                          style: themeText.labelMedium!.copyWith(
                            color: colorScheme.textInvertedColor,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                          softWrap: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ...userFormData.sublist(0, userFormData.length - 1).asMap().entries.map((
          entry,
        ) {
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
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        child: UserStatusWidget(
                          status: data.statusController.text,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        child: Text(
                          " ${data.emailController.text}",
                          style: themeText.labelSmall!.copyWith(
                            color: colorScheme.textInvertedColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                          softWrap: true,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        child: Text(
                          " ${data.roleController.text}",
                          style: themeText.labelSmall!.copyWith(
                            color: colorScheme.textInvertedColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                          softWrap: true,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ActionOnUser(
                              onTap: () {
                                // Modifica l'utente (puoi implementare la logica di modifica qui)
                                print('Edit user at index $index');
                              },
                            ) /*DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colorScheme.selectionColor!.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: colorScheme.cursorColor!,
                                    width: 2,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.edit,
                                    size: 14,
                                    color: colorScheme.cursorColor!,
                                  ),
                                ),
                              )*/,
                            ActionOnUser(
                              borderRadius: 8.0,
                              borderWidth: 2.0,
                              padding: const EdgeInsets.all(4.0),
                              iconSize: 14.0,
                              icon: Icons.delete_forever_outlined,
                              color: colorScheme.deleteCard,
                              onTap: () {
                                // Rimuovi l'utente dalla lista
                                userFormData.removeAt(index);
                                // Aggiorna lo stato per riflettere la modifica
                                (context as Element).markNeedsBuild();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    ),
  );
}
