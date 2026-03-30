import 'package:flutter/material.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/create_role.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/list_role_permission.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

const _kMaxWidth = 1200.0;
const _kHeightRatio = 0.88;
const _kPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);

class RolePageWeb extends StatefulWidget {
  const RolePageWeb({super.key, required this.teamId});
  final String teamId;

  @override
  State<RolePageWeb> createState() => _RolePageWebState();
}

class _RolePageWebState extends State<RolePageWeb>
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
    if (tabController.indexIsChanging) {
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
    final textTheme = theme.textTheme;
    final localization = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: _kMaxWidth,
              maxHeight: constraints.maxHeight * _kHeightRatio,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Prima tab: Lista ruoli
                        Text(
                          localization.roleList,
                          style: textTheme.headlineMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: ListRolePermission(
                            isMobile: false,
                            teamId: widget.teamId,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Prima tab: Lista ruoli
                        Text(
                          localization.createRole,
                          style: textTheme.headlineMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: CreateRoleWidget(teamId: widget.teamId),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
