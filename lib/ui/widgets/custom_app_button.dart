import 'package:flutter/material.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/theme/extensions/theme_extensions.dart';

enum ButtonType { elevated, text, outlined, card }

const _kDefaultHorizontalPadding = EdgeInsets.symmetric(horizontal: 12.0);

class CustomAppButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? iconCard;

  final ButtonType type;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextStyle? customTextStyle;

  final bool isActive;
  final double borderRadius;
  final double elevation;
  final List<BoxShadow>? shadows;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const CustomAppButton({
    super.key,
    required this.onPressed,
    this.type = ButtonType.elevated,
    this.backgroundColor,
    this.foregroundColor,
    this.customTextStyle, // Rinominato in customTextStyle
    this.borderRadius = 8.0,
    this.elevation = 0.0,
    this.shadows,
    this.padding,
    this.margin,
    required this.isActive,
    required this.child,
    this.iconCard,
  });

  // Funzione helper per calcolare lo stile (più facile da profilare)
  ButtonStyle _getButtonStyle(
    BuildContext context,
    ColorScheme colorScheme,
    TextStyle finalTextStyle,
  ) {
    // Usiamo la costante cached
    const defaultPadding = _kDefaultHorizontalPadding;

    return switch (type) {
      ButtonType.elevated => ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? colorScheme.bgsecondary!,
        foregroundColor: foregroundColor ?? colorScheme.textColor!,
        elevation: elevation,
        padding: padding ?? defaultPadding, // Usiamo la costante
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        textStyle: finalTextStyle,
      ),
      ButtonType.outlined => OutlinedButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.transparent,
        foregroundColor: foregroundColor ?? colorScheme.textColor!,
        elevation: elevation,
        padding: padding ?? defaultPadding, // Usiamo la costante
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        side: BorderSide(
          color: foregroundColor ?? colorScheme.primary,
          width: 1.0,
        ),
        textStyle: finalTextStyle,
      ),
      ButtonType.text => TextButton.styleFrom(
        foregroundColor:
            foregroundColor ??
            (isActive
                ? colorScheme.bgNavbartextactive!
                : colorScheme.textColor!),
        backgroundColor:
            backgroundColor ??
            (isActive ? colorScheme.bgsecondary! : Colors.transparent),
        elevation: elevation,
        padding: padding ?? defaultPadding, // Usiamo la costante
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        textStyle: finalTextStyle,
      ),
      ButtonType.card => ButtonStyle(
        // Lo stile del "card" è gestito nel build
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    // 1. Accesso al tema (necessario)
    final colorScheme = Theme.of(context).colorScheme;
    // 2. Calcolo dello stile di testo (Dipendenza da getDefaultAppTextStyle)
    //final TextStyle defaultTextStyle = getDefaultAppTextStyle(context, isDark);
    final TextStyle? defaultTextStyle = context.textTheme.labelLarge;
    final TextStyle finalTextStyle = defaultTextStyle!.merge(customTextStyle);

    // 3. Ottieni lo stile del pulsante (chiama la funzione helper)
    final ButtonStyle style = _getButtonStyle(
      context,
      colorScheme,
      finalTextStyle,
    );

    // 4. Implementa il pulsante
    final Widget button = switch (type) {
      ButtonType.elevated => ElevatedButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
      ButtonType.outlined => OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
      ButtonType.text => TextButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
      ButtonType.card => GestureDetector(
        onTap: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [child, iconCard ?? SizedBox()],
        ),
      ),
    };

    // 5. Gestione Box/Shadow e Margin
    if (shadows != null && shadows!.isNotEmpty || margin != null) {
      return Container(
        margin: margin,
        decoration: BoxDecoration(boxShadow: shadows),
        child: button,
      );
    }

    // Se non ci sono margini o ombre, restituisci solo il pulsante
    return button;
  }
}
