import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/create_team_mobile.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';
import 'package:note_sondage/ui/mobile/widgets/header_page.dart';

class UpdateTeamMobile extends StatelessWidget {
  const UpdateTeamMobile({super.key, this.teamId});
  final String? teamId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.bgColor,
      appBar: HeaderPage(
        title: "Update Team",
        onBackPressed: () {
          context.read<NavigationBloc>().add(NavigationPositionChanged(1));
          context.go(RouterPaths.home);
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(children: [CreateTeamMobile(teamId: teamId)]),
        ),
      ),
    );
  }
}
