import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/feature/clocking/ui/mobile/clocking_shift_tab_page.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/widgets/sondage_mobile.dart';
import 'package:note_sondage/feature/team/ui/mobile/teams_mobile.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/mobile/widgets/header_page.dart';
import 'package:note_sondage/ui/mobile/widgets/home/home_dashboard_mobile.dart';
import 'package:note_sondage/ui/mobile/widgets/settings/settings_mobile.dart';
import 'package:note_sondage/ui/widgets/navigation_bar.dart';

class MainMobile extends StatelessWidget {
  const MainMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    final navBarItem = context.watch<NavigationBloc>().state;

    return Scaffold(
      appBar: HeaderPage(
        showBackButton: false,
        title: navBarItem == 0
            ? loc.home
            : navBarItem == 1
            ? loc.team
            : navBarItem == 2
            ? loc.settings
            : navBarItem == 3
            ? loc.clockingInOut
            : loc.sondage,
      ),
      backgroundColor: colorScheme.homePrimary,
      body: navBarItem == 0
          ? const HomeDashboardMobile()
          : navBarItem == 1
          ? const TeamsMobile()
          : navBarItem == 2
          ? const SettingsMobile()
          : navBarItem == 3
          ? const ClockingShiftTabPage()
          : const SondageMobile(),
      bottomNavigationBar: NavigationBarWidget(
        key: Key("mobile_navigation_bar"),
      ),
    );
  }
}
