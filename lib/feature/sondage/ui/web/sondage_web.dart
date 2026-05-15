import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/ui/bloc/sondage_bloc.dart';
import 'package:note_sondage/feature/sondage/ui/web/widgets/create_sondage_web.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/responsive_grid_sondages.dart';
import 'package:note_sondage/feature/team/ui/widgets/visual_type.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/custom_dialog.dart';
import 'package:showcaseview/showcaseview.dart';

class SondageWeb extends StatefulWidget {
  const SondageWeb({super.key, this.title = "Create Sondage"});
  final String title;

  @override
  State<SondageWeb> createState() => _SondageWebState();
}

class _SondageWebState extends State<SondageWeb> {
  final GlobalKey _headerKey = GlobalKey();
  final GlobalKey _statsKey = GlobalKey();
  final GlobalKey _listKey = GlobalKey();
  int isGridView = 1;
  List<SondageEntity> _lastSondages = const <SondageEntity>[];
  bool _tutorialScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<SondageBloc>().add(LoadSondagesEvent());
    });
  }

  Future<void> _confirmDelete(String sondageId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina sondaggio'),
        content: const Text(
          'Vuoi davvero eliminare questo draft del sondaggio?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (shouldDelete == true && mounted) {
      context.read<SondageBloc>().add(DeleteSondageEvent(sondageId));
    }
  }

  void _openCreateDialog() {
    CustomDialog(
      title: widget.title,
      width: 760,
      child: CreateSondageWeb(
        onsondageCreated: () {
          context.read<SondageBloc>().add(LoadSondagesEvent());
        },
      ),
    ).show(context);
  }

  void _openEditDialog(SondageEntity sondage) {
    CustomDialog(
      title: 'Modifica sondaggio',
      width: 760,
      child: CreateSondageWeb(
        initialSondage: sondage,
        onsondageCreated: () {
          context.read<SondageBloc>().add(LoadSondagesEvent());
        },
      ),
    ).show(context);
  }

  void _refreshList() {
    context.read<SondageBloc>().add(LoadSondagesEvent());
  }

  int _countByStatus(List<SondageEntity> sondages, SondageStatus status) {
    return sondages.where((sondage) => sondage.status == status).length;
  }

  Widget _buildStatChip({
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text('$label: $value'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    AppTutorialController.registerTargets(
      tutorialId: 'web-sondage-list',
      keys: <GlobalKey>[_headerKey, _statsKey, _listKey],
    );
    AppTutorialController.registerReplayAction(
      tutorialId: 'web-sondage-list',
      action: () => AppTutorialController.replay(
        context: context,
        keys: <GlobalKey>[_headerKey, _statsKey, _listKey],
      ),
    );
    AppTutorialController.registerReplayAction(
      tutorialId: 'web-main-4',
      action: () => AppTutorialController.replayRegistered(
        context: context,
        tutorialId: 'web-sondage-list',
      ),
    );
    _scheduleTutorial();

    return BlocConsumer<SondageBloc, SondageState>(
      listener: (context, state) {
        if (state is SondageError) {
          AppSnackBar.showError(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is SondagesLoaded) {
          _lastSondages = state.sondages;
        }
        final List<SondageEntity> sondages = state is SondagesLoaded
            ? state.sondages
            : _lastSondages;
        final isLoading =
            (state is SondageLoading || state is SondageInitial) &&
            sondages.isEmpty;
        final isRefreshing = state is SondageLoading && sondages.isNotEmpty;
        final draftCount = _countByStatus(sondages, SondageStatus.draft);
        final activeCount = _countByStatus(sondages, SondageStatus.active);
        final completedCount = _countByStatus(
          sondages,
          SondageStatus.completed,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.bgNavbarSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Showcase(
                  key: _headerKey,
                  title: _isItalian(context)
                      ? 'Feed dei sondaggi'
                      : 'Survey feed',
                  description: _isItalian(context)
                      ? 'Qui controlli il feed dei sondaggi, puoi aggiornarlo e aprire la sotto-pagina di creazione.'
                      : 'Use this section to review the survey feed, refresh it, and open the creation subpage.',
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      runSpacing: 12,
                      spacing: 12,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.sondage,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: colorScheme.iconLabel,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Feed unificato di bozze personali, bozze team visibili e sondaggi attivi.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.descriptionColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _refreshList,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Aggiorna'),
                            ),
                            FilledButton.icon(
                              onPressed: _openCreateDialog,
                              icon: const Icon(Icons.poll_rounded, size: 20),
                              label: Text(
                                '${AppLocalizations.of(context)!.create} ${AppLocalizations.of(context)!.sondage}',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.secondary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (isRefreshing) const LinearProgressIndicator(minHeight: 2),
                Showcase(
                  key: _statsKey,
                  title: _isItalian(context)
                      ? 'Statistiche del feed'
                      : 'Feed statistics',
                  description: _isItalian(context)
                      ? 'Questi indicatori riassumono bozze, sondaggi attivi e sondaggi chiusi.'
                      : 'These chips summarize draft, active, and closed surveys in your feed.',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildStatChip(
                          label: 'Draft',
                          value: draftCount,
                          color: Colors.orange,
                        ),
                        _buildStatChip(
                          label: 'Attivi',
                          value: activeCount,
                          color: Colors.green,
                        ),
                        _buildStatChip(
                          label: 'Chiusi',
                          value: completedCount,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Divider(height: 4, color: colorScheme.borderColor),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${sondages.length} elementi nel feed',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.descriptionColor,
                          ),
                        ),
                      ),
                      VisualType(
                        isActive1: isGridView == 1,
                        isActive2: isGridView == 2,
                        color: colorScheme.cursorColor,
                        iconData1: Icons.window_sharp,
                        iconData2: Icons.list,
                        onTap1: () => setState(() => isGridView = 1),
                        onTap2: () => setState(() => isGridView = 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Showcase(
                    key: _listKey,
                    title: _isItalian(context)
                        ? 'Lista dei sondaggi'
                        : 'Survey list',
                    description: _isItalian(context)
                        ? 'Questa è la zona principale del feed: apri, modifica o elimina i sondaggi da qui.'
                        : 'This is the main feed area: open, edit, or delete surveys from here.',
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                      child: SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colorScheme.borderColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (colorScheme.bgNavbarSurface ??
                                            Colors.black)
                                        .withValues(alpha: 0.2),
                                blurRadius: 8,
                                spreadRadius: 2,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ResponsiveGridSondages(
                                  items: sondages,
                                  isRow: isGridView == 1,
                                  onDeleteTap: _confirmDelete,
                                  onEditTap: _openEditDialog,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scheduleTutorial() {
    if (_tutorialScheduled) {
      return;
    }
    _tutorialScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await AppTutorialController.showIfNeeded(
        context: context,
        tutorialId: 'web-sondage-list',
        userId: context.read<AuthBloc>().state.user.uid,
        keys: <GlobalKey>[_headerKey, _statsKey, _listKey],
      );
    });
  }

  bool _isItalian(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'it';
  }
}
