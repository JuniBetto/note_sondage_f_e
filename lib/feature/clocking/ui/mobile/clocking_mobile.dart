import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/button_clocking.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/status_clockin_change_view.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/status_clocking.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class ClockingMobile extends StatefulWidget {
  const ClockingMobile({super.key});

  @override
  State<ClockingMobile> createState() => _ClockingMobileState();
}

class _ClockingMobileState extends State<ClockingMobile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final localization = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // ═══════════════════════════════
          // Status + Subtitle
          // ═══════════════════════════════
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.bgNavbarSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.timer_rounded,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      localization.personalStatusClockingActions,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StatusClocking(isCompact: true),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ═══════════════════════════════
          // Action buttons — centered
          // ═══════════════════════════════
          const Center(child: ButtonClocking(isCompact: true)),

          const SizedBox(height: 16),

          // ═══════════════════════════════
          // Tracking section
          // ═══════════════════════════════
          StatusClockInChangeView(isMobile: true),
        ],
      ),
    );
  }
}
