import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/create_team_mobile.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';

class UpdateTeamMobile extends StatelessWidget {
  const UpdateTeamMobile({super.key, this.teamId});
  final String? teamId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
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
          onPressed: () {
            context.read<NavigationBloc>().add(NavigationPositionChanged(1));
            context.go(RouterPaths.home);
          },
        ),
        centerTitle: true,
        title: Text(
          localization.editTeam,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (teamId != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () {
                  context.go(RouterPaths.rolePage, extra: teamId);
                },
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 18,
                    color: Color(0xFF7C4DFF),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(child: CreateTeamMobile(teamId: teamId)),
    );
  }
}
