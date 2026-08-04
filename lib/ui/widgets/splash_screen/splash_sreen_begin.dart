import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/loading/team_management_loading_spinner.dart';

class SplashScreenBegin extends StatelessWidget {
  const SplashScreenBegin({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = colorScheme.bgSurface ?? colorScheme.surface;
    final halo = (colorScheme.bgsecondary ?? colorScheme.primary).withValues(
      alpha: 0.18,
    );

    if (!kIsWeb) {
      return Scaffold(backgroundColor: background);
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.12),
            radius: 0.9,
            colors: [halo, background],
          ),
        ),
        child: const Center(
          child: TeamManagementLoadingSpinner(
            size: 240,
            message: 'Loading workspace...',
          ),
        ),
      ),
    );
  }
}
