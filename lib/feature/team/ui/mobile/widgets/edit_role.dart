import 'package:flutter/material.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/core/utils/app_constant.dart';
import 'package:note_sondage/feature/team/domain/entities/role_entity.dart';
import 'package:note_sondage/feature/team/ui/bloc/role/role_bloc.dart';
import 'package:note_sondage/feature/team/ui/widgets/select_option_with_search.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';

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
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    nameRoleController.text = widget.role?.name ?? '';
    descriptionRoleController.text = widget.role?.description ?? '';

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          top: 16.0,
          bottom: MediaQuery.of(context).padding.bottom + 24.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle bar ──
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.borderColor?.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Header ──
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Color(0xFF7C4DFF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  localization.editRoleManager,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

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
                    controller: nameRoleController,
                  ),
                  const SizedBox(height: 14),
                  CustomInputField(
                    hintText: localization.roleDescription,
                    controller: descriptionRoleController,
                    minLines: 3,
                    maxLines: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

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

            const SizedBox(height: 28),

            // ── Save Button ──
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
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
                icon: const Icon(Icons.save_rounded, size: 20),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    localization.save,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  foregroundColor: Colors.white,
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
