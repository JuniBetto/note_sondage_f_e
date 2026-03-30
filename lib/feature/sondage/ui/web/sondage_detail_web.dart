import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/widgets/sondage_mobile.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';

class SondageDetailWeb extends StatelessWidget {
  const SondageDetailWeb({super.key, required this.sondageId});
  final String sondageId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final localization = AppLocalizations.of(context)!;

    // Cerca il sondaggio nella lista mock
    final sondage = sondagesList.firstWhere(
      (s) => s['sondageId'] == sondageId,
      orElse: () => <String, dynamic>{},
    );

    if (sondage.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Sondage not found',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.iconLabel,
              ),
            ),
            const SizedBox(height: 16),
            CustomAppButton(
              type: ButtonType.outlined,
              isActive: false,
              backgroundColor: colorScheme.bgNavbarSurface,
              elevation: 2,
              onPressed: () => context.go(RouterPaths.sondage),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  '← ${localization.sondage}',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.iconLabel,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final sondageName = sondage['sondageName'] as String;
    final sondageFocus = sondage['sondageFocus'] as String;
    final status = sondage['status'] as String;
    final responses = sondage['responses'] as int;
    final totalQuestions = sondage['totalQuestions'] as int;
    final createdDate = sondage['createdDate'] is String
        ? DateTime.parse(sondage['createdDate'] as String)
        : sondage['createdDate'] as DateTime;
    final expiryDate = sondage['expiryDate'] is String
        ? DateTime.parse(sondage['expiryDate'] as String)
        : sondage['expiryDate'] as DateTime;
    final sondageColor = sondage['color'] as Color;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════
          // TOP BAR: back + titolo + status
          // ═══════════════════════════════════════
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.bgNavbarSurface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Back button
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.go(RouterPaths.sondage),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.homeSecondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: colorScheme.iconLabel,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Colore indicatore
                Container(
                  width: 4,
                  height: 32,
                  decoration: BoxDecoration(
                    color: sondageColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sondageName,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.iconLabel,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sondageFocus,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _StatusBadge(status: status),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ═══════════════════════════════════════
          // CORPO — Layout a due colonne
          // ═══════════════════════════════════════
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;

                if (isWide) {
                  // ── Desktop: due colonne ──
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Colonna sinistra — Info + Statistiche
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // Stats cards orizzontali
                              _StatsRow(
                                responses: responses,
                                totalQuestions: totalQuestions,
                                sondageColor: sondageColor,
                                colorScheme: colorScheme,
                                textTheme: textTheme,
                                localization: localization,
                              ),
                              const SizedBox(height: 20),
                              // Info dettagliate
                              _InfoCard(
                                colorScheme: colorScheme,
                                textTheme: textTheme,
                                sondageColor: sondageColor,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 22,
                                        color: sondageColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Dettagli',
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.iconLabel,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _InfoRow(
                                    icon: Icons.description_outlined,
                                    label: 'Focus',
                                    value: sondageFocus,
                                    textTheme: textTheme,
                                    colorScheme: colorScheme,
                                  ),
                                  const Divider(height: 24),
                                  _InfoRow(
                                    icon: Icons.calendar_today_outlined,
                                    label: localization.createdDate,
                                    value: _formatDate(createdDate),
                                    textTheme: textTheme,
                                    colorScheme: colorScheme,
                                  ),
                                  const Divider(height: 24),
                                  _InfoRow(
                                    icon: Icons.event_outlined,
                                    label: localization.expiryDate,
                                    value: _formatDate(expiryDate),
                                    textTheme: textTheme,
                                    colorScheme: colorScheme,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Progresso
                              _ProgressCard(
                                responses: responses,
                                totalQuestions: totalQuestions,
                                sondageColor: sondageColor,
                                colorScheme: colorScheme,
                                textTheme: textTheme,
                                localization: localization,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Colonna destra — Domande
                      Expanded(
                        flex: 5,
                        child: _QuestionsCard(
                          totalQuestions: totalQuestions,
                          sondageColor: sondageColor,
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                          localization: localization,
                        ),
                      ),
                    ],
                  );
                }

                // ── Mobile/narrow: colonna singola ──
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _StatsRow(
                        responses: responses,
                        totalQuestions: totalQuestions,
                        sondageColor: sondageColor,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                        localization: localization,
                      ),
                      const SizedBox(height: 20),
                      _InfoCard(
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                        sondageColor: sondageColor,
                        children: [
                          _InfoRow(
                            icon: Icons.description_outlined,
                            label: 'Focus',
                            value: sondageFocus,
                            textTheme: textTheme,
                            colorScheme: colorScheme,
                          ),
                          const Divider(height: 24),
                          _InfoRow(
                            icon: Icons.calendar_today_outlined,
                            label: localization.createdDate,
                            value: _formatDate(createdDate),
                            textTheme: textTheme,
                            colorScheme: colorScheme,
                          ),
                          const Divider(height: 24),
                          _InfoRow(
                            icon: Icons.event_outlined,
                            label: localization.expiryDate,
                            value: _formatDate(expiryDate),
                            textTheme: textTheme,
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _ProgressCard(
                        responses: responses,
                        totalQuestions: totalQuestions,
                        sondageColor: sondageColor,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                        localization: localization,
                      ),
                      const SizedBox(height: 20),
                      _QuestionsCard(
                        totalQuestions: totalQuestions,
                        sondageColor: sondageColor,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                        localization: localization,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// ═══════════════════════════════════════════════════
// Componenti privati
// ═══════════════════════════════════════════════════

/// Badge di stato (active, draft, completed, closed)
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'closed':
        return Colors.red;
      case 'draft':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Riga di 3 stats card in orizzontale
class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.responses,
    required this.totalQuestions,
    required this.sondageColor,
    required this.colorScheme,
    required this.textTheme,
    required this.localization,
  });

  final int responses;
  final int totalQuestions;
  final Color sondageColor;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.people_rounded,
            value: '$responses',
            label: localization.responses,
            color: Colors.blue,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.quiz_rounded,
            value: '$totalQuestions',
            label: localization.questions,
            color: Colors.purple,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.percent_rounded,
            value: totalQuestions > 0
                ? '${((responses / (totalQuestions * 10)) * 100).clamp(0, 100).toStringAsFixed(0)}%'
                : '0%',
            label: localization.progress,
            color: sondageColor,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ),
      ],
    );
  }
}

/// Singola stat card
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.colorScheme,
    required this.textTheme,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.bgNavbarSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.iconLabel,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

/// Card generica con bordo colore sondaggio
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.colorScheme,
    required this.textTheme,
    required this.sondageColor,
    required this.children,
  });

  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final Color sondageColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.bgNavbarSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: sondageColor.withValues(alpha: 0.2),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// Riga info con icona, label, valore
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textTheme,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final String value;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[500]),
        const SizedBox(width: 12),
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.iconLabel,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Card progresso con barra
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.responses,
    required this.totalQuestions,
    required this.sondageColor,
    required this.colorScheme,
    required this.textTheme,
    required this.localization,
  });

  final int responses;
  final int totalQuestions;
  final Color sondageColor;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    final progress = totalQuestions > 0
        ? (responses / (totalQuestions * 10)).clamp(0.0, 1.0)
        : 0.0;

    return _InfoCard(
      colorScheme: colorScheme,
      textTheme: textTheme,
      sondageColor: sondageColor,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up_rounded, size: 22, color: sondageColor),
            const SizedBox(width: 8),
            Text(
              localization.progress,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.iconLabel,
              ),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: sondageColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(sondageColor),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$responses ${localization.responses}',
          style: textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
        ),
      ],
    );
  }
}

/// Card domande — scrollabile
class _QuestionsCard extends StatelessWidget {
  const _QuestionsCard({
    required this.totalQuestions,
    required this.sondageColor,
    required this.colorScheme,
    required this.textTheme,
    required this.localization,
  });

  final int totalQuestions;
  final Color sondageColor;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.bgNavbarSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: sondageColor.withValues(alpha: 0.2),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.quiz_rounded, size: 22, color: sondageColor),
              const SizedBox(width: 8),
              Text(
                '${localization.questions} ($totalQuestions)',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.iconLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ...List.generate(
            totalQuestions.clamp(0, 10),
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _QuestionTile(
                index: index,
                sondageColor: sondageColor,
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),
            ),
          ),
          if (totalQuestions > 10)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '+ ${totalQuestions - 10} more questions...',
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

/// Tile singola domanda con opzioni placeholder
class _QuestionTile extends StatelessWidget {
  const _QuestionTile({
    required this.index,
    required this.sondageColor,
    required this.colorScheme,
    required this.textTheme,
  });

  final int index;
  final Color sondageColor;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.homeSecondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: sondageColor.withValues(alpha: 0.15),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: sondageColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Question ${index + 1} — placeholder',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.iconLabel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Opzioni placeholder
          ...List.generate(
            3,
            (optIndex) => Padding(
              padding: const EdgeInsets.only(left: 38, bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[400]!, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Option ${String.fromCharCode(65 + optIndex)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
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
