import 'package:note_sondage/feature/auth/domain/entities/user_device_entity.dart';

class PushDiagnosticsSnapshot {
  const PushDiagnosticsSnapshot({
    required this.supportsPushPlatform,
    required this.serviceAvailable,
    required this.platformLabel,
    required this.apiBaseUrl,
    required this.hasCustomApiBaseUrl,
    required this.authorizationStatus,
    required this.notificationsAuthorized,
    required this.userId,
    required this.apnsToken,
    required this.fcmToken,
    required this.deviceFingerprint,
    required this.cachedRegisteredUserId,
    required this.cachedRegisteredToken,
    required this.cachedRegisteredAt,
    required this.backendDevices,
    required this.lastRegistrationError,
    required this.backendFetchError,
  });

  final bool supportsPushPlatform;
  final bool serviceAvailable;
  final String platformLabel;
  final String apiBaseUrl;
  final bool hasCustomApiBaseUrl;
  final String authorizationStatus;
  final bool notificationsAuthorized;
  final String? userId;
  final String? apnsToken;
  final String? fcmToken;
  final String? deviceFingerprint;
  final String? cachedRegisteredUserId;
  final String? cachedRegisteredToken;
  final DateTime? cachedRegisteredAt;
  final List<UserDeviceEntity> backendDevices;
  final String? lastRegistrationError;
  final String? backendFetchError;

  bool get hasApnsToken => (apnsToken?.isNotEmpty ?? false);
  bool get hasFcmToken => (fcmToken?.isNotEmpty ?? false);
  bool get isUsingFallbackApiBaseUrl => !hasCustomApiBaseUrl;
  bool get isUsingLoopbackOrEmulatorHost {
    final uri = Uri.tryParse(apiBaseUrl);
    final host = uri?.host.trim().toLowerCase() ?? '';
    if (host.isEmpty) {
      return false;
    }
    return host == '127.0.0.1' ||
        host == 'localhost' ||
        host == '::1' ||
        host == '10.0.2.2';
  }

  bool get hasBackendMatchingDevice {
    final fingerprint = deviceFingerprint?.trim();
    if (fingerprint == null || fingerprint.isEmpty) {
      return false;
    }
    return backendDevices.any(
      (device) => device.deviceFingerprint?.trim() == fingerprint,
    );
  }

  String get apnsTokenPreview => _tokenPreview(apnsToken);
  String get fcmTokenPreview => _tokenPreview(fcmToken);
  String get cachedTokenPreview => _tokenPreview(cachedRegisteredToken);

  static String _tokenPreview(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'missing';
    }
    if (normalized.length <= 18) {
      return normalized;
    }
    return '${normalized.substring(0, 10)}...${normalized.substring(normalized.length - 6)}';
  }
}
