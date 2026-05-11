class AuthUserMessageResolver {
  const AuthUserMessageResolver._();

  static String resolve(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    final rawMessage = error.toString().trim();
    if (rawMessage.isEmpty) {
      return fallback;
    }

    final normalizedMessage = _stripTechnicalPrefixes(rawMessage);
    final lowered = normalizedMessage.toLowerCase();

    if (lowered.contains('user-not-found') ||
        lowered.contains('wrong-password') ||
        lowered.contains('incorrect password') ||
        lowered.contains('no user found')) {
      return 'The email or password is incorrect.';
    }

    if (lowered.contains('no account exists for this email address')) {
      return 'No account exists for this email address.';
    }

    if (lowered.contains('email-already-in-use')) {
      return 'An account already exists with this email address.';
    }

    if (lowered.contains('same name and email') ||
        lowered.contains(
          'another user already exists with the same name and email',
        ) ||
        (lowered.contains('already exists') &&
            lowered.contains('name') &&
            lowered.contains('email')) ||
        (lowered.contains('duplicate') && lowered.contains('email')) ||
        (lowered.contains('409') && lowered.contains('email')) ||
        (lowered.contains('conflict') && lowered.contains('email'))) {
      return 'An account with the same name and email already exists.';
    }

    if (lowered.contains('invalid-email')) {
      return 'Enter a valid email address.';
    }

    if (lowered.contains('weak-password')) {
      return 'Choose a stronger password before continuing.';
    }

    if (lowered.contains('verify your email address') ||
        lowered.contains('email not verified') ||
        lowered.contains('unverified-email')) {
      return 'Verify your email address first, then try again.';
    }

    if (lowered.contains('network-request-failed') ||
        lowered.contains('network error') ||
        lowered.contains('socketexception') ||
        lowered.contains('connection error') ||
        lowered.contains('failed host lookup') ||
        lowered.contains('timed out')) {
      return 'Check your connection and try again.';
    }

    if (lowered.contains('too-many-requests') ||
        lowered.contains('too many attempts')) {
      return 'Too many attempts for now. Please wait a moment and try again.';
    }

    if (lowered.contains('invalid-phone-number')) {
      return 'Enter a valid phone number, including the country code.';
    }

    if (lowered.contains('invalid-verification-code')) {
      return 'The verification code is not correct. Please try again.';
    }

    if (lowered.contains('invalid-verification-id') ||
        lowered.contains('phone-session-expired') ||
        lowered.contains('session-expired') ||
        lowered.contains('no pending two-factor sign-in challenge')) {
      return 'This verification session expired. Request a new code and try again.';
    }

    if (lowered.contains('missing-sms-code')) {
      return 'Enter the verification code you received.';
    }

    if (lowered.contains('unsupported-second-factor')) {
      return 'This account does not have a supported second verification method.';
    }

    if (lowered.contains('requires-recent-login')) {
      return 'For security reasons, sign in again before changing two-factor authentication.';
    }

    if (lowered.contains('second-factor-already-in-use')) {
      return 'This phone number is already being used for two-factor authentication.';
    }

    if (lowered.contains('maximum-second-factor-count-exceeded')) {
      return 'You have reached the maximum number of verification methods for this account.';
    }

    if (lowered.contains('google sign-in was cancelled') ||
        lowered.contains('google-sign-in-cancelled')) {
      return 'Google sign-in was cancelled.';
    }

    if (lowered.contains('google sign-in failed') ||
        lowered.contains('google-sign-in-failed')) {
      return 'We could not complete Google sign-in right now. Please try again.';
    }

    if (lowered.contains('failed to update user profile')) {
      return 'We could not save your profile right now. Please try again.';
    }

    if (lowered.contains('failed to update contact email')) {
      return 'We could not save the invitation email right now. Please try again.';
    }

    if (lowered.contains('failed to register password reset request')) {
      return 'We could not start the password reset right now. Please try again.';
    }

    if (lowered.contains('failed to exchange firebase token with backend') ||
        lowered.contains('unable to complete sign-in right now') ||
        lowered.contains('backend-auth-failed')) {
      return 'We could not complete the sign-in right now. Please try again.';
    }

    if (lowered.contains('not-authenticated') ||
        lowered.contains('need to be signed in')) {
      return 'Your session has expired. Please sign in again.';
    }

    if (lowered.contains('operation-not-allowed')) {
      return 'This action is not available right now.';
    }

    if (_looksTechnical(normalizedMessage)) {
      return fallback;
    }

    return normalizedMessage;
  }

  static String _stripTechnicalPrefixes(String message) {
    var value = message.trim();

    const prefixes = [
      'Exception:',
      'Error:',
      'AuthException:',
      'FirebaseAuthException:',
    ];
    for (final prefix in prefixes) {
      if (value.startsWith(prefix)) {
        value = value.substring(prefix.length).trim();
      }
    }

    if (value.startsWith('DioException')) {
      final separatorIndex = value.indexOf(':');
      if (separatorIndex != -1 && separatorIndex + 1 < value.length) {
        value = value.substring(separatorIndex + 1).trim();
      }
    }

    return value;
  }

  static bool _looksTechnical(String message) {
    final lowered = message.toLowerCase();
    return lowered.contains('dioexception') ||
        lowered.contains('firebaseauthexception') ||
        lowered.contains('type \'') ||
        lowered.contains('null is not a subtype') ||
        lowered.contains('stack trace') ||
        lowered.contains('status}') ||
        lowered.contains('package:');
  }
}
