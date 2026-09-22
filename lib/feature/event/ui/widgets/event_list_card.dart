import 'package:flutter/material.dart';
import 'package:note_sondage/feature/event/domain/entities/event_entity.dart';
import 'package:note_sondage/feature/event/ui/widgets/event_reminder_labels.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

import 'event_surface_card.dart';

class EventListCard extends StatelessWidget {
  const EventListCard({
    super.key,
    required this.event,
    required this.isArchivedForMe,
    required this.canEdit,
    required this.onEdit,
    required this.onArchiveToggle,
    required this.onDeleteArchived,
    this.canSetMyReminder = false,
    this.onSetMyReminder,
  });

  final EventEntity event;

  /// Whether *this viewer* has personally archived the event — a purely
  /// local preference (like team/survey/shift archiving), so it's available
  /// to every user regardless of [canEdit].
  final bool isArchivedForMe;

  /// Whether the current user is allowed to manage this event (owner/admin
  /// of its team, a role with Admin/Manage permission, or the creator for a
  /// personal event). The edit and permanent-delete actions are hidden
  /// rather than shown disabled when this is false, so nobody taps into a
  /// form (or a destructive action) that will just fail.
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onArchiveToggle;
  final VoidCallback onDeleteArchived;

  /// Whether the current user (creator or a participant) can set their own
  /// independent reminder on this event — independent from [canEdit], see
  /// `_canSetMyReminder` in `EventWorkspace`.
  final bool canSetMyReminder;
  final VoidCallback? onSetMyReminder;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final participants = event.participantDisplayNames.isEmpty
        ? loc.eventNoParticipants
        : event.participantDisplayNames.join(', ');
    final colorScheme = Theme.of(context).colorScheme;
    final appPrimary = colorScheme.primaryColor ?? colorScheme.primary;

    return EventSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.iconLabel,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatSchedule(context, event),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.descriptionColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              EventTypeChip(
                label: event.allDay ? loc.eventAllDayLabel : loc.eventChipLabel,
                foreground: appPrimary,
              ),
            ],
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
            const SizedBox(height: 10),
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
              label: loc.eventSourceLabel(event.workflowMetadata!.sourceType!),
              foreground: colorScheme.iconLabel ?? appPrimary,
              soft: true,
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (canEdit)
                OutlinedButton.icon(
                  onPressed: isArchivedForMe ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(loc.eventEditAction),
                ),
              // Archiving is a personal "hide from my view" preference, like
              // team/survey/shift archiving — every viewer can toggle it for
              // themselves, no management permission required.
              OutlinedButton.icon(
                onPressed: onArchiveToggle,
                icon: Icon(
                  isArchivedForMe
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                ),
                label: Text(
                  isArchivedForMe
                      ? loc.eventRestoreAction
                      : loc.eventArchiveAction,
                ),
              ),
              if (canEdit && isArchivedForMe)
                TextButton.icon(
                  onPressed: onDeleteArchived,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(loc.eventDeleteAction),
                ),
              if (canSetMyReminder)
                OutlinedButton.icon(
                  onPressed: isArchivedForMe ? null : onSetMyReminder,
                  icon: const Icon(Icons.notifications_outlined),
                  label: Text(eventMyReminderSetAction(context)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSchedule(BuildContext context, EventEntity event) =>
      formatEventSchedule(context, event);
}

/// Shared by [EventListCard] and the event detail dialog so the two views
/// never drift apart on how a schedule reads.
String formatEventSchedule(BuildContext context, EventEntity event) {
  final localizations = MaterialLocalizations.of(context);
  final loc = AppLocalizations.of(context)!;
  final startDate = localizations.formatFullDate(event.startsAt);
  final startTime = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(event.startsAt),
  );
  if (event.allDay) {
    return '$startDate • ${loc.eventScheduleAllDaySuffix}';
  }

  final endsAt = event.endsAt;
  if (endsAt == null) {
    return '$startDate • $startTime';
  }

  final endDate = localizations.formatFullDate(endsAt);
  final endTime = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(endsAt));
  if (startDate == endDate) {
    return '$startDate • $startTime - $endTime';
  }
  return '$startDate • $startTime → $endDate • $endTime';
}

class EventMetaRow extends StatelessWidget {
  const EventMetaRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.descriptionColor),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.descriptionColor,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class EventTypeChip extends StatelessWidget {
  const EventTypeChip({
    super.key,
    required this.label,
    required this.foreground,
    this.soft = false,
  });

  final String label;
  final Color foreground;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: soft
            ? colorScheme.homeSecondary
            : foreground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: soft
              ? colorScheme.borderColor ?? foreground
              : foreground.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
