import 'package:flutter/material.dart';
import 'package:note_sondage/core/tutorial/debug_showcase.dart';
import 'package:note_sondage/feature/event/ui/event_workspace.dart';
import 'package:note_sondage/feature/event/ui/widgets/event_text_size_toggle.dart';
import 'package:note_sondage/feature/event/ui/widgets/event_view_mode_toggle.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_calendar_team_picker.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/archive_view_toggle.dart';

import 'event_surface_card.dart';

class EventWorkspaceHeader extends StatelessWidget {
  const EventWorkspaceHeader({
    super.key,
    required this.embedded,
    required this.teams,
    required this.selectedTeamId,
    required this.showArchived,
    required this.activeCount,
    required this.archivedCount,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.onCreateEvent,
    required this.onTeamChanged,
    required this.onArchivedToggle,
    this.createButtonKey,
    this.createButtonTitle,
    this.createButtonDescription,
    this.filterKey,
    this.filterTitle,
    this.filterDescription,
  });

  final bool embedded;
  final List<TeamEntityForView> teams;
  final String? selectedTeamId;
  final bool showArchived;
  final int activeCount;
  final int archivedCount;
  final EventViewMode viewMode;
  final ValueChanged<EventViewMode> onViewModeChanged;
  final VoidCallback onCreateEvent;
  final ValueChanged<String?> onTeamChanged;
  final ValueChanged<bool> onArchivedToggle;
  final GlobalKey? createButtonKey;
  final String? createButtonTitle;
  final String? createButtonDescription;
  final GlobalKey? filterKey;
  final String? filterTitle;
  final String? filterDescription;

  Widget _wrapShowcase({
    required Widget child,
    GlobalKey? showcaseKey,
    String? title,
    String? description,
  }) {
    if (showcaseKey == null ||
        title == null ||
        description == null ||
        isInspectorSelectionActive) {
      return child;
    }
    return Showcase(
      key: showcaseKey,
      title: title,
      description: description,
      child: child,
    );
  }

  Widget _buildNewEventButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;
    final navButtonColor =
        colorScheme.bgNavbarbutton ??
        colorScheme.primaryColor ??
        colorScheme.primary;
    final onNavButtonColor = colorScheme.textInvertedColor ?? Colors.white;

    final button = FilledButton.icon(
      onPressed: onCreateEvent,
      style: FilledButton.styleFrom(backgroundColor: navButtonColor),
      icon: Icon(Icons.add, color: onNavButtonColor),
      label: Text(
        loc.eventNewEventAction,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: onNavButtonColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return _wrapShowcase(
      showcaseKey: createButtonKey,
      title: createButtonTitle,
      description: createButtonDescription,
      child: button,
    );
  }

  Widget _buildBanner(BuildContext context, {required bool isCompact}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;
    final appPrimary = colorScheme.primaryColor ?? colorScheme.primary;

    final iconChip = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: appPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.event_outlined, size: 22, color: appPrimary),
    );
    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          loc.eventHeaderTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.iconLabel,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          loc.eventHeaderSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    return EventSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      radius: 16,
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    iconChip,
                    const SizedBox(width: 14),
                    Expanded(child: textBlock),
                  ],
                ),
                const SizedBox(height: 14),
                _buildNewEventButton(context),
              ],
            )
          : Row(
              children: [
                iconChip,
                const SizedBox(width: 14),
                Expanded(child: textBlock),
                const SizedBox(width: 16),
                _buildNewEventButton(context),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 760;
        final archiveToggle = _wrapShowcase(
          showcaseKey: filterKey,
          title: filterTitle,
          description: filterDescription,
          child: ArchiveViewToggle(
            showArchivedOnly: showArchived,
            primaryCount: activeCount,
            archivedCount: archivedCount,
            primaryLabel: loc.eventActiveFilterLabel,
            archivedLabel: loc.eventArchivedFilterLabel,
            onChanged: onArchivedToggle,
          ),
        );
        final teamPicker = ShiftCalendarTeamPicker(
          teams: teams,
          selectedTeamId: selectedTeamId,
          includePersonalOption: true,
          personalOptionTitle: loc.eventMyEventsTitle,
          personalOptionSubtitle: loc.eventMyEventsSubtitle,
          onChanged: onTeamChanged,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!embedded) ...[
              _buildBanner(context, isCompact: isCompact),
              const SizedBox(height: 16),
            ],
            if (isCompact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  teamPicker,
                  const SizedBox(height: 12),
                  archiveToggle,
                  const SizedBox(height: 12),
                  if (embedded)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNewEventButton(context),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              const EventTextSizeToggle(),
                              EventViewModeToggle(
                                viewMode: viewMode,
                                onChanged: onViewModeChanged,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const EventTextSizeToggle(),
                        EventViewModeToggle(
                          viewMode: viewMode,
                          onChanged: onViewModeChanged,
                        ),
                      ],
                    ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: teamPicker,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        archiveToggle,
                        EventViewModeToggle(
                          viewMode: viewMode,
                          onChanged: onViewModeChanged,
                        ),
                        if (embedded) _buildNewEventButton(context),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
