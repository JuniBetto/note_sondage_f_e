import 'package:flutter/material.dart';
import 'package:note_sondage/ui/mobile/widgets/login/auth_tab_login.dart';
import 'package:note_sondage/ui/mobile/widgets/login/forget_password.dart';

class LoginMobile extends StatelessWidget {
  final bool? isForgetPassword;
  const LoginMobile({super.key, this.isForgetPassword = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isForgetPassword! ? ForgetPassword() : AuthTabLogin(),
    );
  }
}
