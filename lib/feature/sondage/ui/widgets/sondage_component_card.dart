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
            constraints: const BoxConstraints(minHeight: 170),
            decoration: BoxDecoration(
              color: colorScheme.bgNavbarSurface,
              borderRadius: BorderRadius.circular(16),
              border: (widget.isActive || _isHovered)
                  ? Border.all(color: colorScheme.selectionColor!, width: 3)
                  : null,
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
                  if (widget.isSyncing) ...[
                    const _SyncBadge(),
                    const SizedBox(height: 10),
                  ],
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
                                tooltip: localization.editSurvey,
                                onPressed: widget.onEditTap,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            IconButton(
                              icon: Icon(
                                widget.isArchived
                                    ? Icons.unarchive_outlined
                                    : Icons.archive_outlined,
                                color: Colors.blueGrey,
                              ),
                              tooltip: widget.isArchived
                                  ? localization.restoreSurvey
                                  : localization.archiveSurvey,
                              onPressed: widget.onArchiveTap,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            if (widget.canDelete)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                tooltip: localization.deleteSurvey,
                                onPressed: () =>
                                    widget.onDeleteTap(widget.sondageId),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),

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
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people, size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${widget.responses} ${localization.responses}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.quiz, size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${widget.totalQuestions} ${localization.questions}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
