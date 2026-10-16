import 'package:flutter/material.dart';
import 'package:note_sondage/core/utils/app_constant.dart'
    show listPermissionsUser;
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

/// Scelta dei permessi di un ruolo: ogni permesso ha una breve descrizione
/// di cosa permette davvero (stesse regole applicate dal backend).
class RolePermissionSelector extends StatelessWidget {
  const RolePermissionSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  static String descriptionFor(AppLocalizations loc, String permission) {
    return switch (permission.trim().toUpperCase()) {
      'READ' => loc.permissionReadDescription,
      'UPDATE' => loc.permissionUpdateDescription,
      'ADMIN' => loc.permissionAdminDescription,
      'DELETE' => loc.permissionDeleteDescription,
      'MANAGE' => loc.permissionManageDescription,
      _ => '',
    };
  }

  void _toggle(String permission, bool checked) {
    final next = [
      for (final item in listPermissionsUser)
        if (item == permission ? checked : selected.contains(item)) item,
    ];
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        for (final permission in listPermissionsUser)
          CheckboxListTile(
            key: Key('role_permission_$permission'),
            value: selected.contains(permission),
            onChanged: (checked) => _toggle(permission, checked ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeColor: const Color(0xFF7C4DFF),
            title: Text(
              permission,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              descriptionFor(loc, permission),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.descriptionColor,
              ),
            ),
          ),
      ],
    );
  }
}
