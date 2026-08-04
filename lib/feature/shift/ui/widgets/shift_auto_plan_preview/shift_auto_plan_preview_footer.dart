import 'package:flutter/material.dart';

class ShiftAutoPlanPreviewFooter extends StatelessWidget {
  const ShiftAutoPlanPreviewFooter({
    super.key,
    required this.compact,
    required this.submitting,
    required this.canConfirm,
    required this.backLabel,
    required this.confirmLabel,
    required this.onBack,
    required this.onConfirm,
  });

  final bool compact;
  final bool submitting;
  final bool canConfirm;
  final String backLabel;
  final String confirmLabel;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 24,
        12,
        compact ? 12 : 24,
        compact ? 12 : 18,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.16)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: submitting ? null : onBack,
              child: Text(backLabel),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: submitting || !canConfirm ? null : onConfirm,
              child: submitting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : Text(confirmLabel),
            ),
          ),
        ],
      ),
    );
  }
}
