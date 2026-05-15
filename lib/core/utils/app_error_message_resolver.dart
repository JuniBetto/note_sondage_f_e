import 'package:dio/dio.dart';

class AppErrorMessageResolver {
  const AppErrorMessageResolver._();

  static String resolve(
    Object error, {
    String fallback = 'We could not complete this action. Please try again.',
  }) {
    final dioMessage = _resolveDioException(error, fallback: fallback);
    if (dioMessage != null) {
      return dioMessage;
    }

    final rawMessage = error.toString().trim();
    if (rawMessage.isEmpty) {
      return fallback;
    }

    final normalizedMessage = _stripTechnicalPrefixes(rawMessage);
    if (normalizedMessage.isEmpty) {
      return fallback;
    }

    final lowered = normalizedMessage.toLowerCase();

    if (_isNetworkIssue(lowered)) {
      return 'Check your connection and try again.';
    }

    if (_isTimeoutIssue(lowered)) {
      return 'The request took too long. Please try again.';
    }

    if (_isUnauthorizedIssue(lowered)) {
      return 'Your session has expired. Please sign in again.';
    }

    if (_isForbiddenIssue(lowered)) {
      return 'You do not have permission to perform this action.';
    }

    if (_isConflictIssue(lowered)) {
      return 'This action conflicts with existing data. Please review and try again.';
    }

    if (_isNotFoundIssue(lowered)) {
      return 'We could not find the requested item.';
    }

    if (_isValidationIssue(lowered)) {
      return 'Some information is invalid. Please review it and try again.';
    }

    if (_isServerIssue(lowered)) {
      return 'The service is temporarily unavailable. Please try again shortly.';
    }

    if (_looksTechnical(normalizedMessage)) {
      return fallback;
    }

    return normalizedMessage;
  }

  static String? _resolveDioException(
    Object error, {
    required String fallback,
  }) {
    if (error is! DioException) {
      return null;
    }

    final response = error.response;
    final responseMessage = _extractResponseMessage(response?.data);
    if (responseMessage != null && !_looksTechnical(responseMessage)) {
      final normalized = _stripTechnicalPrefixes(responseMessage);
      if (normalized.isNotEmpty && !_looksTechnical(normalized)) {
        return normalized;
      }
    }

    final statusCode = response?.statusCode;
    if (statusCode != null) {
      if (statusCode == 401) {
        return 'Your session has expired. Please sign in again.';
      }
      if (statusCode == 403) {
        return 'You do not have permission to perform this action.';
      }
      if (statusCode == 404) {
        return 'We could not find the requested item.';
      }
      if (statusCode == 409) {
        return 'This action conflicts with existing data. Please review and try again.';
      }
      if (statusCode == 422) {
        return 'Some information is invalid. Please review it and try again.';
      }
      if (statusCode >= 500) {
        return 'The service is temporarily unavailable. Please try again shortly.';
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The request took too long. Please try again.';
      case DioExceptionType.connectionError:
        return 'Check your connection and try again.';
      case DioExceptionType.cancel:
        return 'The request was cancelled. Please try again.';
      case DioExceptionType.badCertificate:
        return 'A secure connection could not be established. Please try again.';
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }

    final normalized = _stripTechnicalPrefixes(error.toString());
    if (normalized.isEmpty || _looksTechnical(normalized)) {
      return fallback;
    }
    return normalized;
  }

  static String _stripTechnicalPrefixes(String message) {
    var value = message.trim();

    const prefixes = [
      'Exception:',
      'Error:',
      'AuthException:',
      'FirebaseAuthException:',
      'Bad state:',
    ];
    for (final prefix in prefixes) {
      if (value.startsWith(prefix)) {
        value = value.substring(prefix.length).trim();
      }
    }

    const failedPrefixes = [
      'Failed to fetch clocking records:',
      'Failed to fetch clocking records by date:',
      'Failed to fetch clocking records by team:',
      'Failed to clock in:',
      'Failed to clock out:',
      'Failed to start break:',
      'Failed to stop break:',
      'Failed to update team clocking record:',
      'Failed to decommit team clocking record:',
      'Failed to commit team clocking record:',
      'Failed to create team:',
      'Failed to delete team:',
      'Failed to fetch teams:',
      'Failed to fetch team:',
      'Failed to update team:',
      'Failed to create role:',
      'Failed to delete role:',
      'Failed to invite team member:',
      'Failed to delete team member:',
    ];

    var removedPrefix = true;
    while (removedPrefix) {
      removedPrefix = false;
      for (final prefix in failedPrefixes) {
        if (value.startsWith(prefix)) {
          value = value.substring(prefix.length).trim();
          removedPrefix = true;
        }
      }
    }

    if (value.startsWith('DioException')) {
      final separatorIndex = value.indexOf(':');
      if (separatorIndex != -1 && separatorIndex + 1 < value.length) {
        value = value.substring(separatorIndex + 1).trim();
      }
    }

    value = value
        .replaceFirst(
          RegExp(
            r'^This exception was thrown because the response has a status code of \d+\s+and RequestOptions\.validateStatus was configured to throw for this status code\.\s*',
          ),
          '',
        )
        .trim();

    value = value
        .replaceFirst(
          RegExp(
            r'^The status code of \d+ has the following meaning:.*$',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    return value;
  }

  static String? _extractResponseMessage(dynamic data) {
    if (data == null) {
      return null;
    }
    if (data is String) {
      final trimmed = data.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (data is Map) {
      const keys = ['message', 'error', 'detail', 'details', 'description'];
      for (final key in keys) {
        final value = data[key];
        final extracted = _extractResponseMessage(value);
        if (extracted != null && extracted.isNotEmpty) {
          return extracted;
        }
      }
      return null;
    }
    if (data is Iterable) {
      for (final value in data) {
        final extracted = _extractResponseMessage(value);
        if (extracted != null && extracted.isNotEmpty) {
          return extracted;
        }
      }
    }
    return null;
  }

  static bool _isNetworkIssue(String lowered) {
    return lowered.contains('network-request-failed') ||
        lowered.contains('network error') ||
        lowered.contains('socketexception') ||
        lowered.contains('connection error') ||
        lowered.contains('failed host lookup') ||
        lowered.contains('connection refused') ||
        lowered.contains('connection terminated') ||
        lowered.contains('connection closed');
  }

  static bool _isTimeoutIssue(String lowered) {
    return lowered.contains('timed out') ||
        lowered.contains('timeout') ||
        lowered.contains('receive timeout') ||
        lowered.contains('send timeout') ||
        lowered.contains('connection timeout');
  }

  static bool _isUnauthorizedIssue(String lowered) {
    return lowered.contains('401') ||
        lowered.contains('unauthorized') ||
        lowered.contains('not-authenticated') ||
        lowered.contains('jwt expired') ||
        lowered.contains('session has expired') ||
        lowered.contains('token expired');
  }

  static bool _isForbiddenIssue(String lowered) {
    return lowered.contains('403') ||
        lowered.contains('forbidden') ||
        lowered.contains('not allowed') ||
        lowered.contains('permission denied') ||
        lowered.contains('access denied') ||
        lowered.contains('not permitted');
  }

  static bool _isConflictIssue(String lowered) {
    return lowered.contains('409') ||
        lowered.contains('conflict') ||
        lowered.contains('already exists') ||
        lowered.contains('already in use') ||
        lowered.contains('duplicate');
  }

  static bool _isNotFoundIssue(String lowered) {
    return lowered.contains('404') ||
        lowered.contains('not found') ||
        lowered.contains('does not exist');
  }

  static bool _isValidationIssue(String lowered) {
    return lowered.contains('422') ||
        lowered.contains('validation') ||
        lowered.contains('invalid ') ||
        lowered.contains('must not be blank') ||
        lowered.contains('required field') ||
        lowered.contains('missing ');
  }

  static bool _isServerIssue(String lowered) {
    return lowered.contains('500') ||
        lowered.contains('502') ||
        lowered.contains('503') ||
        lowered.contains('504') ||
        lowered.contains('internal server error') ||
        lowered.contains('service unavailable') ||
        lowered.contains('bad gateway');
  }

  static bool _looksTechnical(String message) {
    final lowered = message.toLowerCase();
    return lowered.contains('dioexception') ||
        lowered.contains('firebaseauthexception') ||
        lowered.contains('type \'') ||
        lowered.contains('null is not a subtype') ||
        lowered.contains('stack trace') ||
        lowered.contains('requestoptions.validatestatus') ||
        lowered.contains('the response has a status code of') ||
        lowered.contains('package:') ||
        lowered.contains('instance of ');
  }
}
