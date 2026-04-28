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

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    // Aspetta il frame successivo per non interrompere l'animazione tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SondageBloc>().add(LoadSondagesEvent());
      }
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
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
                        if (state is SondageLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final sondages = state is SondagesLoaded
                            ? state.sondages
                            : const <SondageEntity>[];
                        return SondageDisplay(
                          sondages: sondages,
                          onViewChanged: _handleViewTypeChanged,
                          initialViewType: currentViewType,
                          onDeleteTap: _confirmDelete,
                        );
                      },
                    ),
                    // Tab 1 — crea sondaggio (mai ricreato)
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
