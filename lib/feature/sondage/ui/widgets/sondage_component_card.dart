import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class SondageComponentCard extends StatelessWidget {
  final String sondageName;
  final String sondageFocus;
  final String sondageId;
  final String status;
  final int responses;
  final int totalQuestions;
  final DateTime createdDate;
  final DateTime expiryDate;
  final Color colorSondage;
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
    required this.onTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localization = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SizedBox(
      width: 320,
      height: 200,
      child: Card(
        elevation: 4,
        color: colorScheme.bgNavbarSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorSondage, width: 2),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
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
                        sondageName,
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
                      onPressed: () => onDeleteTap(sondageId),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // Focus/descrizione
                Text(
                  sondageFocus,
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
                    color: _getStatusColor(status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _getStatusColor(status),
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
                          '$responses ${localization.responses}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.quiz, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          '$totalQuestions ${localization.questions}',
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
