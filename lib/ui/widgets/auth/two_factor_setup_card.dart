import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/auth/domain/entities/mfa_factor_hint_entity.dart';
import 'package:note_sondage/feature/auth/domain/use_case/auth_use_case.dart';
import 'package:note_sondage/feature/auth/infrastructure/local/pending_mfa_setup_store.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/auth/mfa_enrollment_dialog.dart';

import '../../../feature/auth/domain/entities/auth_user_entity.dart';

class TwoFactorSetupCard extends StatefulWidget {
  const TwoFactorSetupCard({super.key, this.compact = false});

  final bool compact;

  @override
  State<TwoFactorSetupCard> createState() => _TwoFactorSetupCardState();
}

class _TwoFactorSetupCardState extends State<TwoFactorSetupCard> {
  final _authUseCase = getIt<AuthUseCase>();
  final _pendingStore = PendingMfaSetupStore();

  Future<_TwoFactorSetupData>? _future;
  bool _isRefreshingVerification = false;
  bool _isResendingVerification = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_TwoFactorSetupData> _load() async {
    final authUser = getIt<AuthBloc>().state.user;
    final factors = authUser.isNotEmpty
        ? await _authUseCase.getEnrolledMfaFactors()
        : const <MfaFactorHintEntity>[];
    final pendingSetup = authUser.email.isNotEmpty
        ? await _pendingStore.loadForEmail(authUser.email)
        : null;
    return _TwoFactorSetupData(factors: factors, pendingSetup: pendingSetup);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _startEnrollment(PendingMfaSetupPreference? pendingSetup) async {
    final authUser = context.read<AuthBloc>().state.user;
    final enabled = await showDialog<bool>(
      context: context,
      builder: (_) => MfaEnrollmentDialog(
        initialPhoneNumber: pendingSetup?.phoneNumber,
        initialMethod: pendingSetup?.method ?? MfaFactorType.sms,
      ),
    );

    if (enabled == true) {
      if (authUser.email.isNotEmpty) {
        await _pendingStore.clearForEmail(authUser.email);
      }
      if (!mounted) return;
      AppSnackBar.showSuccess(
        context,
        'Two-factor authentication enabled successfully.',
        title: '2FA enabled',
      );
      await _refresh();
    }
  }

  Future<void> _reloadVerificationStatus() async {
    setState(() {
      _isRefreshingVerification = true;
    });

    try {
      await _authUseCase.reloadUser();
      if (!mounted) return;

      final refreshedUser = _authUseCase.currentUser;
      context.read<AuthBloc>().add(const AuthReloadRequested());
      await _refresh();
      if (!mounted) return;

      if (refreshedUser.emailVerified) {
        AppSnackBar.showSuccess(
          context,
          'Your email is verified. You can now enable authenticator app 2FA.',
          title: 'Email verified',
        );
      } else {
        AppSnackBar.showWarning(
          context,
          'We still see your email as unverified. Open the verification link from your inbox, then try again.',
          title: 'Verification pending',
        );
      }
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        'We could not refresh your verification status right now. Please try again.',
        title: 'Refresh failed',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingVerification = false;
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResendingVerification = true;
    });

    try {
      await _authUseCase.sendEmailVerification();
      if (!mounted) return;
      AppSnackBar.showSuccess(
        context,
        'We sent a new verification email. Open the link you receive, then tap "I\'ve verified my email".',
        title: 'Verification email sent',
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        'We could not send a new verification email right now. Please try again.',
        title: 'Unable to send email',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResendingVerification = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final authUser = authState.user;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final supportsMfa =
        authUser.provider != AuthProvider.phone &&
        authUser.provider != AuthProvider.anonymous;

    return FutureBuilder<_TwoFactorSetupData>(
      future: _future,
      builder: (context, snapshot) {
        final factors = snapshot.data?.factors ?? const <MfaFactorHintEntity>[];
        final pendingSetup = snapshot.data?.pendingSetup;
        final isEnabled = factors.isNotEmpty;
        final actionLabel = pendingSetup != null && !isEnabled
            ? 'Complete setup'
            : 'Enable 2FA';

        return Container(
          padding: EdgeInsets.all(widget.compact ? 18 : 24),
          decoration: BoxDecoration(
            color: colorScheme.homeSecondary,
            borderRadius: BorderRadius.circular(widget.compact ? 18 : 20),
            border: Border.all(
              color: colorScheme.borderColor!.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00897B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: Color(0xFF00897B),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Two-factor authentication',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEnabled
                              ? 'Your account requires a second verification step when signing in.'
                              : 'Add an authenticator app for extra protection.',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.descriptionColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (!supportsMfa)
                Text(
                  'Two-factor authentication is not available for phone-only accounts.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.descriptionColor,
                  ),
                )
              else if (!authUser.emailVerified) ...[
                Text(
                  'Verify your email address first. After that, tap "I\'ve verified my email" and you will see the TOTP setup with the secret key, QR code and first verification step.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.descriptionColor,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: _isRefreshingVerification
                          ? null
                          : _reloadVerificationStatus,
                      icon: _isRefreshingVerification
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified_outlined),
                      label: const Text('I\'ve verified my email'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isResendingVerification
                          ? null
                          : _resendVerificationEmail,
                      icon: _isResendingVerification
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.mark_email_unread_outlined),
                      label: const Text('Resend verification email'),
                    ),
                  ],
                ),
              ] else ...[
                if (pendingSetup != null && !isEnabled) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Registration request detected. Finish setting up your authenticator app.',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (isEnabled) ...[
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: factors
                        .map((factor) => _FactorChip(factor: factor))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _startEnrollment(pendingSetup),
                    icon: const Icon(Icons.add_moderator_rounded),
                    label: const Text('Add another method'),
                  ),
                ] else
                  FilledButton.icon(
                    onPressed: () => _startEnrollment(pendingSetup),
                    icon: const Icon(Icons.lock_open_rounded),
                    label: Text(actionLabel),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TwoFactorSetupData {
  const _TwoFactorSetupData({
    required this.factors,
    required this.pendingSetup,
  });

  final List<MfaFactorHintEntity> factors;
  final PendingMfaSetupPreference? pendingSetup;
}

class _FactorChip extends StatelessWidget {
  const _FactorChip({required this.factor});

  final MfaFactorHintEntity factor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = factor.isTotp ? Icons.key_rounded : Icons.sms_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.borderColor!.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text('${factor.methodLabel}: ${factor.label}'),
        ],
      ),
    );
  }
}
