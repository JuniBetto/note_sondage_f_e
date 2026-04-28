import 'package:flutter/material.dart';
import 'package:note_sondage/feature/clocking/domain/entities/user_clock_info.dart';
import 'package:note_sondage/feature/clocking/ui/widgets/table_component.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class ClockInTrack extends StatelessWidget {
  final bool isMobile;
  const ClockInTrack({
    super.key,
    required this.title,
    required this.isTeamWithUsers,
    required this.dataTable,
    this.isMobile = false,
  });
  final String title;
  final bool isTeamWithUsers;
  final List<UserClockInfo> dataTable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final localization = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: 8),
        ],
        isTeamWithUsers
            ? _buildByTeam(context, isMobile, dataTable, listheaderTable)
            : _buildAllUsers(
                context,
                isMobile,
                dataTable,
                listheaderTable,
                localization.allUsers,
              ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  ALL USERS VIEW
// ════════════════════════════════════════════════════════════════

Widget _buildAllUsers(
  BuildContext context,
  bool isMobile,
  List<UserClockInfo> dataTable,
  List<String> headerTable,
  String allUsersLabel,
) {
  if (dataTable.isEmpty) {
    return const _EmptyClockingState();
  }

  if (isMobile) {
    return _MobileTeamSection(teamName: allUsersLabel, users: dataTable);
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _WebTeamHeader(teamName: allUsersLabel, count: dataTable.length),
      const SizedBox(height: 4),
      SizedBox(
        height: dataTable.length * 58.0,
        width: double.infinity,
        child: TableComponent(dataTable: dataTable, headerTable: headerTable),
      ),
    ],
  );
}

// ════════════════════════════════════════════════════════════════
//  BY TEAM VIEW
// ════════════════════════════════════════════════════════════════

Widget _buildByTeam(
  BuildContext context,
  bool isMobile,
  List<UserClockInfo> dataTable,
  List<String> headerTable,
) {
  if (dataTable.isEmpty) {
    return const _EmptyClockingState();
  }

  final teams = dataTable.map((u) => u.teamName).toSet().toList();

  final List<List<UserClockInfo>> teamsData = teams
      .map((team) => dataTable.where((u) => u.teamName == team).toList())
      .toList();

  if (isMobile) {
    return Column(
      children: teamsData
          .map(
            (teamData) => _MobileTeamSection(
              teamName: teamData.first.teamName,
              users: teamData,
            ),
          )
          .toList(),
    );
  }

  // Web: keep DataTable2
  return Column(
    children: teamsData.map((teamData) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WebTeamHeader(
            teamName: teamData.first.teamName,
            count: teamData.length,
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: teamData.length == 1
                ? 128.0
                : teamData.length > 2
                ? teamData.length * 58.0
                : teamData.length * 72.0,
            width: double.infinity,
            child: TableComponent(
              dataTable: teamData,
              headerTable: headerTable,
            ),
          ),
          const SizedBox(height: 12),
        ],
      );
    }).toList(),
  );
}

class _EmptyClockingState extends StatelessWidget {
  const _EmptyClockingState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final localization = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.grey.withValues(alpha: 0.05),
      ),
      child: Column(
        children: [
          Icon(Icons.schedule_outlined, color: Colors.grey[500], size: 28),
          const SizedBox(height: 8),
          Text(
            localization.noClockingsForFilter,
            style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  WEB — TEAM HEADER (STYLED)
// ════════════════════════════════════════════════════════════════

class _WebTeamHeader extends StatelessWidget {
  const _WebTeamHeader({required this.teamName, required this.count});
  final String teamName;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final teamColor = _teamColor(teamName);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: teamColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.group_rounded, size: 18, color: teamColor),
          const SizedBox(width: 6),
          Text(
            teamName,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: teamColor,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: teamColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              AppLocalizations.of(context)!.member(count),
              style: textTheme.labelSmall?.copyWith(
                color: teamColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  MOBILE — TEAM SECTION (CARD-BASED)
// ════════════════════════════════════════════════════════════════

class _MobileTeamSection extends StatelessWidget {
  const _MobileTeamSection({required this.teamName, required this.users});
  final String teamName;
  final List<UserClockInfo> users;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    // Pick a team color
    final teamColor = _teamColor(teamName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Team header ──
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: teamColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.group_rounded, size: 18, color: teamColor),
              const SizedBox(width: 6),
              Text(
                teamName,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.textColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: teamColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${users.length}',
                  style: textTheme.labelSmall?.copyWith(
                    color: teamColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── User cards ──
          ...users.map(
            (user) => _UserClockCard(user: user, teamColor: teamColor),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  MOBILE — SINGLE USER CARD
// ════════════════════════════════════════════════════════════════

class _UserClockCard extends StatelessWidget {
  const _UserClockCard({required this.user, required this.teamColor});
  final UserClockInfo user;
  final Color teamColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.bgNavbarSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Name + Avatar ──
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: teamColor.withValues(alpha: 0.15),
                child: Text(
                  _initials(user.user),
                  style: textTheme.labelMedium?.copyWith(
                    color: teamColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  user.user,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.textColor,
                  ),
                ),
              ),
              // Team badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: teamColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  user.teamName,
                  style: textTheme.labelSmall?.copyWith(
                    color: teamColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Clock info row ──
          Row(
            children: [
              _ClockInfoChip(
                icon: Icons.login_rounded,
                label: user.clockInTime,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              _ClockInfoChip(
                icon: Icons.logout_rounded,
                label: user.clockOutTime,
                color: Colors.red,
              ),
              const Spacer(),
              // Time worked
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.timeWorked,
                      style: textTheme.labelMedium?.copyWith(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  HELPERS
// ════════════════════════════════════════════════════════════════

class _ClockInfoChip extends StatelessWidget {
  const _ClockInfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return name.isNotEmpty ? name[0].toUpperCase() : '?';
}

Color _teamColor(String teamName) {
  switch (teamName.toLowerCase()) {
    case 'developper':
    case 'developer':
      return Colors.indigo;
    case 'manager':
      return Colors.teal;
    case 'commercial':
      return Colors.orange;
    case 'mobile':
      return Colors.purple;
    default:
      return Colors.blueGrey;
  }
}

final List<String> listheaderTable = [
  "User",
  "Clock in",
  "Clock out",
  "Time worked",
  "Team",
];
