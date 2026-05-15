import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/home/domain/entities/dashboard_entity.dart';
import 'package:note_sondage/feature/home/ui/bloc/dashboard_bloc.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_service.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';
import 'package:note_sondage/ui/widgets/pending_notifications_card.dart';
import 'package:showcaseview/showcaseview.dart';

class HomeWeb extends StatefulWidget {
  const HomeWeb({super.key});

  @override
  State<HomeWeb> createState() => _HomeWebState();
}

class _HomeWebState extends State<HomeWeb> {
  final GlobalKey _bannerKey = GlobalKey();
  final GlobalKey _statsKey = GlobalKey();
  final GlobalKey _notificationsKey = GlobalKey();
  final GlobalKey _quickActionsKey = GlobalKey();
  final GlobalKey _activityKey = GlobalKey();
  StreamSubscription<RealtimeNotification>? _realtimeSub;
  bool _tutorialScheduled = false;

  // Services that contribute to the Recent Activity feed.
  static const _activitySources = {
    'team-service',
    'clocking-service',
    'sondage-service',
    'shift-service',
  };

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadDashboardEvent());

    _realtimeSub = getIt<RealtimeNotificationService>().stream.listen(
      _onRealtimeNotification,
    );
  }

  void _onRealtimeNotification(RealtimeNotification notification) {
    if (!mounted) return;
    if (_activitySources.contains(notification.sourceService)) {
      context.read<DashboardBloc>().add(RefreshDashboardEvent());
    }
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    AppTutorialController.registerTargets(
      tutorialId: 'web-home',
      keys: <GlobalKey>[
        _bannerKey,
        _statsKey,
        _notificationsKey,
        _quickActionsKey,
        _activityKey,
      ],
    );
    AppTutorialController.registerReplayAction(
      tutorialId: 'web-home',
      action: () => AppTutorialController.replay(
        context: context,
        keys: <GlobalKey>[
          _bannerKey,
          _statsKey,
          _notificationsKey,
          _quickActionsKey,
          _activityKey,
        ],
      ),
    );
    AppTutorialController.registerReplayAction(
      tutorialId: 'web-main-0',
      action: () => AppTutorialController.replayRegistered(
        context: context,
        tutorialId: 'web-home',
      ),
    );
    _scheduleTutorial();

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, dashState) {
        final stats = dashState is DashboardLoaded ? dashState.stats : null;
        final activities = dashState is DashboardLoaded
            ? dashState.activities
            : <RecentActivity>[];
        final isLoading =
            dashState is DashboardLoading || dashState is DashboardInitial;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 800;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ═══════════════════════════════
                  // Welcome banner
                  // ═══════════════════════════════
                  Showcase(
                    key: _bannerKey,
                    title: _isItalian(context)
                        ? 'Benvenuto nella dashboard'
                        : 'Welcome to your dashboard',
                    description: _isItalian(context)
                        ? 'Questa parte alta ti dà subito il contesto della giornata e una panoramica iniziale del tuo spazio di lavoro.'
                        : 'This top section immediately sets the context for the day and gives you a first overview of your workspace.',
                    child: _WelcomeBanner(isNarrow: isNarrow),
                  ),
                  const SizedBox(height: 24),

                  // ═══════════════════════════════
                  // Stats row
                  // ═══════════════════════════════
                  Showcase(
                    key: _statsKey,
                    title: _isItalian(context)
                        ? 'Statistiche principali'
                        : 'Key statistics',
                    description: _isItalian(context)
                        ? 'Queste card riassumono subito squadre attive, membri, sondaggi, timbrature e turni del giorno.'
                        : 'These cards summarize your active teams, members, surveys, clocking activity, and daily shifts at a glance.',
                    child: isNarrow
                        ? Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.group_rounded,
                                      label: l.activeTeams,
                                      value: isLoading
                                          ? null
                                          : '${stats?.activeTeams ?? 0}',
                                      color: Colors.indigo,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.people_rounded,
                                      label: l.totalMembers,
                                      value: isLoading
                                          ? null
                                          : '${stats?.totalMembers ?? 0}',
                                      color: Colors.teal,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.checklist_rounded,
                                      label: l.activeSurveys,
                                      value: isLoading
                                          ? null
                                          : '${stats?.activeSurveys ?? 0}',
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.timer_rounded,
                                      label: l.todayClocking,
                                      value: isLoading
                                          ? null
                                          : '${stats?.todayClocking ?? 0}',
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.calendar_month_rounded,
                                      label: l.myShifts,
                                      value: isLoading
                                          ? null
                                          : '${stats?.todayShifts ?? 0}',
                                      color: Colors.purple,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(child: SizedBox()),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.group_rounded,
                                  label: l.activeTeams,
                                  value: isLoading
                                      ? null
                                      : '${stats?.activeTeams ?? 0}',
                                  color: Colors.indigo,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.people_rounded,
                                  label: l.totalMembers,
                                  value: isLoading
                                      ? null
                                      : '${stats?.totalMembers ?? 0}',
                                  color: Colors.teal,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.checklist_rounded,
                                  label: l.activeSurveys,
                                  value: isLoading
                                      ? null
                                      : '${stats?.activeSurveys ?? 0}',
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.timer_rounded,
                                  label: l.todayClocking,
                                  value: isLoading
                                      ? null
                                      : '${stats?.todayClocking ?? 0}',
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.calendar_month_rounded,
                                  label: l.myShifts,
                                  value: isLoading
                                      ? null
                                      : '${stats?.todayShifts ?? 0}',
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),

                  // ═══════════════════════════════
                  // Pending notifications
                  // ═══════════════════════════════
                  Showcase(
                    key: _notificationsKey,
                    title: _isItalian(context)
                        ? 'Notifiche in attesa'
                        : 'Pending notifications',
                    description: _isItalian(context)
                        ? 'Qui trovi inviti, richieste e notifiche che aspettano ancora una tua azione.'
                        : 'This section contains invites, requests, and notifications that still need your attention.',
                    child: const PendingNotificationsCard(maxItems: 5),
                  ),
                  const SizedBox(height: 24),

                  // ═══════════════════════════════
                  // Quick actions + Recent activity
                  // ═══════════════════════════════
                  isNarrow
                      ? Column(
                          children: [
                            Showcase(
                              key: _quickActionsKey,
                              title: _isItalian(context)
                                  ? 'Azioni rapide'
                                  : 'Quick actions',
                              description: _isItalian(context)
                                  ? 'Usa questi collegamenti per entrare subito nelle aree principali e iniziare un\'azione.'
                                  : 'Use these shortcuts to jump directly into the main areas and start an action quickly.',
                              child: _QuickActionsCard(),
                            ),
                            const SizedBox(height: 16),
                            Showcase(
                              key: _activityKey,
                              title: _isItalian(context)
                                  ? 'Attività recenti'
                                  : 'Recent activity',
                              description: _isItalian(context)
                                  ? 'Questa lista ti aiuta a seguire cosa è successo di recente tra team, turni, timbrature e sondaggi.'
                                  : 'This list helps you follow what happened recently across teams, shifts, clocking, and surveys.',
                              child: _RecentActivityCard(
                                activities: activities,
                                isLoading: isLoading,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Showcase(
                                key: _quickActionsKey,
                                title: _isItalian(context)
                                    ? 'Azioni rapide'
                                    : 'Quick actions',
                                description: _isItalian(context)
                                    ? 'Usa questi collegamenti per entrare subito nelle aree principali e iniziare un\'azione.'
                                    : 'Use these shortcuts to jump directly into the main areas and start an action quickly.',
                                child: _QuickActionsCard(),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 3,
                              child: Showcase(
                                key: _activityKey,
                                title: _isItalian(context)
                                    ? 'Attività recenti'
                                    : 'Recent activity',
                                description: _isItalian(context)
                                    ? 'Questa lista ti aiuta a seguire cosa è successo di recente tra team, turni, timbrature e sondaggi.'
                                    : 'This list helps you follow what happened recently across teams, shifts, clocking, and surveys.',
                                child: _RecentActivityCard(
                                  activities: activities,
                                  isLoading: isLoading,
                                ),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _scheduleTutorial() {
    if (_tutorialScheduled) {
      return;
    }
    _tutorialScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await AppTutorialController.showIfNeeded(
        context: context,
        tutorialId: 'web-home',
        userId: context.read<AuthBloc>().state.user.uid,
        keys: <GlobalKey>[
          _bannerKey,
          _statsKey,
          _notificationsKey,
          _quickActionsKey,
          _activityKey,
        ],
      );
    });
  }

  bool _isItalian(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'it';
  }
}

// ════════════════════════════════════════════════════════════════
//  WELCOME BANNER
// ════════════════════════════════════════════════════════════════

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({this.isNarrow = false});
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.withValues(alpha: 0.12),
            Colors.blue.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l.welcomeBack} 👋',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.dashboardSubtitle,
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[500],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (!isNarrow) ...[
            const SizedBox(width: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/astronaut.png',
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    size: 48,
                    color: Colors.indigo,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  STAT CARD
// ════════════════════════════════════════════════════════════════

class _StatCard extends StatefulWidget {
  const _StatCard({
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
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(20),
        transform: _hovering
            ? (Matrix4.identity()..translateByDouble(0, -2, 0, 0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: colorScheme.bgNavbarSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovering
                ? widget.color.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: _hovering
                  ? widget.color.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _hovering ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: widget.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widget.value == null
                      ? const SizedBox(
                          height: 28,
                          width: 28,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.value!,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.textColor,
                          ),
                        ),
                  const SizedBox(height: 2),
                  Text(
                    widget.label,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  QUICK ACTIONS
// ════════════════════════════════════════════════════════════════

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;
    final navBloc = context.read<NavigationBloc>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.bgNavbarSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
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
              Icon(Icons.flash_on_rounded, size: 20, color: Colors.amber[700]),
              const SizedBox(width: 8),
              Text(
                l.quickActions,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ActionTile(
            icon: Icons.group_add_rounded,
            label: l.team,
            subtitle: l.createNewTeam,
            color: Colors.indigo,
            onTap: () => navBloc.add(NavigationPositionChanged(1)),
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.timer_rounded,
            label: l.clockingInOut,
            subtitle: l.personalStatusClockingActions,
            color: Colors.blue,
            onTap: () => navBloc.add(NavigationPositionChanged(3)),
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.checklist_rounded,
            label: l.sondage,
            subtitle: l.create,
            color: Colors.orange,
            onTap: () => navBloc.add(NavigationPositionChanged(4)),
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.calendar_month_rounded,
            label: l.myShifts,
            subtitle: l.shiftCalendar,
            color: Colors.purple,
            onTap: () => navBloc.add(NavigationPositionChanged(5)),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatefulWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _hovering
                ? widget.color.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovering
                  ? widget.color.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, size: 18, color: widget.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.textColor,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  RECENT ACTIVITY
// ════════════════════════════════════════════════════════════════

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.bgNavbarSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
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
              Icon(Icons.history_rounded, size: 20, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                l.recentActivity,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                  style: textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                ),
              ),
            )
          else
            ...activities.map((a) {
              final icon = _iconFor(a.type);
              final color = _colorFor(a.type);
              final time = _formatTime(a.timestamp);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 16, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.title,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            a.subtitle,
                            style: textTheme.bodySmall?.copyWith(
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
            }),
        ],
      ),
    );
  }
}
