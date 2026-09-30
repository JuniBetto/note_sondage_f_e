import 'package:flutter/material.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

/// Quanto deve risaltare il link.
enum AppTextLinkTone {
  /// Azione secondaria importante (es. "Password dimenticata"): colore
  /// principale dell'app, con buon contrasto in tema chiaro e scuro.
  primary,

  /// Link di servizio (es. pagine legali): più piccolo e più chiaro, per non
  /// competere con le azioni principali.
  subtle,
}

/// Link testuale condiviso: testo sottolineato, sfondo trasparente e area
/// di tocco accessibile (min 48×44).
///
/// Usare questo invece di un `TextButton`: il tema dell'app dà ai
/// `TextButton` uno sfondo pieno, che trasformerebbe il link in un pulsante.
class AppTextLink extends StatelessWidget {
  const AppTextLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = AppTextLinkTone.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppTextLinkTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSubtle = tone == AppTextLinkTone.subtle;
    final color = isSubtle
        ? colorScheme.onSurfaceVariant
        : colorScheme.bgsecondary ?? colorScheme.primary;
    final baseStyle = isSubtle
        ? theme.textTheme.bodySmall
        : theme.textTheme.bodyMedium;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        minimumSize: const Size(48, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: baseStyle?.copyWith(
          color: color,
          fontWeight: isSubtle ? FontWeight.w400 : null,
          decoration: TextDecoration.underline,
          decorationColor: color,
        ),
      ),
    );
  }
}
