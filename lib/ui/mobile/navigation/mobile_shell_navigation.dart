import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/widgets/sondage_mobile.dart';
import 'package:note_sondage/feature/team/ui/mobile/teams_mobile.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_bloc.dart';
import 'package:note_sondage/ui/bloc/navigation_bloc/navigation_event.dart';

/// Index of the Team/Chat tab in MainMobile's bottom navigation bar.
const int mobileShellTeamNavIndex = 1;

/// Index of the Sondage tab in MainMobile's bottom navigation bar.
const int mobileShellSondageNavIndex = 4;

/// Opens the Sondage section (list = tab 0, create = 1) *inside* MainMobile,
/// which owns the Material/Scaffold and the bottom navigation bar.
///
/// `RouterPaths.sondage` builds a bare `SondageMobile` with no Scaffold of
/// its own, so `context.go`-ing to it directly renders it without
/// background, theme or navigation bar. Use this as the "nothing to pop"
/// fallback of a page that may have been opened standalone (notification
/// tap, deep link) instead of pushed from the shell.
void openSondageInMobileShell(BuildContext context, {int tab = 0}) {
  if (tab != 0) {
    SondageMobile.requestedInitialTab = tab;
  }
  context.read<NavigationBloc>().add(
    NavigationPositionChanged(mobileShellSondageNavIndex),
  );
  context.go(RouterPaths.home);
}

/// Opens the Team section (list = tab 0, create = 1, chat = 2) *inside*
/// MainMobile. Same reason as [openSondageInMobileShell]: `RouterPaths.team`
/// and `RouterPaths.teamChat` build a bare `TeamsMobile` without Scaffold.
void openTeamInMobileShell(BuildContext context, {int tab = 0}) {
  if (tab != 0) {
    TeamsMobile.requestedInitialTab = tab;
  }
  context.read<NavigationBloc>().add(
    NavigationPositionChanged(mobileShellTeamNavIndex),
  );
  context.go(RouterPaths.home);
}
