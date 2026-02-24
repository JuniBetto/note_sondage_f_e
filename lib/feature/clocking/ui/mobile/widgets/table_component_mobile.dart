import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:note_sondage/feature/clocking/domain/entities/user_clock_info.dart';
import 'package:note_sondage/theme/color_palette.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class TableComponentMobile extends StatelessWidget {
  const TableComponentMobile({
    super.key,
    required this.dataTable,
    required this.headerTable,
    this.headingRowColor,
    this.headerTextTextStyle,
  });
  final List<String> headerTable;
  final List<UserClockInfo> dataTable;
  final Color? headingRowColor;
  final TextStyle? headerTextTextStyle;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    //final localization = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DataTable2(
        columnSpacing: 10.0,
        horizontalMargin: 7.0,
        minWidth: 300,
        headingRowColor: WidgetStateProperty.all(
          headingRowColor ?? colorScheme.surface,
        ),
        headingTextStyle:
            headerTextTextStyle ??
            TextStyle(
              color: colorScheme.descriptionColor,
              fontWeight: FontWeight.w600,
            ),
        headingRowDecoration: BoxDecoration(
          border: Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(8.0),
        ),
        fixedColumnsColor: Theme.of(context).colorScheme.error,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        dividerThickness: 1.0,

        border: TableBorder(
          horizontalInside: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
            width: 2,
          ),
        ),
        columns: headerTable
            .map(
              (header) => DataColumn2(
                label: Text(
                  header,
                  style: textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                size: ColumnSize.S,
              ),
            )
            .toList(),
        rows: List<DataRow>.generate(dataTable.length, (index) {
          final clockInfo = dataTable[index];
          return DataRow(
            cells: [
              DataCell(
                Text(clockInfo.user.toString(), style: textTheme.bodySmall),
              ),
              DataCell(
                Text(
                  clockInfo.clockInTime.toString(),
                  style: textTheme.bodySmall,
                ),
              ),
              DataCell(
                Text(
                  clockInfo.clockOutTime.toString(),
                  style: textTheme.bodySmall,
                ),
              ),
              DataCell(
                Text(
                  clockInfo.timeWorked.toString(),
                  style: textTheme.bodySmall,
                ),
              ),
              DataCell(
                Text(clockInfo.teamName.toString(), style: textTheme.bodySmall),
              ),
            ],
            color: WidgetStateProperty.resolveWith<Color?>((
              Set<WidgetState> states,
            ) {
              // Colore per righe pari
              return index.isEven
                  ? ColorPalette.secondary[1]
                  : ColorPalette.secondary[1].withAlpha(90);
            }),
          );
        }),
      ),
    );
  }
}
