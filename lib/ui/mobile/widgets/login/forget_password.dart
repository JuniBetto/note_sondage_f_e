import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final TextEditingController _loginEmailController = TextEditingController();

  @override
  void dispose() {
    _loginEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),

          Text(localization.forgotPassword.toUpperCase()),
          const SizedBox(height: 8),
          Text(localization.pleaseEnterYourEmail),
          const SizedBox(height: 24),
          CustomInputField(
            key: ValueKey("login_email_field"),
            hintText: "exemple@mail.com",
            controller: _loginEmailController,
            prefixIcon: Icons.email_outlined,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              CustomAppButton(
                type: ButtonType.text,
                backgroundColor: Colors.red,
                onPressed: () {},
                isActive: true,
                child: Text(localization.resetPassword),
              ),
            ],
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(localization.donthaveAnAccount),
                CustomAppButton(
                  onPressed: () => context.pop(),
                  type: ButtonType.text,
                  isActive: false,

                  child: Text(localization.signup),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
