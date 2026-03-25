import 'package:flutter/material.dart';
import 'package:note_sondage/ui/widgets/custom_input_field.dart';

class ContactUsWeb extends StatelessWidget {
  const ContactUsWeb({super.key});

  @override
  Widget build(BuildContext context) {
    // Colore di sfondo simile all'immagine
    const backgroundColor = Color(0xFFF9D5D3);
    const primaryDark = Color(0xFF2D4356);
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _messageController = TextEditingController();

    return DecoratedBox(
      decoration: BoxDecoration(color: backgroundColor),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
        child: Column(
          children: [
            // --- Header / Navbar ---
            //const _HeaderSection(),
            //const SizedBox(height: 10),

            // --- Main Content (Row per Web/Tablet) ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lato Sinistro: Il Form
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contact us',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: primaryDark,
                        ),
                      ),
                      const SizedBox(height: 30),
                      CustomTextFieldImmersive(
                        hint: 'Your Name',
                        controller: _nameController,
                      ),
                      const SizedBox(height: 20),
                      CustomTextFieldImmersive(
                        hint: 'Your Email',
                        controller: _emailController,
                      ),
                      const SizedBox(height: 20),
                      CustomTextFieldImmersive(
                        hint: 'Message',
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
                        child: const Text(
                          'Submit',
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
                    child: Image.network(
                      'https://placeholder.com/illustration_url', // Sostituisci con il tuo asset
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.support_agent,
                          size: 300,
                          color: primaryDark,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),
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
          ],
        ),
      ),
    );
  }
}

// Widget per la Navbar superiore
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'YOUR LOGO',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.redAccent,
          ),
        ),
        Row(
          children: [
            _navItem('HOME'),
            _navItem('ABOUT US'),
            _navItem('SERVICES'),
            _navItem('CONTACT US', isActive: true),
          ],
        ),
      ],
    );
  }

  Widget _navItem(String title, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 30.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? Colors.black : Colors.grey,
        ),
      ),
    );
  }
}
