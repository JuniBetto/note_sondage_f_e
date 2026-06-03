import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.queryParameters});

  final Map<String, String> queryParameters;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _ResetPasswordViewState _state = const _ResetPasswordViewState.loading();
  String? _oobCode;
  String? _email;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    unawaited(_prepareResetFlow());
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _prepareResetFlow() async {
    final mode = widget.queryParameters['mode']?.trim();
    final oobCode = widget.queryParameters['oobCode']?.trim();

    if (mode != 'resetPassword' || oobCode == null || oobCode.isEmpty) {
      if (!mounted) return;
      setState(() {
        _state = const _ResetPasswordViewState.info(
          title: 'Open the reset link',
          message:
              'Use the password reset link from your email to choose a new password.',
        );
      });
      return;
    }

    try {
      final email = await firebase.FirebaseAuth.instance
          .verifyPasswordResetCode(oobCode);
      if (!mounted) return;
      setState(() {
        _oobCode = oobCode;
        _email = email;
        _state = _ResetPasswordViewState.ready(email: email);
      });
    } on firebase.FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _state = _ResetPasswordViewState.error(
          title: 'Invalid reset link',
          message: _mapFirebaseError(error),
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = const _ResetPasswordViewState.error(
          title: 'Reset unavailable',
          message:
              'We could not verify this password reset link. Request a new one and try again.',
        );
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final oobCode = _oobCode;
    if (oobCode == null || oobCode.isEmpty) {
      setState(() {
        _state = const _ResetPasswordViewState.error(
          title: 'Reset unavailable',
          message:
              'This password reset session is no longer valid. Request a new reset email and try again.',
        );
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await firebase.FirebaseAuth.instance.confirmPasswordReset(
        code: oobCode,
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      setState(() {
        _state = const _ResetPasswordViewState.success(
          title: 'Password updated',
          message:
              'Your password has been updated successfully. You can now sign in with the new password.',
        );
      });
    } on firebase.FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _state = _ResetPasswordViewState.error(
          title: 'Password not updated',
          message: _mapFirebaseError(error),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _mapFirebaseError(firebase.FirebaseAuthException error) {
    switch (error.code) {
      case 'expired-action-code':
        return 'This reset link has expired. Request a new password reset email.';
      case 'invalid-action-code':
        return 'This reset link is not valid or has already been used.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'We could not find an account for this reset link.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      default:
        return error.message ??
            'We could not update the password right now. Please try again.';
    }
  }

  String? _passwordValidator(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Enter a new password.';
    }
    if (password.length < 6) {
      return 'Password must contain at least 6 characters.';
    }
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Confirm your new password.';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: _state
                            .accentColor(context)
                            .withValues(alpha: 0.12),
                        child: Icon(
                          _state.icon,
                          color: _state.accentColor(context),
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _state.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _state.message,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                      ),
                      if (_state.kind == _ResetPasswordKind.ready) ...[
                        const SizedBox(height: 20),
                        if (_email != null && _email!.isNotEmpty) ...[
                          Text(
                            'Account: $_email',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              CustomInputField(
                                hintText: 'New password',
                                controller: _passwordController,
                                prefixIcon: Icons.lock_outline,
                                isPassword: true,
                                validator: _passwordValidator,
                              ),
                              const SizedBox(height: 16),
                              CustomInputField(
                                hintText: 'Confirm new password',
                                controller: _confirmPasswordController,
                                prefixIcon: Icons.lock_outline,
                                isPassword: true,
                                validator: _confirmPasswordValidator,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _isSubmitting ? null : _submit,
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Update password'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          FilledButton(
                            onPressed: () => context.go(RouterPaths.login),
                            child: Text(
                              _state.kind == _ResetPasswordKind.success
                                  ? 'Go to login'
                                  : 'Back to login',
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_state.showRetry)
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _state =
                                      const _ResetPasswordViewState.loading();
                                });
                                unawaited(_prepareResetFlow());
                              },
                              child: const Text('Try again'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetPasswordViewState {
  const _ResetPasswordViewState._({
    required this.icon,
    required this.title,
    required this.message,
    required this.kind,
    this.showRetry = false,
  });

  const _ResetPasswordViewState.loading()
    : this._(
        icon: Icons.lock_reset_outlined,
        title: 'Checking reset link',
        message: 'We are verifying your password reset request...',
        kind: _ResetPasswordKind.loading,
      );

  const _ResetPasswordViewState.ready({required String email})
    : this._(
        icon: Icons.lock_open_rounded,
        title: 'Choose a new password',
        message:
            'Enter a new password for $email and confirm it to finish the reset.',
        kind: _ResetPasswordKind.ready,
      );

  const _ResetPasswordViewState.success({
    required String title,
    required String message,
  }) : this._(
         icon: Icons.verified_outlined,
         title: title,
         message: message,
         kind: _ResetPasswordKind.success,
       );

  const _ResetPasswordViewState.info({
    required String title,
    required String message,
  }) : this._(
         icon: Icons.mail_outline,
         title: title,
         message: message,
         kind: _ResetPasswordKind.info,
       );

  const _ResetPasswordViewState.error({
    required String title,
    required String message,
  }) : this._(
         icon: Icons.error_outline,
         title: title,
         message: message,
         kind: _ResetPasswordKind.error,
         showRetry: true,
       );

  final IconData icon;
  final String title;
  final String message;
  final _ResetPasswordKind kind;
  final bool showRetry;

  Color accentColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (kind) {
      case _ResetPasswordKind.success:
        return Colors.green;
      case _ResetPasswordKind.error:
        return colorScheme.error;
      case _ResetPasswordKind.loading:
      case _ResetPasswordKind.info:
      case _ResetPasswordKind.ready:
        return colorScheme.primary;
    }
  }
}

enum _ResetPasswordKind { loading, ready, success, info, error }
