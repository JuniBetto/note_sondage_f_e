import 'package:flutter/material.dart';
import 'package:note_sondage/feature/team/domain/entities/permission_entity.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/action_on_user.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/edit_role.dart';
import 'package:note_sondage/feature/team/ui/widgets/visual_type.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/custom_dialog.dart';

class RolePermissionComponent extends StatelessWidget {
  const RolePermissionComponent({
    super.key,
    required this.id,
    required this.teamId,
    required this.code,
    required this.description,
    this.isMobile = true,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
    this.permissions,
  });
  final String? id;
  final String? teamId;
  final String code;
  final String description;
  final List<String>? permissions;
  final bool isSelected;
  final bool isMobile;
  final void Function(String?)? onTap;
  final void Function(String?)? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 4,
      color: isSelected ? colorScheme.primary : colorScheme.selectionColor,
      child: GestureDetector(
        onTap: () => onTap?.call(id),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth,
                  minWidth: 200,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: constraints.maxWidth * 0.6,
                            child: Text(
                              "Code: $code",
                              style: textTheme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              softWrap: true,
                            ),
                          ),
                          SizedBox(width: 8),
                          SizedBox(
                            width: constraints.maxWidth * 0.9,
                            child: Text(
                              "Description: $description",
                              style: textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ActionOnUser(
                      iconSize: 18,
                      icon: Icons.edit,
                      color: colorScheme.cursorColor!,
                      onTap: () {
                        print('Edit permission');
                        // final String permissionId = const Uuid().v4();
                        final role = RoleEntity(
                          id,
                          name: code,
                          description: description,
                          permissions: permissions ?? [],
                          teamId: teamId!,
                        );
                        isMobile
                            ? showModalBottomPermissionEdit(context, role)
                            : CustomDialog(
                                child: EditRoleWidget(role: role),
                              ).show(context);
                        /*context.go(
                                                  RouterPaths.updateTeam,
                                                  extra: 1,
                                                );*/
                      },
                    ),
                    SizedBox(width: 8),
                    ActionOnUser(
                      iconSize: 18,
                      icon: Icons.delete_forever,
                      color: colorScheme.deleteCard!,
                      onTap: () {
                        if (id != null) {
                          onDelete?.call(id);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

showModalBottomPermissionEdit(BuildContext context, RoleEntity role) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    elevation: 4,
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(child: EditRoleWidget(role: role)),
      );
    },
  );
}