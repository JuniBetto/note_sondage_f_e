import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_model.dart';
import 'package:note_sondage/feature/notification/realtime/realtime_notification_service.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/domain/use_case/sondage_use_case.dart';
import 'package:note_sondage/feature/sondage/ui/bloc/sondage_bloc.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';

class SondageDetailMobile extends StatefulWidget {
  const SondageDetailMobile({super.key, required this.sondageId});
  final String sondageId;

  @override
  State<SondageDetailMobile> createState() => _SondageDetailMobileState();
}

class _SondageDetailMobileState extends State<SondageDetailMobile> {
  late final SondageBloc _bloc;
  late final TeamMemberUseCase _teamMemberUseCase;
  StreamSubscription<RealtimeNotification>? _subscription;
  SondageEntity? _lastSondage;
  String? _loadedTeamId;
  int? _teamMemberCount;

  @override
  void initState() {
    super.initState();
    _teamMemberUseCase = getIt<TeamMemberUseCase>();
    _bloc = SondageBloc(
      sondageUseCase: getIt<SondageUseCase>(),
      sondageLocalDataSource: getIt(),
    )..add(LoadSondageByIdEvent(widget.sondageId));
    _subscription = getIt<RealtimeNotificationService>().stream.listen((event) {
      if (!mounted || _bloc.isClosed) return;
      if (event.sourceService == 'sondage-service' &&
          event.metadata['sondageId'] == widget.sondageId) {
        _bloc.add(LoadSondageByIdEvent(widget.sondageId));
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _bloc.close();
    super.dispose();
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  Future<void> _ensureTeamMemberCountLoaded(SondageEntity sondage) async {
    final teamId = sondage.teamId;
    if (teamId == null || teamId.isEmpty || _loadedTeamId == teamId) {
      return;
    }

    _loadedTeamId = teamId;
    try {
      final members = await _teamMemberUseCase.getAllMembersByTeamId(teamId);
      if (!mounted) return;
      setState(() {
        _teamMemberCount = members.length;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _teamMemberCount = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<SondageBloc, SondageState>(
        listenWhen: (_, state) => state is SondageError,
        listener: (context, state) {
          if (state is SondageError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        buildWhen: (_, state) =>
            state is SondageInitial ||
            state is SondageLoading ||
            state is SondageLoaded ||
            state is SondageActionSuccess ||
            state is SondageError,
        builder: (context, state) {
          if (state is SondageLoaded) {
            _lastSondage = state.sondage;
          } else if (state is SondageActionSuccess) {
            _lastSondage = state.sondage;
          }

          final sondage = state is SondageLoaded
              ? state.sondage
              : state is SondageActionSuccess
              ? state.sondage
              : _lastSondage;
          final isRefreshing = state is SondageLoading && sondage != null;

          if ((state is SondageLoading || state is SondageInitial) &&
              sondage == null) {
            return Scaffold(
              backgroundColor: colorScheme.homePrimary,
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          if (state is SondageError && sondage == null) {
            return Scaffold(
              backgroundColor: colorScheme.homePrimary,
              body: Center(child: Text(localization.surveyNotFound)),
            );
          }

          if (sondage == null) {
            return Scaffold(
              backgroundColor: colorScheme.homePrimary,
              body: Center(child: Text(localization.surveyNotFound)),
            );
          }

          _ensureTeamMemberCountLoaded(sondage);

          final sondageColor = sondage.color;
          final teamMemberCount = _teamMemberCount;
          final progressValue =
              teamMemberCount != null && teamMemberCount > 0
              ? (sondage.responses / teamMemberCount).clamp(0.0, 1.0)
              : 0.0;
          final progressLabel =
              teamMemberCount != null && teamMemberCount > 0
              ? '${sondage.responses} / $teamMemberCount ${localization.responses}'
              : '${sondage.responses} ${localization.responses}';

          return Scaffold(
            backgroundColor: colorScheme.homePrimary,
            appBar: AppBar(
              backgroundColor: colorScheme.bgNavbarSurface,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: colorScheme.iconLabel,
                ),
                onPressed: () {
                  context.read<NavigationBloc>().add(
                    NavigationPositionChanged(4),
                  );
                  context.go(RouterPaths.home);
                },
              ),
              title: Text(
                sondage.name,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.iconLabel,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                _StatusChip(status: sondage.status.name),
                const SizedBox(width: 12),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isRefreshing)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  // ── Card info ──
                  _DetailCard(
                    colorScheme: colorScheme,
                    sondageColor: sondageColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LabelValue(
                          label: localization.focus,
                          value: sondage.description?.isNotEmpty == true
                              ? sondage.description!
                              : sondage.focus,
                          icon: Icons.description_outlined,
                          textTheme: textTheme,
                          colorScheme: colorScheme,
                        ),
                        const Divider(height: 20),
                        _LabelValue(
                          label: 'Team',
                          value: sondage.teamName ?? '-',
                          icon: Icons.groups_outlined,
                          textTheme: textTheme,
                          colorScheme: colorScheme,
                        ),
                        const Divider(height: 20),
                        _LabelValue(
                          label: localization.responses,
                          value: '${sondage.responses}',
                          icon: Icons.people_outline,
                          textTheme: textTheme,
                          colorScheme: colorScheme,
                        ),
                        const Divider(height: 20),
                        _LabelValue(
                          label: localization.createdDate,
                          value: _formatDate(sondage.createdDate),
                          icon: Icons.calendar_today_outlined,
                          textTheme: textTheme,
                          colorScheme: colorScheme,
                        ),
                        if (sondage.expiryDate != null) ...[
                          const Divider(height: 20),
                          _LabelValue(
                            label: localization.expiryDate,
                            value: _formatDate(sondage.expiryDate!),
                            icon: Icons.event_outlined,
                            textTheme: textTheme,
                            colorScheme: colorScheme,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Progresso ──
                  _DetailCard(
                    colorScheme: colorScheme,
                    sondageColor: sondageColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localization.progress,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.iconLabel,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progressValue,
                            minHeight: 10,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              sondageColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          progressLabel,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Opzioni di voto ──
                  _DetailCard(
                    colorScheme: colorScheme,
                    sondageColor: sondageColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localization.options,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.iconLabel,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (sondage.options.isEmpty)
                          Text(
                            localization.noOptionsAvailable,
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          )
                        else
                          ...sondage.options.map((option) {
                            final isSelected =
                                sondage.currentUserOptionId == option.id;
                            final totalVotes = sondage.responses > 0
                                ? sondage.responses
                                : 1;
                            final votePercent = (option.voteCount / totalVotes)
                                .clamp(0.0, 1.0);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: sondage.canVote
                                    ? () => _bloc.add(
                                        VoteSondageEvent(sondage.id, option.id),
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? sondageColor.withValues(alpha: 0.15)
                                        : colorScheme.homeSecondary,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? sondageColor
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: sondageColor
                                                .withValues(alpha: 0.2),
                                            child: Text(
                                              '${option.sortOrder + 1}',
                                              style: TextStyle(
                                                color: sondageColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              option.label,
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color:
                                                        colorScheme.iconLabel,
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                            ),
                                          ),
                                          if (isSelected)
                                            Icon(
                                              Icons.check_circle_rounded,
                                              color: sondageColor,
                                              size: 20,
                                            ),
                                          const SizedBox(width: 8),
                                          Text(
                                            localization.votes(
                                              option.voteCount,
                                            ),
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey[600],
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: votePercent,
                                          minHeight: 6,
                                          backgroundColor: Colors.grey[200],
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                sondageColor,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        if (!sondage.canVote &&
                            sondage.status == SondageStatus.active)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              sondage.currentUserOptionId != null
                                  ? localization.alreadyVoted
                                  : localization.cannotVote,
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Azioni owner ──
                  if (sondage.canPublish || sondage.canClose)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (sondage.canPublish)
                          FilledButton.icon(
                            onPressed: () =>
                                _bloc.add(PublishSondageEvent(sondage.id)),
                            icon: const Icon(Icons.publish_rounded),
                            label: Text(localization.publish),
                          ),
                        if (sondage.canClose)
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                _bloc.add(CloseSondageEvent(sondage.id)),
                            icon: const Icon(Icons.lock_clock_rounded),
                            label: Text(localization.closeSurvey),
                          ),
                      ],
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Widget privati ──

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.sondageStatusColor(status);
    final l10n = AppLocalizations.of(context)!;
    final label = switch (status.toLowerCase()) {
      'active' => l10n.statusActive,
      'draft' => l10n.statusDraft,
      'closed' => l10n.statusClosed,
      'completed' => l10n.statusCompleted,
      'published' => l10n.statusPublished,
      _ => status.toUpperCase(),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.colorScheme,
    required this.sondageColor,
    required this.child,
  });

  final ColorScheme colorScheme;
  final Color sondageColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.bgNavbarSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: sondageColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({
    required this.label,
    required this.value,
    required this.icon,
    required this.textTheme,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final IconData icon;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.iconLabel,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
