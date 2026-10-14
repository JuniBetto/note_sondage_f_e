import 'package:flutter/material.dart';
import 'package:note_sondage/feature/shift/ui/utils/shift_report_table_data.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

/// Scelta fatta nel modal di esportazione.
class ShiftReportExportSelection {
  const ShiftReportExportSelection({
    required this.format,
    required this.columns,
    required this.order,
  });

  final ShiftReportExportFormat format;

  /// Colonne selezionate, nell'ordine scelto.
  final List<ShiftReportColumn> columns;

  /// Ordine di tutte le colonne (anche quelle non selezionate).
  final List<ShiftReportColumn> order;
}

/// Modal di esportazione del report turni: formato (PDF, CSV, Excel) e colonne
/// da includere, riordinabili con il drag.
class ShiftReportExportDialog extends StatefulWidget {
  const ShiftReportExportDialog({
    super.key,
    required this.subtitle,
    required this.initialColumns,
    this.initialOrder,
    this.initialFormat = ShiftReportExportFormat.pdf,
  });

  final String subtitle;
  final List<ShiftReportColumn> initialColumns;

  /// Ordine di partenza di tutte le colonne; se assente si parte da
  /// [initialColumns] seguite dalle altre.
  final List<ShiftReportColumn>? initialOrder;
  final ShiftReportExportFormat initialFormat;

  /// Restituisce formato e colonne (nell'ordine scelto), oppure `null`
  /// se l'utente annulla.
  static Future<ShiftReportExportSelection?> show(
    BuildContext context, {
    required String subtitle,
    required List<ShiftReportColumn> initialColumns,
    List<ShiftReportColumn>? initialOrder,
    ShiftReportExportFormat initialFormat = ShiftReportExportFormat.pdf,
  }) {
    return showDialog<ShiftReportExportSelection>(
      context: context,
      builder: (_) => ShiftReportExportDialog(
        subtitle: subtitle,
        initialColumns: initialColumns,
        initialOrder: initialOrder,
        initialFormat: initialFormat,
      ),
    );
  }

  @override
  State<ShiftReportExportDialog> createState() =>
      _ShiftReportExportDialogState();
}

class _ShiftReportExportDialogState extends State<ShiftReportExportDialog> {
  late List<ShiftReportColumn> _order;
  late Set<ShiftReportColumn> _selected;
  late ShiftReportExportFormat _format;

  @override
  void initState() {
    super.initState();
    _format = widget.initialFormat;
    _selected = widget.initialColumns.toSet();
    final base = widget.initialOrder ?? widget.initialColumns;
    _order = [
      ...base,
      ...ShiftReportColumn.values.where((column) => !base.contains(column)),
    ];
  }

  String _label(AppLocalizations loc, ShiftReportColumn column) {
    switch (column) {
      case ShiftReportColumn.date:
        return loc.shiftReportDateColumn;
      case ShiftReportColumn.user:
        return loc.shiftReportUserColumn;
      case ShiftReportColumn.account:
        return loc.shiftReportAccountColumn;
      case ShiftReportColumn.profile:
        return loc.shiftReportProfileColumn;
      case ShiftReportColumn.start:
        return loc.start;
      case ShiftReportColumn.end:
        return loc.end;
      case ShiftReportColumn.type:
        return loc.shiftReportTypeColumn;
      case ShiftReportColumn.note:
        return loc.note;
    }
  }

  String _formatTitle(ShiftReportExportFormat format) {
    switch (format) {
      case ShiftReportExportFormat.pdf:
        return 'PDF';
      case ShiftReportExportFormat.csv:
        return 'CSV';
      case ShiftReportExportFormat.excel:
        return 'Excel';
    }
  }

  String _formatHint(AppLocalizations loc, ShiftReportExportFormat format) {
    switch (format) {
      case ShiftReportExportFormat.pdf:
        return loc.shiftReportExportFormatPdfHint;
      case ShiftReportExportFormat.csv:
        return loc.shiftReportExportFormatCsvHint;
      case ShiftReportExportFormat.excel:
        return loc.shiftReportExportFormatExcelHint;
    }
  }

  void _toggle(ShiftReportColumn column, bool value) {
    setState(() {
      if (value) {
        _selected.add(column);
      } else if (_selected.length > 1) {
        // Serve almeno una colonna per generare il report.
        _selected.remove(column);
      }
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _order.removeAt(oldIndex);
      _order.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final accent = colorScheme.bgNavbarbutton ?? colorScheme.primary;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: colorScheme.bgNavbarSurface ?? theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.shiftReportExportTitle,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.descriptionColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.shiftReportExportFormat,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final format in ShiftReportExportFormat.values)
                          _FormatCard(
                            title: _formatTitle(format),
                            hint: _formatHint(loc, format),
                            selected: _format == format,
                            accent: accent,
                            onTap: () => setState(() => _format = format),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          loc.shiftReportExportColumns,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          loc.shiftReportExportColumnsCount(
                            _selected.length,
                            _order.length,
                          ),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.descriptionColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.shiftReportExportDragHint,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.descriptionColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      onReorder: _reorder,
                      proxyDecorator: (child, _, _) => Material(
                        color: Colors.transparent,
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: child,
                      ),
                      children: [
                        for (var i = 0; i < _order.length; i++)
                          _ColumnTile(
                            key: ValueKey(_order[i]),
                            index: i,
                            label: _label(loc, _order[i]),
                            selected: _selected.contains(_order[i]),
                            onChanged: (value) => _toggle(_order[i], value),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(loc.cancel),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(
                      ShiftReportExportSelection(
                        format: _format,
                        columns: _order.where(_selected.contains).toList(),
                        order: List.of(_order),
                      ),
                    ),
                    icon: Icon(
                      Icons.download_rounded,
                      color: colorScheme.textInvertedColor,
                    ),
                    label: Text(
                      loc.shiftReportDownload,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.textInvertedColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(backgroundColor: accent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColumnTile extends StatelessWidget {
  const _ColumnTile({
    super.key,
    required this.index,
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final int index;
  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!selected),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    size: 20,
                    color: theme.colorScheme.descriptionColor,
                  ),
                ),
              ),
            ),
            Checkbox(value: selected, onChanged: (v) => onChanged(v ?? false)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  const _FormatCard({
    required this.title,
    required this.hint,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String hint;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return SizedBox(
      width: 150,
      child: Material(
        color: selected ? accent.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? accent
                    : (theme.colorScheme.borderColor ?? theme.dividerColor),
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.descriptionColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
