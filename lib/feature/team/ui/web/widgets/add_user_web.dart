import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/core/utils/app_constant.dart';
import 'package:note_sondage/feature/team/ui/bloc/role/role_bloc.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/ui/bloc/user/user_bloc.dart';
import 'package:note_sondage/feature/team/ui/helper/user_form_data.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/action_on_user.dart';
import 'package:note_sondage/feature/team/ui/widgets/select_option_with_search.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/avatar_input.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';
import 'package:note_sondage/ui/widgets/custom_dialog.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';
import 'package:note_sondage/ui/widgets/user_status_widget.dart';
import 'package:uuid/uuid.dart';

class AddUserWeb extends StatefulWidget {
  const AddUserWeb({super.key, this.teamId, required this.listUserFormData});
  final String? teamId;
  final List<UserFormData> listUserFormData;

  @override
  State<AddUserWeb> createState() => _AddUserWebState();
}

Widget buildAvatarInput(UserFormData userFormData, int index) {
  // Resolve the image URL for cross-platform compatibility (MinIO proxy)
  final resolvedUrl =
      userFormData.avatarUrl != null && userFormData.avatarUrl!.isNotEmpty
      ? DioClient.resolveImageUrl(userFormData.avatarUrl!)
      : null;
  debugPrint(
    'Avatar URL for index $index: ${userFormData.avatarUrl} -> resolved: $resolvedUrl',
  );
  return AvatarInput(
    key: ValueKey('avatar_$index'), // Key unica per forzare ricreazione
    size: 50,
    initialImageUrl: resolvedUrl,
    initialImageFile: userFormData.avatarFile,
    initialImageBytes: userFormData.avatarBytes,
    onImageChanged: (file) {
      userFormData.avatarFile = file;
      userFormData.avatarBytes = null;
    },
    onImageBytesChanged: (bytes) {
      userFormData.avatarBytes = bytes;
      userFormData.avatarFile = null;
    },
    placeholder: CircleAvatar(
      backgroundColor: Colors.blue.shade100,
      child: Icon(Icons.person, color: Colors.blue.shade600),
    ),
    borderColor: Colors.blue,
    borderWidth: 3,
  );
}

class _AddUserWebState extends State<AddUserWeb> {
  /*final List<UserFormData> listUserFormData = [
    UserFormData(
      statusController: TextEditingController(),
      emailController: TextEditingController(),
      roleController: TextEditingController(),
    ),
  ];*/
  late final UserBloc _userBloc;
  late final RoleBloc _roleBloc;
  List<RoleEntity> selectedRoles = [];

  // Form key separata per i campi utente (non validati dal form principale)
  final GlobalKey<FormState> _userFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    // TODO: implement initState
    final team_id = '11111111-1111-1111-1111-111111111111';
    _userBloc = getIt<UserBloc>();
    _userBloc.add(LoadUserByTeamIdEvent(widget.teamId ?? team_id));
    _roleBloc = getIt<RoleBloc>();
    _roleBloc.add(LoadRolesEvent());

    super.initState();
  }

  @override
  void dispose() {
    for (var userData in widget.listUserFormData) {
      userData.statusController.dispose();
      userData.emailController.dispose();
      userData.roleController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final localization = AppLocalizations.of(context)!;

    /*  Widget buildAvatarInput(UserFormData userFormData, int index) {
      return AvatarInput(
        key: ValueKey('avatar_$index'), // Key unica per forzare ricreazione
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
    }*/

    void _addEmptyUser() {
      /*  // Ottieni l'ultimo utente (quello appena compilato)
      final lastIndex = widget.listUserFormData.length - 1;
      final currentUser = widget.listUserFormData[lastIndex];

      // Verifica che i campi siano compilati prima di aggiungere
      if (currentUser.emailController.text.isEmpty) {
        return; // Non aggiungere se l'email è vuota
      }*/
      if (_userFormKey.currentState?.validate() ?? false) {
        final userId = Uuid().v4();
        debugPrint("user ID: $userId");
        setState(() {
          // Aggiungi un nuovo form vuoto
          widget.listUserFormData.add(
            UserFormData(
              statusController: TextEditingController(),
              emailController: TextEditingController(),
              roleController: TextEditingController(),
              userId: userId,
            ),
          );
        });
      }
    }

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
            selectedRoles = roleState.roles;
          });
        }
      },
      builder: (context, roleState) {
        return BlocConsumer<UserBloc, UserState>(
          bloc: _userBloc,
          listener: (context, userState) {
            if (userState is UserError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${localization.errorPrefix} ${userState.message}',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (userState is UsersUpdateLoaded) {
              debugPrint("Loaded users for update: ${userState.users}");
              // Populate listUserFormData with loaded users
              setState(() {
                widget.listUserFormData.clear();
                for (final user in userState.users) {
                  widget.listUserFormData.add(
                    UserFormData(
                      userId: user.id!,
                      key: ValueKey(user.id), // Key unica basata sull'email
                      statusController: TextEditingController(
                        text: user.status,
                      ),
                      emailController: TextEditingController(text: user.email),
                      roleController: TextEditingController(text: user.role),
                      // Optionally set avatarFile/avatarBytes if needed
                      avatarUrl: user.imageUrl,
                    ),
                  );
                }
                // Always add an empty form for new user input
                widget.listUserFormData.add(
                  UserFormData(
                    statusController: TextEditingController(),
                    emailController: TextEditingController(),
                    roleController: TextEditingController(),
                    userId: Uuid().v4(),
                  ),
                );
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
                  if (widget.listUserFormData.length > 1) ...[
                    Text(localization.userList),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.bgNavbarSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: buildListUserForm(
                        context,
                        selectedRoles,
                        widget.listUserFormData,
                      ),
                    ),
                  ] else
                    SizedBox(),
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
                        final currentUser =
                            widget.listUserFormData[currentIndex];
                        return buildNewUserForm(
                          context,
                          currentUser,
                          selectedRoles,
                          buildAvatarInput(currentUser, currentIndex),
                          _addEmptyUser,
                          onSelectedPermissionsChanged: (selectedItems) {
                            setState(() {
                              currentUser.selectedPermissions = selectedItems;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
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
  void Function()? onPressed, {
  required void Function(List<String>) onSelectedPermissionsChanged,
}) {
  final theme = Theme.of(context);
  //final colorScheme = theme.colorScheme;
  //final textTheme = theme.textTheme;
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
        SizedBox(width: 16.0),
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
          child: Text(localization.addUser),
        ),
      ],
    ),
  );
}

Widget buildEditUserForm(
  BuildContext context,
  UserFormData userFormData,
  List<RoleEntity> selectedRoles,
  Widget avatar,
  void Function()? onPressed, {
  required void Function(List<String>) onSelectedPermissionsChanged,
}) {
  final theme = Theme.of(context);
  //final colorScheme = theme.colorScheme;
  //final textTheme = theme.textTheme;
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
        SizedBox(width: 16.0),
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
          child: Text(localization.saveChanges),
        ),
      ],
    ),
  );
}

Widget buildListUserForm(
  BuildContext context,
  List<RoleEntity> selectedRoles,
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
                          status: " ${data.statusController.text}",
                        ) /*Text(
                          " ${data.statusController.text}",
                          style: themeText.labelSmall!.copyWith(
                            color: colorScheme.textInvertedColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                          softWrap: true,
                        ),*/,
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
                                print('Edit user at index $index');

                                final originalData = userFormData[index];

                                // Salva i valori originali PRIMA di aprire il dialog
                                final originalEmail =
                                    originalData.emailController.text;
                                final originalRole =
                                    originalData.roleController.text;
                                final originalStatus =
                                    originalData.statusController.text;
                                final originalAvatarUrl =
                                    originalData.avatarUrl;
                                final originalAvatarFile =
                                    originalData.avatarFile;
                                final originalAvatarBytes =
                                    originalData.avatarBytes;

                                // Crea controller temporanei per il dialog (copie indipendenti)
                                final editData = UserFormData(
                                  userId: originalData.userId,
                                  emailController: TextEditingController(
                                    text: originalEmail,
                                  ),
                                  roleController: TextEditingController(
                                    text: originalRole,
                                  ),
                                  statusController: TextEditingController(
                                    text: originalStatus,
                                  ),
                                  avatarUrl: originalAvatarUrl,
                                  avatarFile: originalAvatarFile,
                                  avatarBytes: originalAvatarBytes,
                                );

                                CustomDialog(
                                  child: buildEditUserForm(
                                    context,
                                    editData,
                                    selectedRoles,
                                    buildAvatarInput(editData, index),
                                    () {
                                      // Ora confronta i valori originali con quelli modificati nel dialog

                                      if (originalEmail !=
                                          editData.emailController.text) {
                                        debugPrint(
                                          'Email changed from "$originalEmail" to "${editData.emailController.text}"',
                                        );
                                        originalData.emailController.text =
                                            editData.emailController.text;
                                      }

                                      if (originalRole !=
                                          editData.roleController.text) {
                                        originalData.roleController.text =
                                            editData.roleController.text;
                                      }

                                      if (originalStatus !=
                                          editData.statusController.text) {
                                        originalData.statusController.text =
                                            editData.statusController.text;
                                      }

                                      if (editData.avatarBytes !=
                                              originalAvatarBytes ||
                                          editData.avatarFile !=
                                              originalAvatarFile ||
                                          editData.avatarUrl !=
                                              originalAvatarUrl) {
                                        originalData.avatarUrl =
                                            editData.avatarUrl;
                                        originalData.avatarFile =
                                            editData.avatarFile;
                                        originalData.avatarBytes =
                                            editData.avatarBytes;
                                      }

                                      // Applica le modifiche ai dati originali

                                      /* originalData.statusController.text =
                                          editData.statusController.text;
                                      originalData.avatarUrl =
                                          editData.avatarUrl;
                                      originalData.avatarFile =
                                          editData.avatarFile;
                                      originalData.avatarBytes =
                                          editData.avatarBytes;*/

                                      // Forza il rebuild per aggiornare la lista
                                      (context as Element).markNeedsBuild();

                                      // Chiudi il dialog
                                      Navigator.of(context).pop();
                                    },
                                    onSelectedPermissionsChanged:
                                        (selectedItems) {
                                          // Handle permission changes if needed
                                        },
                                  ),
                                ).show(context);
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
