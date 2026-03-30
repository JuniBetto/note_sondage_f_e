import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:note_sondage/core/config/routes.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/sondage_component_card.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/sondage_component_row.dart';

class ResponsiveGridSondages extends StatefulWidget {
  const ResponsiveGridSondages({
    super.key,
    required this.items,
    required this.isRow,
  });

  final List<Map<String, dynamic>> items;
  final bool isRow;

  @override
  State<ResponsiveGridSondages> createState() => _ResponsiveGridSondagesState();
}

class _ResponsiveGridSondagesState extends State<ResponsiveGridSondages> {
  String? _selectedSondageId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Wrap(
          alignment: WrapAlignment.spaceAround,
          runSpacing: 8.0,
          spacing: 8.0,
          children: widget.items.map((item) {
            final sondageId = item["sondageId"] as String;
            final createdDate = item["createdDate"] is String
                ? DateTime.parse(item["createdDate"])
                : item["createdDate"] as DateTime;
            final expiryDate = item["expiryDate"] is String
                ? DateTime.parse(item["expiryDate"])
                : item["expiryDate"] as DateTime;

            return widget.isRow
                ? SondageComponentCard(
                    key: ValueKey('sondage_card_$sondageId'),
                    sondageName: item["sondageName"],
                    sondageFocus: item["sondageFocus"],
                    sondageId: sondageId,
                    status: item["status"],
                    responses: item["responses"],
                    totalQuestions: item["totalQuestions"],
                    createdDate: createdDate,
                    expiryDate: expiryDate,
                    colorSondage: item["color"],
                    isActive: _selectedSondageId == sondageId,
                    onTap: () {
                      setState(() => _selectedSondageId = sondageId);
                      context.go(RouterPaths.sondageDetail, extra: sondageId);
                    },
                    onDeleteTap: (sondageId) {
                      debugPrint("Delete sondage: $sondageId");
                    },
                  )
                : SondageComponentRow(
                    key: ValueKey('sondage_row_$sondageId'),
                    sondageName: item["sondageName"],
                    sondageFocus: item["sondageFocus"],
                    sondageId: sondageId,
                    status: item["status"],
                    responses: item["responses"],
                    totalQuestions: item["totalQuestions"],
                    createdDate: createdDate,
                    expiryDate: expiryDate,
                    colorSondage: item["color"],
                    isActive: _selectedSondageId == sondageId,
                    onTap: () {
                      setState(() => _selectedSondageId = sondageId);
                      context.go(RouterPaths.sondageDetail, extra: sondageId);
                    },
                    onDeleteTap: (sondageId) {
                      debugPrint("Delete sondage: $sondageId");
                    },
                  );
          }).toList(),
        ),
      ),
    );
  }
}
