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
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class SondageDetailWeb extends StatefulWidget {
  const SondageDetailWeb({super.key, required this.sondageId});
  final String sondageId;

  @override
  State<SondageDetailWeb> createState() => _SondageDetailWebState();
}

class _SondageDetailWebState extends State<SondageDetailWeb> {
  late final SondageBloc _bloc;
  StreamSubscription<RealtimeNotification>? _subscription;
  SondageEntity? _lastSondage;

  @override
  void initState() {
    super.initState();
    _bloc = SondageBloc(
      sondageUseCase: getIt<SondageUseCase>(),
      sondageLocalDataSource: getIt(),
    )
      ..add(LoadSondageByIdEvent(widget.sondageId));
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final localization = AppLocalizations.of(context)!;

    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<SondageBloc, SondageState>(
        listenWhen: (_, state) => state is SondageError,
        listener: (context, state) {
          if (state is SondageError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
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

          final sondageColor = sondage.color;
          final detailText = sondage.description?.isNotEmpty == true
              ? sondage.description!
              : sondage.focus;

          return Scaffold(
            backgroundColor: colorScheme.homePrimary,
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isRefreshing)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.bgNavbarSurface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => context.go(RouterPaths.sondage),
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: colorScheme.iconLabel,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sondage.name,
                                    style: textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.iconLabel,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    sondage.teamName ?? '-',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _StatusChip(status: sondage.status.name),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 900;
                          final children = [
                            _DetailCard(
                              colorScheme: colorScheme,
                              sondageColor: sondageColor,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _LabelValue(
                                    label: localization.focus,
                                    value: detailText,
                                    icon: Icons.description_outlined,
                                    textTheme: textTheme,
                                    colorScheme: colorScheme,
                                  ),
                                  const Divider(height: 24),
                                  _LabelValue(
                                    label: 'Team',
                                    value: sondage.teamName ?? '-',
                                    icon: Icons.groups_outlined,
                                    textTheme: textTheme,
                                    colorScheme: colorScheme,
                                  ),
                                  const Divider(height: 24),
                                  _LabelValue(
                                    label: localization.responses,
                                    value: '${sondage.responses}',
                                    icon: Icons.people_outline,
                                    textTheme: textTheme,
                                    colorScheme: colorScheme,
                                  ),
                                  const Divider(height: 24),
                                  _LabelValue(
                                    label: localization.createdDate,
                                    value: _formatDate(sondage.createdDate),
                                    icon: Icons.calendar_today_outlined,
                                    textTheme: textTheme,
                                    colorScheme: colorScheme,
                                  ),
                                  if (sondage.expiryDate != null) ...[
                                    const Divider(height: 24),
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
                                      value: sondage.options.isNotEmpty
                                          ? (sondage.responses /
                                                (sondage.options.length * 10))
                                              .clamp(0.0, 1.0)
                                          : 0,
                                      minHeight: 10,
                                      backgroundColor: Colors.grey[300],
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                            sondageColor,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${sondage.responses} ${localization.responses}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                                      final totalVotes =
                                          sondage.responses > 0
                                          ? sondage.responses
                                          : 1;
                                      final votePercent = (option.voteCount /
                                              totalVotes)
                                          .clamp(0.0, 1.0);

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: InkWell(
                                          onTap: sondage.canVote
                                              ? () => _bloc.add(
                                                  VoteSondageEvent(
                                                    sondage.id,
                                                    option.id,
                                                  ),
                                                )
                                              : null,
                                          borderRadius: BorderRadius.circular(10),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? sondageColor.withValues(
                                                      alpha: 0.15,
                                                    )
                                                  : colorScheme.homeSecondary,
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                                      backgroundColor:
                                                          sondageColor
                                                              .withValues(
                                                                alpha: 0.2,
                                                              ),
                                                      child: Text(
                                                        '${option.sortOrder + 1}',
                                                        style: TextStyle(
                                                          color: sondageColor,
                                                          fontWeight:
                                                              FontWeight.bold,
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
                                                              color: colorScheme
                                                                  .iconLabel,
                                                              fontWeight: isSelected
                                                                  ? FontWeight
                                                                        .bold
                                                                  : FontWeight
                                                                        .normal,
                                                            ),
                                                      ),
                                                    ),
                                                    if (isSelected)
                                                      Icon(
                                                        Icons
                                                            .check_circle_rounded,
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
                                                            color:
                                                                Colors.grey[600],
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child: LinearProgressIndicator(
                                                    value: votePercent,
                                                    minHeight: 6,
                                                    backgroundColor:
                                                        Colors.grey[200],
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(sondageColor),
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
                            if (sondage.canPublish || sondage.canClose)
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  if (sondage.canPublish)
                                    FilledButton.icon(
                                      onPressed: () => _bloc.add(
                                        PublishSondageEvent(sondage.id),
                                      ),
                                      icon: const Icon(
                                        Icons.publish_rounded,
                                      ),
                                      label: Text(localization.publish),
                                    ),
                                  if (sondage.canClose)
                                    FilledButton.tonalIcon(
                                      onPressed: () => _bloc.add(
                                        CloseSondageEvent(sondage.id),
                                      ),
                                      icon: const Icon(
                                        Icons.lock_clock_rounded,
                                      ),
                                      label: Text(localization.closeSurvey),
                                    ),
                                ],
                              ),
                          ];

                          if (isCompact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final child in children) ...[
                                  child,
                                  const SizedBox(height: 18),
                                ],
                              ],
                            );
                          }

                          return Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: children[0]),
                                  const SizedBox(width: 20),
                                  Expanded(child: children[1]),
                                ],
                              ),
                              const SizedBox(height: 20),
                              children[2],
                              if (children.length > 3) ...[
                                const SizedBox(height: 20),
                                children[3],
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}

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
      padding: const EdgeInsets.all(18),
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
