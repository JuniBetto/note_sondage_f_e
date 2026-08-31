import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/auth/domain/use_case/auth_use_case.dart';
import 'package:note_sondage/feature/auth/ui/auth_user_message_resolver.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

class ConfirmAccountErasurePage extends StatefulWidget {
  const ConfirmAccountErasurePage({super.key, required this.queryParameters});

  final Map<String, String> queryParameters;

  @override
  State<ConfirmAccountErasurePage> createState() =>
      _ConfirmAccountErasurePageState();
}

class _ConfirmAccountErasurePageState extends State<ConfirmAccountErasurePage> {
  late final AuthUseCase _authUseCase;
  _ConfirmErasureViewState _state = const _ConfirmErasureViewState.loading();

  @override
  void initState() {
    super.initState();
    _authUseCase = GetIt.instance<AuthUseCase>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_confirmErasure());
    });
  }

  Future<void> _confirmErasure() async {
    final status = widget.queryParameters['status']?.trim().toLowerCase();
    final localization = AppLocalizations.of(context)!;

    if (status == 'success') {
      if (!mounted) return;
      setState(() {
        _state = _ConfirmErasureViewState.success(
          title: localization.accountErasureConfirmedTitle,
          message: localization.accountErasureConfirmedMessage,
        );
      });
      return;
    }

    if (status == 'error') {
      if (!mounted) return;
      setState(() {
        _state = _ConfirmErasureViewState.error(
          title: localization.accountErasureFailedTitle,
          message: localization.accountErasureFailedMessage,
        );
      });
      return;
    }

    final token = widget.queryParameters['token']?.trim();

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _state = _ConfirmErasureViewState.info(
          title: localization.accountErasureOpenEmailTitle,
          message: localization.accountErasureOpenEmailMessage,
        );
      });
      return;
    }

    try {
      await _authUseCase.confirmAccountErasure(token: token);
      if (!mounted) return;
      setState(() {
        _state = _ConfirmErasureViewState.success(
          title: localization.accountErasureConfirmedTitle,
          message: localization.accountErasureConfirmedMessage,
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _state = _ConfirmErasureViewState.error(
          title: localization.accountErasureFailedTitle,
          message: AuthUserMessageResolver.resolve(
            error,
            fallback: localization.accountErasureFailedMessage,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localization = AppLocalizations.of(context)!;
    final stateTitle = _state.title.isEmpty
        ? localization.accountErasureLoadingTitle
        : _state.title;
    final stateMessage = _state.message.isEmpty
        ? localization.accountErasureLoadingMessage
        : _state.message;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: _state
                            .accentColor(context)
                            .withValues(alpha: 0.12),
                        child: Icon(
                          _state.icon,
                          color: _state.accentColor(context),
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        stateTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        stateMessage,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          FilledButton(
                            onPressed: () => context.go(RouterPaths.login),
                            child: Text(localization.backToLogin),
                          ),
                          const SizedBox(width: 12),
                          if (_state.showRetry)
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _state =
                                      const _ConfirmErasureViewState.loading();
                                });
                                unawaited(_confirmErasure());
                              },
                              child: Text(localization.tryAgain),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmErasureViewState {
  const _ConfirmErasureViewState._({
    required this.icon,
    required this.title,
    required this.message,
    required this.kind,
    this.showRetry = false,
  });

  const _ConfirmErasureViewState.loading()
    : this._(
        icon: Icons.delete_forever_outlined,
        title: '',
        message: '',
        kind: _ConfirmErasureKind.info,
      );

  const _ConfirmErasureViewState.success({
    required String title,
    required String message,
  }) : this._(
         icon: Icons.delete_forever_outlined,
         title: title,
         message: message,
         kind: _ConfirmErasureKind.success,
       );

  const _ConfirmErasureViewState.info({
    required String title,
    required String message,
  }) : this._(
         icon: Icons.mark_email_unread_outlined,
         title: title,
         message: message,
         kind: _ConfirmErasureKind.info,
       );

  const _ConfirmErasureViewState.error({
    required String title,
    required String message,
  }) : this._(
         icon: Icons.error_outline,
         title: title,
         message: message,
         kind: _ConfirmErasureKind.error,
         showRetry: true,
       );

  final IconData icon;
  final String title;
  final String message;
  final _ConfirmErasureKind kind;
  final bool showRetry;

  Color accentColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (kind) {
      case _ConfirmErasureKind.success:
        return colorScheme.error;
      case _ConfirmErasureKind.error:
        return colorScheme.error;
      case _ConfirmErasureKind.info:
        return colorScheme.primary;
    }
  }
}

enum _ConfirmErasureKind { info, success, error }
