import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/create_role.dart';
import 'package:note_sondage/feature/team/ui/mobile/widgets/list_role_permission.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
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

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!tabController.indexIsChanging) {
      setState(() {});
    }
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
            context.goNamed(RouterPaths.updateTeam, extra: widget.teamId);
          },
        ),
        centerTitle: true,
        title: Text(
          localization.roleManager,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Tab Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.homeSecondary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.borderColor!.withValues(alpha: 0.3),
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFF7C4DFF),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: colorScheme.descriptionColor,
                  labelStyle: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: textTheme.labelMedium,
                  tabs: [
                    Tab(text: localization.grantList),
                    Tab(text: localization.createGrant),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Content ──
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  ListRolePermission(teamId: widget.teamId),
                  CreateRoleWidget(teamId: widget.teamId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
