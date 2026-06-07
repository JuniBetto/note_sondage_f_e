import 'package:flutter/material.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/anchored_dropdown_overlay.dart';

class ShiftCalendarTeamPicker extends StatefulWidget {
  const ShiftCalendarTeamPicker({
    super.key,
    required this.teams,
    required this.selectedTeamId,
    required this.onChanged,
    this.includePersonalOption = true,
    this.personalOptionTitle,
    this.personalOptionSubtitle,
    this.unselectedTitle,
    this.triggerSubtitle,
    this.teamFallbackSubtitle,
  });

  final List<TeamEntityForView> teams;
  final String? selectedTeamId;
  final ValueChanged<String?> onChanged;
  final bool includePersonalOption;
  final String? personalOptionTitle;
  final String? personalOptionSubtitle;
  final String? unselectedTitle;
  final String? triggerSubtitle;
  final String? teamFallbackSubtitle;

  @override
  State<ShiftCalendarTeamPicker> createState() =>
      _ShiftCalendarTeamPickerState();
}

class _ShiftCalendarTeamPickerState extends State<ShiftCalendarTeamPicker> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<TeamEntityForView> get _filteredTeams {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.teams;
    }
    return widget.teams.where((team) {
      final name = team.team.name.toLowerCase();
      final description = (team.team.description).toLowerCase();
      return name.contains(query) || description.contains(query);
    }).toList();
  }

  TeamEntityForView? get _selectedTeam {
    final selectedId = widget.selectedTeamId;
    if (selectedId == null || selectedId.isEmpty) {
      return null;
    }
    return widget.teams.where((team) => team.team.id == selectedId).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final personalTitle = widget.personalOptionTitle ?? loc.myShifts;
    final personalSubtitle =
        widget.personalOptionSubtitle ?? loc.shiftCalendarSubtitle;
    final unselectedTitle = widget.unselectedTitle ?? personalTitle;
    final triggerSubtitle = widget.triggerSubtitle ?? loc.changeOrSearchTeam;
    final teamFallbackSubtitle =
        widget.teamFallbackSubtitle ?? loc.teamAvailableForClocking;

    return AnchoredDropdownOverlay(
      triggerBuilder: (context, isOpen, toggle) => _PickerTriggerCard(
        title: _selectedTeam?.team.name ?? unselectedTitle,
        subtitle: triggerSubtitle,
        isOpen: isOpen,
        onTap: toggle,
      ),
      overlayBuilder: (context, width, maxHeight, close) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: _PickerPanel(
          width: width,
          searchController: _searchController,
          searchHintText: loc.searchTeam,
          onSearchChanged: (_) => setState(() {}),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: _filteredTeams.length > 4,
              child: ListView.separated(
                controller: _scrollController,
                shrinkWrap: true,
                itemCount: _filteredTeams.isEmpty
                    ? (widget.includePersonalOption ? 2 : 1)
                    : _filteredTeams.length +
                          (widget.includePersonalOption ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  if (widget.includePersonalOption && index == 0) {
                    return _PickerOptionTile(
                      label: personalTitle,
                      subtitle: personalSubtitle,
                      isSelected: widget.selectedTeamId == null,
                      onTap: () {
                        widget.onChanged(null);
                        _searchController.clear();
                        close();
                      },
                    );
                  }

                  if (_filteredTeams.isEmpty) {
                    return _PickerEmptyState(message: loc.noTeamFound);
                  }

                  final team =
                      _filteredTeams[index -
                          (widget.includePersonalOption ? 1 : 0)];
                  return _PickerOptionTile(
                    label: team.team.name,
                    subtitle: (team.team.description).trim().isNotEmpty
                        ? team.team.description.trim()
                        : teamFallbackSubtitle,
                    isSelected: team.team.id == widget.selectedTeamId,
                    onTap: () {
                      widget.onChanged(team.team.id);
                      _searchController.clear();
                      close();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerTriggerCard extends StatelessWidget {
  const _PickerTriggerCard({
    required this.title,
    required this.subtitle,
    required this.isOpen,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = colorScheme.primaryColor ?? colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOpen
                ? accent.withValues(alpha: 0.45)
                : colorScheme.outlineVariant,
          ),
          color: isOpen ? accent.withValues(alpha: 0.05) : colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isOpen ? 0.05 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.groups_2_outlined, size: 18, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.descriptionColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isOpen
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: colorScheme.descriptionColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerPanel extends StatelessWidget {
  const _PickerPanel({
    required this.width,
    required this.searchController,
    required this.searchHintText,
    required this.child,
    this.onSearchChanged,
  });

  final double width;
  final TextEditingController searchController;
  final String searchHintText;
  final Widget child;
  final ValueChanged<String>? onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: searchHintText,
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Flexible(child: child),
        ],
      ),
    );
  }
}

class _PickerOptionTile extends StatelessWidget {
  const _PickerOptionTile({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = colorScheme.primaryColor ?? colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? accent.withValues(alpha: 0.45)
                : colorScheme.outlineVariant,
          ),
          color: isSelected
              ? accent.withValues(alpha: 0.08)
              : colorScheme.surface,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.descriptionColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isSelected)
              Icon(Icons.check_circle_rounded, size: 18, color: accent),
          ],
        ),
      ),
    );
  }
}

class _PickerEmptyState extends StatelessWidget {
  const _PickerEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        color: colorScheme.surface,
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 18,
            color: colorScheme.descriptionColor,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
