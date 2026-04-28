import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/sondage_component_card.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/sondage_component_row.dart';

class ResponsiveGridSondages extends StatefulWidget {
  const ResponsiveGridSondages({
    super.key,
    required this.items,
    required this.isRow,
    required this.onDeleteTap,
  });

  final List<SondageEntity> items;
  final bool isRow;
  final ValueChanged<String> onDeleteTap;

  @override
  State<ResponsiveGridSondages> createState() => _ResponsiveGridSondagesState();
}

class _ResponsiveGridSondagesState extends State<ResponsiveGridSondages> {
  String? _selectedSondageId;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Center(
        child: Text('Nessun sondaggio disponibile'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: widget.isRow ? _buildGridView() : _buildListView(),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 340,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 210,
      ),
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        final sondageId = item.id;
        return SondageComponentCard(
          key: ValueKey('sondage_card_$sondageId'),
          sondageName: item.name,
          sondageFocus: item.focus,
          sondageId: sondageId,
          status: item.status.name,
          responses: item.responses,
          totalQuestions: item.totalQuestions,
          createdDate: item.createdDate,
          expiryDate: item.expiryDate,
          colorSondage: item.color,
          canDelete: item.canDelete,
          isActive: _selectedSondageId == sondageId,
          onTap: () {
            setState(() => _selectedSondageId = sondageId);
            context.go(RouterPaths.sondageDetail, extra: sondageId);
          },
          onDeleteTap: widget.onDeleteTap,
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: widget.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = widget.items[index];
        final sondageId = item.id;
        return SondageComponentRow(
          key: ValueKey('sondage_row_$sondageId'),
          sondageName: item.name,
          sondageFocus: item.focus,
          sondageId: sondageId,
          status: item.status.name,
          responses: item.responses,
          totalQuestions: item.totalQuestions,
          createdDate: item.createdDate,
          expiryDate: item.expiryDate,
          colorSondage: item.color,
          canDelete: item.canDelete,
          isActive: _selectedSondageId == sondageId,
          onTap: () {
            setState(() => _selectedSondageId = sondageId);
            context.go(RouterPaths.sondageDetail, extra: sondageId);
          },
          onDeleteTap: widget.onDeleteTap,
        );
      },
    );
  }
}
