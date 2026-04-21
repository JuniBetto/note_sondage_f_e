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
    // Non aggiungere token alle richieste di exchange-token (evita loop)
    if (options.path.contains('/auth/exchange-token')) {
      return handler.next(options);
    }

    final token = await _tokenService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Se 401 e non è già un retry, tenta di refreshare il token
    if (err.response?.statusCode == 401 &&
        err.requestOptions.extra['isRetry'] != true) {
      try {
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          // Force refresh del Firebase ID Token
          final newFirebaseToken = await firebaseUser.getIdToken(true);

          if (newFirebaseToken != null) {
            // Ri-scambia con il backend
            final dio = Dio(BaseOptions(baseUrl: err.requestOptions.baseUrl));
            final response = await dio.post(
              '/auth/exchange-token',
              data: {'firebaseToken': newFirebaseToken},
            );

            if (response.data is Map<String, dynamic> &&
                response.data.containsKey('token')) {
              final newToken = response.data['token'] as String;
              await _tokenService.saveToken(newToken);

              // Riprova la richiesta originale con il nuovo token
              final opts = err.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newToken';
              opts.extra['isRetry'] = true;

              final retryResponse = await Dio().fetch(opts);
              return handler.resolve(retryResponse);
            }
          }
        }
      } catch (e) {
        debugPrint('[AuthInterceptor] Token refresh failed: $e');
      }
    }
    handler.next(err);
  }
}
