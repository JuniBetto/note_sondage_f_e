import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/utils/app_constant.dart';
import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';
import 'package:note_sondage/feature/clocking/domain/entities/user_clock_info.dart';
import 'package:note_sondage/feature/clocking/ui/bloc/clocking_bloc.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/clockin_track.dart';
import 'package:note_sondage/feature/team/ui/widgets/select_option_with_search.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';

class StatusClockInChangeView extends StatefulWidget {
  const StatusClockInChangeView({super.key, this.isMobile = false});
  final bool isMobile;

  @override
  State<StatusClockInChangeView> createState() =>
      _StatusClockInChangeViewState();
}

class _StatusClockInChangeViewState extends State<StatusClockInChangeView> {
  bool isClockedTeamWithUsers = true;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onStatusChanged(String? value) {
    // Handle status change logic here
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final localization = AppLocalizations.of(context)!;

    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.bgNavbarSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
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
        mainAxisSize: widget.isMobile ? MainAxisSize.min : MainAxisSize.max,
        children: [
          // ── Search + filter row ──
          widget.isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchField(textTheme, colorScheme),
                    const SizedBox(height: 12),
                    _buildDropdown(theme, localization, colorScheme),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildSearchField(textTheme, colorScheme),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildDropdown(theme, localization, colorScheme),
                    ),
                  ],
                ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 16),

          // ── Table / Cards ──
          BlocBuilder<ClockingBloc, ClockingState>(
            builder: (context, state) {
              final records = state is ClockingRecordsLoaded
                  ? state.records
                  : const <ClockingRecordEntity>[];
              final filteredRecords = _filterRecords(records);
              final tableRows = filteredRecords
                  .map(
                    (record) => UserClockInfo(
                      user: record.userName,
                      clockInTime: record.clockInFormatted,
                      clockOutTime: record.clockOutFormatted,
                      timeWorked: record.timeWorkedFormatted,
                      teamName: record.teamName,
                    ),
                  )
                  .toList();

              if (widget.isMobile) {
                return ClockInTrack(
                  isTeamWithUsers: isClockedTeamWithUsers,
                  title: '',
                  isMobile: true,
                  dataTable: tableRows,
                );
              }

              return Expanded(
                child: SingleChildScrollView(
                  child: ClockInTrack(
                    isTeamWithUsers: isClockedTeamWithUsers,
                    title: '',
                    isMobile: false,
                    dataTable: tableRows,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );

    // Su web: Expanded per riempire lo spazio. Su mobile: no Expanded.
    if (widget.isMobile) {
      return content;
    }
    return Expanded(child: content);
  }

  Widget _buildSearchField(TextTheme textTheme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.search_rounded, size: 18, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              "Search team or member",
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.iconLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CustomInputField(
          hintText: "Email or team name",
          controller: _searchController,
          isSearch: true,
          onSearchPressed: () => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    ThemeData theme,
    AppLocalizations localization,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.filter_list_rounded, size: 18, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              "Filter view",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.iconLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GenericDropdownFormField<String>(
          label: "",
          style: theme.textTheme.bodyMedium,
          items: listStatusClockCheck,
          value: listStatusClockCheck.first,
          displayText: (status) => status,
          valueGetter: (status) => status,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                isClockedTeamWithUsers = value == "Team with users"
                    ? true
                    : false;
              });
            }
            _onStatusChanged(value);
          },
          hintText: localization.status,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a status';
            }
            return null;
          },
        ),
      ],
    );
  }

  List<ClockingRecordEntity> _filterRecords(List<ClockingRecordEntity> records) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return records;

    return records.where((record) {
      return record.userName.toLowerCase().contains(query) ||
          record.teamName.toLowerCase().contains(query);
    }).toList();
  }
}
