import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_cubit.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_item.dart';
import 'package:note_sondage/feature/notification/navigation/notification_navigation.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class PendingNotificationsCard extends StatefulWidget {
  const PendingNotificationsCard({
    super.key,
    this.maxItems = 4,
  });

  final int maxItems;

  @override
  State<PendingNotificationsCard> createState() => _PendingNotificationsCardState();
}

class _PendingNotificationsCardState extends State<PendingNotificationsCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationCenterCubit>().loadNotifications(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user.uid,
    );

    return BlocBuilder<NotificationCenterCubit, NotificationCenterState>(
      builder: (context, state) {
        final pending = state.pendingFor(currentUserId);
        final visibleItems = pending.take(widget.maxItems).toList();
        final hiddenCount = pending.length - visibleItems.length;
        final isLoading =
            (state.status == NotificationCenterStatus.initial ||
                state.status == NotificationCenterStatus.loading) &&
            state.notifications.isEmpty;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.bgNavbarSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.selectItem!.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      color: colorScheme.selectItem,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifiche da gestire',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pending.isEmpty
                              ? 'Non hai nulla in sospeso.'
                              : 'Qui trovi quelle non ancora viste o senza risposta.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.descriptionColor,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (pending.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${pending.length}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (visibleItems.isEmpty)
                _EmptyPendingNotifications(colorScheme: colorScheme)
              else ...[
                for (final item in visibleItems) ...[
                  _PendingNotificationTile(item: item),
                  if (item != visibleItems.last) const SizedBox(height: 12),
                ],
                if (hiddenCount > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    '+$hiddenCount altre notifiche restano disponibili nel centro notifiche.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.descriptionColor,
                    ),
                  ),
                ],
              ],
              if (state.errorMessage != null &&
                  state.errorMessage!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Impossibile aggiornare le notifiche in questo momento.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context
                          .read<NotificationCenterCubit>()
                          .loadNotifications(force: true),
                      child: const Text('Riprova'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EmptyPendingNotifications extends StatelessWidget {
  const _EmptyPendingNotifications({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.homeSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hai gia visto tutto oppure hai gia risposto agli inviti in sospeso.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.textColor,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingNotificationTile extends StatelessWidget {
  const _PendingNotificationTile({required this.item});

  final NotificationCenterItem item;

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user.uid,
    );
    final state = context.watch<NotificationCenterCubit>().state;
    final canRespond =
        item.supportsInviteDecisionFor(currentUserId) &&
        !state.completedActionNotificationIds.contains(item.notificationId);
    final isProcessing = state.processingNotificationIds.contains(
      item.notificationId,
    );
    final isSeen = state.seenNotificationIds.contains(item.notificationId);
    final navigationLabel = canRespond ? null : _navigationLabelFor(item);
    final teamName = item.teamName;
    final roleCode = item.roleCode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: canRespond ? null : () => _handleOpen(context),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.homeSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSeen
                  ? Colors.grey.withValues(alpha: 0.1)
                  : colorScheme.selectItem!.withValues(alpha: 0.28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title.isEmpty ? item.eventType : item.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.textColor,
                          ),
                        ),
                        if (item.body.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            item.body,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.textColor,
                              height: 1.35,
                            ),
                          ),
                        ],
                        if (teamName != null || roleCode != null) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (teamName != null)
                                _DetailChip(
                                  label: 'Team: $teamName',
                                  color: colorScheme.selectItem!,
                                ),
                              if (roleCode != null)
                                _DetailChip(
                                  label: 'Ruolo: ${_formatRole(roleCode)}',
                                  color: const Color(0xFF1B8C4A),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSeen
                          ? Colors.grey.withValues(alpha: 0.12)
                          : colorScheme.selectItem!.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isSeen ? 'Vista' : 'Nuova',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSeen
                            ? colorScheme.descriptionColor
                            : colorScheme.selectItem,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    _leadingIconFor(item),
                    size: 16,
                    color: colorScheme.descriptionColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _formatDate(context, item.occurredAt),
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
                      onPressed: isProcessing
                          ? null
                          : () => context
                                .read<NotificationCenterCubit>()
                                .rejectInvitation(item),
                      child: const Text('Rifiuta'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: isProcessing
                          ? null
                          : () => context
                                .read<NotificationCenterCubit>()
                                .acceptInvitation(item),
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
              ] else if (!isSeen) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => context
                        .read<NotificationCenterCubit>()
                        .markAsSeen(item.notificationId),
                    child: const Text('Segna come vista'),
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
    await NotificationNavigation.open(item, context: context);
  }

  static IconData _leadingIconFor(NotificationCenterItem item) {
    if (item.eventType.startsWith('TEAM_')) {
      return Icons.group_outlined;
    }
    if (item.eventType.contains('CLOCK')) {
      return Icons.timer_outlined;
    }
    if (item.eventType.contains('SURVEY') || item.eventType.contains('SONDAGE')) {
      return Icons.checklist_rtl_outlined;
    }
    return Icons.notifications_none_rounded;
  }

  static String? _navigationLabelFor(NotificationCenterItem item) {
    return NotificationNavigation.labelFor(item);
  }

  static String _formatDate(BuildContext context, DateTime value) {
    final localValue = value.toLocal();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();

    if (localValue.year == now.year) {
      return DateFormat('dd MMM, HH:mm', locale).format(localValue);
    }

    return DateFormat('dd MMM yyyy, HH:mm', locale).format(localValue);
  }

  static String _formatRole(String roleCode) {
    switch (roleCode.toUpperCase()) {
      case 'OWNER':
        return 'Owner';
      case 'ADMIN':
        return 'Admin';
      case 'VIEWER':
        return 'Viewer';
      case 'MEMBER':
      default:
        return 'Member';
    }
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
