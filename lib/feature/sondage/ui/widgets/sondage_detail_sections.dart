import 'package:flutter/material.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class SondageStatusChip extends StatelessWidget {
  const SondageStatusChip({super.key, required this.status});

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

class SondageDetailCard extends StatelessWidget {
  const SondageDetailCard({
    super.key,
    required this.colorScheme,
    required this.sondageColor,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final ColorScheme colorScheme;
  final Color sondageColor;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
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

class SondageLabelValue extends StatelessWidget {
  const SondageLabelValue({
    super.key,
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

class SondageDetailInfoSection extends StatelessWidget {
  const SondageDetailInfoSection({
    super.key,
    required this.sondage,
    required this.formatDate,
    required this.colorScheme,
    required this.textTheme,
  });

  final SondageEntity sondage;
  final String Function(DateTime value) formatDate;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final detailText = sondage.description?.isNotEmpty == true
        ? sondage.description!
        : sondage.focus;

    return SondageDetailCard(
      colorScheme: colorScheme,
      sondageColor: sondage.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SondageLabelValue(
            label: localization.focus,
            value: detailText,
            icon: Icons.description_outlined,
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          const Divider(height: 24),
          SondageLabelValue(
            label: 'Team',
            value: sondage.teamName ?? '-',
            icon: Icons.groups_outlined,
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          const Divider(height: 24),
          SondageLabelValue(
            label: localization.responses,
            value: '${sondage.responses}',
            icon: Icons.people_outline,
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          const Divider(height: 24),
          SondageLabelValue(
            label: localization.createdDate,
            value: formatDate(sondage.createdDate),
            icon: Icons.calendar_today_outlined,
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          if (sondage.expiryDate != null) ...[
            const Divider(height: 24),
            SondageLabelValue(
              label: localization.expiryDate,
              value: formatDate(sondage.expiryDate!),
              icon: Icons.event_outlined,
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
          ],
        ],
      ),
    );
  }
}

class SondageDetailProgressSection extends StatelessWidget {
  const SondageDetailProgressSection({
    super.key,
    required this.sondage,
    required this.teamMemberCount,
    required this.colorScheme,
    required this.textTheme,
  });

  final SondageEntity sondage;
  final int? teamMemberCount;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final progressValue = teamMemberCount != null && teamMemberCount! > 0
        ? (sondage.responses / teamMemberCount!).clamp(0.0, 1.0)
        : 0.0;
    final progressLabel = teamMemberCount != null && teamMemberCount! > 0
        ? '${sondage.responses} / $teamMemberCount ${localization.responses}'
        : '${sondage.responses} ${localization.responses}';

    return SondageDetailCard(
      colorScheme: colorScheme,
      sondageColor: sondage.color,
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
              valueColor: AlwaysStoppedAnimation<Color>(sondage.color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progressLabel,
            style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class SondageVoteSection extends StatelessWidget {
  const SondageVoteSection({
    super.key,
    required this.sondage,
    required this.onVote,
    required this.colorScheme,
    required this.textTheme,
    this.compactPadding = const EdgeInsets.all(16),
    this.pendingOptionIds = const <String>{},
  });

  final SondageEntity sondage;
  final ValueChanged<String> onVote;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final EdgeInsetsGeometry compactPadding;
  final Set<String> pendingOptionIds;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return SondageDetailCard(
      colorScheme: colorScheme,
      sondageColor: sondage.color,
      padding: compactPadding,
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
              style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            )
          else
            ...sondage.options.map((option) {
              final isSelected = sondage.allowMultipleResponses
                  ? sondage.currentUserOptionIds.contains(option.id)
                  : sondage.currentUserOptionId == option.id;
              final isOptionPending = pendingOptionIds.contains(option.id);
              final hasPendingVote = pendingOptionIds.isNotEmpty;
              final totalVotes = sondage.totalVotes > 0
                  ? sondage.totalVotes
                  : 1;
              final votePercent = (option.voteCount / totalVotes).clamp(
                0.0,
                1.0,
              );
              final canTapOption = sondage.allowMultipleResponses
                  ? sondage.canVote && !hasPendingVote
                  : sondage.canVote && !hasPendingVote && !isSelected;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: canTapOption ? () => onVote(option.id) : null,
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? sondage.color.withValues(alpha: 0.15)
                          : colorScheme.homeSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? sondage.color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: sondage.color.withValues(
                                alpha: 0.2,
                              ),
                              child: Text(
                                '${option.sortOrder + 1}',
                                style: TextStyle(
                                  color: sondage.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                option.label,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.iconLabel,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isOptionPending)
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: sondage.color,
                                ),
                              )
                            else if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: sondage.color,
                                size: 20,
                              ),
                            const SizedBox(width: 8),
                            Text(
                              localization.votes(option.voteCount),
                              style: textTheme.bodySmall?.copyWith(
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              sondage.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          if (!sondage.canVote && sondage.status == SondageStatus.active)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                (((sondage.currentUserOptionId ?? '').trim().isNotEmpty) ||
                        sondage.currentUserOptionIds.isNotEmpty)
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
    );
  }
}

class SondageOwnerActionsSection extends StatelessWidget {
  const SondageOwnerActionsSection({
    super.key,
    required this.sondage,
    required this.onPublish,
    required this.onClose,
    this.onReopen,
    this.onDelete,
    this.onRemind,
  });

  final SondageEntity sondage;
  final VoidCallback onPublish;
  final VoidCallback onClose;
  final VoidCallback? onReopen;
  final VoidCallback? onDelete;
  final VoidCallback? onRemind;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme= Theme.of(context);
    final colorScheme= theme.colorScheme;

    if (!sondage.canPublish &&
        !sondage.canClose &&
        !sondage.canReopen &&
        !sondage.canDelete &&
        onRemind == null) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (sondage.canPublish)
          FilledButton.icon(
            onPressed: onPublish,
            icon: const Icon(Icons.publish_rounded),
            label: Text(localization.publish,
              ),style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.bgNavbarbutton,
          )
          ),
        if (sondage.canClose)
          FilledButton.tonalIcon(
            onPressed: onClose,
            icon: const Icon(Icons.lock_clock_rounded),
            label: Text(localization.closeSurvey),
          ),
        if (sondage.canReopen && onReopen != null)
          FilledButton.tonalIcon(
            onPressed: onReopen,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(_reopenLabel(context)),
          ),
        if (onRemind != null)
          FilledButton.tonalIcon(
            onPressed: onRemind,
            icon: const Icon(Icons.notifications_active_rounded),
            label: Text(_remindLabel(context)),
          ),
        if (sondage.canDelete && onDelete != null)
          FilledButton.tonalIcon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(_deleteLabel(context)),
          ),
      ],
    );
  }

  String _remindLabel(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'it' => 'Sollecita voto',
      'fr' => 'Relancer le vote',
      'es' => 'Recordar voto',
      _ => 'Remind to vote',
    };
  }

  String _deleteLabel(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'it' => 'Elimina sondaggio',
      'fr' => 'Supprimer le sondage',
      'es' => 'Eliminar encuesta',
      _ => 'Delete survey',
    };
  }

  String _reopenLabel(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'it' => 'Riapri sondaggio',
      'fr' => 'Rouvrir le sondage',
      'es' => 'Reabrir encuesta',
      _ => 'Reopen survey',
    };
  }
}
