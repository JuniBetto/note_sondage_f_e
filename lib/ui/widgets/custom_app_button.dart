import 'package:flutter/material.dart';
import 'package:note_sondage/theme/extensions/theme_extensions.dart';

enum ButtonType { elevated, filled, filledTonal, text, outlined, card }

const _kDefaultHorizontalPadding = EdgeInsets.symmetric(
  horizontal: 14,
  vertical: 12,
);

class CustomAppButton extends StatelessWidget {
  const CustomAppButton({
    super.key,
    required this.onPressed,
    required this.isActive,
    required this.child,
    this.type = ButtonType.filled,
    this.iconCard,
    this.leadingIcon,
    this.trailingIcon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.customTextStyle,
    this.borderRadius = 12.0,
    this.elevation = 0.0,
    this.shadows,
    this.padding,
    this.margin,
    this.fullWidth = false,
    this.isLoading = false,
    this.minHeight,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? iconCard;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final ButtonType type;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final TextStyle? customTextStyle;
  final bool isActive;
  final double borderRadius;
  final double elevation;
  final List<BoxShadow>? shadows;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool fullWidth;
  final bool isLoading;
  final double? minHeight;

  bool get _isEnabled => onPressed != null && !isLoading;

  ButtonStyle _getButtonStyle(
    BuildContext context,
    ColorScheme colorScheme,
    TextStyle finalTextStyle,
  ) {
    final defaultPadding = padding ?? _kDefaultHorizontalPadding;
    final minimumSize = Size(fullWidth ? double.infinity : 0, minHeight ?? 0);
    final primaryButtonColor =
        backgroundColor ?? colorScheme.bgNavbarbutton ?? colorScheme.primary;
    final primaryForegroundColor =
        foregroundColor ?? colorScheme.bgNavbartextactive ?? Colors.white;
    final disabledBackgroundColor =
        colorScheme.buttonIsDisableBg ?? colorScheme.surfaceContainerHighest;
    final disabledForegroundColor =
        colorScheme.descriptionColor ?? colorScheme.onSurfaceVariant;
    final outlinedForegroundColor =
        foregroundColor ?? colorScheme.primaryColor ?? colorScheme.primary;
    final outlinedBorderColor =
        borderColor ??
        foregroundColor ??
        (colorScheme.primaryColor ?? colorScheme.primary).withValues(
          alpha: 0.65,
        );
    final filledTonalBackgroundColor =
        backgroundColor ??
        (colorScheme.primaryColor ?? colorScheme.primary).withValues(
          alpha: 0.12,
        );
    final filledTonalForegroundColor =
        foregroundColor ?? colorScheme.primaryColor ?? colorScheme.primary;

    return switch (type) {
      ButtonType.elevated => ElevatedButton.styleFrom(
        backgroundColor: primaryButtonColor,
        disabledBackgroundColor: disabledBackgroundColor,
        foregroundColor: primaryForegroundColor,
        disabledForegroundColor: disabledForegroundColor,
        elevation: elevation,
        padding: defaultPadding,
        minimumSize: minimumSize,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        textStyle: finalTextStyle,
      ),
      ButtonType.filled => FilledButton.styleFrom(
        backgroundColor: primaryButtonColor,
        disabledBackgroundColor: disabledBackgroundColor,
        foregroundColor: primaryForegroundColor,
        disabledForegroundColor: disabledForegroundColor,
        elevation: elevation,
        padding: defaultPadding,
        minimumSize: minimumSize,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        textStyle: finalTextStyle,
      ),
      ButtonType.filledTonal => FilledButton.styleFrom(
        backgroundColor: filledTonalBackgroundColor,
        disabledBackgroundColor: disabledBackgroundColor.withValues(alpha: 0.7),
        foregroundColor: filledTonalForegroundColor,
        disabledForegroundColor: disabledForegroundColor,
        elevation: elevation,
        padding: defaultPadding,
        minimumSize: minimumSize,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        textStyle: finalTextStyle,
      ),
      ButtonType.outlined =>
        OutlinedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: outlinedForegroundColor,
          disabledForegroundColor: disabledForegroundColor,
          elevation: elevation,
          padding: defaultPadding,
          minimumSize: minimumSize,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          side: BorderSide(color: outlinedBorderColor, width: 1.0),
          textStyle: finalTextStyle,
        ).copyWith(
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(
                color: disabledForegroundColor.withValues(alpha: 0.45),
                width: 1.0,
              );
            }
            return BorderSide(color: outlinedBorderColor, width: 1.0);
          }),
        ),
      ButtonType.text => TextButton.styleFrom(
        foregroundColor:
            foregroundColor ??
            (isActive
                ? colorScheme.bgNavbartextactive!
                : colorScheme.primaryColor ?? colorScheme.primary),
        disabledForegroundColor: disabledForegroundColor,
        backgroundColor:
            backgroundColor ??
            (isActive
                ? colorScheme.bgNavbarbutton ?? colorScheme.primary
                : Colors.transparent),
        disabledBackgroundColor: Colors.transparent,
        elevation: elevation,
        padding: defaultPadding,
        minimumSize: minimumSize,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        textStyle: finalTextStyle,
      ),
      ButtonType.card => ButtonStyle(
        padding: WidgetStatePropertyAll(defaultPadding),
      ),
    };
  }

  Widget _buildContent(BuildContext context) {
    final effectiveForeground =
        foregroundColor ??
        (type == ButtonType.filled || type == ButtonType.elevated
            ? (Theme.of(context).colorScheme.bgNavbartextactive ?? Colors.white)
            : Theme.of(context).colorScheme.primary);

    final content = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: effectiveForeground,
            ),
          )
        : child;

    if (leadingIcon == null && trailingIcon == null) {
      return content;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null) ...[leadingIcon!, const SizedBox(width: 8)],
        Flexible(child: content),
        if (trailingIcon != null) ...[const SizedBox(width: 8), trailingIcon!],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final defaultTextStyle = context.textTheme.labelLarge;
    final finalTextStyle = (defaultTextStyle ?? const TextStyle()).merge(
      customTextStyle,
    );
    final style = _getButtonStyle(context, colorScheme, finalTextStyle);
    final content = _buildContent(context);

    Widget button = switch (type) {
      ButtonType.elevated => ElevatedButton(
        onPressed: _isEnabled ? onPressed : null,
        style: style,
        child: content,
      ),
      ButtonType.filled || ButtonType.filledTonal => FilledButton(
        onPressed: _isEnabled ? onPressed : null,
        style: style,
        child: content,
      ),
      ButtonType.outlined => OutlinedButton(
        onPressed: _isEnabled ? onPressed : null,
        style: style,
        child: content,
      ),
      ButtonType.text => TextButton(
        onPressed: _isEnabled ? onPressed : null,
        style: style,
        child: content,
      ),
      ButtonType.card => GestureDetector(
        onTap: _isEnabled ? onPressed : null,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [content, iconCard ?? const SizedBox()],
        ),
      ),
    };

    if (fullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    if ((shadows != null && shadows!.isNotEmpty) || margin != null) {
      return Container(
        margin: margin,
        decoration: BoxDecoration(boxShadow: shadows),
        child: button,
      );
    }

    return button;
  }
}
