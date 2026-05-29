import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class SondageComponentRow extends StatefulWidget {
  final String sondageName;
  final String sondageFocus;
  final String sondageId;
  final String status;
  final int responses;
  final int totalQuestions;
  final DateTime createdDate;
  final DateTime? expiryDate;
  final Color colorSondage;
  final bool isActive;
  final bool canDelete;
  final bool canEdit;
  final bool isSyncing;
  final bool isArchived;
  final VoidCallback onTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onArchiveTap;
  final Function(String) onDeleteTap;

  const SondageComponentRow({
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
    this.canDelete = false,
    this.canEdit = false,
    this.isSyncing = false,
    this.isArchived = false,
    required this.onTap,
    this.onEditTap,
    this.onArchiveTap,
    required this.onDeleteTap,
  });

  @override
  State<SondageComponentRow> createState() => _SondageComponentRowState();
}

class _SondageComponentRowState extends State<SondageComponentRow> {
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
        child: Opacity(
          opacity: widget.isSyncing ? 0.78 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.bgNavbarSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: showBorder
                    ? colorScheme.selectionColor!
                    : widget.colorSondage,
                width: showBorder ? 3 : 2,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: colorScheme.selectionColor!.withValues(
                          alpha: 0.3,
                        ),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Colore indicatore
                  Container(
                    width: 4,
                    height: 60,
                    decoration: BoxDecoration(
                      color: widget.colorSondage,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: 16),

                  // Contenuto principale
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.isSyncing) ...[
                          const _SyncBadge(),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          widget.sondageName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.iconLabel,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.sondageFocus,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Status badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  SizedBox(width: 16),

                  // Info risposte
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people, size: 18, color: Colors.grey),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${widget.responses} ${localization.responses}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),

                  // Info domande
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.quiz, size: 18, color: Colors.grey),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${widget.totalQuestions} ${localization.questions}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),

                  // Bottone delete
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.canEdit)
                          IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              color: colorScheme.selectionColor,
                            ),
                            tooltip: 'Modifica sondaggio',
                            onPressed: widget.onEditTap,
                          ),
                        IconButton(
                          icon: Icon(
                            widget.isArchived
                                ? Icons.unarchive_outlined
                                : Icons.archive_outlined,
                            color: Colors.blueGrey,
                          ),
                          tooltip: widget.isArchived
                              ? 'Ripristina sondaggio'
                              : 'Archivia sondaggio',
                          onPressed: widget.onArchiveTap,
                        ),
                        if (widget.canDelete)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                widget.onDeleteTap(widget.sondageId),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
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
      case 'completed':
      case 'closed':
        return Colors.red;
      case 'draft':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFF1C972)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 6),
          Text(
            'Syncing',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8A5A00),
            ),
          ),
        ],
      ),
    );
  }
}
