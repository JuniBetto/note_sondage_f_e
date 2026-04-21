import 'package:shared_preferences/shared_preferences.dart';

/// Servizio per gestire il JWT del backend in modo persistente.
///
/// Dopo il login Firebase, il Firebase ID Token viene scambiato con il backend
/// per ottenere un JWT interno contenente ruoli e permessi specifici dell'app.
/// Questo servizio memorizza/recupera quel JWT con SharedPreferences.
class TokenService {
  static const _backendTokenKey = 'backend_jwt';

  static TokenService? _instance;
  TokenService._();

  factory TokenService() {
    _instance ??= TokenService._();
    return _instance!;
  }

  /// Salva il JWT ricevuto dal backend.
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backendTokenKey, token);
  }

  /// Recupera il JWT salvato. Ritorna `null` se non esiste.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backendTokenKey);
  }

  /// Rimuove il JWT salvato (es. al logout).
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backendTokenKey);
  }

  /// Verifica se un token è salvato.
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
