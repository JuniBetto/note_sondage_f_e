import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/auth/domain/use_case/auth_use_case.dart';
import 'package:note_sondage/feature/auth/ui/auth_user_message_resolver.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

class ConfirmAccountDeletionPage extends StatefulWidget {
  const ConfirmAccountDeletionPage({super.key, required this.queryParameters});

  final Map<String, String> queryParameters;

  @override
  State<ConfirmAccountDeletionPage> createState() =>
      _ConfirmAccountDeletionPageState();
}

class _ConfirmAccountDeletionPageState
    extends State<ConfirmAccountDeletionPage> {
  late final AuthUseCase _authUseCase;
  _ConfirmDeletionViewState _state = const _ConfirmDeletionViewState.loading();

  @override
  void initState() {
    super.initState();
    _authUseCase = GetIt.instance<AuthUseCase>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_confirmDeletion());
    });
  }

  Future<void> _confirmDeletion() async {
    final status = widget.queryParameters['status']?.trim().toLowerCase();
    final localization = AppLocalizations.of(context)!;

    if (status == 'success') {
      if (!mounted) return;
      setState(() {
        _state = _ConfirmDeletionViewState.success(
          title: localization.accountDeletionConfirmedTitle,
          message: localization.accountDeletionConfirmedMessage,
        );
      });
      return;
    }

    if (status == 'error') {
      if (!mounted) return;
      setState(() {
        _state = _ConfirmDeletionViewState.error(
          title: localization.accountDeletionFailedTitle,
          message: localization.accountDeletionFailedMessage,
        );
      });
      return;
    }

    final token = widget.queryParameters['token']?.trim();

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _state = _ConfirmDeletionViewState.info(
          title: localization.accountDeletionOpenEmailTitle,
          message: localization.accountDeletionOpenEmailMessage,
        );
      });
      return;
    }

    try {
      await _authUseCase.confirmAccountDeletion(token: token);
      if (!mounted) return;
      setState(() {
        _state = _ConfirmDeletionViewState.success(
          title: localization.accountDeletionConfirmedTitle,
          message: localization.accountDeletionConfirmedMessage,
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _state = _ConfirmDeletionViewState.error(
          title: localization.accountDeletionFailedTitle,
          message: AuthUserMessageResolver.resolve(
            error,
            fallback: localization.accountDeletionFailedMessage,
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
        ? localization.accountDeletionLoadingTitle
        : _state.title;
    final stateMessage = _state.message.isEmpty
        ? localization.accountDeletionLoadingMessage
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
                                      const _ConfirmDeletionViewState.loading();
                                });
                                unawaited(_confirmDeletion());
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

class _ConfirmDeletionViewState {
  const _ConfirmDeletionViewState._({
    required this.icon,
    required this.title,
    required this.message,
    required this.kind,
    this.showRetry = false,
  });

  const _ConfirmDeletionViewState.loading()
    : this._(
        icon: Icons.person_off_outlined,
        title: '',
        message: '',
        kind: _ConfirmDeletionKind.info,
      );

  const _ConfirmDeletionViewState.success({
    required String title,
    required String message,
  }) : this._(
         icon: Icons.person_off_outlined,
         title: title,
         message: message,
         kind: _ConfirmDeletionKind.success,
       );

  const _ConfirmDeletionViewState.info({
    required String title,
    required String message,
  }) : this._(
         icon: Icons.mark_email_unread_outlined,
         title: title,
         message: message,
         kind: _ConfirmDeletionKind.info,
       );

  const _ConfirmDeletionViewState.error({
    required String title,
    required String message,
  }) : this._(
         icon: Icons.error_outline,
         title: title,
         message: message,
         kind: _ConfirmDeletionKind.error,
         showRetry: true,
       );

  final IconData icon;
  final String title;
  final String message;
  final _ConfirmDeletionKind kind;
  final bool showRetry;

  Color accentColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (kind) {
      _ConfirmDeletionKind.success => Colors.red.shade700,
      _ConfirmDeletionKind.error => colorScheme.error,
      _ConfirmDeletionKind.info => colorScheme.primary,
    };
  }
}

enum _ConfirmDeletionKind { success, info, error }
