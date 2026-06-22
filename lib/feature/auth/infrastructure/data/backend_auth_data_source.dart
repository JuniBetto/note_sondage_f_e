import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:note_sondage/core/network/setup_dio.dart';
import 'package:note_sondage/feature/notification/inbox/notification_center_item.dart';
import 'package:note_sondage/feature/notification/preferences/notification_preferences_entity.dart';

/// Data source per scambiare il Firebase ID Token con un JWT del backend.
///
/// Flusso:
/// 1. L'utente si autentica con Firebase (email/password o Google SSO).
/// 2. Si ottiene il Firebase ID Token (`user.getIdToken()`).
/// 3. Si invia il token al backend: `POST /auth/exchange-token`.
/// 4. Il backend verifica il token Firebase, crea/recupera l'utente interno
///    e ritorna un JWT con ruoli e info dell'app.
class BackendAuthDataSource {
  static const _defaultConnectTimeout = Duration(seconds: 15);
  static const _defaultSendTimeout = Duration(seconds: 15);
  static const _defaultReceiveTimeout = Duration(seconds: 45);

  final Dio _dio;
  final Dio _authenticatedDio;

  BackendAuthDataSource({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: DioClient.baseUrl,
              connectTimeout: _defaultConnectTimeout,
              receiveTimeout: _defaultReceiveTimeout,
              sendTimeout: _defaultSendTimeout,
              headers: const {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          ),
      _authenticatedDio = DioClient().dio;

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

  Future<void> requestPasswordReset(String email) async {
    try {
      await _dio.post(
        '/public/api/password-reset/request',
        data: {'email': email},
      );
    } on DioException catch (e) {
      debugPrint('[BackendAuth] Password reset request failed: ${e.message}');
      final responseData = e.response?.data;
      throw Exception(
        'Failed to register password reset request: '
        '${e.response?.statusCode ?? 'no status'} – ${responseData ?? e.message}',
      );
    }
  }

  Future<void> requestAccountDeletion(String email) async {
    try {
      await _dio.post(
        '/public/api/account-deletion/request',
        data: {'email': email},
      );
    } on DioException catch (e) {
      debugPrint('[BackendAuth] Account deletion request failed: ${e.message}');
      final responseData = e.response?.data;
      throw Exception(
        'Failed to request account deletion: '
        '${e.response?.statusCode ?? 'no status'} – ${responseData ?? e.message}',
      );
    }
  }

  Future<Map<String, dynamic>> confirmAccountDeletion(String token) async {
    try {
      final response = await _dio.post(
        '/public/api/account-deletion/confirm',
        data: {'token': token},
      );
      return Map<String, dynamic>.from(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint(
        '[BackendAuth] Account deletion confirmation failed: ${e.message}',
      );
      throw Exception(
        'Failed to confirm account deletion: '
        '${e.response?.statusCode ?? 'no status'} – ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<void> requestAccountReactivation(String email) async {
    try {
      await _dio.post(
        '/public/api/account-deletion/reactivation/request',
        data: {'email': email},
      );
    } on DioException catch (e) {
      debugPrint(
        '[BackendAuth] Account reactivation request failed: ${e.message}',
      );
      final responseData = e.response?.data;
      throw Exception(
        'Failed to request account reactivation: '
        '${e.response?.statusCode ?? 'no status'} – ${responseData ?? e.message}',
      );
    }
  }

  Future<Map<String, dynamic>> confirmAccountReactivation(String token) async {
    try {
      final response = await _dio.post(
        '/public/api/account-deletion/reactivation/confirm',
        data: {'token': token},
      );
      return Map<String, dynamic>.from(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint(
        '[BackendAuth] Account reactivation confirmation failed: ${e.message}',
      );
      throw Exception(
        'Failed to confirm account reactivation: '
        '${e.response?.statusCode ?? 'no status'} – ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<String> uploadProfileImage({
    required String firebaseUid,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(imageBytes, filename: fileName),
      });

      final response = await _authenticatedDio.post(
        '/api/storage/profile-image/user/$firebaseUid',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['path'] != null) {
        return data['path'].toString();
      }

      throw Exception('Invalid response from profile image upload');
    } on DioException catch (e) {
      debugPrint('[BackendAuth] Profile image upload failed: ${e.message}');
      throw Exception(
        'Failed to upload profile image: '
        '${e.response?.statusCode ?? 'no status'} – ${e.message}',
      );
    }
  }

  Future<void> updateMyProfile({
    String? fullName,
    String? avatarUrl,
    String? email,
  }) async {
    try {
      await _authenticatedDio.patch(
        '/api/users/me',
        queryParameters: {
          if (fullName != null && fullName.trim().isNotEmpty)
            'fullName': fullName.trim(),
          if (avatarUrl != null && avatarUrl.trim().isNotEmpty)
            'avatarUrl': avatarUrl.trim(),
          if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        },
      );
    } on DioException catch (e) {
      debugPrint('[BackendAuth] Profile update failed: ${e.message}');
      throw Exception(
        'Failed to update user profile: '
        '${e.response?.statusCode ?? 'no status'} – '
        '${e.response?.data ?? e.message}',
      );
    }
  }

  Future<void> updateContactEmail(String email) async {
    try {
      await _authenticatedDio.patch(
        '/api/users/me/contact-email',
        queryParameters: {'email': email.trim()},
      );
    } on DioException catch (e) {
      debugPrint('[BackendAuth] Contact email update failed: ${e.message}');
      throw Exception(
        'Failed to update contact email: '
        '${e.response?.statusCode ?? 'no status'} – ${e.message}',
      );
    }
  }

  Future<String?> getMyProfileEmail() async {
    final profile = await getMyProfile();
    if (profile == null) return null;

    final email = profile['email']?.toString().trim();
    if (email == null || email.isEmpty) {
      return null;
    }
    return email;
  }

  Future<Map<String, dynamic>?> getMyProfile() async {
    try {
      final response = await _authenticatedDio.get('/api/users/me');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return null;
    } on DioException catch (e) {
      debugPrint('[BackendAuth] Profile fetch failed: ${e.message}');
      return null;
    }
  }

  Future<NotificationPreferencesEntity> getNotificationPreferences() async {
    try {
      final response = await _authenticatedDio.get(
        '/api/users/me/notification-preferences',
      );
      return NotificationPreferencesEntity.fromJson(
        Map<String, dynamic>.from(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      debugPrint(
        '[BackendAuth] Notification preferences fetch failed: ${e.message}',
      );
      throw Exception(
        'Failed to fetch notification preferences: '
        '${e.response?.statusCode ?? 'no status'} – ${e.message}',
      );
    }
  }

  Future<NotificationPreferencesEntity> updateNotificationPreferences(
    NotificationPreferencesEntity preferences,
  ) async {
    try {
      final response = await _authenticatedDio.patch(
        '/api/users/me/notification-preferences',
        data: preferences.toJson(),
      );
      return NotificationPreferencesEntity.fromJson(
        Map<String, dynamic>.from(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      debugPrint(
        '[BackendAuth] Notification preferences update failed: ${e.message}',
      );
      throw Exception(
        'Failed to update notification preferences: '
        '${e.response?.statusCode ?? 'no status'} – ${e.message}',
      );
    }
  }

  Future<void> registerCurrentDevice({
    required String deviceFingerprint,
    String? deviceName,
    String? platform,
    String? clientApp,
    String? pushProvider,
    String? pushToken,
  }) async {
    try {
      await _authenticatedDio.post(
        '/api/users/me/devices',
        data: {
          'deviceFingerprint': deviceFingerprint,
          if (deviceName != null && deviceName.isNotEmpty)
            'deviceName': deviceName,
          if (platform != null && platform.isNotEmpty) 'platform': platform,
          if (clientApp != null && clientApp.isNotEmpty) 'clientApp': clientApp,
          if (pushProvider != null && pushProvider.isNotEmpty)
            'pushProvider': pushProvider,
          if (pushToken != null && pushToken.isNotEmpty) 'pushToken': pushToken,
        },
      );
    } on DioException catch (e) {
      debugPrint('[BackendAuth] Device registration failed: ${e.message}');
      throw Exception(
        'Failed to register current device: '
        '${e.response?.statusCode ?? 'no status'} – ${e.message}',
      );
    }
  }

  Future<List<NotificationCenterItem>> getMyNotifications({
    int limit = 30,
  }) async {
    try {
      final response = await _authenticatedDio.get(
        '/api/aggregate/notifications/me',
        queryParameters: {'limit': limit},
      );
      final list = response.data as List<dynamic>? ?? [];
      return list
          .map(
            (entry) => NotificationCenterItem.fromJson(
              Map<String, dynamic>.from(entry as Map<String, dynamic>),
            ),
          )
          .toList();
    } on DioException catch (e) {
      debugPrint('[BackendAuth] Notifications fetch failed: ${e.message}');
      throw Exception(
        'Failed to fetch notifications: '
        '${e.response?.statusCode ?? 'no status'} – ${e.message}',
      );
    }
  }

  Future<void> acceptTeamInvitationById(String invitationId) async {
    try {
      await _authenticatedDio.patch(
        '/api/aggregate/teams/invitations/$invitationId/accept-self',
      );
    } on DioException catch (e) {
      debugPrint('[BackendAuth] Accept invitation failed: ${e.message}');
      throw Exception(
        'Failed to accept invitation: '
        '${e.response?.statusCode ?? 'no status'} – ${e.message}',
      );
    }
  }

  Future<void> rejectTeamInvitationById(String invitationId) async {
    try {
      await _authenticatedDio.patch(
        '/api/aggregate/teams/invitations/$invitationId/reject-self',
      );
    } on DioException catch (e) {
      debugPrint('[BackendAuth] Reject invitation failed: ${e.message}');
      throw Exception(
        'Failed to reject invitation: '
        '${e.response?.statusCode ?? 'no status'} – ${e.message}',
      );
    }
  }

  Future<void> dismissNotification(String notificationId) async {
    try {
      await _authenticatedDio.post(
        '/api/aggregate/notifications/me/$notificationId/dismiss',
      );
    } on DioException catch (e) {
      debugPrint('[BackendAuth] Notification dismiss failed: ${e.message}');
      throw Exception(
        'Failed to dismiss notification: '
        '${e.response?.statusCode ?? 'no status'} – ${e.message}',
      );
    }
  }

  Future<void> linkInvitationsAfterRegistration(String email) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      return;
    }

    try {
      await _authenticatedDio.post(
        '/api/aggregate/teams/invitations/link',
        queryParameters: {'email': normalizedEmail},
      );
    } on DioException catch (e) {
      debugPrint(
        '[BackendAuth] Invitation link-after-registration failed: ${e.message}',
      );
      throw Exception(
        'Failed to link pending invitations: '
        '${e.response?.statusCode ?? 'no status'} – ${e.message}',
      );
    }
  }

  Future<void> approveClockingRequest({
    required String teamId,
    required String requesterUserId,
    required String requestedDate,
    String? note,
  }) async {
    await _postClockingDecision(
      '/api/aggregate/clocking/approve-clocking-request',
      {
        'teamId': teamId,
        'targetUserId': requesterUserId,
        'date': requestedDate,
        if (note != null && note.isNotEmpty) 'note': note,
      },
      'approve clocking request',
    );
  }

  Future<void> rejectClockingRequest({
    required String teamId,
    required String requesterUserId,
    required String requestedDate,
    String? note,
  }) async {
    await _postClockingDecision(
      '/api/aggregate/clocking/reject-clocking-request',
      {
        'teamId': teamId,
        'targetUserId': requesterUserId,
        'date': requestedDate,
        if (note != null && note.isNotEmpty) 'note': note,
      },
      'reject clocking request',
    );
  }

  Future<void> approveVacationRequest({
    required String teamId,
    required String requesterUserId,
    required String requestedDate,
    String? note,
  }) async {
    await _postClockingDecision(
      '/api/aggregate/clocking/approve-vacation-request',
      {
        'teamId': teamId,
        'targetUserId': requesterUserId,
        'date': requestedDate,
        if (note != null && note.isNotEmpty) 'note': note,
      },
      'approve vacation request',
    );
  }

  Future<void> rejectVacationRequest({
    required String teamId,
    required String requesterUserId,
    required String requestedDate,
    String? note,
  }) async {
    await _postClockingDecision(
      '/api/aggregate/clocking/reject-vacation-request',
      {
        'teamId': teamId,
        'targetUserId': requesterUserId,
        'date': requestedDate,
        if (note != null && note.isNotEmpty) 'note': note,
      },
      'reject vacation request',
    );
  }

  Future<void> approvePermissionRequest({
    required String teamId,
    required String requesterUserId,
    required String requestedDate,
    required String startTime,
    required String endTime,
    String? note,
  }) async {
    await _postClockingDecision(
      '/api/aggregate/clocking/approve-permission-request',
      {
        'teamId': teamId,
        'targetUserId': requesterUserId,
        'date': requestedDate,
        'startTime': startTime,
        'endTime': endTime,
        if (note != null && note.isNotEmpty) 'note': note,
      },
      'approve permission request',
    );
  }

  Future<void> rejectPermissionRequest({
    required String teamId,
    required String requesterUserId,
    required String requestedDate,
    required String startTime,
    required String endTime,
    String? note,
  }) async {
    await _postClockingDecision(
      '/api/aggregate/clocking/reject-permission-request',
      {
        'teamId': teamId,
        'targetUserId': requesterUserId,
        'date': requestedDate,
        'startTime': startTime,
        'endTime': endTime,
        if (note != null && note.isNotEmpty) 'note': note,
      },
      'reject permission request',
    );
  }

  Future<void> approveShiftChangeRequest({
    required String assignmentId,
    required String requesterUserId,
    String? profileId,
    String? startTime,
    String? endTime,
    bool? overnight,
    String? note,
    List<int>? alarmOffsets,
  }) async {
    await _postShiftChangeDecision(
      '/api/aggregate/shift/approve-change-request/$assignmentId',
      {
        'requesterFirebaseUid': requesterUserId,
        if (profileId != null && profileId.isNotEmpty) 'profileId': profileId,
        if (startTime != null && startTime.isNotEmpty) 'startTime': startTime,
        if (endTime != null && endTime.isNotEmpty) 'endTime': endTime,
        if (overnight != null) 'overnight': overnight,
        if (note != null && note.isNotEmpty) 'note': note,
        if (alarmOffsets != null && alarmOffsets.isNotEmpty)
          'alarmOffsets': alarmOffsets,
      },
      'approve shift change request',
    );
  }

  Future<void> rejectShiftChangeRequest({
    required String assignmentId,
    required String requesterUserId,
    String? profileId,
    String? startTime,
    String? endTime,
    bool? overnight,
    String? note,
    List<int>? alarmOffsets,
  }) async {
    await _postShiftChangeDecision(
      '/api/aggregate/shift/reject-change-request/$assignmentId',
      {
        'requesterFirebaseUid': requesterUserId,
        if (profileId != null && profileId.isNotEmpty) 'profileId': profileId,
        if (startTime != null && startTime.isNotEmpty) 'startTime': startTime,
        if (endTime != null && endTime.isNotEmpty) 'endTime': endTime,
        if (overnight != null) 'overnight': overnight,
        if (note != null && note.isNotEmpty) 'note': note,
        if (alarmOffsets != null && alarmOffsets.isNotEmpty)
          'alarmOffsets': alarmOffsets,
      },
      'reject shift change request',
    );
  }

  Future<void> _postClockingDecision(
    String path,
    Map<String, dynamic> data,
    String actionLabel,
  ) async {
    try {
      await _authenticatedDio.post(path, data: data);
    } on DioException catch (e) {
      debugPrint('[BackendAuth] $actionLabel failed: ${e.message}');
      throw Exception(
        'Failed to $actionLabel: '
        '${e.response?.statusCode ?? 'no status'} – ${e.message}',
      );
    }
  }

  Future<void> _postShiftChangeDecision(
    String path,
    Map<String, dynamic> data,
    String actionLabel,
  ) async {
    try {
      await _authenticatedDio.post(path, data: data);
    } on DioException catch (e) {
      debugPrint('[BackendAuth] $actionLabel failed: ${e.message}');
      throw Exception(
        'Failed to $actionLabel: '
        '${e.response?.statusCode ?? 'no status'} – ${e.message}',
      );
    }
  }
}
