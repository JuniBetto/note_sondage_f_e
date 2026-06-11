import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class SettingsPrivacyWeb extends StatelessWidget {
  const SettingsPrivacyWeb({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.privacy_tip_rounded,
                  color: Color(0xFF4CAF50),
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localization.privacyPolicy,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localization.howWeProtectYourData,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.descriptionColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Privacy sections
          _PrivacySection(
            icon: Icons.shield_rounded,
            iconColor: const Color(0xFF2196F3),
            title: localization.dataProtection,
            content: localization.dataProtectionDescription,
          ),

          _PrivacySection(
            icon: Icons.storage_rounded,
            iconColor: const Color(0xFF9C27B0),
            title: localization.dataCollection,
            content: localization.dataCollectionDescription,
          ),

          _PrivacySection(
            icon: Icons.share_rounded,
            iconColor: const Color(0xFFFF9800),
            title: localization.dataSharing,
            content: localization.dataSharingDescription,
          ),

          _PrivacySection(
            icon: Icons.delete_sweep_rounded,
            iconColor: const Color(0xFFE91E63),
            title: localization.dataRetention,
            content: localization.dataRetentionDescription,
          ),

          _PrivacySection(
            icon: Icons.gavel_rounded,
            iconColor: const Color(0xFF00BCD4),
            title: localization.yourRights,
            content: localization.yourRightsDescription,
          ),

          const SizedBox(height: 24),

          // Last updated
          Center(
            child: Text(
              localization.privacyLastUpdated,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.descriptionColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.homeSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.borderColor!.withValues(alpha: 0.3),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.descriptionColor,
                      height: 1.5,
                    ),
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
