import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_cubit.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_item.dart';
import 'package:note_sondage/feature/notification/navigation/notification_navigation.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_replacement_reject_reason_dialog.dart';
import 'package:note_sondage/feature/team/ui/bloc/team/team_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

const int _maxWebNotificationCenterItems = 10;

class NotificationCenterButton extends StatelessWidget {
  const NotificationCenterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCenterCubit, NotificationCenterState>(
      builder: (context, state) {
        final visibleNotifications = _visibleNotifications(state.notifications);
        final count = _visiblePendingCount(state, visibleNotifications);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _showNotificationCenter(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.bgNavbarSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Icon(Icons.notifications_none_rounded, size: 22),
                ),
              ),
            ),
            if (count > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showNotificationCenter(BuildContext context) async {
    final cubit = context.read<NotificationCenterCubit>();
    await cubit.loadNotifications(force: true);
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => const _NotificationCenterDialog(),
    );
  }
}

class _NotificationCenterDialog extends StatelessWidget {
  const _NotificationCenterDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUserId = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user.uid,
    );

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 720),
        decoration: BoxDecoration(
          color: colorScheme.homePrimary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: BlocBuilder<NotificationCenterCubit, NotificationCenterState>(
          builder: (context, state) {
            final visibleNotifications = _visibleNotifications(
              state.notifications,
            );
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Notification center',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: state.notifications.isEmpty
                            ? null
                            : () => context
                                  .read<NotificationCenterCubit>()
                                  .closeNotifications(
                                    state.notifications,
                                    currentUserId: currentUserId,
                                  ),
                        icon: const Icon(Icons.done_all_rounded, size: 18),
                        label: Text(AppLocalizations.of(context)!.close),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (state.status == NotificationCenterStatus.loading &&
                      visibleNotifications.isEmpty)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (visibleNotifications.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          'No notifications yet.',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: visibleNotifications.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = visibleNotifications[index];
                          final isProcessing = state.processingNotificationIds
                              .contains(item.notificationId);
                          final isCompleted = state
                              .completedActionNotificationIds
                              .contains(item.notificationId);
                          final canRespond =
                              !isCompleted &&
                              (item.supportsInviteDecisionFor(currentUserId) ||
                                  item.supportsClockingDecision() ||
                                  item.supportsReplacementOfferDecision());

                          return _NotificationCard(
                            item: item,
                            isProcessing: isProcessing,
                            canRespond: canRespond,
                            onAccept: () =>
                                item.supportsReplacementOfferDecision()
                                ? context
                                      .read<NotificationCenterCubit>()
                                      .acceptReplacementOffer(item)
                                : item.supportsClockingDecision()
                                ? context
                                      .read<NotificationCenterCubit>()
                                      .approveClockingDecision(item)
                                : context
                                      .read<NotificationCenterCubit>()
                                      .acceptInvitation(item),
                            onReject: () async {
                              if (item.supportsReplacementOfferDecision()) {
                                final reason =
                                    await showShiftReplacementRejectReasonDialog(
                                      context: context,
                                    );
                                if (reason == null ||
                                    reason.isEmpty ||
                                    !context.mounted) {
                                  return;
                                }
                                context
                                    .read<NotificationCenterCubit>()
                                    .rejectReplacementOffer(item, reason);
                                return;
                              }
                              if (item.supportsClockingDecision()) {
                                context
                                    .read<NotificationCenterCubit>()
                                    .rejectClockingDecision(item);
                                return;
                              }
                              context
                                  .read<NotificationCenterCubit>()
                                  .rejectInvitation(item);
                            },
                          );
                        },
                      ),
                    ),
                  if (state.errorMessage != null &&
                      state.errorMessage!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        state.errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

List<NotificationCenterItem> _visibleNotifications(
  List<NotificationCenterItem> notifications,
) {
  if (notifications.length <= _maxWebNotificationCenterItems) {
    return notifications;
  }

  return notifications.take(_maxWebNotificationCenterItems).toList();
}

int _visiblePendingCount(
  NotificationCenterState state,
  List<NotificationCenterItem> visibleNotifications,
) {
  return visibleNotifications.where((item) {
    if (state.dismissedNotificationIds.contains(item.notificationId)) {
      return false;
    }
    final seen = state.seenNotificationIds.contains(item.notificationId);
    final completed = state.completedActionNotificationIds.contains(
      item.notificationId,
    );
    return !seen && !completed;
  }).length;
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.isProcessing,
    required this.canRespond,
    required this.onAccept,
    required this.onReject,
  });

  final NotificationCenterItem item;
  final bool isProcessing;
  final bool canRespond;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localization = AppLocalizations.of(context)!;
    final navigationLabel = canRespond
        ? null
        : NotificationNavigation.labelFor(item);
    final actionRequestNote = item.actionRequestNote;
    final teamName = _resolveDisplayTeamName(item);
    final impactedShiftSummaries = item.impactedShiftSummaries;
    final impactedTaskSummaries = item.impactedTaskSummaries;
    final impactedEventSummaries = item.impactedEventSummaries;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: canRespond ? null : () => _handleOpen(context),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.homeSecondary,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title.isEmpty ? item.eventType : item.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (item.bodyWithTeamContext.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  item.bodyWithTeamContext,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (teamName != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.selectItem!.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Team: $teamName',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.selectItem,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              if (actionRequestNote != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.selectItem!.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localization.note,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.selectItem,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        actionRequestNote,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
              if (impactedShiftSummaries.isNotEmpty) ...[
                const SizedBox(height: 10),
                _ImpactedItemsSection(
                  title: _impactedShiftTitle(context),
                  icon: Icons.event_busy_rounded,
                  summaries: impactedShiftSummaries,
                  textTheme: theme.textTheme,
                ),
              ],
              if (impactedTaskSummaries.isNotEmpty) ...[
                const SizedBox(height: 10),
                _ImpactedItemsSection(
                  title: _impactedTaskTitle(context),
                  icon: Icons.task_alt_rounded,
                  summaries: impactedTaskSummaries,
                  textTheme: theme.textTheme,
                ),
              ],
              if (impactedEventSummaries.isNotEmpty) ...[
                const SizedBox(height: 10),
                _ImpactedItemsSection(
                  title: _impactedEventTitle(context),
                  icon: Icons.event_rounded,
                  summaries: impactedEventSummaries,
                  textTheme: theme.textTheme,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.occurredAt.toLocal().toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.descriptionColor,
                      ),
                    ),
                  ),
                  if (navigationLabel != null)
                    Text(
                      navigationLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.selectItem,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              if (canRespond) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: isProcessing ? null : onReject,
                      child: Text(localization.rejectRequest),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: isProcessing ? null : onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.bgNavbarbutton,
                      ),
                      child: isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(localization.approveRequest),
                    ),
                  ],
                ),
              ] else if (navigationLabel != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _handleOpen(context),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(navigationLabel),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleOpen(BuildContext context) async {
    context.read<NotificationCenterCubit>().markAsSeen(item.notificationId);
    await NotificationNavigation.open(
      item,
      context: context,
      closeOverlays: true,
    );
  }

  String _impactedShiftTitle(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'it' => 'Turni impattati',
      'fr' => 'Quarts impactes',
      'es' => 'Turnos afectados',
      _ => 'Impacted shifts',
    };
  }

  String _impactedTaskTitle(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'it' => 'Task impattati',
      'fr' => 'Taches impactees',
      'es' => 'Tareas afectadas',
      _ => 'Impacted tasks',
    };
  }

  String _impactedEventTitle(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'it' => 'Eventi impattati',
      'fr' => 'Evenements impactes',
      'es' => 'Eventos afectados',
      _ => 'Impacted events',
    };
  }
}

class _ImpactedItemsSection extends StatelessWidget {
  const _ImpactedItemsSection({
    required this.title,
    required this.icon,
    required this.summaries,
    required this.textTheme,
  });

  final String title;
  final IconData icon;
  final List<String> summaries;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.labelMedium?.copyWith(
              color: const Color(0xFFB45309),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          for (final summary in summaries)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(icon, size: 14, color: const Color(0xFFB45309)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      summary,
                      style: textTheme.bodySmall?.copyWith(
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String? _resolveDisplayTeamName(NotificationCenterItem item) {
  final directTeamName = item.teamName;
  if (directTeamName != null) {
    return directTeamName;
  }

  final teamId = item.metadata['teamId']?.trim();
  if (teamId == null || teamId.isEmpty) {
    return null;
  }

  final state = getIt<TeamBloc>().state;
  if (state is TeamsLoaded) {
    for (final team in state.teams) {
      final candidateId = team.id?.trim();
      final candidateName = team.name.trim();
      if (candidateId == teamId && candidateName.isNotEmpty) {
        return candidateName;
      }
    }
  } else if (state is TeamLoaded) {
    final candidateId = state.team.id?.trim();
    final candidateName = state.team.name.trim();
    if (candidateId == teamId && candidateName.isNotEmpty) {
      return candidateName;
    }
  }

  return null;
}
