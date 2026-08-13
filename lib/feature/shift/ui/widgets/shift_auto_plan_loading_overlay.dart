import 'package:flutter/material.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/loading/team_management_loading_spinner.dart';

class ShiftAutoPlanLoadingOverlay extends StatelessWidget {
  const ShiftAutoPlanLoadingOverlay({
    super.key,
    this.compact = false,
    this.message,
  });

  final bool compact;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final overlayColor = Colors.black.withValues(alpha: 0.28);

    return AbsorbPointer(
      absorbing: true,
      child: ColoredBox(
        color: overlayColor,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: TeamManagementLoadingSpinner(
              size: compact ? 160 : 220,
              message: message ?? _localizedAutoPlannerLoadingMessage(context),
            ),
          ),
        ),
      ),
    );
  }

  String _localizedAutoPlannerLoadingMessage(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'it':
        return 'Stiamo preparando l\'anteprima dell\'Auto Planner...';
      case 'fr':
        return 'Preparation de l\'aperçu de l\'Auto Planner...';
      case 'es':
        return 'Estamos preparando la vista previa del Auto Planner...';
      default:
        return 'Preparing the Auto Planner preview...';
    }
  }
}
