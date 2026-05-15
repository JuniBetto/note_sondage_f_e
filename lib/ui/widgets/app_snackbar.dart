import 'package:flutter/material.dart';
import 'package:note_sondage/core/utils/app_error_message_resolver.dart';
import 'package:note_sondage/ui/app_keys.dart';

enum AppSnackBarType { success, warning, error }

class AppSnackBar {
  const AppSnackBar._();

  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
  }) {
    _show(context, message, type: AppSnackBarType.success, title: title);
  }

  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
  }) {
    _show(context, message, type: AppSnackBarType.warning, title: title);
  }

  static void showError(BuildContext context, String message, {String? title}) {
    _show(context, message, type: AppSnackBarType.error, title: title);
  }

  static void showResolvedError(
    BuildContext context,
    Object error, {
    String? title,
    String fallback = 'We could not complete this action. Please try again.',
  }) {
    showError(
      context,
      AppErrorMessageResolver.resolve(error, fallback: fallback),
      title: title,
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required AppSnackBarType type,
    String? title,
  }) {
    final messenger =
        scaffoldMessengerKey.currentState ?? ScaffoldMessenger.of(context);
    final themeContext = scaffoldMessengerKey.currentContext ?? context;
    final theme = Theme.of(themeContext);
    final style = _resolveStyle(type);
    final resolvedMessage = message.trim().isEmpty
        ? _defaultMessage(type)
        : message.trim();
    final resolvedTitle = title ?? _defaultTitle(type);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          elevation: 2,
          backgroundColor: style.backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: style.borderColor),
          ),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(style.icon, color: style.foregroundColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      resolvedTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          theme.textTheme.titleSmall?.copyWith(
                            color: style.foregroundColor,
                            fontWeight: FontWeight.w800,
                          ) ??
                          TextStyle(
                            color: style.foregroundColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resolvedMessage,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style:
                          theme.textTheme.bodyMedium?.copyWith(
                            color: style.foregroundColor,
                            fontWeight: FontWeight.w600,
                          ) ??
                          TextStyle(
                            color: style.foregroundColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  static String _defaultTitle(AppSnackBarType type) {
    switch (type) {
      case AppSnackBarType.success:
        return 'Done';
      case AppSnackBarType.warning:
        return 'Attention';
      case AppSnackBarType.error:
        return 'Something went wrong';
    }
  }

  static String _defaultMessage(AppSnackBarType type) {
    switch (type) {
      case AppSnackBarType.success:
        return 'The operation completed successfully.';
      case AppSnackBarType.warning:
        return 'Please review this information before continuing.';
      case AppSnackBarType.error:
        return 'We could not complete this action. Please try again.';
    }
  }

  static _SnackBarStyle _resolveStyle(AppSnackBarType type) {
    switch (type) {
      case AppSnackBarType.success:
        return _SnackBarStyle(
          icon: Icons.check_circle_rounded,
          backgroundColor: const Color(0xFFE7F7EF),
          borderColor: const Color(0xFF9AD9B2),
          foregroundColor: const Color(0xFF146C43),
        );
      case AppSnackBarType.warning:
        return _SnackBarStyle(
          icon: Icons.info_rounded,
          backgroundColor: const Color(0xFFFFF4DB),
          borderColor: const Color(0xFFF1C972),
          foregroundColor: const Color(0xFF8A5A00),
        );
      case AppSnackBarType.error:
        return _SnackBarStyle(
          icon: Icons.error_rounded,
          backgroundColor: const Color(0xFFFDECEC),
          borderColor: const Color(0xFFF3A8A8),
          foregroundColor: const Color(0xFF8E1B1B),
        );
    }
  }
}

class _SnackBarStyle {
  const _SnackBarStyle({
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
}
