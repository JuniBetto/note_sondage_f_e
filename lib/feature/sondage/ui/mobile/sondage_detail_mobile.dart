import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/widgets/sondage_mobile.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';

class SondageDetailMobile extends StatelessWidget {
  const SondageDetailMobile({super.key, required this.sondageId});
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
      return Scaffold(
        appBar: AppBar(title: const Text('Sondage')),
        body: const Center(child: Text('Sondage not found')),
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

    return Scaffold(
      backgroundColor: colorScheme.homePrimary,
      appBar: AppBar(
        backgroundColor: colorScheme.bgNavbarSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colorScheme.iconLabel),
          onPressed: () {
            // Imposta il NavigationBloc su sondage (index 4) e torna a MainMobile.
            // Non usare RouterPaths.sondage che è una route senza Scaffold.
            context.read<NavigationBloc>().add(NavigationPositionChanged(4));
            context.go(RouterPaths.home);
          },
        ),
        title: Text(
          sondageName,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.iconLabel,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          _StatusChip(status: status),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card info principale ──
            _DetailCard(
              colorScheme: colorScheme,
              sondageColor: sondageColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LabelValue(
                    label: 'Focus',
                    value: sondageFocus,
                    icon: Icons.description_outlined,
                    textTheme: textTheme,
                    colorScheme: colorScheme,
                  ),
                  const Divider(height: 20),
                  _LabelValue(
                    label: localization.responses,
                    value: '$responses',
                    icon: Icons.people_outline,
                    textTheme: textTheme,
                    colorScheme: colorScheme,
                  ),
                  const Divider(height: 20),
                  _LabelValue(
                    label: localization.questions,
                    value: '$totalQuestions',
                    icon: Icons.quiz_outlined,
                    textTheme: textTheme,
                    colorScheme: colorScheme,
                  ),
                  const Divider(height: 20),
                  _LabelValue(
                    label: localization.createdDate,
                    value:
                        '${createdDate.day.toString().padLeft(2, '0')}/${createdDate.month.toString().padLeft(2, '0')}/${createdDate.year}',
                    icon: Icons.calendar_today_outlined,
                    textTheme: textTheme,
                    colorScheme: colorScheme,
                  ),
                  const Divider(height: 20),
                  _LabelValue(
                    label: localization.expiryDate,
                    value:
                        '${expiryDate.day.toString().padLeft(2, '0')}/${expiryDate.month.toString().padLeft(2, '0')}/${expiryDate.year}',
                    icon: Icons.event_outlined,
                    textTheme: textTheme,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Sezione Progresso ──
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
                      value: totalQuestions > 0
                          ? (responses / (totalQuestions * 10)).clamp(0.0, 1.0)
                          : 0,
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                      valueColor:
                          AlwaysStoppedAnimation<Color>(sondageColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$responses ${localization.responses}',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Sezione Domande (placeholder) ──
            _DetailCard(
              colorScheme: colorScheme,
              sondageColor: sondageColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localization.questions,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.iconLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    totalQuestions.clamp(0, 5),
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                sondageColor.withValues(alpha: 0.2),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: sondageColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.homeSecondary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Question ${index + 1} — placeholder',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.iconLabel,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Componenti privati ──

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  Color _getColor() {
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
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
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
