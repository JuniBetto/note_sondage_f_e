import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/auth/domain/entities/mfa_factor_hint_entity.dart';
import 'package:note_sondage/feature/auth/infrastructure/local/pending_mfa_setup_store.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/auth/mfa_sign_in_dialog.dart';
import 'package:note_sondage/ui/widgets/auth/phone_sign_in_dialog.dart';
import 'package:note_sondage/ui/widgets/auth/request_account_deletion_dialog.dart';
import 'package:note_sondage/ui/widgets/auth/request_account_reactivation_dialog.dart';
import 'package:note_sondage/ui/mobile/widgets/login/tab_bar_component.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';
import 'package:note_sondage/ui/widgets/submit_on_enter_scope.dart';
import 'package:note_sondage/ui/widgets/sso_login.dart';

class AuthTabLogin extends StatefulWidget {
  final Map<String, String>? queryParameters;

  const AuthTabLogin({super.key, this.queryParameters});

  @override
  State<AuthTabLogin> createState() => _AuthTabLoginState();
}

class _AuthTabLoginState extends State<AuthTabLogin>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _registerFormKey = GlobalKey<FormState>();

  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();
  final TextEditingController _registerNameController = TextEditingController();
  final TextEditingController _registerEmailController =
      TextEditingController();
  final TextEditingController _registerMfaPhoneController =
      TextEditingController();
  final TextEditingController _registerPasswordController =
      TextEditingController();
  final TextEditingController _registerConfirmPasswordController =
      TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final PendingMfaSetupStore _pendingMfaSetupStore = PendingMfaSetupStore();

  Uint8List? _registerAvatarBytes;
  String? _registerAvatarFileName;
  bool _enableMfaOnRegistration = false;
  MfaFactorType _registrationMfaMethod = MfaFactorType.sms;
  bool _mfaDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _shouldStartOnRegister ? 1 : 0,
    );

    // AGGIUNGI QUESTO LISTENER per aggiornare la UI
    _tabController.addListener(_handleTabSelection);
  }

  bool get _shouldStartOnRegister {
    final queryParameters = widget.queryParameters;
    if (queryParameters == null || queryParameters.isEmpty) {
      return false;
    }

    final mode = queryParameters['mode']?.trim().toLowerCase();
    final tab = queryParameters['tab']?.trim().toLowerCase();
    return mode == 'register' ||
        tab == 'register' ||
        queryParameters.containsKey('inviteToken');
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        // Forza il rebuild quando cambia il tab
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerMfaPhoneController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (_loginFormKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          email: _loginEmailController.text.trim(),
          password: _loginPasswordController.text,
        ),
      );
    }
  }

  void _submitRegister() {
    if (_enableMfaOnRegistration &&
        _registrationMfaMethod == MfaFactorType.sms &&
        _registerMfaPhoneController.text.trim().isEmpty) {
      AppSnackBar.showWarning(
        context,
        'Enter a phone number to enable two-factor authentication.',
        title: 'Phone number required',
      );
      return;
    }
    if (_registerFormKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          email: _registerEmailController.text.trim(),
          password: _registerPasswordController.text,
          displayName: _registerNameController.text.trim(),
          profileImageBytes: _registerAvatarBytes,
          profileImageFileName: _registerAvatarFileName,
        ),
      );
    }
  }

  Future<void> _pickRegisterAvatar() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      if (!mounted) return;

      setState(() {
        _registerAvatarBytes = bytes;
        _registerAvatarFileName = pickedFile.name;
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        'We could not select the image. Please try again.',
        title: 'Image not selected',
      );
    }
  }

  void _clearRegisterAvatar() {
    setState(() {
      _registerAvatarBytes = null;
      _registerAvatarFileName = null;
    });
  }

  Future<void> _startPhoneSignIn() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const PhoneSignInDialog(),
    );

    if (!mounted || result != true) return;
    AppSnackBar.showSuccess(
      context,
      'Your account has been verified and you are now signed in.',
      title: 'Phone sign-in completed',
    );
  }

  Future<void> _openAccountDeletionDialog() async {
    await showDialog<bool>(
      context: context,
      builder: (_) => RequestAccountDeletionDialog(
        initialEmail: _loginEmailController.text.trim(),
      ),
    );
  }

  Future<void> _openAccountReactivationDialog() async {
    await showDialog<bool>(
      context: context,
      builder: (_) => RequestAccountReactivationDialog(
        initialEmail: _loginEmailController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.pendingMfaFactors.isNotEmpty && !_mfaDialogOpen) {
          _mfaDialogOpen = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            final result = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (_) => MfaSignInDialog(factors: state.pendingMfaFactors),
            );
            _mfaDialogOpen = false;
            if (!mounted) return;
            if (result != true) {
              context.read<AuthBloc>().add(const AuthMfaChallengeDismissed());
            }
          });
          return;
        }

        if (state.verificationEmailSent) {
          final shouldFinishMfaLater = _enableMfaOnRegistration;
          final selectedMfaMethod = _registrationMfaMethod;
          if (_enableMfaOnRegistration) {
            unawaited(
              _pendingMfaSetupStore.save(
                email: _registerEmailController.text.trim(),
                method: selectedMfaMethod,
                phoneNumber: selectedMfaMethod == MfaFactorType.sms
                    ? _registerMfaPhoneController.text.trim()
                    : null,
              ),
            );
          }
          _tabController.animateTo(0);
          _registerPasswordController.clear();
          _registerConfirmPasswordController.clear();
          setState(() {
            _registerMfaPhoneController.clear();
            _enableMfaOnRegistration = false;
            _registrationMfaMethod = MfaFactorType.sms;
          });
          final selectedMethodMessage =
              ' After your first verified sign-in, you can finish enabling your authenticator app from your profile.';
          AppSnackBar.showSuccess(
            context,
            'We sent a confirmation email to '
            '${state.verificationEmail ?? _registerEmailController.text.trim()}. '
            'Open the link you received, then sign in.'
            '${shouldFinishMfaLater ? selectedMethodMessage : ''}',
            title: 'Check your email',
          );
          return;
        }

        if (state.verificationEmailRequired) {
          _tabController.animateTo(0);
          _loginPasswordController.clear();
          AppSnackBar.showWarning(
            context,
            'Confirm the registration email sent to '
            '${state.verificationEmail ?? _loginEmailController.text.trim()}, '
            'then sign in again.',
            title: 'Check your email',
          );
          return;
        }

        if (state.errorMessage != null) {
          final isRegisterTab = _tabController.index == 1;
          AppSnackBar.showError(
            context,
            state.errorMessage!,
            title: isRegisterTab
                ? 'Unable to create account'
                : 'Unable to sign in',
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 60),

            // Tab Bar custom
            TabBarComponent(
              tabController: _tabController,
              setToUpdate: setState,
            ),

            const SizedBox(height: 32),

            // Tab Bar View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  KeyedSubtree(
                    key: const ValueKey('login_tab_content'),
                    child: buildLoginForm(context),
                  ),
                  KeyedSubtree(
                    key: const ValueKey('register_tab_content'),
                    child: buildRegisterForm(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLoginForm(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final localization = AppLocalizations.of(context)!;
    return SubmitOnEnterScope(
      onSubmit: _submitLogin,
      child: Form(
        key: _loginFormKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(localization.login.toUpperCase()),
              const SizedBox(height: 10),
              Text(localization.gladYouAreBack),
              const SizedBox(height: 24),
              CustomInputField(
                key: ValueKey("login_email_field"),
                hintText: localization.email,
                controller: _loginEmailController,
                prefixIcon: Icons.email_outlined,
                validator: emailValidator,
              ),

              const SizedBox(height: 24),
              CustomInputField(
                key: ValueKey("login_Password_field"),
                hintText: localization.password,
                controller: _loginPasswordController,
                prefixIcon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: CustomAppButton(
                  type: ButtonType.text,
                  onPressed: _submitLogin,
                  isActive: true,
                  child: Text(localization.login),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        CustomAppButton(
                          type: ButtonType.elevated,
                          backgroundColor: Colors.transparent,
                          onPressed: () {
                            context.pushNamed(RouterPaths.forgotPassword);
                          },
                          isActive: true,
                          child: Text(localization.forgotPassword),
                        ),
                        CustomAppButton(
                          type: ButtonType.elevated,
                          backgroundColor: Colors.transparent,
                          onPressed: _openAccountDeletionDialog,
                          isActive: true,
                          child: Text(localization.deleteAccount),
                        ),
                        CustomAppButton(
                          type: ButtonType.elevated,
                          backgroundColor: Colors.transparent,
                          onPressed: _openAccountReactivationDialog,
                          isActive: true,
                          child: Text(localization.reactivateAccount),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Divider(
                      color: colorScheme.bgborderLogin!,
                      thickness: 2,
                    ),
                  ),
                  Text(' Or '),
                  Expanded(
                    child: Divider(
                      color: colorScheme.bgborderLogin!,
                      thickness: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SsoLogin(
                key: ValueKey("google_sso_login_button"),
                onPressed: () {
                  context.read<AuthBloc>().add(
                    const AuthGoogleSignInRequested(),
                  );
                },
                buttonText: 'Continue with Google',
              ),
              const SizedBox(height: 12),
              SsoLogin(
                key: const ValueKey("phone_sso_login_button"),
                onPressed: _startPhoneSignIn,
                assetPath: null,
                iconData: Icons.phone_iphone_rounded,
                buttonText: 'Continue with Phone',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRegisterForm(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localization = AppLocalizations.of(context)!;
    return SubmitOnEnterScope(
      onSubmit: _submitRegister,
      child: Form(
        key: _registerFormKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(localization.register.toUpperCase()),
              const SizedBox(height: 10),
              Text(localization.justSomeInfoToGetStarted),
              const SizedBox(height: 24),
              _RegisterAvatarPicker(
                imageBytes: _registerAvatarBytes,
                onPickImage: _pickRegisterAvatar,
                onRemoveImage: _clearRegisterAvatar,
              ),
              const SizedBox(height: 16),
              CustomInputField(
                key: ValueKey("register_full_name_field"),
                hintText: localization.fullName,
                controller: _registerNameController,
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              CustomInputField(
                key: ValueKey("register_email_field"),
                hintText: localization.email,
                controller: _registerEmailController,
                prefixIcon: Icons.email_outlined,
                validator: emailValidator,
              ),

              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                value: _enableMfaOnRegistration,
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable two-factor authentication'),
                subtitle: const Text(
                  'Use an authenticator app to protect this account after your first verified sign-in.',
                ),
                onChanged: (value) {
                  setState(() {
                    _enableMfaOnRegistration = value;
                    if (value) {
                      _registrationMfaMethod = MfaFactorType.totp;
                    }
                    if (!value) {
                      _registerMfaPhoneController.clear();
                      _registrationMfaMethod = MfaFactorType.sms;
                    }
                  });
                },
              ),
              if (_enableMfaOnRegistration) ...[
                const SizedBox(height: 8),
                Text(
                  'You will finish setup with Google Authenticator, Authy or another app from your profile after the first verified sign-in.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.descriptionColor,
                  ),
                ),
              ],

              const SizedBox(height: 16),
              CustomInputField(
                key: ValueKey("register_password_field"),
                hintText: localization.password,
                controller: _registerPasswordController,
                prefixIcon: Icons.lock_outline,
                isPassword: true,
              ),

              const SizedBox(height: 16),
              CustomInputField(
                key: ValueKey("register_confirm_password_field"),
                hintText: localization.confirmPassword,
                controller: _registerConfirmPasswordController,
                prefixIcon: Icons.lock_outline,
                isPassword: true,
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CustomAppButton(
                  type: ButtonType.text,
                  key: ValueKey("register_button"),
                  onPressed: _submitRegister,
                  isActive: true,
                  child: Text(localization.register),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Divider(
                      color: colorScheme.bgborderLogin!,
                      thickness: 2,
                    ),
                  ),
                  Text(' Or '),
                  Expanded(
                    child: Divider(
                      color: colorScheme.bgborderLogin!,
                      thickness: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SsoLogin(
                key: ValueKey("google_sso_register_button"),
                onPressed: () {
                  context.read<AuthBloc>().add(
                    const AuthGoogleSignInRequested(),
                  );
                },
                buttonText: 'Continue with Google',
              ),
              const SizedBox(height: 12),
              SsoLogin(
                key: const ValueKey("phone_sso_register_button"),
                onPressed: _startPhoneSignIn,
                assetPath: null,
                iconData: Icons.phone_iphone_rounded,
                buttonText: 'Continue with Phone',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterAvatarPicker extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  const _RegisterAvatarPicker({
    required this.imageBytes,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        GestureDetector(
          onTap: onPickImage,
          child: CircleAvatar(
            radius: 34,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.10),
            backgroundImage: imageBytes != null
                ? MemoryImage(imageBytes!)
                : null,
            child: imageBytes == null
                ? Icon(
                    Icons.add_a_photo_outlined,
                    color: theme.colorScheme.primary,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Foto profilo opzionale',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Puoi aggiungerla subito durante la registrazione.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: imageBytes == null ? onPickImage : onRemoveImage,
          child: Text(imageBytes == null ? 'Scegli' : 'Rimuovi'),
        ),
      ],
    );
  }
}
