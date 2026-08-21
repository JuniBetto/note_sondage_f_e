import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';

Future<String?> showShiftReplacementRejectReasonDialog({
  required BuildContext context,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _ShiftReplacementRejectReasonDialog(),
  );
}

class _ShiftReplacementRejectReasonDialog extends StatefulWidget {
  const _ShiftReplacementRejectReasonDialog();

  @override
  State<_ShiftReplacementRejectReasonDialog> createState() =>
      _ShiftReplacementRejectReasonDialogState();
}

class _ShiftReplacementRejectReasonDialogState
    extends State<_ShiftReplacementRejectReasonDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    _reasonController.addListener(() {
      final hasContent = _reasonController.text.trim().isNotEmpty;
      if (hasContent != _hasContent) {
        setState(() {
          _hasContent = hasContent;
        });
      }
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _localizedText(
                  context,
                  it: 'Rifiuta sostituzione',
                  en: 'Decline replacement',
                  fr: 'Refuser le remplacement',
                  es: 'Rechazar reemplazo',
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _localizedText(
                  context,
                  it: 'Indica il motivo del rifiuto: verra mostrato a chi ha inviato la richiesta.',
                  en: 'Explain why you are declining: this will be shown to whoever sent the request.',
                  fr: 'Indiquez le motif du refus : il sera affiche a la personne qui a envoye la demande.',
                  es: 'Indica el motivo del rechazo: se mostrara a quien envio la solicitud.',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.descriptionColor,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: _localizedText(
                    context,
                    it: 'Es. ho gia un impegno quel giorno',
                    en: 'E.g. I already have a commitment that day',
                    fr: 'Ex. j\'ai deja un engagement ce jour-la',
                    es: 'Ej. ya tengo un compromiso ese dia',
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
                      onPressed: !_hasContent
                          ? null
                          : () => Navigator.of(
                              context,
                            ).pop(_reasonController.text.trim()),
                      type: ButtonType.filled,
                      backgroundColor: colorScheme.errorColor,
                      borderRadius: 10,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      isActive: true,
                      fullWidth: true,
                      child: Text(
                        _localizedText(
                          context,
                          it: 'Rifiuta',
                          en: 'Decline',
                          fr: 'Refuser',
                          es: 'Rechazar',
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
