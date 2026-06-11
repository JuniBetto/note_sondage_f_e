import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:note_sondage/core/config/runtime_config.dart';
import 'package:note_sondage/core/network/auth_interceptor.dart';
import 'package:note_sondage/core/network/token_service.dart';

class DioClient {
  static DioClient? _instance;
  final Dio dio;

  static void debugWarnIfMisconfiguredForPlatform() {
    if (kIsWeb || !RuntimeConfig.hasCustomApiBaseUrl) {
      return;
    }

    final configuredUri = Uri.tryParse(RuntimeConfig.resolvedApiBaseUrl);
    final configuredHost = configuredUri?.host;
    if (configuredHost == null || configuredHost.isEmpty) {
      return;
    }

    if (Platform.isIOS && configuredHost == '10.0.2.2') {
      debugPrint(
        '[DioClient] API_BASE_URL points to 10.0.2.2 on iOS. '
        '10.0.2.2 is the Android emulator loopback alias. '
        'Use your Mac/host LAN IP or 127.0.0.1 only when the backend runs on the same Mac.',
      );
    }
  }

  static String get _scheme {
    if (kIsWeb) {
      return Uri.base.scheme == 'https' ? 'https' : 'http';
    }
    return 'http';
  }

  /// The host to use depending on platform
  static String get _host {
    if (kIsWeb) {
      final host = Uri.base.host;
      return host.isNotEmpty ? host : '127.0.0.1';
    }
    if (Platform.isAndroid) return '10.0.2.2';
    return '127.0.0.1';
  }

  static String get _resolvedHostForAbsoluteUrls {
    if (RuntimeConfig.hasCustomApiBaseUrl) {
      final configuredHost = Uri.tryParse(
        RuntimeConfig.resolvedApiBaseUrl,
      )?.host;
      if (configuredHost != null && configuredHost.isNotEmpty) {
        return configuredHost;
      }
    }
    return _host;
  }

  /// Returns the correct base URL depending on the platform:
  /// - Web / iOS / macOS / desktop: http://127.0.0.1:8081
  /// - Android emulator:            http://10.0.2.2:8081
  static String get baseUrl {
    if (RuntimeConfig.hasCustomApiBaseUrl) {
      return RuntimeConfig.resolvedApiBaseUrl;
    }
    return '$_scheme://$_host:8080';
  }

  static bool usesAuthenticatedImageProxy(String url) {
    if (url.isEmpty) return false;
    return !(url.startsWith('http://') || url.startsWith('https://'));
  }

  static Future<Map<String, String>?> resolveImageHeaders(String url) async {
    if (!usesAuthenticatedImageProxy(url)) {
      return null;
    }

    final token = await TokenService().getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    return {'Authorization': 'Bearer $token'};
  }

  /// Resolves a server-side image path to a URL that works across platforms.
  ///
  /// Relative paths like `user/{uid}/{file}.jpg` or
  /// `team_member/{id}/{file}.jpg` are private MinIO objects and must be
  /// fetched through the authenticated backend gateway.
  static String resolveImageUrl(String url) {
    if (url.isEmpty) return url;

    // Already a full URL – just fix the host
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url
          .replaceAll('localhost', _resolvedHostForAbsoluteUrls)
          .replaceAll('127.0.0.1', _resolvedHostForAbsoluteUrls);
    }

    final path = url.startsWith('/') ? url.substring(1) : url;
    final encodedPath = Uri.encodeQueryComponent(path);
    return '$baseUrl/api/storage/file?path=$encodedPath';
  }

  DioClient._(this.dio) {
    debugWarnIfMisconfiguredForPlatform();

    // Interceptor per autenticazione: aggiunge il JWT del backend a ogni richiesta
    dio.interceptors.add(AuthInterceptor(tokenService: TokenService()));

    // Aggiungi interceptors nel costruttore privato
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  factory DioClient({Dio? dio}) {
    _instance ??= DioClient._(
      dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          ),
    );
    return _instance!;
  }
}
