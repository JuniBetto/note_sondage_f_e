import 'package:note_sondage/core/utils/app_error_message_resolver.dart';
import 'package:note_sondage/feature/auth/infrastructure/repositories/firebase_auth_repository_impl.dart';

class AuthUserMessageResolver {
  const AuthUserMessageResolver._();

  /// Codici che indicano che l'utente ha chiuso il login Google di sua
  /// volontà: non sono errori da mostrare.
  static const _cancellationCodes = {
    'google-sign-in-cancelled',
    'popup-closed-by-user',
  };

  static String resolve(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    return AppErrorMessageResolver.resolve(error, fallback: fallback);
  }

  /// Codice dell'errore di autenticazione (es. `user-disabled`), se presente.
  static String? code(Object error) =>
      error is AuthException ? error.code : null;

  static bool isUserCancellation(Object error) =>
      _cancellationCodes.contains(code(error));

  /// L'account è stato disattivato o eliminato lato server.
  static bool isAccountRevoked(Object error) =>
      AuthException.accountRevokedCodes.contains(code(error));
}
