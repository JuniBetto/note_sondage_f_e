import 'package:flutter/material.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_replacement_candidate_entity.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';

String _localizedReplacementText(
  BuildContext context, {
  required String it,
  required String en,
  String? fr,
  String? es,
}) {
  switch (Localizations.localeOf(context).languageCode.toLowerCase()) {
    case 'it':
      return it;
    case 'fr':
      return fr ?? en;
    case 'es':
      return es ?? en;
    default:
      return en;
  }
}

String _formatShiftTime(BuildContext context, TimeOfDay time) {
  final material = MaterialLocalizations.of(context);
  return material.formatTimeOfDay(time, alwaysUse24HourFormat: true);
}

String _formatShiftDate(BuildContext context, DateTime value) {
  final material = MaterialLocalizations.of(context);
  return material.formatMediumDate(value);
}

Future<void> showShiftReplacementCandidatesDialog({
  required BuildContext context,
  required ShiftReplacementCandidatesEntity result,
  VoidCallback? onOpenAvailability,
}) async {
  final sheet = _ShiftReplacementCandidatesSheet(
    result: result,
    onOpenAvailability: onOpenAvailability,
  );
  final isWideLayout = MediaQuery.of(context).size.width >= 720;

  if (isWideLayout) {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: sheet,
      ),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => sheet,
  );
}

class _ShiftReplacementCandidatesSheet extends StatelessWidget {
  const _ShiftReplacementCandidatesSheet({
    required this.result,
    this.onOpenAvailability,
  });

  final ShiftReplacementCandidatesEntity result;
  final VoidCallback? onOpenAvailability;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dialogBackground =
        colorScheme.dialogBackgroundColor ?? colorScheme.surface;
    final borderColor = colorScheme.borderColor ?? colorScheme.outlineVariant;
    final mutedSurface =
        colorScheme.bgDialogSecondary?.withValues(alpha: 0.72) ??
        colorScheme.surfaceContainerHighest;
    final successColor = colorScheme.successColor;
    final warningColor = colorScheme.warningColor;
    final compatibleCount = result.candidates
        .where((item) => item.compatible)
        .length;
    final blockedCount = result.candidates.length - compatibleCount;
    final teamName = result.teamName?.trim();
    final shiftWindow =
        '${_formatShiftTime(context, result.startTime)} - ${_formatShiftTime(context, result.endTime)}'
        '${result.overnight ? ' • +1' : ''}';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Material(
              color: dialogBackground,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localizedReplacementText(
                        context,
                        it: 'Cerca sostituto',
                        en: 'Find replacement',
                        fr: 'Trouver un remplacement',
                        es: 'Buscar reemplazo',
                      ),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _localizedReplacementText(
                        context,
                        it: 'Questi sono i primi colleghi da contattare per coprire il turno selezionato.',
                        en: 'These are the first teammates to contact for the selected shift.',
                        fr: 'Voici les premiers collegues a contacter pour couvrir le quart selectionne.',
                        es: 'Estos son los primeros companeros a contactar para cubrir el turno seleccionado.',
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.descriptionColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: mutedSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Wrap(
                        runSpacing: 10,
                        spacing: 16,
                        children: [
                          _SummaryBlock(
                            label: _localizedReplacementText(
                              context,
                              it: 'Team',
                              en: 'Team',
                              fr: 'Equipe',
                              es: 'Equipo',
                            ),
                            value: teamName == null || teamName.isEmpty
                                ? '-'
                                : teamName,
                          ),
                          _SummaryBlock(
                            label: _localizedReplacementText(
                              context,
                              it: 'Data',
                              en: 'Date',
                              fr: 'Date',
                              es: 'Fecha',
                            ),
                            value: _formatShiftDate(context, result.shiftDate),
                          ),
                          _SummaryBlock(
                            label: _localizedReplacementText(
                              context,
                              it: 'Fascia',
                              en: 'Window',
                              fr: 'Plage',
                              es: 'Franja',
                            ),
                            value: shiftWindow,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: result.hasCompatibleCandidates
                            ? successColor.withValues(alpha: 0.08)
                            : warningColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: result.hasCompatibleCandidates
                              ? successColor.withValues(alpha: 0.22)
                              : warningColor.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.hasCompatibleCandidates
                                ? _localizedReplacementText(
                                    context,
                                    it: '$compatibleCount candidati compatibili trovati',
                                    en: '$compatibleCount compatible candidates found',
                                    fr: '$compatibleCount candidats compatibles trouves',
                                    es: '$compatibleCount candidatos compatibles encontrados',
                                  )
                                : _localizedReplacementText(
                                    context,
                                    it: 'Nessun candidato compatibile al momento',
                                    en: 'No compatible candidates right now',
                                    fr: 'Aucun candidat compatible pour le moment',
                                    es: 'No hay candidatos compatibles en este momento',
                                  ),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: result.hasCompatibleCandidates
                                  ? successColor
                                  : warningColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _localizedReplacementText(
                              context,
                              it: '$blockedCount colleghi risultano bloccati da assenze o sovrapposizioni.',
                              en: '$blockedCount teammates are currently blocked by absences or overlaps.',
                              fr: '$blockedCount collegues sont actuellement bloques par des absences ou des chevauchements.',
                              es: '$blockedCount companeros estan bloqueados por ausencias o solapamientos.',
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.descriptionColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: result.candidates.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                  horizontal: 12,
                                ),
                                child: Text(
                                  _localizedReplacementText(
                                    context,
                                    it: 'Non ci sono ancora membri candidabili in questo team.',
                                    en: 'There are no candidate teammates in this team yet.',
                                    fr: 'Il n\'y a pas encore de collegues candidats dans cette equipe.',
                                    es: 'Todavia no hay companeros candidatos en este equipo.',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.descriptionColor,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: result.candidates.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final candidate = result.candidates[index];
                                return _CandidateCard(
                                  candidate: candidate,
                                  borderColor: borderColor,
                                  compatibleColor: successColor,
                                  blockedColor: warningColor,
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    if (!result.hasCompatibleCandidates &&
                        onOpenAvailability != null) ...[
                      CustomAppButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onOpenAvailability?.call();
                        },
                        type: ButtonType.filled,
                        borderRadius: 12,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        isActive: true,
                        fullWidth: true,
                        leadingIcon: const Icon(Icons.poll_outlined, size: 18),
                        child: Text(
                          _localizedReplacementText(
                            context,
                            it: 'Apri disponibilita',
                            en: 'Open availability survey',
                            fr: 'Ouvrir le sondage de disponibilite',
                            es: 'Abrir encuesta de disponibilidad',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    CustomAppButton(
                      onPressed: () => Navigator.of(context).pop(),
                      type: ButtonType.outlined,
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      isActive: true,
                      fullWidth: true,
                      child: Text(
                        _localizedReplacementText(
                          context,
                          it: 'Chiudi',
                          en: 'Close',
                          fr: 'Fermer',
                          es: 'Cerrar',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.descriptionColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.candidate,
    required this.borderColor,
    required this.compatibleColor,
    required this.blockedColor,
  });

  final ShiftReplacementCandidateEntity candidate;
  final Color borderColor;
  final Color compatibleColor;
  final Color blockedColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final badgeColor = candidate.compatible ? compatibleColor : blockedColor;
    final subtitle = candidate.subtitle;
    final role = candidate.role?.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: badgeColor.withValues(alpha: 0.14),
                foregroundColor: badgeColor,
                child: Text(
                  _initials(candidate.displayName),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.descriptionColor,
                        ),
                      ),
                    ],
                    if (role != null && role.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        role,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.descriptionColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  candidate.compatible
                      ? _localizedReplacementText(
                          context,
                          it: 'Compatibile',
                          en: 'Compatible',
                          fr: 'Compatible',
                          es: 'Compatible',
                        )
                      : _localizedReplacementText(
                          context,
                          it: 'Bloccato',
                          en: 'Blocked',
                          fr: 'Bloque',
                          es: 'Bloqueado',
                        ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: badgeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (candidate.incompatibilities.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...candidate.incompatibilities.map(
              (issue) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: blockedColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        issue.message.trim().isEmpty
                            ? issue.code
                            : issue.message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.descriptionColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();
  if (parts.isEmpty) {
    return '?';
  }
  return parts.map((part) => part.characters.first.toUpperCase()).join();
}
