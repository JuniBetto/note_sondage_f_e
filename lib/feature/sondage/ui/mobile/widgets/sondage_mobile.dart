import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/core/tutorial/app_tutorial_controller.dart';
import 'package:note_sondage/feature/auth/ui/bloc/auth_bloc.dart';
import 'package:note_sondage/feature/chat/ui/mobile/chat_mobile_team_list_page.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/ui/bloc/sondage_bloc.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/widgets/create_sondage_mobile.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/widgets/sondage_display.dart';
import 'package:note_sondage/ui/mobile/widgets/login/tab_bar_component.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/app_confirmation_dialog.dart';
import 'package:note_sondage/ui/widgets/app_search_field.dart';
import 'package:note_sondage/core/tutorial/debug_showcase.dart';

class SondageMobile extends StatefulWidget {
  const SondageMobile({
    super.key,
    this.initialTabIndex = 0,
    this.initialChatTeamId,
  });

  final int initialTabIndex;
  final String? initialChatTeamId;

  @override
  State<SondageMobile> createState() => _SondageMobileState();
}

class _SondageMobileState extends State<SondageMobile>
    with SingleTickerProviderStateMixin {
  final GlobalKey _summaryKey = GlobalKey();
  final GlobalKey _statsKey = GlobalKey();
  final GlobalKey _listKey = GlobalKey();
  late TabController tabController;
  final TextEditingController _searchController = TextEditingController();
  int currentViewType = 1;
  List<SondageEntity> _lastSondages = const <SondageEntity>[];
  bool _listTutorialScheduled = false;
  String _searchQuery = '';
  SondageStatus? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    final safeInitialTab = widget.initialTabIndex.clamp(0, 2);
    tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: safeInitialTab,
    );
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
    final localization = AppLocalizations.of(context)!;
    if (!sondage.canEdit) {
      AppSnackBar.showWarning(context, localization.noPermissionToEditSurvey);
      return;
    }
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
    final localization = AppLocalizations.of(context)!;
    final shouldDelete = await showAppConfirmationDialog(
      context,
      title: localization.deleteSurveyTitle,
      message: localization.deleteSurveyMessage,
      confirmLabel: localization.deleteAction,
      destructive: true,
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
    required SondageStatus status,
  }) {
    final isSelected = _selectedStatusFilter == status;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          _selectedStatusFilter = isSelected ? null : status;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.22)
              : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.7)
                : color.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
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
            Text(
              '$label: $value',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color.withValues(alpha: 0.95) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    tabController.removeListener(_handleTabChange);
    tabController.dispose();
    _searchController.dispose();
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
        tutorialId: tabController.index == 1
            ? 'mobile-sondage-create'
            : 'mobile-sondage-list',
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
                      builder: (context, _) =>
                          Text('Lista ${localization.sondage}'),
                    ),
                    childTab2: Text('Create ${localization.sondage}'),
                    childTab3: const Text('Chat'),
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
                            final filteredSondages = _filterSondages(sondages);

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
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Bozze e sondaggi attivi dei tuoi team',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 12),
                                        AppSearchField(
                                          controller: _searchController,
                                          hintText: _isItalian(context)
                                              ? 'Cerca sondaggio, team o opzione'
                                              : 'Search survey, team, or option',
                                          onChanged: (value) {
                                            setState(() {
                                              _searchQuery = value;
                                            });
                                          },
                                        ),
                                      ],
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
                                      status: SondageStatus.draft,
                                    ),
                                    _buildSummaryChip(
                                      label: 'Attivi',
                                      value: activeCount,
                                      color: Colors.green,
                                      status: SondageStatus.active,
                                    ),
                                    _buildSummaryChip(
                                      label: 'Chiusi',
                                      value: completedCount,
                                      color: Colors.red,
                                      status: SondageStatus.completed,
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
                                sondages: filteredSondages,
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
                        ChatMobileTeamListPage(
                          initialTeamId: widget.initialChatTeamId,
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

  List<SondageEntity> _filterSondages(List<SondageEntity> sondages) {
    final normalized = _searchQuery.trim().toLowerCase();
    return sondages.where((sondage) {
      final matchesStatus =
          _selectedStatusFilter == null ||
          sondage.status == _selectedStatusFilter;
      if (!matchesStatus) {
        return false;
      }
      if (normalized.isEmpty) {
        return true;
      }
      final searchable = [
        sondage.name,
        sondage.focus,
        sondage.description ?? '',
        sondage.teamName ?? '',
        ...sondage.options.map((option) => option.label),
      ].join(' ').toLowerCase();
      return searchable.contains(normalized);
    }).toList();
  }
}
