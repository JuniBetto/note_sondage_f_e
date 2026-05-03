import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/feature/clocking/ui/mobile/clocking_shift_tab_page.dart';
import 'package:note_sondage/feature/home/domain/entities/dashboard_entity.dart';
import 'package:note_sondage/feature/home/ui/bloc/dashboard_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';
import 'package:note_sondage/ui/widgets/pending_notifications_card.dart';

class HomeDashboardMobile extends StatefulWidget {
  const HomeDashboardMobile({super.key});

  @override
  State<HomeDashboardMobile> createState() => _HomeDashboardMobileState();
}

class _HomeDashboardMobileState extends State<HomeDashboardMobile> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadDashboardEvent());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final stats = state is DashboardLoaded ? state.stats : null;
        final activities =
            state is DashboardLoaded ? state.activities : <RecentActivity>[];
        final isLoading = state is DashboardLoading || state is DashboardInitial;

        return RefreshIndicator(
          onRefresh: () async {
            context.read<DashboardBloc>().add(RefreshDashboardEvent());
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══════════════════════════════
                // Welcome banner
                // ═══════════════════════════════
                _MobileWelcomeBanner(),
                const SizedBox(height: 20),

                // ═══════════════════════════════
                // Stats grid 2×2 + 1 riga shift
                // ═══════════════════════════════
                Row(
                  children: [
                    Expanded(
                      child: _MobileStatCard(
                        icon: Icons.group_rounded,
                        label: l.activeTeams,
                        value: isLoading ? null : '${stats?.activeTeams ?? 0}',
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MobileStatCard(
                        icon: Icons.people_rounded,
                        label: l.totalMembers,
                        value:
                            isLoading ? null : '${stats?.totalMembers ?? 0}',
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MobileStatCard(
                        icon: Icons.checklist_rounded,
                        label: l.activeSurveys,
                        value:
                            isLoading ? null : '${stats?.activeSurveys ?? 0}',
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MobileStatCard(
                        icon: Icons.timer_rounded,
                        label: l.todayClocking,
                        value:
                            isLoading ? null : '${stats?.todayClocking ?? 0}',
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MobileStatCard(
                        icon: Icons.calendar_month_rounded,
                        label: l.myShifts,
                        value:
                            isLoading ? null : '${stats?.todayShifts ?? 0}',
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Spazio vuoto a destra per mantenere la griglia bilanciata
                    const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: 20),

                // ═══════════════════════════════
                // Quick actions
                // ═══════════════════════════════
                _MobileQuickActions(),
                const SizedBox(height: 20),

                // ═══════════════════════════════
                // Pending notifications
                // ═══════════════════════════════
                const PendingNotificationsCard(),
                const SizedBox(height: 20),

                // ═══════════════════════════════
                // Recent activity
                // ═══════════════════════════════
                _MobileRecentActivity(
                  activities: activities,
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


// ════════════════════════════════════════════════════════════════
//  WELCOME BANNER (MOBILE)
// ════════════════════════════════════════════════════════════════

class _MobileWelcomeBanner extends StatelessWidget {
  const _MobileWelcomeBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.withValues(alpha: 0.12),
            Colors.blue.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l.welcomeBack} 👋',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.dashboardSubtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/astronaut.png',
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  size: 32,
                  color: Colors.indigo,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  STAT CARD (MOBILE)
// ════════════════════════════════════════════════════════════════

class _MobileStatCard extends StatelessWidget {
  const _MobileStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.bgNavbarSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          value == null
              ? const SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  value!,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.textColor,
                  ),
                ),
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  QUICK ACTIONS (MOBILE)
// ════════════════════════════════════════════════════════════════

class _MobileQuickActions extends StatelessWidget {
  const _MobileQuickActions();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;
    final navBloc = context.read<NavigationBloc>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.bgNavbarSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
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
          Row(
            children: [
              Icon(Icons.flash_on_rounded, size: 18, color: Colors.amber[700]),
              const SizedBox(width: 6),
              Text(
                l.quickActions,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.group_add_rounded,
                  label: l.team,
                  color: Colors.indigo,
                  onTap: () => navBloc.add(NavigationPositionChanged(1)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.timer_rounded,
                  label: l.clockingInOut,
                  color: Colors.blue,
                  onTap: () => navBloc.add(NavigationPositionChanged(3)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.checklist_rounded,
                  label: l.sondage,
                  color: Colors.orange,
                  onTap: () => navBloc.add(NavigationPositionChanged(4)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.calendar_month_rounded,
                  label: l.myShifts,
                  color: Colors.purple,
                  onTap: () {
                    ClockingShiftTabPage.requestedInitialTab = 1;
                    navBloc.add(NavigationPositionChanged(3));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.textColor,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  RECENT ACTIVITY (MOBILE)
// ════════════════════════════════════════════════════════════════

class _MobileRecentActivity extends StatelessWidget {
  const _MobileRecentActivity({
    required this.activities,
    required this.isLoading,
  });

  final List<RecentActivity> activities;
  final bool isLoading;

  IconData _iconFor(RecentActivityType type) {
    switch (type) {
      case RecentActivityType.clockIn:
        return Icons.login_rounded;
      case RecentActivityType.clockOut:
        return Icons.logout_rounded;
      case RecentActivityType.teamCreated:
        return Icons.group_rounded;
      case RecentActivityType.memberJoined:
        return Icons.group_add_rounded;
      case RecentActivityType.sondageCreated:
        return Icons.checklist_rounded;
      case RecentActivityType.sondageCompleted:
        return Icons.check_circle_outline_rounded;
      case RecentActivityType.shiftAssigned:
        return Icons.calendar_month_rounded;
    }
  }

  Color _colorFor(RecentActivityType type) {
    switch (type) {
      case RecentActivityType.clockIn:
        return Colors.green;
      case RecentActivityType.clockOut:
        return Colors.red;
      case RecentActivityType.teamCreated:
      case RecentActivityType.memberJoined:
        return Colors.indigo;
      case RecentActivityType.sondageCreated:
        return Colors.orange;
      case RecentActivityType.sondageCompleted:
        return Colors.teal;
      case RecentActivityType.shiftAssigned:
        return Colors.purple;
    }
  }

  String _formatTime(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.bgNavbarSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
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
          Row(
            children: [
              Icon(Icons.history_rounded, size: 18, color: Colors.blue[600]),
              const SizedBox(width: 6),
              Text(
                l.recentActivity,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (activities.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  l.noRecentActivity,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ),
            )
          else
            ...activities.map(
              (a) {
                final icon = _iconFor(a.type);
                final color = _colorFor(a.type);
                final time = _formatTime(a.timestamp);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 14, color: color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.title,
                              style: textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.textColor,
                              ),
                            ),
                            Text(
                              a.subtitle,
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        time,
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
