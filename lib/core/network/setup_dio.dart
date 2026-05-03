import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:note_sondage/core/config/runtime_config.dart';
import 'package:note_sondage/core/network/auth_interceptor.dart';
import 'package:note_sondage/core/network/token_service.dart';

class DioClient {
  static DioClient? _instance;
  final Dio dio;

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

  /// MinIO API port for direct access (only used if bucket is public)
  static String get _minioBaseUrl => 'http://$_host:9002/bucket1';

  /// Resolves an image URL from the server (e.g. MinIO) so it works
  /// on every platform.
  ///
  /// Since MinIO requires authentication (access_key / secret_key),
  /// images are served through the backend API as a proxy.
  ///
  /// The imageUrl from the backend is a relative path like:
  ///   "team_member/{member_id}/{filename}.jpg"
  ///
  /// We build: http://{host}:8001/team-members/{member_id}/profile-image
  static String resolveImageUrl(String url) {
    if (url.isEmpty) return url;

    // Already a full URL – just fix the host
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url
          .replaceAll('localhost', _resolvedHostForAbsoluteUrls)
          .replaceAll('127.0.0.1', _resolvedHostForAbsoluteUrls);
    }

    // Relative path from MinIO: "team_member/{member_id}/{filename}"
    // Route through backend API proxy
    final path = url.startsWith('/') ? url.substring(1) : url;
    final parts = path.split('/');

    // Expected format: team_member/{member_id}/{filename}
    if (parts.length >= 2) {
      final memberId = parts[1]; // second segment is the member_id
      return '$baseUrl/team-members/$memberId/profile-image';
    }

    // Fallback: try direct MinIO URL
    return '$_minioBaseUrl/$path';
  }

  DioClient._(this.dio) {
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
