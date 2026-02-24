import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/mobile/widgets/login/auth_tab_login.dart';
import 'package:note_sondage/ui/mobile/widgets/login/forget_password.dart';
import 'package:note_sondage/ui/web/widgets/web_navbar.dart';

class LoginWeb extends StatelessWidget {
  final bool? isForgetPassword;
  const LoginWeb({super.key, this.isForgetPassword = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final localization = AppLocalizations.of(context)!;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.surface, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            WebNavbar(isVisible: false),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            localization.welcomeBack,
                            style: textTheme.displayLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(
                      right: 80.0,
                      bottom: 8,
                      top: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.bgborderLogin!,
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(4.0),
                    width: 400,
                    height: 800,
                    child: isForgetPassword!
                        ? ForgetPassword()
                        : AuthTabLogin(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
