import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class StatusClocking extends StatelessWidget {
  const StatusClocking({super.key, this.isCompact = false});
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final items = [
      _StatusItem(
        icon: Icons.login_rounded,
        label: localization.clockedInAt,
        time: '9:00 AM',
        color: Colors.green,
      ),
      _StatusItem(
        icon: Icons.coffee_rounded,
        label: localization.startBreakAt,
        time: '12:30 PM',
        color: Colors.orange,
      ),
      _StatusItem(
        icon: Icons.play_circle_outline,
        label: localization.endBreakAt,
        time: '1:00 PM',
        color: Colors.blue,
      ),
      _StatusItem(
        icon: Icons.logout_rounded,
        label: localization.clockedOutAt,
        time: '5:00 PM',
        color: Colors.red,
      ),
    ];

    if (isCompact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _StatusTile(
                  item: item,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
              ),
            )
            .toList(),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map(
            (item) => _StatusTile(
              item: item,
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
          )
          .toList(),
    );
  }
}

class _StatusItem {
  final IconData icon;
  final String label;
  final String time;
  final Color color;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
  });
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.item,
    required this.colorScheme,
    required this.textTheme,
  });

  final _StatusItem item;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 18, color: item.color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.label,
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
              Text(
                item.time,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.iconLabel,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
