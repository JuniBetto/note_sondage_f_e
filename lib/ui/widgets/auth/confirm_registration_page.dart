import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';

class ConfirmRegistrationPage extends StatefulWidget {
  final Map<String, String> queryParameters;

  const ConfirmRegistrationPage({super.key, required this.queryParameters});

  @override
  State<ConfirmRegistrationPage> createState() =>
      _ConfirmRegistrationPageState();
}

class _ConfirmRegistrationPageState extends State<ConfirmRegistrationPage> {
  _ConfirmationViewState _state = const _ConfirmationViewState.loading();

  @override
  void initState() {
    super.initState();
    unawaited(_confirmRegistration());
  }

  Future<void> _confirmRegistration() async {
    final mode = widget.queryParameters['mode'];
    final oobCode = widget.queryParameters['oobCode'];

    if (mode == 'verifyEmail' && oobCode != null && oobCode.isNotEmpty) {
      try {
        await firebase.FirebaseAuth.instance.applyActionCode(oobCode);
        await firebase.FirebaseAuth.instance.currentUser?.reload();
        if (!mounted) return;
        setState(() {
          _state = const _ConfirmationViewState.success(
            title: 'Registrazione confermata',
            message:
                'La tua email e stata confermata con successo. Ora puoi accedere all\'app.',
          );
        });
      } on firebase.FirebaseAuthException catch (error) {
        if (!mounted) return;
        setState(() {
          _state = _ConfirmationViewState.error(
            title: 'Link non valido',
            message: _mapFirebaseError(error),
          );
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _state = const _ConfirmationViewState.error(
            title: 'Conferma non riuscita',
            message:
                'Non siamo riusciti a confermare la registrazione. Prova ad aprire di nuovo il link ricevuto via email.',
          );
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _state = const _ConfirmationViewState.info(
        title: 'Controlla la tua email',
        message:
            'Apri il link ricevuto per confermare la registrazione. Se hai gia completato la conferma, puoi tornare al login.',
      );
    });
  }

  String _mapFirebaseError(firebase.FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-action-code':
        return 'Il link di conferma non e valido o e gia stato usato.';
      case 'expired-action-code':
        return 'Il link di conferma e scaduto. Richiedi una nuova email di verifica.';
      case 'user-disabled':
        return 'Questo account e stato disabilitato.';
      case 'user-not-found':
        return 'Non abbiamo trovato un account associato a questo link.';
      default:
        return error.message ??
            'Si e verificato un problema durante la conferma della registrazione.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                        backgroundColor: _state.accentColor(context)
                            .withValues(alpha: 0.12),
                        child: Icon(
                          _state.icon,
                          color: _state.accentColor(context),
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _state.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _state.message,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          FilledButton(
                            onPressed: () => context.go(RouterPaths.login),
                            child: const Text('Vai al login'),
                          ),
                          const SizedBox(width: 12),
                          if (_state.showRetry)
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _state =
                                      const _ConfirmationViewState.loading();
                                });
                                unawaited(_confirmRegistration());
                              },
                              child: const Text('Riprova'),
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

class _ConfirmationViewState {
  final IconData icon;
  final String title;
  final String message;
  final _ConfirmationKind kind;
  final bool showRetry;

  const _ConfirmationViewState._({
    required this.icon,
    required this.title,
    required this.message,
    required this.kind,
    this.showRetry = false,
  });

  const _ConfirmationViewState.loading()
    : this._(
        icon: Icons.mark_email_read_outlined,
        title: 'Conferma in corso',
        message: 'Stiamo verificando il link di registrazione...',
        kind: _ConfirmationKind.info,
      );

  const _ConfirmationViewState.success({
    required String title,
    required String message,
  }) : this._(
         icon: Icons.verified_outlined,
         title: title,
         message: message,
         kind: _ConfirmationKind.success,
       );

  const _ConfirmationViewState.info({
    required String title,
    required String message,
  }) : this._(
         icon: Icons.mail_outline,
         title: title,
         message: message,
         kind: _ConfirmationKind.info,
       );

  const _ConfirmationViewState.error({
    required String title,
    required String message,
  }) : this._(
         icon: Icons.error_outline,
         title: title,
         message: message,
         kind: _ConfirmationKind.error,
         showRetry: true,
       );

  Color accentColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (kind) {
      _ConfirmationKind.success => Colors.green,
      _ConfirmationKind.error => colorScheme.error,
      _ConfirmationKind.info => colorScheme.primary,
    };
  }
}

enum _ConfirmationKind { success, info, error }
