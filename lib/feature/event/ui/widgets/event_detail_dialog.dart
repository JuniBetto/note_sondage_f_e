import 'package:flutter/material.dart';
import 'package:note_sondage/feature/event/domain/entities/event_entity.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';

import 'event_list_card.dart';

/// Read-only detail view opened by tapping an event in the calendar (day,
/// week or month) — mirrors what [EventListCard] shows, plus who created
/// it. Editing stays a deliberate, separate action: [onEdit] is only wired
/// up (and its button only shown) when [canEdit] is true.
Future<void> showEventDetailDialog(
  BuildContext context, {
  required EventEntity event,
  required bool canEdit,
  required VoidCallback onEdit,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        _EventDetailDialog(event: event, canEdit: canEdit, onEdit: onEdit),
  );
}

class _EventDetailDialog extends StatelessWidget {
  const _EventDetailDialog({
    required this.event,
    required this.canEdit,
    required this.onEdit,
  });

  final EventEntity event;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final appPrimary = colorScheme.primaryColor ?? colorScheme.primary;
    final participants = event.participantDisplayNames.isEmpty
        ? loc.eventNoParticipants
        : event.participantDisplayNames.join(', ');

    return AlertDialog(
      backgroundColor: colorScheme.dialogBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              event.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          EventTypeChip(
            label: event.allDay ? loc.eventAllDayLabel : loc.eventChipLabel,
            foreground: appPrimary,
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EventMetaRow(
                icon: Icons.schedule_outlined,
                label: loc.eventScheduleLabel,
                value: formatEventSchedule(context, event),
              ),
              if ((event.createdByDisplayName ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                EventMetaRow(
                  icon: Icons.person_outline,
                  label: loc.eventCreatedByLabel,
                  value: event.createdByDisplayName!,
                ),
              ],
              if ((event.location ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                EventMetaRow(
                  icon: Icons.place_outlined,
                  label: loc.eventLocationLabel,
                  value: event.location!,
                ),
              ],
              if ((event.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  event.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 12),
              EventMetaRow(
                icon: Icons.group_outlined,
                label: loc.eventParticipantsLabel,
                value: participants,
              ),
              if ((event.workflowMetadata?.sourceType ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                EventTypeChip(
                  label: loc.eventSourceLabel(
                    event.workflowMetadata!.sourceType!,
                  ),
                  foreground: colorScheme.iconLabel ?? appPrimary,
                  soft: true,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        CustomAppButton(
          onPressed: () => Navigator.of(context).pop(),
          isActive: false,
          type: ButtonType.text,
          child: Text(loc.close),
        ),
        if (canEdit)
          CustomAppButton(
            onPressed: () {
              Navigator.of(context).pop();
              onEdit();
            },
            isActive: true,
            type: ButtonType.filled,
            child: Text(loc.eventEditAction),
          ),
      ],
    );
  }
}
