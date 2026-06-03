import 'package:flutter/material.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/auth/domain/entities/mfa_factor_hint_entity.dart';
import 'package:note_sondage/feature/auth/domain/entities/phone_sign_in_start_result.dart';
import 'package:note_sondage/feature/auth/domain/use_case/auth_use_case.dart';
import 'package:note_sondage/feature/auth/ui/auth_user_message_resolver.dart';

class MfaSignInDialog extends StatefulWidget {
  const MfaSignInDialog({super.key, required this.factors});

  final List<MfaFactorHintEntity> factors;

  @override
  State<MfaSignInDialog> createState() => _MfaSignInDialogState();
}

class _MfaSignInDialogState extends State<MfaSignInDialog> {
  final _codeController = TextEditingController();
  final _authUseCase = getIt<AuthUseCase>();

  bool _isLoading = false;
  String? _verificationId;
  String? _errorMessage;
  bool _isCollectingCode = false;
  late MfaFactorHintEntity _selectedFactor;

  bool get _awaitingCode => _isCollectingCode;

  @override
  void initState() {
    super.initState();
    _selectedFactor = widget.factors.first;
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_selectedFactor.isTotp) {
      setState(() {
        _errorMessage = null;
        _verificationId = null;
        _isCollectingCode = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final PhoneSignInStartResult result = await _authUseCase
          .requestPendingMfaSignInCode(factorUid: _selectedFactor.uid);
      if (!mounted) return;

      if (result.sessionId == null) {
        throw Exception('Unable to start the second-factor challenge.');
      }

      setState(() {
        _verificationId = result.sessionId;
        _isCollectingCode = true;
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
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = _selectedFactor.isTotp
            ? 'Enter the verification code from your authenticator app.'
            : 'Enter the verification code you received.';
      });
      return;
    }
    if (_selectedFactor.isSms && _verificationId == null) {
      setState(() {
        _errorMessage = 'Request a new SMS code and try again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_selectedFactor.isTotp) {
        await _authUseCase.confirmPendingTotpMfaSignIn(
          factorUid: _selectedFactor.uid,
          verificationCode: code,
        );
      } else {
        await _authUseCase.confirmPendingMfaSignIn(
          sessionId: _verificationId!,
          smsCode: code,
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _awaitingCode
            ? 'Enter second-factor code'
            : 'Two-factor authentication',
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _awaitingCode
                  ? _selectedFactor.signInPrompt
                  : 'Choose how to receive your verification code.',
            ),
            const SizedBox(height: 16),
            if (!_awaitingCode)
              DropdownButtonFormField<String>(
                initialValue: _selectedFactor.uid,
                items: widget.factors
                    .map(
                      (factor) => DropdownMenuItem<String>(
                        value: factor.uid,
                        child: Text('${factor.methodLabel}: ${factor.label}'),
                      ),
                    )
                    .toList(),
                onChanged: _isLoading
                    ? null
                    : (value) {
                        final selected = widget.factors.firstWhere(
                          (factor) => factor.uid == value,
                          orElse: () => widget.factors.first,
                        );
                        setState(() {
                          _selectedFactor = selected;
                          _verificationId = null;
                          _isCollectingCode = false;
                          _codeController.clear();
                          _errorMessage = null;
                        });
                      },
              ),
            if (_awaitingCode)
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: _selectedFactor.isTotp
                      ? 'Authenticator code'
                      : 'SMS code',
                  hintText: '123456',
                  errorText: _errorMessage,
                ),
              ),
            if (!_awaitingCode && _errorMessage != null) ...[
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
              : Text(
                  _awaitingCode
                      ? 'Verify'
                      : _selectedFactor.isTotp
                      ? 'Use authenticator app'
                      : 'Send code',
                ),
        ),
      ],
    );
  }
}
