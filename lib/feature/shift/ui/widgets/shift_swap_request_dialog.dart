import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';

class ShiftSwapCandidateOption {
  const ShiftSwapCandidateOption({
    required this.userId,
    required this.label,
    this.subtitle,
  });

  final String userId;
  final String label;
  final String? subtitle;
}

class ShiftSwapRequestDialogResult {
  const ShiftSwapRequestDialogResult({
    required this.candidateUserId,
    this.note,
  });

  final String candidateUserId;
  final String? note;
}

Future<ShiftSwapRequestDialogResult?> showShiftSwapRequestDialog({
  required BuildContext context,
  required String shiftDateLabel,
  required String teamName,
  required List<ShiftSwapCandidateOption> candidates,
}) {
  return showDialog<ShiftSwapRequestDialogResult>(
    context: context,
    builder: (_) => _ShiftSwapRequestDialog(
      shiftDateLabel: shiftDateLabel,
      teamName: teamName,
      candidates: candidates,
    ),
  );
}

class _ShiftSwapRequestDialog extends StatefulWidget {
  const _ShiftSwapRequestDialog({
    required this.shiftDateLabel,
    required this.teamName,
    required this.candidates,
  });

  final String shiftDateLabel;
  final String teamName;
  final List<ShiftSwapCandidateOption> candidates;

  @override
  State<_ShiftSwapRequestDialog> createState() =>
      _ShiftSwapRequestDialogState();
}

class _ShiftSwapRequestDialogState extends State<_ShiftSwapRequestDialog> {
  final TextEditingController _noteController = TextEditingController();
  String? _selectedCandidateUserId;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _localizedText(
                  context,
                  it: 'Sostituzione turno',
                  en: 'Shift swap',
                  fr: 'Echange de quart',
                  es: 'Intercambio de turno',
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _localizedText(
                  context,
                  it: 'Scegli il collega con cui scambiare il turno del ${widget.shiftDateLabel} nel team ${widget.teamName}.',
                  en: 'Choose the teammate to swap the ${widget.shiftDateLabel} shift with in team ${widget.teamName}.',
                  fr: 'Choisissez le collegue avec qui echanger le quart du ${widget.shiftDateLabel} dans l\'equipe ${widget.teamName}.',
                  es: 'Elige al companero con quien intercambiar el turno del ${widget.shiftDateLabel} en el equipo ${widget.teamName}.',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.descriptionColor,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _localizedText(
                  context,
                  it: 'Collega',
                  en: 'Teammate',
                  fr: 'Collegue',
                  es: 'Companero',
                ),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCandidateUserId,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                items: widget.candidates
                    .map(
                      (candidate) => DropdownMenuItem<String>(
                        value: candidate.userId,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              candidate.label,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                            if (candidate.subtitle != null &&
                                candidate.subtitle!.trim().isNotEmpty)
                              Text(
                                candidate.subtitle!,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.descriptionColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  setState(() {
                    _selectedCandidateUserId = value;
                  });
                },
                hint: Text(
                  _localizedText(
                    context,
                    it: 'Seleziona un collega',
                    en: 'Select a teammate',
                    fr: 'Selectionnez un collegue',
                    es: 'Selecciona un companero',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _localizedText(
                  context,
                  it: 'Nota facoltativa',
                  en: 'Optional note',
                  fr: 'Note facultative',
                  es: 'Nota opcional',
                ),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _localizedText(
                    context,
                    it: 'Aggiungi un messaggio per il collega o per il manager',
                    en: 'Add a message for the teammate or manager',
                    fr: 'Ajoutez un message pour le collegue ou le manager',
                    es: 'Agrega un mensaje para el companero o el manager',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomAppButton(
                      onPressed: () => Navigator.of(context).pop(),
                      type: ButtonType.outlined,
                      borderRadius: 10,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      isActive: true,
                      fullWidth: true,
                      child: Text(loc.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomAppButton(
                      onPressed: _selectedCandidateUserId == null
                          ? null
                          : () => Navigator.of(context).pop(
                              ShiftSwapRequestDialogResult(
                                candidateUserId: _selectedCandidateUserId!,
                                note: _trimToNull(_noteController.text),
                              ),
                            ),
                      type: ButtonType.filled,
                      backgroundColor: colorScheme.primaryColor,
                      borderRadius: 10,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      isActive: true,
                      fullWidth: true,
                      child: Text(
                        _localizedText(
                          context,
                          it: 'Invia richiesta',
                          en: 'Send request',
                          fr: 'Envoyer la demande',
                          es: 'Enviar solicitud',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _trimToNull(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}

String _localizedText(
  BuildContext context, {
  required String it,
  required String en,
  required String fr,
  required String es,
}) {
  final locale = Localizations.localeOf(context).languageCode.toLowerCase();
  switch (locale) {
    case 'it':
      return it;
    case 'fr':
      return fr;
    case 'es':
      return es;
    default:
      return en;
  }
}
