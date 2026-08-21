import 'package:flutter/material.dart';
import 'package:note_sondage/feature/event/ui/widgets/event_view_mode_button.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

import '../event_workspace.dart';

class EventViewModeToggle extends StatelessWidget {
  const EventViewModeToggle({
    super.key,
    required this.viewMode,
    required this.onChanged,
  });

  final EventViewMode viewMode;
  final ValueChanged<EventViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final borderColor = colorScheme.borderColor ?? colorScheme.outlineVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            EventViewModeButton(
              icon: Icons.view_agenda_rounded,
              tooltip: l10n.eventViewModeCard,
              selected: viewMode == EventViewMode.card,
              onTap: () => onChanged(EventViewMode.card),
            ),
            EventViewModeButton(
              icon: Icons.calendar_month_rounded,
              tooltip: l10n.eventViewModeCalendar,
              selected: viewMode == EventViewMode.calendar,
              onTap: () => onChanged(EventViewMode.calendar),
            ),
          ],
        ),
      ),
    );
  }
}
