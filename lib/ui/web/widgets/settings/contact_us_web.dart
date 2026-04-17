import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';

class ContactUsWeb extends StatelessWidget {
  const ContactUsWeb({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Colore di sfondo simile all'immagine
    final backgroundColor = colorScheme.homeSecondary!;
    final primaryDark = Color(0xFF2D4356);
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _messageController = TextEditingController();

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(color: backgroundColor),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
          child: Column(
            children: [
              // --- Main Content (Row per Web/Tablet) ---
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Lato Sinistro: Il Form
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localization.contactUs,
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: primaryDark,
                            ),
                          ),
                          const SizedBox(height: 30),
                          CustomTextFieldImmersive(
                            hintText: localization.yourName,
                            controller: _nameController,
                          ),
                          const SizedBox(height: 20),
                          CustomTextFieldImmersive(
                            hintText: localization.yourEmail,
                            controller: _emailController,
                          ),
                          const SizedBox(height: 20),
                          CustomTextFieldImmersive(
                            hintText: localization.message,
                            maxLines: 5,
                            controller: _messageController,
                          ),
                          const SizedBox(height: 40),

                          // Bottone Submit
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              localization.submit,
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Lato Destro: Illustrazione
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Icon(
                          Icons.support_agent,
                          size: 300,
                          color: primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- Footer Icons ---
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
