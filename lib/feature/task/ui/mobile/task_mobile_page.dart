import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/task/ui/task_workspace.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/mobile/widgets/header_page.dart';

class TaskMobilePage extends StatelessWidget {
  const TaskMobilePage({super.key, this.initialTeamId});

  final String? initialTeamId;

  void _handleBack(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.go(RouterPaths.home);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.bgSurface,
      appBar: HeaderPage(
        title: AppLocalizations.of(context)!.taskPageTitle,
        onBackPressed: () => _handleBack(context),
      ),
      body: SafeArea(
        top: false,
        child: TaskWorkspace(initialTeamId: initialTeamId),
      ),
    );
  }
}
