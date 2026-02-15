import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/feature/clocking/ui/web/clocking_web.dart';
import 'package:note_sondage/feature/sondage/ui/web/sondage_web.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/mobile/widgets/home/home_mobile.dart';
import 'package:note_sondage/ui/web/settings/settings_web.dart';
import 'package:note_sondage/ui/web/widgets/home/left_home_section.dart';
import 'package:note_sondage/ui/web/widgets/right_home_section.dart';
import 'package:note_sondage/ui/widgets/about_page.dart';
import 'package:note_sondage/ui/widgets/team_page.dart';

class WebFullSection extends StatelessWidget {
  const WebFullSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final navBarItem = context.watch<NavigationBloc>().state;

    return Column(
      children: [
        SizedBox(height: 4),
        Expanded(
          child: Row(
            children: [
              Expanded(child: LeftHomeSection()),
              Expanded(
                flex: 3,
                child: /*RightHomeSection() */ Container(
                  color: colorScheme.bgColor,
                  child: switch (navBarItem) {
                    0 => const HomeMobile(),
                    1 =>
                      const TeamPage(), // Puoi sostituire con un altro widget web
                    2 => const SettingsWeb(),
                    5 => const ClockingWeb(),
                    6 => const SondageWeb(),
                    // TODO: Handle this case.
                    int() => throw UnimplementedError(),
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
