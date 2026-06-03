import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/auth/domain/entities/mfa_factor_hint_entity.dart';
import 'package:note_sondage/feature/auth/domain/entities/phone_sign_in_start_result.dart';
import 'package:note_sondage/feature/auth/domain/entities/totp_enrollment_secret_entity.dart';
import 'package:note_sondage/feature/auth/domain/use_case/auth_use_case.dart';
import 'package:note_sondage/feature/auth/ui/auth_user_message_resolver.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/auth/totp_qr_code.dart';

enum _MfaEnrollmentMethod { sms, totp }

const bool _showSmsEnrollmentOption = false;

class MfaEnrollmentDialog extends StatefulWidget {
  const MfaEnrollmentDialog({
    super.key,
    this.initialPhoneNumber,
    this.initialMethod = MfaFactorType.sms,
  });

  final String? initialPhoneNumber;
  final MfaFactorType initialMethod;

  @override
  State<MfaEnrollmentDialog> createState() => _MfaEnrollmentDialogState();
}

class _MfaEnrollmentDialogState extends State<MfaEnrollmentDialog> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _labelController = TextEditingController(text: 'Primary phone');
  final _authUseCase = getIt<AuthUseCase>();

  _MfaEnrollmentMethod _selectedMethod = _MfaEnrollmentMethod.sms;
  bool _isLoading = false;
  String? _verificationId;
  TotpEnrollmentSecretEntity? _totpSecret;
  String? _errorMessage;

  bool get _awaitingSmsCode => _verificationId != null;
  bool get _awaitingTotpCode => _totpSecret != null;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.initialPhoneNumber?.trim() ?? '';
    _selectedMethod =
        !_showSmsEnrollmentOption || widget.initialMethod == MfaFactorType.totp
        ? _MfaEnrollmentMethod.totp
        : _MfaEnrollmentMethod.sms;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _switchMethod(_MfaEnrollmentMethod method) {
    if (_selectedMethod == method) {
      return;
    }
    setState(() {
      _selectedMethod = method;
      _verificationId = null;
      _totpSecret = null;
      _codeController.clear();
      _errorMessage = null;
    });
  }

  Future<void> _sendCode() async {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Enter your phone number, including country code.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final PhoneSignInStartResult result = await _authUseCase
          .startSmsMfaEnrollment(phoneNumber: phoneNumber);
      if (!mounted) return;

      if (result.sessionId == null) {
        throw Exception('Unable to start two-factor enrollment.');
      }

      setState(() {
        _verificationId = result.sessionId;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AuthUserMessageResolver.resolve(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateTotpSetup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final secret = await _authUseCase.startTotpMfaEnrollment(
        accountName: null,
        issuer: 'NoteSondage',
      );
      if (!mounted) return;
      setState(() {
        _totpSecret = secret;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AuthUserMessageResolver.resolve(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final verificationCode = _codeController.text.trim();
      if (_selectedMethod == _MfaEnrollmentMethod.sms) {
        if (_verificationId == null || verificationCode.isEmpty) {
          setState(() {
            _errorMessage = 'Enter the verification code you received.';
          });
          return;
        }
        await _authUseCase.confirmSmsMfaEnrollment(
          sessionId: _verificationId!,
          smsCode: verificationCode,
          displayName: _labelController.text.trim(),
        );
      } else {
        if (verificationCode.isEmpty) {
          setState(() {
            _errorMessage =
                'Enter the verification code from your authenticator app.';
          });
          return;
        }
        await _authUseCase.confirmTotpMfaEnrollment(
          verificationCode: verificationCode,
          displayName: _resolvedTotpDisplayName,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AuthUserMessageResolver.resolve(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String get _resolvedTotpDisplayName {
    final label = _labelController.text.trim();
    return label.isEmpty ? 'Authenticator app' : label;
  }

  Future<void> _copySecretKey() async {
    final secretKey = _totpSecret?.secretKey;
    if (secretKey == null || secretKey.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: secretKey));
    if (!mounted) return;
    AppSnackBar.showSuccess(
      context,
      'The setup key has been copied. You can paste it into your authenticator app.',
      title: 'Setup key copied',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSms =
        _showSmsEnrollmentOption && _selectedMethod == _MfaEnrollmentMethod.sms;
    return AlertDialog(
      title: Text(
        (isSms ? _awaitingSmsCode : _awaitingTotpCode)
            ? 'Confirm two-factor setup'
            : 'Enable two-factor authentication',
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _showSmsEnrollmentOption
                    ? 'Choose the verification method you want to add to your account.'
                    : 'Use an authenticator app to protect your account with a second verification step.',
              ),
              const SizedBox(height: 16),
              if (_showSmsEnrollmentOption)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text('SMS'),
                      selected: isSms,
                      onSelected: _isLoading
                          ? null
                          : (_) => _switchMethod(_MfaEnrollmentMethod.sms),
                    ),
                    ChoiceChip(
                      label: const Text('Authenticator app'),
                      selected: !isSms,
                      onSelected: _isLoading
                          ? null
                          : (_) => _switchMethod(_MfaEnrollmentMethod.totp),
                    ),
                  ],
                ),
              if (_showSmsEnrollmentOption) const SizedBox(height: 8),
              Text(
                isSms
                    ? (_awaitingSmsCode
                          ? 'Enter the verification code sent to your phone.'
                          : 'Add a phone number that will receive a verification code when you sign in.')
                    : (_awaitingTotpCode
                          ? 'Scan the QR code with Google Authenticator or another app, then enter the current code.'
                          : 'Use an authenticator app like Google Authenticator, 1Password or Authy.'),
              ),
              const SizedBox(height: 16),
              if (isSms && !_awaitingSmsCode) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Phone number',
                    hintText: '+39 333 123 4567',
                    errorText: _errorMessage,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Label (optional)',
                    hintText: 'Primary phone',
                  ),
                ),
              ],
              if (isSms && _awaitingSmsCode)
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'SMS code',
                    hintText: '123456',
                    errorText: _errorMessage,
                  ),
                ),
              if (!isSms) ...[
                TextField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    hintText: 'Authenticator app',
                  ),
                ),
                const SizedBox(height: 16),
                if (_totpSecret != null) ...[
                  Center(child: TotpQrCode(data: _totpSecret!.qrCodeUrl)),
                  const SizedBox(height: 16),
                  Text(
                    'If you cannot scan the QR code, use this setup key manually:',
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      _totpSecret!.secretKey,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _copySecretKey,
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy setup key'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Authenticator code',
                      hintText: '123456',
                      errorText: _errorMessage,
                    ),
                  ),
                ],
              ],
              if ((isSms && !_awaitingSmsCode) ||
                  (!isSms && !_awaitingTotpCode)) ...[
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
              if ((isSms && _awaitingSmsCode) ||
                  (!isSms && _awaitingTotpCode)) ...[
                const SizedBox(height: 12),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading
              ? null
              : isSms
              ? (_awaitingSmsCode ? _confirmCode : _sendCode)
              : (_awaitingTotpCode ? _confirmCode : _generateTotpSetup),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  isSms
                      ? (_awaitingSmsCode ? 'Enable' : 'Send code')
                      : (_awaitingTotpCode ? 'Enable' : 'Generate setup'),
                ),
        ),
      ],
    );
  }
}
