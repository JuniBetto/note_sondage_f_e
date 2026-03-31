import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:note_sondage/feature/clocking/domain/entities/user_clock_info.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class TableComponent extends StatelessWidget {
  const TableComponent({
    super.key,
    required this.dataTable,
    required this.headerTable,
    this.headingRowColor,
    this.headerTextTextStyle,
  });
  final List<String> headerTable;
  final List<UserClockInfo> dataTable;
  final Color? headingRowColor;
  final TextStyle? headerTextTextStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: DataTable2(
        columnSpacing: 16,
        horizontalMargin: 16,
        minWidth: 500,
        dataRowHeight: 52,
        headingRowHeight: 48,
        headingRowColor: WidgetStateProperty.all(
          headingRowColor ?? Colors.blueGrey.withValues(alpha: 0.07),
        ),
        headingTextStyle:
            headerTextTextStyle ??
            textTheme.labelLarge?.copyWith(
              color: colorScheme.descriptionColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
        headingRowDecoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        dividerThickness: 0.5,
        border: TableBorder(
          horizontalInside: BorderSide(
            color: Colors.grey.withValues(alpha: 0.12),
            width: 0.5,
          ),
        ),
        columns: headerTable.map((header) {
          final isFirst = header == headerTable.first;
          return DataColumn2(
            label: Row(
              children: [
                if (isFirst) ...[
                  Icon(_headerIcon(header), size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                ],
                Text(header),
              ],
            ),
            size: ColumnSize.M,
          );
        }).toList(),
        rows: List<DataRow>.generate(dataTable.length, (index) {
          final info = dataTable[index];
          final isEven = index.isEven;

          return DataRow(
            color: WidgetStateProperty.all(
              isEven ? Colors.transparent : Colors.grey.withValues(alpha: 0.04),
            ),
            cells: [
              // User
              DataCell(
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: _teamColor(
                        info.teamName,
                      ).withValues(alpha: 0.12),
                      child: Text(
                        _initials(info.user),
                        style: textTheme.labelSmall?.copyWith(
                          color: _teamColor(info.teamName),
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      info.user,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Clock in
              DataCell(
                _TimeBadge(
                  time: info.clockInTime,
                  icon: Icons.login_rounded,
                  color: Colors.green,
                ),
              ),
              // Clock out
              DataCell(
                _TimeBadge(
                  time: info.clockOutTime,
                  icon: Icons.logout_rounded,
                  color: Colors.red[400]!,
                ),
              ),
              // Time worked
              DataCell(
                _TimeBadge(
                  time: info.timeWorked,
                  icon: Icons.schedule_rounded,
                  color: Colors.blue,
                ),
              ),
              // Team
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _teamColor(info.teamName).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    info.teamName,
                    style: textTheme.labelSmall?.copyWith(
                      color: _teamColor(info.teamName),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Small badge with icon + time ──
class _TimeBadge extends StatelessWidget {
  const _TimeBadge({
    required this.time,
    required this.icon,
    required this.color,
  });
  final String time;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 5),
        Text(
          time,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Helpers ──
IconData _headerIcon(String header) {
  switch (header.toLowerCase()) {
    case 'user':
      return Icons.person_outline_rounded;
    case 'clock in':
      return Icons.login_rounded;
    case 'clock out':
      return Icons.logout_rounded;
    case 'time worked':
      return Icons.schedule_rounded;
    case 'team':
      return Icons.group_outlined;
    default:
      return Icons.circle;
  }
}

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return name.isNotEmpty ? name[0].toUpperCase() : '?';
}

Color _teamColor(String teamName) {
  switch (teamName.toLowerCase()) {
    case 'developper':
    case 'developer':
      return Colors.indigo;
    case 'manager':
      return Colors.teal;
    case 'commercial':
      return Colors.orange;
    case 'mobile':
      return Colors.purple;
    default:
      return Colors.blueGrey;
  }
}
