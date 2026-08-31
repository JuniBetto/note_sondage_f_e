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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: isForgetPassword!
                  ? ForgetPassword()
                  : AuthTabLogin(queryParameters: queryParameters),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: PublicLegalLinksPanel(
                centered: true,
                showDescription: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
