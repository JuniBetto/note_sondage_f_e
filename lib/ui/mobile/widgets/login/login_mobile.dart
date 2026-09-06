import 'package:flutter/material.dart';
import 'package:note_sondage/ui/mobile/widgets/login/auth_tab_login.dart';
import 'package:note_sondage/ui/mobile/widgets/login/forget_password.dart';
import 'package:note_sondage/ui/widgets/legal/public_legal_links_panel.dart';

class LoginMobile extends StatelessWidget {
  final bool? isForgetPassword;
  final Map<String, String>? queryParameters;

  const LoginMobile({
    super.key,
    this.isForgetPassword = false,
    this.queryParameters,
  });

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: isForgetPassword!
                  ? ForgetPassword()
                  : AuthTabLogin(queryParameters: queryParameters),
            ),
            // Nascosto mentre la tastiera è aperta: da spazio al form
            // (già scrollabile al suo interno) invece di restare fisso
            // e "rubare" altezza utile sopra la tastiera.
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: isKeyboardVisible
                  ? const SizedBox.shrink()
                  : const Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: PublicLegalLinksPanel(
                        centered: true,
                        showDescription: false,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
