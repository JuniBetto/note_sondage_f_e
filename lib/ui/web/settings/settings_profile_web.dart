import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/auth/domain/entities/auth_user_entity.dart';
import 'package:note_sondage/feature/auth/domain/use_case/auth_use_case.dart';
import 'package:note_sondage/feature/auth/infrastructure/data/backend_auth_data_source.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/auth/ui/auth_user_message_resolver.dart';
import 'package:note_sondage/feature/team/domain/use_case/user/user_use_case.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/auth/two_factor_setup_card.dart';
import 'package:note_sondage/ui/widgets/avatar_input.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';

class SettingsProfileWeb extends StatefulWidget {
  const SettingsProfileWeb({super.key});

  @override
  State<SettingsProfileWeb> createState() => _SettingsProfileWebState();
}

class _SettingsProfileWebState extends State<SettingsProfileWeb> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _authUseCase = getIt<AuthUseCase>();
  final _userUseCase = getIt<UserUseCase>();
  final _backendAuth = BackendAuthDataSource();

  String _seededUid = '';
  String _initialDisplayName = '';
  String _initialEmail = '';
  String _initialPhotoUrl = '';
  Uint8List? _selectedProfileImageBytes;
  int _avatarInputRevision = 0;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _hasChanges =>
      _displayNameController.text.trim() != _initialDisplayName ||
      _selectedProfileImageBytes != null;

  void _seedControllers(AuthUserEntity user) {
    final resolvedDisplayName = _resolveDisplayName(user);
    final email = user.email.trim();
    final photoUrl = _resolvePhotoUrl(user) ?? '';

    final shouldReplaceValues =
        _seededUid != user.uid ||
        (!_hasChanges &&
            (_initialDisplayName != resolvedDisplayName ||
                _initialEmail != email ||
                _initialPhotoUrl != photoUrl));

    if (!shouldReplaceValues) {
      return;
    }

    _seededUid = user.uid;
    _initialDisplayName = resolvedDisplayName;
    _initialEmail = email;
    _initialPhotoUrl = photoUrl;
    _displayNameController.text = resolvedDisplayName;
    _emailController.text = email;
  }

  String _resolveDisplayName(AuthUserEntity user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = user.email.trim();
    if (email.isNotEmpty) {
      return email.split('@').first;
    }

    return '';
  }

  String? _resolvePhotoUrl(AuthUserEntity user) {
    final photoUrl = user.photoUrl?.trim();
    if (photoUrl == null || photoUrl.isEmpty) {
      return null;
    }
    return photoUrl;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final normalizedDisplayName = _displayNameController.text.trim();
    final normalizedEmail = _emailController.text.trim().toLowerCase();

    if (!_hasChanges) {
      AppSnackBar.showWarning(
        context,
        'Update at least one field before saving your profile.',
        title: 'No changes detected',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final currentProfile = await _backendAuth.getMyProfile();
      final currentProfileId = currentProfile?['id']?.toString().trim();

      if (normalizedEmail.isNotEmpty &&
          currentProfileId != null &&
          currentProfileId.isNotEmpty) {
        final existingUser = await _userUseCase.getUserByEmail(normalizedEmail);
        final existingUserId = existingUser?.id?.trim();
        final existingName = existingUser?.fullName.trim().toLowerCase();

        if (existingUser != null &&
            existingUserId != null &&
            existingUserId.isNotEmpty &&
            existingUserId != currentProfileId &&
            existingName == normalizedDisplayName.toLowerCase()) {
          throw Exception(
            'Another user already exists with the same name and email.',
          );
        }
      }

      await _authUseCase.updateMyProfile(
        displayName: normalizedDisplayName,
        profileImageBytes: _selectedProfileImageBytes,
        profileImageFileName: _selectedProfileImageBytes != null
            ? 'profile-$_seededUid.jpg'
            : null,
      );

      if (!mounted) return;

      final refreshedUser = _authUseCase.currentUser;
      context.read<AuthBloc>().add(
        AuthProfileDisplayNameUpdated(normalizedDisplayName),
      );
      context.read<AuthBloc>().add(
        AuthProfilePhotoUpdated(refreshedUser.photoUrl),
      );

      setState(() {
        _initialDisplayName = normalizedDisplayName;
        _initialPhotoUrl = refreshedUser.photoUrl?.trim() ?? _initialPhotoUrl;
        _selectedProfileImageBytes = null;
        _avatarInputRevision += 1;
      });

      AppSnackBar.showSuccess(
        context,
        'Your profile information has been saved successfully.',
        title: 'Profile updated',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _mapSaveError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _mapSaveError(Object error) {
    return AuthUserMessageResolver.resolve(
      error,
      fallback: 'We could not save your profile right now. Please try again.',
    );
  }

  void _resetForm() {
    _displayNameController.text = _initialDisplayName;
    setState(() {
      _selectedProfileImageBytes = null;
      _avatarInputRevision += 1;
      _errorMessage = null;
    });
  }

  String? _displayNameValidator(String? value) {
    final trimmedValue = value?.trim() ?? '';
    if (trimmedValue.isEmpty) {
      return 'Full name is required';
    }
    if (trimmedValue.length < 2) {
      return 'Full name must contain at least 2 characters';
    }
    if (trimmedValue.length > 80) {
      return 'Full name must contain at most 80 characters';
    }
    return null;
  }

  String _providerLabel(AuthProvider provider) {
    switch (provider) {
      case AuthProvider.google:
        return 'Google';
      case AuthProvider.phone:
        return 'Phone';
      case AuthProvider.apple:
        return 'Apple';
      case AuthProvider.anonymous:
        return 'Anonymous';
      case AuthProvider.email:
        return 'Email';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status != AuthStatus.authenticated) {
          return const SizedBox.shrink();
        }

        final authUser = state.user;
        _seedControllers(authUser);

        return Align(
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF2E7D32,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Color(0xFF2E7D32),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage the information shown for your account.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.descriptionColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.homeSecondary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.borderColor!.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _InfoChip(
                                icon: Icons.verified_user_outlined,
                                label: _providerLabel(authUser.provider),
                              ),
                              _InfoChip(
                                icon: authUser.emailVerified
                                    ? Icons.mark_email_read_outlined
                                    : Icons.mark_email_unread_outlined,
                                label: authUser.emailVerified
                                    ? 'Email verified'
                                    : 'Email not verified',
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: Column(
                              children: [
                                AvatarInput(
                                  key: ValueKey(
                                    'profile-web-avatar-${_avatarInputRevision}_$_initialPhotoUrl',
                                  ),
                                  size: 116,
                                  initialImageUrl: _initialPhotoUrl,
                                  editable: !_isSaving,
                                  onImageBytesChanged: (bytes) {
                                    setState(() {
                                      _selectedProfileImageBytes = bytes;
                                      _errorMessage = null;
                                    });
                                  },
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Tap the avatar to choose a new profile image.',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.descriptionColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            localization.fullName,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomInputField(
                            hintText: localization.fullName,
                            controller: _displayNameController,
                            prefixIcon: Icons.person_outline,
                            validator: _displayNameValidator,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            localization.email,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomInputField(
                            hintText: localization.email,
                            controller: _emailController,
                            prefixIcon: Icons.email_outlined,
                            enabled: false,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Email cannot be changed from this page.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.descriptionColor,
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: _isSaving ? null : _resetForm,
                                child: const Text('Reset'),
                              ),
                              const SizedBox(width: 12),
                              FilledButton(
                                onPressed: _isSaving ? null : _save,
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Save changes'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const TwoFactorSetupCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
          Icon(icon, size: 16, color: colorScheme.selectItem),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
