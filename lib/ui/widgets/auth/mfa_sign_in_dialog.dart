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
  late MfaFactorHintEntity _selectedFactor;

  bool get _awaitingCode => _verificationId != null;

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
    if (_verificationId == null || code.isEmpty) {
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
      await _authUseCase.confirmPendingMfaSignIn(
        sessionId: _verificationId!,
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
                  ? 'We sent a verification code to ${_selectedFactor.label}.'
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
                        child: Text(factor.label),
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
                        });
                      },
              ),
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
              : Text(_awaitingCode ? 'Verify' : 'Send code'),
        ),
      ],
    );
  }
}
