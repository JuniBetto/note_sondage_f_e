import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/auth/domain/use_case/auth_use_case.dart';
import 'package:note_sondage/feature/auth/ui/auth_user_message_resolver.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

class ConfirmAccountReactivationPage extends StatefulWidget {
  const ConfirmAccountReactivationPage({
    super.key,
    required this.queryParameters,
  });

  final Map<String, String> queryParameters;

  @override
  State<ConfirmAccountReactivationPage> createState() =>
      _ConfirmAccountReactivationPageState();
}

class _ConfirmAccountReactivationPageState
    extends State<ConfirmAccountReactivationPage> {
  late final AuthUseCase _authUseCase;
  _ConfirmReactivationViewState _state =
      const _ConfirmReactivationViewState.loading();

  @override
  void initState() {
    super.initState();
    _authUseCase = GetIt.instance<AuthUseCase>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_confirmReactivation());
    });
  }

  Future<void> _confirmReactivation() async {
    final status = widget.queryParameters['status']?.trim().toLowerCase();
    final localization = AppLocalizations.of(context)!;

    if (status == 'success') {
      if (!mounted) return;
      setState(() {
        _state = _ConfirmReactivationViewState.success(
          title: localization.accountReactivationConfirmedTitle,
          message: localization.accountReactivationConfirmedMessage,
        );
      });
      return;
    }

    if (status == 'error') {
      if (!mounted) return;
      setState(() {
        _state = _ConfirmReactivationViewState.error(
          title: localization.accountReactivationFailedTitle,
          message: localization.accountReactivationFailedMessage,
        );
      });
      return;
    }

    final token = widget.queryParameters['token']?.trim();

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _state = _ConfirmReactivationViewState.info(
          title: localization.accountReactivationOpenEmailTitle,
          message: localization.accountReactivationOpenEmailMessage,
        );
      });
      return;
    }

    try {
      await _authUseCase.confirmAccountReactivation(token: token);
      if (!mounted) return;
      setState(() {
        _state = _ConfirmReactivationViewState.success(
          title: localization.accountReactivationConfirmedTitle,
          message: localization.accountReactivationConfirmedMessage,
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _state = _ConfirmReactivationViewState.error(
          title: localization.accountReactivationFailedTitle,
          message: AuthUserMessageResolver.resolve(
            error,
            fallback: localization.accountReactivationFailedMessage,
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
        ? localization.accountReactivationLoadingTitle
        : _state.title;
    final stateMessage = _state.message.isEmpty
        ? localization.accountReactivationLoadingMessage
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
                                      const _ConfirmReactivationViewState.loading();
                                });
                                unawaited(_confirmReactivation());
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

class _ConfirmReactivationViewState {
  const _ConfirmReactivationViewState._({
    required this.icon,
    required this.title,
    required this.message,
    required this.kind,
    this.showRetry = false,
  });

  const _ConfirmReactivationViewState.loading()
    : this._(
        icon: Icons.autorenew_rounded,
        title: '',
        message: '',
        kind: _ConfirmReactivationKind.info,
      );

  const _ConfirmReactivationViewState.success({
    required String title,
    required String message,
  }) : this._(
         icon: Icons.check_circle_outline,
         title: title,
         message: message,
         kind: _ConfirmReactivationKind.success,
       );

  const _ConfirmReactivationViewState.info({
    required String title,
    required String message,
  }) : this._(
         icon: Icons.mark_email_unread_outlined,
         title: title,
         message: message,
         kind: _ConfirmReactivationKind.info,
       );

  const _ConfirmReactivationViewState.error({
    required String title,
    required String message,
  }) : this._(
         icon: Icons.error_outline,
         title: title,
         message: message,
         kind: _ConfirmReactivationKind.error,
         showRetry: true,
       );

  final IconData icon;
  final String title;
  final String message;
  final _ConfirmReactivationKind kind;
  final bool showRetry;

  Color accentColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (kind) {
      _ConfirmReactivationKind.success => Colors.green.shade700,
      _ConfirmReactivationKind.error => colorScheme.error,
      _ConfirmReactivationKind.info => colorScheme.primary,
    };
  }
}

enum _ConfirmReactivationKind { success, info, error }
