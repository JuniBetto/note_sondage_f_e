import 'package:flutter/material.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/auth/domain/use_case/auth_use_case.dart';
import 'package:note_sondage/feature/auth/domain/entities/phone_sign_in_start_result.dart';
import 'package:note_sondage/feature/auth/ui/auth_user_message_resolver.dart';

class PhoneSignInDialog extends StatefulWidget {
  const PhoneSignInDialog({super.key});

  @override
  State<PhoneSignInDialog> createState() => _PhoneSignInDialogState();
}

class _PhoneSignInDialogState extends State<PhoneSignInDialog> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final AuthUseCase _authUseCase = getIt<AuthUseCase>();

  bool _isLoading = false;
  String? _sessionId;
  String? _errorMessage;

  bool get _awaitingCode => _sessionId != null;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
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
      final PhoneSignInStartResult result = await _authUseCase.startPhoneSignIn(
        phoneNumber: phone,
      );
      if (!mounted) return;

      if (result.requiresSmsCode && result.sessionId != null) {
        setState(() {
          _sessionId = result.sessionId;
        });
        return;
      }

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

  Future<void> _confirmCode() async {
    final code = _codeController.text.trim();
    if (_sessionId == null || code.isEmpty) {
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
      await _authUseCase.confirmPhoneSignIn(
        sessionId: _sessionId!,
        smsCode: code,
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
        _awaitingCode ? 'Enter verification code' : 'Continue with phone',
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _awaitingCode
                  ? 'We sent an SMS code to your phone number.'
                  : 'Use your phone number to receive a one-time verification code.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _awaitingCode ? _codeController : _phoneController,
              keyboardType: _awaitingCode
                  ? TextInputType.number
                  : TextInputType.phone,
              autofocus: true,
              decoration: InputDecoration(
                labelText: _awaitingCode ? 'SMS code' : 'Phone number',
                hintText: _awaitingCode ? '123456' : '+39 333 123 4567',
                errorText: _errorMessage,
              ),
            ),
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
              : (_awaitingCode ? _confirmCode : _requestCode),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_awaitingCode ? 'Verify' : 'Send code'),
        ),
      ],
    );
  }
}
