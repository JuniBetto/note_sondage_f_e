import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/ui/bloc/sondage_bloc.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/widgets/create_sondage_mobile.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/widgets/sondage_display.dart';
import 'package:note_sondage/theme/color_palette.dart';
import 'package:note_sondage/ui/mobile/widgets/login/tab_bar_component.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

class SondageMobile extends StatefulWidget {
  const SondageMobile({super.key});

  @override
  State<SondageMobile> createState() => _SondageMobileState();
}

class _SondageMobileState extends State<SondageMobile>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  int currentViewType = 1;
  List<SondageEntity> _lastSondages = const <SondageEntity>[];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<SondageBloc>().add(LoadSondagesEvent());
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SondageBloc>().add(LoadSondagesEvent());
      }
    });
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

    return SafeArea(
      bottom: false,
      child: BlocListener<SondageBloc, SondageState>(
        listener: (context, state) {
          if (state is SondageError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TabBarComponent(
                childTab1: BlocBuilder<SondageBloc, SondageState>(
                  buildWhen: (_, current) =>
                      current is SondagesLoaded || current is SondageLoading,
                  builder: (context, _) => Text(
                    'Lista ${localization.sondage}',
                    style: TextStyle(
                      color: tabController.index == 0
                          ? ColorPalette.primary[6]
                          : Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                childTab2: Text(
                  'Create ${localization.sondage}',
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
              const SizedBox(height: 8),
              Divider(height: 2, color: Colors.grey[400]),
              const SizedBox(height: 16),
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

                        return Column(
                          children: [
                            Row(
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
                            if (isRefreshing)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: LinearProgressIndicator(minHeight: 2),
                              ),
                            Align(
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
                            const SizedBox(height: 12),
                            Expanded(
                              child: SondageDisplay(
                                sondages: sondages,
                                onViewChanged: _handleViewTypeChanged,
                                initialViewType: currentViewType,
                                onDeleteTap: _confirmDelete,
                                onEditTap: _openEditSheet,
                              ),
                            ),
                          ],
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
        ),
      ),
    );
  }
}
