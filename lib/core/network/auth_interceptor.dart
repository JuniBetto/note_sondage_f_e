import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:note_sondage/core/network/token_service.dart';

/// Interceptor Dio che aggiunge automaticamente il JWT del backend
/// a ogni richiesta HTTP come header `Authorization: Bearer <token>`.
///
/// Se il token non è disponibile (es. utente non loggato), la richiesta
/// viene inviata senza header di autorizzazione.
///
/// Se il backend ritorna 401 (Unauthorized), l'interceptor tenta di:
/// 1. Ottenere un nuovo Firebase ID Token (force refresh).
/// 2. Ri-scambiarlo con il backend per un nuovo JWT.
/// 3. Ripetere la richiesta originale con il nuovo token.
class AuthInterceptor extends Interceptor {
  final TokenService _tokenService;

  AuthInterceptor({TokenService? tokenService})
    : _tokenService = tokenService ?? TokenService();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Non aggiungere il JWT backend alla richiesta che lo genera
    // (evita loop o header inconsistenti durante il token exchange).
    if (options.path.contains('/public/api/auth/verify')) {
      return handler.next(options);
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    var token = await _tokenService.getToken();

    // Sul web l'app puo' risultare autenticata via Firebase prima che il JWT
    // backend sia stato ancora scambiato/salvato. In quel caso proviamo a
    // generarlo on-demand prima di far partire la richiesta protetta.
    if ((token == null || token.isEmpty) && firebaseUser != null) {
      token = await _exchangeFirebaseTokenForBackendJwt(
        baseUrl: options.baseUrl,
        firebaseUser: firebaseUser,
      );
    }

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Aggiunge X-User-Id usando il Firebase UID dell'utente corrente
    if (firebaseUser != null && firebaseUser.uid.isNotEmpty) {
      options.headers['X-User-Id'] = firebaseUser.uid;
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Spring Security puo' restituire 403 quando il JWT backend manca o non e'
    // piu' valido. Gestiamo sia 401 che 403 per riallineare il token backend.
    if ((err.response?.statusCode == 401 || err.response?.statusCode == 403) &&
        err.requestOptions.extra['isRetry'] != true) {
      try {
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          final newToken = await _exchangeFirebaseTokenForBackendJwt(
            baseUrl: err.requestOptions.baseUrl,
            firebaseUser: firebaseUser,
            forceRefreshFirebaseToken: true,
          );

          if (newToken != null && newToken.isNotEmpty) {
            // Riprova la richiesta originale con il nuovo token
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newToken';
            opts.extra['isRetry'] = true;

            final retryResponse = await Dio().fetch(opts);
            return handler.resolve(retryResponse);
          }
        }
      } catch (e) {
        debugPrint('[AuthInterceptor] Token refresh failed: $e');
      }
    }
    handler.next(err);
  }

  Future<String?> _exchangeFirebaseTokenForBackendJwt({
    required String baseUrl,
    required User firebaseUser,
    bool forceRefreshFirebaseToken = false,
  }) async {
    final firebaseToken = await firebaseUser.getIdToken(forceRefreshFirebaseToken);
    if (firebaseToken == null || firebaseToken.isEmpty) {
      return null;
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    final response = await dio.post(
      '/public/api/auth/verify',
      data: {'firebaseToken': firebaseToken},
    );

    if (response.data is! Map<String, dynamic> ||
        !response.data.containsKey('token')) {
      return null;
    }

    final backendToken = response.data['token'] as String;
    await _tokenService.saveToken(backendToken);
    return backendToken;
  }
}
