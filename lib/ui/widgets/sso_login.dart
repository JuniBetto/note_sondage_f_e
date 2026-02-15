import 'package:flutter/material.dart';

class SsoLogin extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final double? width;
  final String assetPath;
  final String buttonText;

  const SsoLogin({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.assetPath = 'assets/images/logo.png',
    this.buttonText = 'Continue with Google',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          side: const BorderSide(color: Color(0xFFDADCE0), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icona Google con dimensioni precise
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: Image.asset(assetPath, fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3C4043),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
