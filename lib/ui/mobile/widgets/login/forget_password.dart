import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _loginEmailController = TextEditingController();

  @override
  void dispose() {
    _loginEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.passwordResetSent) {
          AppSnackBar.showSuccess(
            context,
            'Password reset email sent. Check your inbox.',
            title: 'Reset email sent',
          );
          context.go(RouterPaths.login);
        } else if (state.errorMessage != null) {
          AppSnackBar.showError(
            context,
            state.errorMessage!,
            title: 'Password reset failed',
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Text(localization.forgotPassword.toUpperCase()),
                const SizedBox(height: 8),
                Text(localization.pleaseEnterYourEmail),
                const SizedBox(height: 24),
                CustomInputField(
                  key: const ValueKey("login_email_field"),
                  hintText: "exemple@mail.com",
                  controller: _loginEmailController,
                  prefixIcon: Icons.email_outlined,
                  validator: emailValidator,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    CustomAppButton(
                      type: ButtonType.text,
                      backgroundColor: Colors.red,
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          context.read<AuthBloc>().add(
                            AuthPasswordResetRequested(
                              email: _loginEmailController.text.trim(),
                            ),
                          );
                        }
                      },
                      isActive: true,
                      child: Text(localization.resetPassword),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(localization.donthaveAnAccount),
                      CustomAppButton(
                        onPressed: () => context.go(RouterPaths.login),
                        type: ButtonType.text,
                        isActive: false,
                        child: Text(localization.signup),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
