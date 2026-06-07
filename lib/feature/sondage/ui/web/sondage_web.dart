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
import 'package:note_sondage/ui/widgets/app_search_field.dart';
import 'package:note_sondage/ui/widgets/custom_dialog.dart';
import 'package:note_sondage/core/tutorial/debug_showcase.dart';

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
  final TextEditingController _searchController = TextEditingController();
  int isGridView = 1;
  List<SondageEntity> _lastSondages = const <SondageEntity>[];
  bool _tutorialScheduled = false;
  String _searchQuery = '';
  SondageStatus? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(String sondageId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina sondaggio'),
        content: const Text('Vuoi davvero eliminare questo sondaggio?'),
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
      child: const CreateSondageWeb(),
    ).show(context);
  }

  void _openEditDialog(SondageEntity sondage) {
    if (!sondage.canEdit) {
      AppSnackBar.showWarning(
        context,
        Localizations.localeOf(context).languageCode == 'it'
            ? 'Non hai i permessi per modificare questo sondaggio.'
            : 'You do not have permission to edit this survey.',
      );
      return;
    }
    CustomDialog(
      title: 'Modifica sondaggio',
      width: 760,
      child: CreateSondageWeb(initialSondage: sondage),
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
    required SondageStatus status,
  }) {
    final isSelected = _selectedStatusFilter == status;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() {
          _selectedStatusFilter = isSelected ? null : status;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.22)
              : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.75)
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
        final filteredSondages = _filterSondages(sondages);

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
                              const SizedBox(height: 14),
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
                          status: SondageStatus.draft,
                        ),
                        _buildStatChip(
                          label: 'Attivi',
                          value: activeCount,
                          color: Colors.green,
                          status: SondageStatus.active,
                        ),
                        _buildStatChip(
                          label: 'Chiusi',
                          value: completedCount,
                          color: Colors.red,
                          status: SondageStatus.completed,
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
                          _searchQuery.trim().isEmpty
                              ? '${sondages.length} elementi nel feed'
                              : '${filteredSondages.length} risultati trovati',
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
                                  items: filteredSondages,
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
