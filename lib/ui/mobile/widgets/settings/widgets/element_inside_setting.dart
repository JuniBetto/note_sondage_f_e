import 'package:flutter/material.dart';
import 'package:note_sondage/domain/entities/setting_type.dart';

class ElementInsideSetting extends StatelessWidget {
  const ElementInsideSetting({
    super.key,
    required this.setting,
    required this.contentModal,
  });
  final SettingType setting;
  final Widget contentModal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    _showModalBottomPermissionEdit(BuildContext context) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        //backgroundColor: Colors.green,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        elevation: 4,
        builder: (BuildContext context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle indicator
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Flexible(child: contentModal),
              ],
            ),
          );
        },
      );
    }

    return GestureDetector(
      onTap: () => _showModalBottomPermissionEdit(context),
      child: Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(setting.title, style: textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text(setting.subtitle, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
