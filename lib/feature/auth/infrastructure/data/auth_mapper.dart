import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:note_sondage/feature/auth/domain/entities/auth_user_entity.dart';

/// Mapper per convertire Firebase User → AuthUserEntity.
class AuthMapper {
  /// Converte un [firebase.User] in [AuthUserEntity].
  static AuthUserEntity fromFirebaseUser(firebase.User? user) {
    if (user == null) return AuthUserEntity.empty;

    return AuthUserEntity(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
      phoneNumber: user.phoneNumber,
      provider: _extractProvider(user),
    );
  }

  /// Estrae il provider principale dall'utente Firebase.
  static AuthProvider _extractProvider(firebase.User user) {
    if (user.providerData.isEmpty) return AuthProvider.email;

    final providerId = user.providerData.first.providerId;
    switch (providerId) {
      case 'google.com':
        return AuthProvider.google;
      case 'apple.com':
        return AuthProvider.apple;
      case 'password':
        return AuthProvider.email;
      default:
        return AuthProvider.email;
    }
  }
}
