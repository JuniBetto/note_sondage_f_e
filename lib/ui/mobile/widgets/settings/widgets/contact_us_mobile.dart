import 'package:flutter/material.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

class ContactUsMobile extends StatefulWidget {
  const ContactUsMobile({super.key});

  @override
  State<ContactUsMobile> createState() => _ContactUsMobileState();
}

class _ContactUsMobileState extends State<ContactUsMobile> {
  late TextEditingController _loginEmailController;
  late TextEditingController _messageController;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _loginEmailController = TextEditingController();
    _messageController = TextEditingController();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _loginEmailController.dispose();
    _messageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final localization = AppLocalizations.of(context)!;

    const primaryDark = Color(0xFF2D4356);

    return DecoratedBox(
      decoration: BoxDecoration(color: colorScheme.homeSecondary!),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localization.contactUs.toUpperCase(),
                    style: textTheme.headlineMedium,
                  ),
                  const Icon(
                    Icons.support_agent,
                    size: 60,
                    color: primaryDark,
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            CustomTextFieldImmersive(
              key: ValueKey("Your name"),
              hintText: localization.yourName,
              controller: _nameController,
            ),
            const SizedBox(height: 16),
            CustomTextFieldImmersive(
              key: ValueKey("Your email"),
              controller: _loginEmailController,
              hintText: localization.yourEmail,
            ),
            const SizedBox(height: 16),
            CustomTextFieldImmersive(
              key: ValueKey("Your message"),
              hintText: localization.message,
              maxLines: 5,
              controller: _messageController,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                CustomAppButton(
                  type: ButtonType.text,
                  backgroundColor: primaryDark,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  isActive: true,
                  child: Text(localization.submit),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.facebook, color: Colors.grey),
                SizedBox(width: 20),
                Icon(Icons.camera_alt, color: Colors.grey),
                SizedBox(width: 20),
                Icon(Icons.alternate_email, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
