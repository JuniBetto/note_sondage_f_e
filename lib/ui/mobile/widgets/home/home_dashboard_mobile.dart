import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';
import 'package:note_sondage/ui/widgets/pending_notifications_card.dart';

class HomeDashboardMobile extends StatelessWidget {
  const HomeDashboardMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return SingleChildScrollView(
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
          // Stats grid 2×2
          // ═══════════════════════════════
          Row(
            children: [
              Expanded(
                child: _MobileStatCard(
                  icon: Icons.group_rounded,
                  label: l.activeTeams,
                  value: '4',
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MobileStatCard(
                  icon: Icons.people_rounded,
                  label: l.totalMembers,
                  value: '24',
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
                  value: '3',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MobileStatCard(
                  icon: Icons.timer_rounded,
                  label: l.todayClocking,
                  value: '18',
                  color: Colors.blue,
                ),
              ),
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
          _MobileRecentActivity(),
        ],
      ),
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
  final String value;
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
          Text(
            value,
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
  const _MobileRecentActivity();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    final activities = _mockActivities(l);

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
          ...activities.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: a.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(a.icon, size: 14, color: a.color),
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
                    a.time,
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mock data ──

class _Activity {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  const _Activity({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });
}

List<_Activity> _mockActivities(AppLocalizations l) => [
  _Activity(
    icon: Icons.login_rounded,
    title: 'User 3 clocked in',
    subtitle: 'Manager team',
    time: '2 min',
    color: Colors.green,
  ),
  _Activity(
    icon: Icons.group_add_rounded,
    title: 'New member added',
    subtitle: 'User 10 → Mobile team',
    time: '15 min',
    color: Colors.indigo,
  ),
  _Activity(
    icon: Icons.checklist_rounded,
    title: 'Survey "Q1 Feedback" created',
    subtitle: '5 ${l.questions} • 2 ${l.team}',
    time: '1h',
    color: Colors.orange,
  ),
  _Activity(
    icon: Icons.logout_rounded,
    title: 'User 1 clocked out',
    subtitle: 'Developper team • 8h worked',
    time: '2h',
    color: Colors.red,
  ),
];
