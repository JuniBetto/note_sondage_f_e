import 'package:flutter/material.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/auth/domain/entities/phone_sign_in_start_result.dart';
import 'package:note_sondage/feature/auth/domain/use_case/auth_use_case.dart';
import 'package:note_sondage/feature/auth/ui/auth_user_message_resolver.dart';

class MfaEnrollmentDialog extends StatefulWidget {
  const MfaEnrollmentDialog({super.key, this.initialPhoneNumber});

  final String? initialPhoneNumber;

  @override
  State<MfaEnrollmentDialog> createState() => _MfaEnrollmentDialogState();
}

class _MfaEnrollmentDialogState extends State<MfaEnrollmentDialog> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _labelController = TextEditingController(text: 'Primary phone');
  final _authUseCase = getIt<AuthUseCase>();

  bool _isLoading = false;
  String? _verificationId;
  String? _errorMessage;

  bool get _awaitingCode => _verificationId != null;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.initialPhoneNumber?.trim() ?? '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _labelController.dispose();
    super.dispose();
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

  Future<void> _confirmCode() async {
    final smsCode = _codeController.text.trim();
    if (_verificationId == null || smsCode.isEmpty) {
      setState(() {
        _errorMessage = 'Enter the verification code you received.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authUseCase.confirmSmsMfaEnrollment(
        sessionId: _verificationId!,
        smsCode: smsCode,
        displayName: _labelController.text.trim(),
      );
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _awaitingCode
            ? 'Confirm two-factor setup'
            : 'Enable two-factor authentication',
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _awaitingCode
                  ? 'Enter the verification code sent to your phone.'
                  : 'Add a phone number that will receive a verification code when you sign in.',
            ),
            const SizedBox(height: 16),
            if (!_awaitingCode) ...[
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
            if (_awaitingCode)
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
            if (_awaitingCode == false && _errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
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
              : (_awaitingCode ? _confirmCode : _sendCode),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_awaitingCode ? 'Enable' : 'Send code'),
        ),
      ],
    );
  }
}
