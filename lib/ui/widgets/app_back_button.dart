import 'package:flutter/material.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

/// The app's one back-button look: a chevron in a soft rounded square.
/// Every page that needs its own back action (an `AppBar.leading` or an
/// inline header row) should use this instead of a bare [IconButton], so
/// every screen reads as the same control rather than each one drifting its
/// own variant.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onPressed,
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: colorScheme.homeSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colorScheme.borderColor!.withValues(alpha: 0.3),
          ),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
      ),
    );
  }
}
