import 'package:flutter/material.dart';

class ShiftAutoPlanPreviewHeaderCard extends StatelessWidget {
  const ShiftAutoPlanPreviewHeaderCard({
    super.key,
    required this.compact,
    required this.fullyFeasible,
    required this.statusLabel,
    required this.dateRangeLabel,
    required this.description,
  });

  final bool compact;
  final bool fullyFeasible;
  final String statusLabel;
  final String dateRangeLabel;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = fullyFeasible
        ? const Color(0xFF146C43)
        : const Color(0xFF8A5A00);
    final statusBackground = fullyFeasible
        ? const Color(0xFFE7F7EF)
        : const Color(0xFFFFF4DB);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  dateRangeLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: compact ? 12.5 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
