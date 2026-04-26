import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_cubit.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_item.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class NotificationCenterButton extends StatelessWidget {
  const NotificationCenterButton({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user.uid,
    );

    return BlocBuilder<NotificationCenterCubit, NotificationCenterState>(
      builder: (context, state) {
        final count = state.pendingFor(currentUserId).length;
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
    cubit.markManyAsSeen(
      cubit.state.notifications.map((item) => item.notificationId),
    );
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
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (state.status == NotificationCenterStatus.loading &&
                      state.notifications.isEmpty)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.notifications.isEmpty)
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
                        itemCount: state.notifications.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = state.notifications[index];
                          final isProcessing = state.processingNotificationIds
                              .contains(item.notificationId);
                          final isCompleted = state.completedActionNotificationIds
                              .contains(item.notificationId);
                          final canRespond =
                              !isCompleted &&
                              item.supportsInviteDecisionFor(currentUserId);

                          return _NotificationCard(
                            item: item,
                            isProcessing: isProcessing,
                            canRespond: canRespond,
                            onAccept: () => context
                                .read<NotificationCenterCubit>()
                                .acceptInvitation(item),
                            onReject: () => context
                                .read<NotificationCenterCubit>()
                                .rejectInvitation(item),
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
    return Container(
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
          if (item.body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.body, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 10),
          Text(
            item.occurredAt.toLocal().toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.descriptionColor,
            ),
          ),
          if (canRespond) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                OutlinedButton(
                  onPressed: isProcessing ? null : onReject,
                  child: const Text('Rifiuta'),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: isProcessing ? null : onAccept,
                  child: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Accetta'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
