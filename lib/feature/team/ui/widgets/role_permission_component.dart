import 'package:flutter/material.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/action_on_user.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/edit_role.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
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

  static const Set<String> _defaultRoleCodes = {
    'OWNER',
    'ADMIN',
    'MEMBER',
    'VIEWER',
  };

  bool get _isDefaultRole {
    final normalizedId = id?.trim().toUpperCase();
    final normalizedCode = code.trim().toUpperCase();
    return _defaultRoleCodes.contains(normalizedId) ||
        _defaultRoleCodes.contains(normalizedCode);
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
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
                              code,
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
                              description,
                              style: textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              softWrap: true,
                            ),
                          ),
                          if (_isDefaultRole) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                localization.defaultRole,
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!_isDefaultRole) ...[
                      ActionOnUser(
                        iconSize: 18,
                        icon: Icons.edit,
                        color: colorScheme.cursorColor!,
                        onTap: () {
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
