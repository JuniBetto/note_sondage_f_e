import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/archive/user_archive_service.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/core/dependency_injection/dependency_injection.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/ui/bloc/sondage_bloc.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/sondage_component_card.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/sondage_component_row.dart';
import 'package:note_sondage/ui/widgets/archive_view_toggle.dart';

class ResponsiveGridSondages extends StatefulWidget {
  const ResponsiveGridSondages({
    super.key,
    required this.items,
    required this.isRow,
    required this.onDeleteTap,
    required this.onEditTap,
    this.shrinkWrapLayout = false,
  });

  final List<SondageEntity> items;
  final bool isRow;
  final ValueChanged<String> onDeleteTap;
  final ValueChanged<SondageEntity> onEditTap;
  final bool shrinkWrapLayout;

  @override
  State<ResponsiveGridSondages> createState() => _ResponsiveGridSondagesState();
}

class _ResponsiveGridSondagesState extends State<ResponsiveGridSondages> {
  final UserArchiveService _archiveService = getIt<UserArchiveService>();
  final SondageBloc _sondageBloc = getIt<SondageBloc>();
  String? _selectedSondageId;
  bool _showArchivedOnly = false;
  Set<String> _archivedSondageIds = <String>{};

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadArchivedSondages();
  }

  Future<void> _loadArchivedSondages() async {
    final archived = await _archiveService.loadArchivedIds(
      userId: _currentUserId,
      bucket: ArchiveBuckets.sondages,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _archivedSondageIds = archived;
    });
  }

  Future<void> _toggleArchive(String sondageId) async {
    await _archiveService.toggleArchived(
      userId: _currentUserId,
      bucket: ArchiveBuckets.sondages,
      itemId: sondageId,
    );
    await _loadArchivedSondages();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Center(
        child: Text('Nessun draft o sondaggio attivo disponibile'),
      );
    }

    final foregroundItems = widget.items
        .where((item) => !_archivedSondageIds.contains(item.id))
        .toList();
    final archivedItems = widget.items
        .where((item) => _archivedSondageIds.contains(item.id))
        .toList();
    final displayedItems = _showArchivedOnly ? archivedItems : foregroundItems;

    final content = displayedItems.isEmpty
        ? Center(
            child: Text(
              _showArchivedOnly
                  ? 'Nessun sondaggio archiviato.'
                  : 'Nessun sondaggio in primo piano.',
            ),
          )
        : (widget.isRow
              ? _buildGridView(displayedItems)
              : _buildListView(displayedItems));

    if (widget.shrinkWrapLayout) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ArchiveViewToggle(
                showArchivedOnly: _showArchivedOnly,
                primaryCount: foregroundItems.length,
                archivedCount: archivedItems.length,
                onChanged: (value) {
                  setState(() => _showArchivedOnly = value);
                },
              ),
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ArchiveViewToggle(
              showArchivedOnly: _showArchivedOnly,
              primaryCount: foregroundItems.length,
              archivedCount: archivedItems.length,
              onChanged: (value) {
                setState(() => _showArchivedOnly = value);
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildGridView(List<SondageEntity> items) {
    return GridView.builder(
      shrinkWrap: widget.shrinkWrapLayout,
      physics: widget.shrinkWrapLayout
          ? const NeverScrollableScrollPhysics()
          : null,
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 340,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 210,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final sondageId = item.id;
        final canEditAsCreator =
            item.createdByUserId == _currentUserId && item.canEdit;
        final isArchived = _archivedSondageIds.contains(sondageId);
        return SondageComponentCard(
          key: ValueKey('sondage_card_$sondageId'),
          sondageName: item.name,
          sondageFocus: (item.description?.trim().isNotEmpty ?? false)
              ? item.description!
              : item.focus,
          sondageId: sondageId,
          status: item.status.name,
          responses: item.responses,
          totalQuestions: item.totalQuestions,
          createdDate: item.createdDate,
          expiryDate: item.expiryDate,
          colorSondage: item.color,
          canDelete: item.canDelete,
          canEdit: canEditAsCreator,
          isSyncing: _sondageBloc.syncingSondageIds.contains(sondageId),
          isArchived: isArchived,
          isActive: _selectedSondageId == sondageId,
          onTap: () {
            setState(() => _selectedSondageId = sondageId);
            context.go(RouterPaths.sondageDetail, extra: sondageId);
          },
          onEditTap: canEditAsCreator ? () => widget.onEditTap(item) : null,
          onArchiveTap: () => _toggleArchive(sondageId),
          onDeleteTap: widget.onDeleteTap,
        );
      },
    );
  }

  Widget _buildListView(List<SondageEntity> items) {
    return ListView.separated(
      shrinkWrap: widget.shrinkWrapLayout,
      physics: widget.shrinkWrapLayout
          ? const NeverScrollableScrollPhysics()
          : null,
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final sondageId = item.id;
        final canEditAsCreator =
            item.createdByUserId == _currentUserId && item.canEdit;
        final isArchived = _archivedSondageIds.contains(sondageId);
        return SondageComponentRow(
          key: ValueKey('sondage_row_$sondageId'),
          sondageName: item.name,
          sondageFocus: (item.description?.trim().isNotEmpty ?? false)
              ? item.description!
              : item.focus,
          sondageId: sondageId,
          status: item.status.name,
          responses: item.responses,
          totalQuestions: item.totalQuestions,
          createdDate: item.createdDate,
          expiryDate: item.expiryDate,
          colorSondage: item.color,
          canDelete: item.canDelete,
          canEdit: canEditAsCreator,
          isSyncing: _sondageBloc.syncingSondageIds.contains(sondageId),
          isArchived: isArchived,
          isActive: _selectedSondageId == sondageId,
          onTap: () {
            setState(() => _selectedSondageId = sondageId);
            context.go(RouterPaths.sondageDetail, extra: sondageId);
          },
          onEditTap: canEditAsCreator ? () => widget.onEditTap(item) : null,
          onArchiveTap: () => _toggleArchive(sondageId),
          onDeleteTap: widget.onDeleteTap,
        );
      },
    );
  }
}
