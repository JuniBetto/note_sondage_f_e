import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/ui/app_keys.dart';
import 'package:note_sondage/ui/mobile/widgets/login/login_mobile.dart';
import 'package:note_sondage/ui/web/login/login_web.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

/// La pagina "Oops!" mostrata all'utente per un errore fatale
/// che non è stato gestito.
class ErrorPage extends StatelessWidget {
  final String? error;

  const ErrorPage({super.key, this.error});

  Future<void> _handleGoBack(BuildContext context) async {
    final localNavigator = Navigator.of(context);
    if (localNavigator.canPop()) {
      await localNavigator.maybePop();
      return;
    }

    final rootNavigator = navigatorKey.currentState;
    if (rootNavigator != null && rootNavigator.canPop()) {
      await rootNavigator.maybePop();
      return;
    }

    final authBloc = GetIt.instance<AuthBloc>();
    authBloc.add(const AuthLogoutRequested());

    if (!context.mounted) {
      return;
    }

    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(RouterPaths.login);
      return;
    }

    rootNavigator?.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => kIsWeb ? const LoginWeb() : const LoginMobile(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                "Oops! Qualcosa è andato storto.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Abbiamo notificato il nostro team. Per favore, prova a riavviare l'app.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _handleGoBack(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(localization.goBack),
              ),
              // Mostra i dettagli dell'errore solo in modalità DEBUG
              if (kDebugMode && error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ExpansionTile(
                    title: Text(localization.errorDetailsDebug),
                    children: [
                      Text(error!, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
