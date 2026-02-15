import 'package:flutter/material.dart';
import 'package:note_sondage/feature/team/domain/entities/user_status.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class UserStatusWidget extends StatelessWidget {
  const UserStatusWidget({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final trimmedStatus = status.trim().toLowerCase();
    
    Color statusColor;
    switch (trimmedStatus) {
      case 'active':
        statusColor = Colors.green;
        break;
      case 'deactivated':
        statusColor = Colors.grey;
        break;
      case 'deleted':
        statusColor = Colors.red;
        break;
      case 'banned':
        statusColor = Colors.yellow;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.bgIcons!, width: 2.0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Text(
              trimmedStatus,
              style: textTheme.bodyMedium!.copyWith(
                color: colorScheme.textInvertedColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
