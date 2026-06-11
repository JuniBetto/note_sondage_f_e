import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SsoLogin extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final double? width;
  final String? assetPath;
  final IconData? iconData;
  final String buttonText;

  const SsoLogin({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.assetPath = 'assets/images/google_sso.png',
    this.iconData,
    this.buttonText = 'Continue with Google',
  });

  @override
  Widget build(BuildContext context) {
    final isGoogleButton =
        assetPath != null && assetPath!.contains('google_sso');

    return SizedBox(
      width: width ?? double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          side: const BorderSide(color: Color(0xFFD7DCE3), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  if (assetPath != null)
                    SizedBox(
                      width: isGoogleButton ? 20 : 18,
                      height: isGoogleButton ? 20 : 18,
                      child: _buildAssetIcon(assetPath!, isGoogleButton),
                    )
                  else if (iconData != null)
                    Icon(iconData, size: 18, color: const Color(0xFF3C4043)),
                  const SizedBox(width: 10),
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2F3337),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAssetIcon(String path, bool isGoogleButton) {
    if (isGoogleButton) {
      return SvgPicture.string(_googleMarkSvg, fit: BoxFit.contain);
    }

    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(path, fit: BoxFit.contain);
    }

    return Image.asset(
      path,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

const String _googleMarkSvg = '''
<svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M17.64 9.20455C17.64 8.56636 17.5827 7.95273 17.4764 7.36364H9V10.845H13.8436C13.635 11.97 12.9982 12.9232 12.045 13.5614V15.8195H14.9523C16.6532 14.2532 17.64 11.9455 17.64 9.20455Z" fill="#4285F4"/>
  <path d="M9 18C11.43 18 13.4673 17.1941 14.9523 15.8195L12.045 13.5614C11.2391 14.1014 10.2082 14.4205 9 14.4205C6.65591 14.4205 4.67182 12.8368 3.96409 10.71H0.958641V13.0418C2.43545 15.975 5.47091 18 9 18Z" fill="#34A853"/>
  <path d="M3.96409 10.71C3.78409 10.17 3.68182 9.59318 3.68182 9C3.68182 8.40682 3.78409 7.83 3.96409 7.29V4.95818H0.958636C0.350455 6.17045 0 7.53955 0 9C0 10.4605 0.350455 11.8295 0.958636 13.0418L3.96409 10.71Z" fill="#FBBC05"/>
  <path d="M9 3.57955C10.3186 3.57955 11.5036 4.03364 12.435 4.92364L15.0177 2.34091C13.4632 0.880909 11.4259 0 9 0C5.47091 0 2.43545 2.025 0.958641 4.95818L3.96409 7.29C4.67182 5.16318 6.65591 3.57955 9 3.57955Z" fill="#EA4335"/>
</svg>
''';
