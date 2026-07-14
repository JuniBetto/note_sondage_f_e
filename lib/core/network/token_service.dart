import 'package:shared_preferences/shared_preferences.dart';

/// Servizio per gestire il JWT del backend in modo persistente.
///
/// Dopo il login Firebase, il Firebase ID Token viene scambiato con il backend
/// per ottenere un JWT interno contenente ruoli e permessi specifici dell'app.
/// Questo servizio memorizza/recupera quel JWT con SharedPreferences.
class TokenService {
  static const _backendTokenKey = 'backend_jwt';
  static const _backendTokenOwnerUidKey = 'backend_jwt_owner_uid';

  static TokenService? _instance;
  TokenService._();

  factory TokenService() {
    _instance ??= TokenService._();
    return _instance!;
  }

  /// Salva il JWT ricevuto dal backend e l'UID Firebase a cui appartiene.
  Future<void> saveToken(String token, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backendTokenKey, token);
    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(_backendTokenOwnerUidKey, userId);
    } else {
      await prefs.remove(_backendTokenOwnerUidKey);
    }
  }

  /// Recupera il JWT salvato. Ritorna `null` se non esiste.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backendTokenKey);
  }

  /// Recupera l'UID Firebase proprietario del JWT backend salvato.
  Future<String?> getTokenOwnerUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backendTokenOwnerUidKey);
  }

  /// Recupera il JWT salvato solo se appartiene all'utente Firebase corrente.
  Future<String?> getTokenForUser(String? userId) async {
    if (userId == null || userId.isEmpty) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final ownerUid = prefs.getString(_backendTokenOwnerUidKey);
    if (ownerUid == null || ownerUid.isEmpty || ownerUid != userId) {
      return null;
    }

    final token = prefs.getString(_backendTokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  /// Rimuove il JWT salvato (es. al logout).
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backendTokenKey);
    await prefs.remove(_backendTokenOwnerUidKey);
  }

  /// Verifica se un token è salvato.
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
