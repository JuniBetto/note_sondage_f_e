import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class SondageComponentRow extends StatelessWidget {
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
    required this.onTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localization = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      elevation: 2,
      color: colorScheme.bgNavbarSurface,
      margin: EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorSondage, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Colore indicatore
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: colorSondage,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 16),

              // Contenuto principale
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sondageName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.iconLabel,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      sondageFocus,
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
              SizedBox(width: 16),

              // Info risposte
              Row(
                children: [
                  Icon(Icons.people, size: 18, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    '$responses ${localization.responses}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 20),

              // Info domande
              Row(
                children: [
                  Icon(Icons.quiz, size: 18, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    '$totalQuestions ${localization.questions}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 16),

              // Bottone delete
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => onDeleteTap(sondageId),
              ),
            ],
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
