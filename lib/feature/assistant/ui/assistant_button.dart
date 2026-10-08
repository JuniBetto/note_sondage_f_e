import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/assistant/ui/assistant_dialog.dart';
import 'package:note_sondage/feature/assistant/ui/assistant_session.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

/// Pulsante flottante che apre l'assistente. Stesso stile del pulsante "?"
/// del tutorial, sopra il quale viene mostrato.
class AssistantButton extends StatelessWidget {
  const AssistantButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppLocalizations.of(context)!.assistantTooltip,
      child: IconButton.filledTonal(
        key: const Key('assistant_button'),
        onPressed: () {
          AssistantSession.instance.bindUser(
            context.read<AuthBloc>().state.user.uid,
          );
          showAssistantDialog(context);
        },
        icon: const Icon(Icons.auto_awesome_rounded),
      ),
    );
  }
}
