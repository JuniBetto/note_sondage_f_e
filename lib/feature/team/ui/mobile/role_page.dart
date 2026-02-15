import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/team/domain/entities/permission_entity.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/create_role.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/list_role_permission.dart';
import 'package:note_sondage/theme/color_palette.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/mobile/widgets/header_page.dart';
import 'package:note_sondage/ui/mobile/widgets/login/tab_bar_component.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

class RolePage extends StatefulWidget {
  const RolePage({super.key, required this.teamId});
  final String teamId;

  @override
  State<RolePage> createState() => _RolePageState();
}

class _RolePageState extends State<RolePage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  int currentViewType = 1;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    // Rimuovi il controllo indexIsChanging per reagire anche allo swipe
    if (!tabController.indexIsChanging) {
      setState(() {});
    }
  }

  void _handleViewTypeChanged(int viewType) {
    setState(() {
      currentViewType = viewType;
    });
  }

  void _handleTeamCreated() {
    // Logica per aggiornare la lista dei team
    // Potresti qui fare una chiamata API e poi cambiare tab
    setState(() {
      // Aggiorna la lista dei team
    });

    // Torna alla tab dei team selezionati
    tabController.animateTo(0);
  }

  @override
  void dispose() {
    tabController.removeListener(_handleTabChange);
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.bgColor,
      appBar: HeaderPage(
        title: "Permission Team",
        onBackPressed: () {
          // context.read<NavigationBloc>().add(NavigationPositionChanged(1));
          // context.go(RouterPaths.home);
          context.goNamed(RouterPaths.updateTeam, extra: widget.teamId);
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              TabBarComponent(
                childTab1: Text(
                  localization.grantList,
                  style: TextStyle(
                    color: tabController.index == 0
                        ? ColorPalette.primary[6]
                        : Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                childTab2: Text(
                  localization.createGrant,
                  style: TextStyle(
                    color: tabController.index == 1
                        ? ColorPalette.primary[6]
                        : Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                tabController: tabController,
                setToUpdate: setState,
              ),
              SizedBox(height: 8),
              Divider(height: 2, color: Colors.grey[400]),
              SizedBox(height: 16),

              // Contenuto dinamico basato sulla tab selezionata
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    // Prima tab: Lista permessi
                    ListRolePermission(teamId: widget.teamId),
                    // Seconda tab: Creazione permesso
                    CreateRoleWidget(teamId: widget.teamId),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
