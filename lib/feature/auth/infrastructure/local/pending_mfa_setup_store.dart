import 'package:shared_preferences/shared_preferences.dart';

class PendingMfaSetupStore {
  static const _emailKey = 'pending_mfa_setup_email';
  static const _phoneKey = 'pending_mfa_setup_phone';

  Future<void> save({
    required String email,
    required String phoneNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email.trim().toLowerCase());
    await prefs.setString(_phoneKey, phoneNumber.trim());
  }

  Future<String?> loadPhoneNumberForEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString(_emailKey)?.trim().toLowerCase();
    if (storedEmail != email.trim().toLowerCase()) {
      return null;
    }
    final phoneNumber = prefs.getString(_phoneKey)?.trim();
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return null;
    }
    return phoneNumber;
  }

  Future<void> clearForEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString(_emailKey)?.trim().toLowerCase();
    if (storedEmail != email.trim().toLowerCase()) {
      return;
    }
    await prefs.remove(_emailKey);
    await prefs.remove(_phoneKey);
  }
}
