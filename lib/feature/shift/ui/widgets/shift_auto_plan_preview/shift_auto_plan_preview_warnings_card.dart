import 'package:flutter/material.dart';

class ShiftAutoPlanPreviewWarningsCard extends StatelessWidget {
  const ShiftAutoPlanPreviewWarningsCard({
    super.key,
    required this.compact,
    required this.title,
    required this.warnings,
  });

  final bool compact;
  final String title;
  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: const Color(0xFFFFF9EA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFF1C972)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF8A5A00),
              ),
            ),
            const SizedBox(height: 10),
            ...warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: Color(0xFF8A5A00),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        warning,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: compact ? 12.5 : 13.5,
                          color: const Color(0xFF8A5A00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
