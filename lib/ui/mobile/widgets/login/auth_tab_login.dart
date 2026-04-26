import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/ui/mobile/widgets/login/tab_bar_component.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';
import 'package:note_sondage/ui/widgets/sso_login.dart';

class AuthTabLogin extends StatefulWidget {
  const AuthTabLogin({super.key});

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
  final TextEditingController _registerPasswordController =
      TextEditingController();
  final TextEditingController _registerConfirmPasswordController =
      TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  Uint8List? _registerAvatarBytes;
  String? _registerAvatarFileName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // AGGIUNGI QUESTO LISTENER per aggiornare la UI
    _tabController.addListener(_handleTabSelection);
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
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Impossibile selezionare l\'immagine: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
    }
  }

  void _clearRegisterAvatar() {
    setState(() {
      _registerAvatarBytes = null;
      _registerAvatarFileName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.redAccent,
              ),
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
    return Form(
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
                onPressed: () {
                  if (_loginFormKey.currentState?.validate() ?? false) {
                    context.read<AuthBloc>().add(
                      AuthLoginRequested(
                        email: _loginEmailController.text.trim(),
                        password: _loginPasswordController.text,
                      ),
                    );
                  }
                },
                isActive: true,
                child: Text(localization.login),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomAppButton(
                  type: ButtonType.elevated,
                  backgroundColor: Colors.transparent,
                  onPressed: () {
                    context.pushNamed(RouterPaths.forgotPassword);
                    //context.goNamed(RouterPaths.forgotPassword);
                  },
                  isActive: true,
                  child: Text(localization.forgotPassword),
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
                context.read<AuthBloc>().add(const AuthGoogleSignInRequested());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRegisterForm(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localization = AppLocalizations.of(context)!;
    return Form(
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
                onPressed: () {
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
                },
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
                context.read<AuthBloc>().add(const AuthGoogleSignInRequested());
              },
            ),
          ],
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
            backgroundImage: imageBytes != null ? MemoryImage(imageBytes!) : null,
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
