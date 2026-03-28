import 'package:flutter/material.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/sondage_component_card.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/sondage_component_row.dart';

class ResponsiveGridSondages extends StatelessWidget {
  const ResponsiveGridSondages({
    super.key,
    required this.items,
    required this.isRow,
  });

  final List<Map<String, dynamic>> items;
  final bool isRow;

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
          children: items.map((item) {
            final sondageId = item["sondageId"] as String;
            final createdDate = item["createdDate"] is String
                ? DateTime.parse(item["createdDate"])
                : item["createdDate"] as DateTime;
            final expiryDate = item["expiryDate"] is String
                ? DateTime.parse(item["expiryDate"])
                : item["expiryDate"] as DateTime;

            return isRow
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
                    onTap: () {
                      // TODO: Implementare navigazione ai dettagli del sondaggio
                      debugPrint("Clicked on sondage: ${item["sondageName"]}");
                    },
                    onDeleteTap: (sondageId) {
                      // TODO: Implementare eliminazione sondaggio
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
                    onTap: () {
                      debugPrint("Clicked on sondage: ${item["sondageName"]}");
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
