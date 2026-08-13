import 'package:flutter/material.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class ShiftAutoPlanPreviewFooter extends StatelessWidget {
  const ShiftAutoPlanPreviewFooter({
    super.key,
    required this.compact,
    required this.submitting,
    required this.canConfirm,
    required this.backLabel,
    required this.recalculateLabel,
    required this.confirmLabel,
    required this.onBack,
    required this.onRecalculate,
    required this.onConfirm,
    this.canRecalculate = true,
  });

  final bool compact;
  final bool submitting;
  final bool canConfirm;
  final bool canRecalculate;
  final String backLabel;
  final String recalculateLabel;
  final String confirmLabel;
  final VoidCallback onBack;
  final VoidCallback onRecalculate;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
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
            child: OutlinedButton(
              onPressed: submitting || !canRecalculate ? null : onRecalculate,
              child: Text(recalculateLabel),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: submitting || !canConfirm ? null : onConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: submitting ? null : colorScheme.bgsecondary,
              ),
              child: submitting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Text(
                      confirmLabel,
                      style: textTheme.bodyMedium!.copyWith(
                        color: submitting
                            ? colorScheme.textColor
                            : colorScheme.textInvertedColor,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
