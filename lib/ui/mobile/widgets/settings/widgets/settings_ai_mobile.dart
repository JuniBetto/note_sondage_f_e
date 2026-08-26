import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/ai/preferences/workflow_ai_preferences_cubit.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_toggle_switch.dart';

class SettingsAiMobile extends StatefulWidget {
  const SettingsAiMobile({super.key});

  @override
  State<SettingsAiMobile> createState() => _SettingsAiMobileState();
}

class _SettingsAiMobileState extends State<SettingsAiMobile> {
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
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale == 'it' ? 'Autorizzazione AI' : 'AI authorization',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  locale == 'it'
                      ? 'Questo interruttore abilita o blocca l uso dell AI in tutta l app. Quando e spento, i suggerimenti AI non sono disponibili in nessun team.'
                      : 'This switch enables or blocks AI usage across the whole app. When it is off, AI suggestions are unavailable in every team.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.descriptionColor,
                  ),
                ),
                const SizedBox(height: 16),
                AppSwitchListTile(
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
                        ? 'Ogni team deve anche attivare il proprio flag AI nelle impostazioni team.'
                        : 'Each team must also enable its own AI flag in the team settings.',
                  ),
                ),
                if (saving) ...[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(minHeight: 2),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
