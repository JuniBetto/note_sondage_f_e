import 'package:flutter/material.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class SettingsPrivacyWeb extends StatelessWidget {
  const SettingsPrivacyWeb({super.key});

  @override
  Widget build(BuildContext context) {
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
                    'Privacy Policy',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'How we protect your data',
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
            title: 'Data Protection',
            content:
                'Your data is encrypted at rest and in transit. We use industry-standard encryption protocols to ensure your information remains secure.',
          ),

          _PrivacySection(
            icon: Icons.storage_rounded,
            iconColor: const Color(0xFF9C27B0),
            title: 'Data Collection',
            content:
                'We collect only the data necessary to provide our services. This includes your account information, survey responses, and clocking records.',
          ),

          _PrivacySection(
            icon: Icons.share_rounded,
            iconColor: const Color(0xFFFF9800),
            title: 'Data Sharing',
            content:
                'We never share your personal data with third parties without your explicit consent. Team data is shared only within your organization.',
          ),

          _PrivacySection(
            icon: Icons.delete_sweep_rounded,
            iconColor: const Color(0xFFE91E63),
            title: 'Data Retention',
            content:
                'Your data is retained for as long as your account is active. Upon account deletion, all personal data will be permanently removed within 30 days.',
          ),

          _PrivacySection(
            icon: Icons.gavel_rounded,
            iconColor: const Color(0xFF00BCD4),
            title: 'Your Rights',
            content:
                'You have the right to access, rectify, or delete your personal data at any time. Contact our support team for any privacy-related requests.',
          ),

          const SizedBox(height: 24),

          // Last updated
          Center(
            child: Text(
              'Last updated: January 2025',
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
