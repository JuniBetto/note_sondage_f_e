import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class SondageComponentCard extends StatefulWidget {
  final String sondageName;
  final String sondageFocus;
  final String sondageId;
  final String status;
  final int responses;
  final int totalQuestions;
  final DateTime createdDate;
  final DateTime expiryDate;
  final Color colorSondage;
  final bool isActive;
  final VoidCallback onTap;
  final Function(String) onDeleteTap;

  const SondageComponentCard({
    super.key,
    required this.sondageName,
    required this.sondageFocus,
    required this.sondageId,
    required this.status,
    required this.responses,
    required this.totalQuestions,
    required this.createdDate,
    required this.expiryDate,
    required this.colorSondage,
    this.isActive = false,
    required this.onTap,
    required this.onDeleteTap,
  });

  @override
  State<SondageComponentCard> createState() => _SondageComponentCardState();
}

class _SondageComponentCardState extends State<SondageComponentCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localization = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final showBorder = widget.isActive || _isHovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 320,
          height: 200,
          decoration: BoxDecoration(
            color: colorScheme.bgNavbarSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: showBorder
                  ? colorScheme.selectionColor!
                  : widget.colorSondage,
              width: showBorder ? 3 : 2,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: colorScheme.selectionColor!.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con nome e bottone delete
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.sondageName,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.iconLabel,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => widget.onDeleteTap(widget.sondageId),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // Focus/descrizione
                Text(
                  widget.sondageFocus,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),

                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      widget.status,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.status,
                    style: TextStyle(
                      color: _getStatusColor(widget.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Spacer(),

                // Footer con info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          '${widget.responses} ${localization.responses}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.quiz, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          '${widget.totalQuestions} ${localization.questions}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'closed':
        return Colors.red;
      case 'draft':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
