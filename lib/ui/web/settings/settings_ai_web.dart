import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/ai/preferences/workflow_ai_preferences_cubit.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class SettingsAiWeb extends StatefulWidget {
  const SettingsAiWeb({super.key});

  @override
  State<SettingsAiWeb> createState() => _SettingsAiWebState();
}

class _SettingsAiWebState extends State<SettingsAiWeb> {
  final WorkflowAiPreferencesCubit _cubit = getIt<WorkflowAiPreferencesCubit>();

  @override
  void initState() {
    super.initState();
    _cubit.loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode.toLowerCase();

    return BlocBuilder<WorkflowAiPreferencesCubit, WorkflowAiPreferencesState>(
      bloc: _cubit,
      builder: (context, state) {
        final saving = state.status == WorkflowAiPreferenceStatus.saving;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.homeSecondary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.borderColor!.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale == 'it' ? 'Autorizzazione AI' : 'AI authorization',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    locale == 'it'
                        ? 'Qui controlli il consenso globale all uso dell AI nell app. Se questo toggle e off, nessun team puo usare i suggerimenti AI anche se il team li ha attivati.'
                        : 'Here you control the global consent for AI usage in the app. If this toggle is off, no team can use AI suggestions even when the team has enabled them.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.descriptionColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SwitchListTile.adaptive(
                    value: state.appAiEnabled,
                    onChanged: saving ? null : _cubit.setAppAiEnabled,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      locale == 'it'
                          ? 'Autorizzo l uso dell AI a pagamento'
                          : 'Authorize paid AI usage',
                    ),
                    subtitle: Text(
                      locale == 'it'
                          ? 'Ogni team deve anche attivare il proprio flag AI dalle impostazioni del team.'
                          : 'Each team must also enable its own AI flag from the team settings.',
                    ),
                  ),
                  if (saving) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
