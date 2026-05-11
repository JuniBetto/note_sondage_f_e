import 'package:shared_preferences/shared_preferences.dart';

import 'package:note_sondage/feature/auth/domain/entities/mfa_factor_hint_entity.dart';

class PendingMfaSetupPreference {
  const PendingMfaSetupPreference({required this.method, this.phoneNumber});

  final MfaFactorType method;
  final String? phoneNumber;

  bool get usesSms => method == MfaFactorType.sms;
  bool get usesTotp => method == MfaFactorType.totp;
}

class PendingMfaSetupStore {
  static const _emailKey = 'pending_mfa_setup_email';
  static const _phoneKey = 'pending_mfa_setup_phone';
  static const _methodKey = 'pending_mfa_setup_method';

  Future<void> save({
    required String email,
    required MfaFactorType method,
    String? phoneNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email.trim().toLowerCase());
    await prefs.setString(_methodKey, method.name);
    final normalizedPhone = phoneNumber?.trim();
    if (normalizedPhone != null && normalizedPhone.isNotEmpty) {
      await prefs.setString(_phoneKey, normalizedPhone);
    } else {
      await prefs.remove(_phoneKey);
    }
  }

  Future<PendingMfaSetupPreference?> loadForEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString(_emailKey)?.trim().toLowerCase();
    if (storedEmail != email.trim().toLowerCase()) {
      return null;
    }

    final methodName = prefs.getString(_methodKey)?.trim().toLowerCase();
    final method = switch (methodName) {
      'totp' => MfaFactorType.totp,
      _ => MfaFactorType.sms,
    };
    final phoneNumber = prefs.getString(_phoneKey)?.trim();

    if (method == MfaFactorType.sms &&
        (phoneNumber == null || phoneNumber.isEmpty)) {
      return null;
    }

    return PendingMfaSetupPreference(
      method: method,
      phoneNumber: phoneNumber == null || phoneNumber.isEmpty
          ? null
          : phoneNumber,
    );
  }

  Future<void> clearForEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString(_emailKey)?.trim().toLowerCase();
    if (storedEmail != email.trim().toLowerCase()) {
      return;
    }
    await prefs.remove(_emailKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_methodKey);
  }
}
