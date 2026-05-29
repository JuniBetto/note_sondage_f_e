import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/ui/bloc/sondage_bloc.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/widgets/create_sondage_mobile.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/widgets/sondage_display.dart';
import 'package:note_sondage/theme/color_palette.dart';
import 'package:note_sondage/ui/mobile/widgets/login/tab_bar_component.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:showcaseview/showcaseview.dart';

class SondageMobile extends StatefulWidget {
  const SondageMobile({super.key});

  @override
  State<SondageMobile> createState() => _SondageMobileState();
}

class _SondageMobileState extends State<SondageMobile>
    with SingleTickerProviderStateMixin {
  final GlobalKey _summaryKey = GlobalKey();
  final GlobalKey _statsKey = GlobalKey();
  final GlobalKey _listKey = GlobalKey();
  late TabController tabController;
  int currentViewType = 1;
  List<SondageEntity> _lastSondages = const <SondageEntity>[];
  bool _listTutorialScheduled = false;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final blocState = context.read<SondageBloc>().state;
      if (blocState is! SondagesLoaded && blocState is! SondageLoading) {
        context.read<SondageBloc>().add(LoadSondagesEvent());
      }
    });
  }

  void _handleTabChange() => setState(() {});

  void _handleViewTypeChanged(int viewType) {
    setState(() {
      currentViewType = viewType;
    });
  }

  void _handleSondageCreated() {
    tabController.animateTo(0);
  }

  Future<void> _openEditSheet(SondageEntity sondage) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: FractionallySizedBox(
            heightFactor: 0.92,
            child: CreateSondageMobile(
              initialSondage: sondage,
              onsondageCreated: _handleSondageCreated,
            ),
          ),
        );
      },
    );
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

  void _refreshList() {
    context.read<SondageBloc>().add(LoadSondagesEvent());
  }

  int _countByStatus(List<SondageEntity> sondages, SondageStatus status) {
    return sondages.where((sondage) => sondage.status == status).length;
  }

  Widget _buildSummaryChip({
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text('$label: $value'),
    );
  }

  @override
  void dispose() {
    tabController.removeListener(_handleTabChange);
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final orientation = MediaQuery.orientationOf(context);

    AppTutorialController.registerReplayAction(
      tutorialId: 'mobile-main-4',
      action: () => AppTutorialController.replayRegistered(
        context: context,
        tutorialId: tabController.index == 0
            ? 'mobile-sondage-list'
            : 'mobile-sondage-create',
      ),
    );
    AppTutorialController.registerTargets(
      tutorialId: 'mobile-sondage-list',
      keys: <GlobalKey>[_summaryKey, _statsKey, _listKey],
    );
    AppTutorialController.registerReplayAction(
      tutorialId: 'mobile-sondage-list',
      action: () => AppTutorialController.replay(
        context: context,
        keys: <GlobalKey>[_summaryKey, _statsKey, _listKey],
      ),
    );
    if (tabController.index == 0) {
      _scheduleListTutorial();
    }

    return SafeArea(
      bottom: false,
      child: BlocListener<SondageBloc, SondageState>(
        listener: (context, state) {
          if (state is SondageError) {
            AppSnackBar.showError(context, state.message);
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useLandscapeCompactLayout =
                orientation == Orientation.landscape &&
                constraints.maxHeight < 560;
            final pagePadding = EdgeInsets.symmetric(
              horizontal: useLandscapeCompactLayout ? 12 : 16,
              vertical: useLandscapeCompactLayout ? 10 : 16,
            );
            final sectionSpacing = useLandscapeCompactLayout ? 8.0 : 16.0;

            return Padding(
              padding: pagePadding,
              child: Column(
                children: [
                  TabBarComponent(
                    childTab1: BlocBuilder<SondageBloc, SondageState>(
                      buildWhen: (_, current) =>
                          current is SondagesLoaded ||
                          current is SondageLoading,
                      builder: (context, _) => Text(
                        'Lista ${localization.sondage}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    childTab2: Text(
                      'Create ${localization.sondage}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    tabController: tabController,
                    setToUpdate: setState,
                  ),
                  SizedBox(height: useLandscapeCompactLayout ? 6 : 8),
                  Divider(height: 2, color: Colors.grey[400]),
                  SizedBox(height: sectionSpacing),
                  Expanded(
                    child: TabBarView(
                      controller: tabController,
                      children: [
                        // Tab 0 — lista sondaggi
                        BlocBuilder<SondageBloc, SondageState>(
                          buildWhen: (_, current) =>
                              current is SondageLoading ||
                              current is SondagesLoaded ||
                              current is SondageError,
                          builder: (context, state) {
                            if ((state is SondageLoading ||
                                    state is SondageInitial) &&
                                _lastSondages.isEmpty) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (state is SondagesLoaded) {
                              _lastSondages = state.sondages;
                            }
                            final sondages = state is SondagesLoaded
                                ? state.sondages
                                : _lastSondages;
                            final isRefreshing =
                                state is SondageLoading && sondages.isNotEmpty;
                            final draftCount = _countByStatus(
                              sondages,
                              SondageStatus.draft,
                            );
                            final activeCount = _countByStatus(
                              sondages,
                              SondageStatus.active,
                            );
                            final completedCount = _countByStatus(
                              sondages,
                              SondageStatus.completed,
                            );

                            final summaryHeader = Showcase(
                              key: _summaryKey,
                              title: _isItalian(context)
                                  ? 'Panoramica sondaggi'
                                  : 'Survey overview',
                              description: _isItalian(context)
                                  ? 'Questa intestazione ti aiuta a capire subito cosa stai guardando e ti permette di aggiornare il feed.'
                                  : 'This header explains the feed at a glance and lets you refresh the survey data.',
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Bozze e sondaggi attivi dei tuoi team',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _refreshList,
                                    icon: const Icon(Icons.refresh_rounded),
                                    tooltip: 'Aggiorna',
                                  ),
                                ],
                              ),
                            );
                            final statsSection = Showcase(
                              key: _statsKey,
                              title: _isItalian(context)
                                  ? 'Statistiche rapide'
                                  : 'Quick stats',
                              description: _isItalian(context)
                                  ? 'Qui vedi quante bozze, quanti sondaggi attivi e quanti chiusi hai nel feed.'
                                  : 'See how many draft, active, and closed surveys you currently have in the feed.',
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildSummaryChip(
                                      label: 'Draft',
                                      value: draftCount,
                                      color: Colors.orange,
                                    ),
                                    _buildSummaryChip(
                                      label: 'Attivi',
                                      value: activeCount,
                                      color: Colors.green,
                                    ),
                                    _buildSummaryChip(
                                      label: 'Chiusi',
                                      value: completedCount,
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ),
                            );
                            final listSection = Showcase(
                              key: _listKey,
                              title: _isItalian(context)
                                  ? 'Lista dei sondaggi'
                                  : 'Survey list',
                              description: _isItalian(context)
                                  ? 'Da questa lista puoi aprire, modificare o eliminare i sondaggi che ti competono.'
                                  : 'Use this list to open, edit, or delete the surveys that belong to you or your teams.',
                              child: SondageDisplay(
                                sondages: sondages,
                                onViewChanged: _handleViewTypeChanged,
                                initialViewType: currentViewType,
                                onDeleteTap: _confirmDelete,
                                onEditTap: _openEditSheet,
                              ),
                            );

                            if (!useLandscapeCompactLayout) {
                              return Column(
                                children: [
                                  summaryHeader,
                                  if (isRefreshing)
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 12),
                                      child: LinearProgressIndicator(
                                        minHeight: 2,
                                      ),
                                    ),
                                  statsSection,
                                  const SizedBox(height: 12),
                                  Expanded(child: listSection),
                                ],
                              );
                            }

                            return SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    summaryHeader,
                                    if (isRefreshing)
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 12),
                                        child: LinearProgressIndicator(
                                          minHeight: 2,
                                        ),
                                      ),
                                    statsSection,
                                    const SizedBox(height: 12),
                                    listSection,
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        CreateSondageMobile(
                          onsondageCreated: _handleSondageCreated,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _scheduleListTutorial() {
    if (_listTutorialScheduled) {
      return;
    }
    _listTutorialScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || tabController.index != 0) {
        return;
      }
      await AppTutorialController.showIfNeeded(
        context: context,
        tutorialId: 'mobile-sondage-list',
        userId: context.read<AuthBloc>().state.user.uid,
        keys: <GlobalKey>[_summaryKey, _statsKey, _listKey],
      );
    });
  }

  bool _isItalian(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'it';
  }
}
