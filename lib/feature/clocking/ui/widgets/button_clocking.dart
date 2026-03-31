import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class ButtonClocking extends StatefulWidget {
  const ButtonClocking({super.key, this.isCompact = false});
  final bool isCompact;

  @override
  State<ButtonClocking> createState() => _ButtonClockingState();
}

class _ButtonClockingState extends State<ButtonClocking>
    with SingleTickerProviderStateMixin {
  bool isClockedIn = false;
  bool isPaused = false;

  void toggleClocking() {
    setState(() {
      if (isClockedIn) {
        isClockedIn = false;
        isPaused = false;
      } else {
        isClockedIn = true;
      }
    });
  }

  void togglePause() {
    setState(() {
      if (isClockedIn) {
        isPaused = !isPaused;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final localization = AppLocalizations.of(context)!;

    final clockColor = isClockedIn ? Colors.red : Colors.green;
    final pauseColor = isPaused
        ? Colors.orange
        : isClockedIn
        ? Colors.amber[700]!
        : Colors.grey[400]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Clock In/Out button ──
        _ClockActionButton(
          onTap: toggleClocking,
          color: clockColor,
          icon: isClockedIn ? Icons.stop_rounded : Icons.play_arrow_rounded,
          label: isClockedIn
              ? localization.clockedOutAt.replaceAll(':', '').trim()
              : localization.clockedInAt.replaceAll(':', '').trim(),
          subtitle: isClockedIn ? 'Tap to clock out' : 'Tap to clock in',
          isCompact: widget.isCompact,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        const SizedBox(width: 12),
        // ── Pause/Resume button ──
        _ClockActionButton(
          onTap: isClockedIn ? togglePause : null,
          color: pauseColor,
          icon: isPaused ? Icons.play_circle_outline : Icons.coffee_rounded,
          label: isPaused
              ? localization.endBreakAt.replaceAll(':', '').trim()
              : localization.startBreakAt.replaceAll(':', '').trim(),
          subtitle: isPaused ? 'Tap to resume' : 'Tap for break',
          isCompact: widget.isCompact,
          isDisabled: !isClockedIn,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
      ],
    );
  }
}

class _ClockActionButton extends StatefulWidget {
  const _ClockActionButton({
    required this.onTap,
    required this.color,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isCompact,
    required this.colorScheme,
    required this.textTheme,
    this.isDisabled = false,
  });

  final VoidCallback? onTap;
  final Color color;
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isCompact;
  final bool isDisabled;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  State<_ClockActionButton> createState() => _ClockActionButtonState();
}

class _ClockActionButtonState extends State<_ClockActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final opacity = widget.isDisabled ? 0.4 : 1.0;

    return MouseRegion(
      cursor: widget.isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? 14 : 20,
            vertical: widget.isCompact ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: widget.color.withValues(
              alpha: _isHovered ? 0.18 : 0.1 * opacity,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.35 * opacity),
              width: 1.5,
            ),
            boxShadow: _isHovered && !widget.isDisabled
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15 * opacity),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: widget.isCompact ? 24 : 30,
                  color: widget.color.withValues(alpha: opacity),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: widget.textTheme.bodyMedium?.copyWith(
                  color: widget.colorScheme.iconLabel?.withValues(
                    alpha: opacity,
                  ),
                  fontWeight: FontWeight.w700,
                  fontSize: widget.isCompact ? 12 : 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: widget.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500]?.withValues(alpha: opacity),
                  fontSize: widget.isCompact ? 10 : 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
