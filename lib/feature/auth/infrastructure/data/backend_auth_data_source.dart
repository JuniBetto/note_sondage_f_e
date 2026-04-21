import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:note_sondage/core/network/setup_dio.dart';

/// Data source per scambiare il Firebase ID Token con un JWT del backend.
///
/// Flusso:
/// 1. L'utente si autentica con Firebase (email/password o Google SSO).
/// 2. Si ottiene il Firebase ID Token (`user.getIdToken()`).
/// 3. Si invia il token al backend: `POST /auth/exchange-token`.
/// 4. Il backend verifica il token Firebase, crea/recupera l'utente interno
///    e ritorna un JWT con ruoli e info dell'app.
class BackendAuthDataSource {
  final Dio _dio;

  BackendAuthDataSource({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: DioClient.baseUrl));

  /// Scambia il [firebaseIdToken] con un JWT del backend.
  ///
  /// Il backend si aspetta:
  /// ```json
  /// POST /auth/exchange-token
  /// { "firebaseToken": "<ID_TOKEN>" }
  /// ```
  ///
  /// E ritorna:
  /// ```json
  /// { "token": "<BACKEND_JWT>", "expiresIn": 3600 }
  /// ```
  Future<String> exchangeToken(String firebaseIdToken) async {
    try {
      final response = await _dio.post(
        '/public/api/auth/verify',
        data: {'firebaseToken': firebaseIdToken},
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('token')) {
        return data['token'] as String;
      }

      throw Exception('Invalid response from /public/auth/exchange-token');
    } on DioException catch (e) {
      debugPrint('[BackendAuth] Token exchange failed: ${e.message}');
      throw Exception(
        'Failed to exchange Firebase token with backend: '
        '${e.response?.statusCode ?? 'no status'} – ${e.message}',
      );
    }
  }
}
