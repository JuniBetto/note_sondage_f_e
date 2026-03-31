import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/mobile/widgets/settings/widgets/change_language.dart';
import 'package:note_sondage/ui/mobile/widgets/settings/widgets/change_theme.dart';
import 'package:note_sondage/ui/mobile/widgets/settings/widgets/contact_us_mobile.dart';
import 'package:note_sondage/ui/mobile/widgets/settings/widgets/notification_settings_mobile.dart';
import 'package:note_sondage/ui/web/settings/settings_privacy_web.dart';
import 'package:note_sondage/ui/widgets/language_config/bloc/language_bloc.dart';
import 'package:note_sondage/ui/widgets/theme_config/bloc/theme/theme_bloc.dart';
import 'package:note_sondage/ui/widgets/theme_config/bloc/theme/theme_state.dart';

class SettingsMobile extends StatelessWidget {
  const SettingsMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                localization.settings,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                localization.manageYourPrivacySettings,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.descriptionColor,
                ),
              ),
            ),

            // ── User Profile Card ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.selectItem!.withValues(alpha: 0.8),
                      colorScheme.selectItem!.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.selectItem!.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User',
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'user@example.com',
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Pro',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Preferences Section ──
            _buildSectionHeader(
              context,
              localization.preferences,
              Icons.tune_rounded,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.homeSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.borderColor!.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    _SettingTile(
                      icon: Icons.palette_rounded,
                      iconColor: const Color(0xFF7C4DFF),
                      title: localization.themeTitle,
                      subtitle: _getThemeSubtitle(context, localization),
                      onTap: () =>
                          _showSettingModal(context, const ChangeTheme()),
                      showDivider: true,
                    ),
                    _SettingTile(
                      icon: Icons.language_rounded,
                      iconColor: const Color(0xFF2196F3),
                      title: localization.language,
                      subtitle: _getLanguageSubtitle(context),
                      onTap: () =>
                          _showSettingModal(context, const ChangeLanguage()),
                      showDivider: true,
                    ),
                    _SettingTile(
                      icon: Icons.notifications_rounded,
                      iconColor: const Color(0xFFFF9800),
                      title: localization.notification,
                      subtitle: localization.none,
                      onTap: () => _showSettingModal(
                        context,
                        const NotificationSettingsMobile(),
                      ),
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Support Section ──
            _buildSectionHeader(
              context,
              localization.privacy,
              Icons.shield_rounded,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.homeSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.borderColor!.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    _SettingTile(
                      icon: Icons.privacy_tip_rounded,
                      iconColor: const Color(0xFF4CAF50),
                      title: localization.privacy,
                      subtitle: localization.manageYourPrivacySettings,
                      onTap: () => _showSettingModal(
                        context,
                        const SettingsPrivacyWeb(),
                      ),
                      showDivider: true,
                    ),
                    _SettingTile(
                      icon: Icons.headset_mic_rounded,
                      iconColor: const Color(0xFFE91E63),
                      title: localization.contactUs,
                      subtitle: localization.getInTouchWithOurSupportTeam,
                      onTap: () =>
                          _showSettingModal(context, const ContactUsMobile()),
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Danger Zone ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.deleteCard?.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.deleteCard!.withValues(alpha: 0.2),
                  ),
                ),
                child: _SettingTile(
                  icon: Icons.logout_rounded,
                  iconColor: colorScheme.deleteCard!,
                  title: localization.logout,
                  subtitle: '',
                  onTap: () {},
                  showDivider: false,
                  isDestructive: true,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── App Version ──
            Center(
              child: Text(
                'v1.0.0',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.descriptionColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.descriptionColor),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: theme.colorScheme.descriptionColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeSubtitle(
    BuildContext context,
    AppLocalizations localization,
  ) {
    final themeState = context.watch<ThemeBloc>().state;
    if (themeState is ThemeisDark) return localization.dark;
    if (themeState is ThemeisLight) return localization.light;
    return localization.system;
  }

  String _getLanguageSubtitle(BuildContext context) {
    final languageState = context.watch<LanguageBloc>().state;
    switch (languageState.locale.languageCode) {
      case 'en':
        return 'English';
      case 'it':
        return 'Italiano';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      default:
        return 'English';
    }
  }

  void _showSettingModal(BuildContext context, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      elevation: 8,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Flexible(child: content),
            ],
          ),
        );
      },
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.showDivider,
    this.isDestructive = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: showDivider
                ? BorderRadius.zero
                : BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: isDestructive
                                ? colorScheme.deleteCard
                                : null,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: textTheme.bodySmall?.copyWith(
                              color: isDestructive
                                  ? colorScheme.deleteCard?.withValues(
                                      alpha: 0.7,
                                    )
                                  : colorScheme.descriptionColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDestructive
                        ? colorScheme.deleteCard
                        : colorScheme.descriptionColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 70),
            child: Divider(
              height: 1,
              color: colorScheme.borderColor?.withValues(alpha: 0.3),
            ),
          ),
      ],
    );
  }
}
