import 'dart:io';

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

class ProfileSettingsMobile extends StatefulWidget {
  const ProfileSettingsMobile({super.key});

  @override
  State<ProfileSettingsMobile> createState() => _ProfileSettingsMobileState();
}

class _ProfileSettingsMobileState extends State<ProfileSettingsMobile> {
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
  File? _selectedProfileImageFile;
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
      _selectedProfileImageFile != null;

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

  String _mapSaveError(Object error) {
    return AuthUserMessageResolver.resolve(
      error,
      fallback: 'We could not save your profile right now. Please try again.',
    );
  }

  void _resetForm() {
    _displayNameController.text = _initialDisplayName;
    setState(() {
      _selectedProfileImageFile = null;
      _avatarInputRevision += 1;
      _errorMessage = null;
    });
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

      final imageBytes = await _selectedProfileImageFile?.readAsBytes();

      await _authUseCase.updateMyProfile(
        displayName: normalizedDisplayName,
        profileImageBytes: imageBytes,
        profileImageFileName: _selectedProfileImageFile != null
            ? _selectedProfileImageFile!.path.split('/').last
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
        _selectedProfileImageFile = null;
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

        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.82,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
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
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ProfileChip(
                        icon: Icons.verified_user_outlined,
                        label: _providerLabel(authUser.provider),
                      ),
                      _ProfileChip(
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
                            'profile-mobile-avatar-${_avatarInputRevision}_$_initialPhotoUrl',
                          ),
                          size: 108,
                          initialImageUrl: _initialPhotoUrl,
                          editable: !_isSaving,
                          onImageChanged: (file) {
                            setState(() {
                              _selectedProfileImageFile = file;
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
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colorScheme.homeSecondary,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: colorScheme.borderColor!.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        const SizedBox(height: 18),
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
                          const SizedBox(height: 14),
                          Text(
                            _errorMessage!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : _resetForm,
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSaving ? null : _save,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const TwoFactorSetupCard(compact: true),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.icon, required this.label});

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
