import 'package:flutter/material.dart';
import 'package:note_sondage/core/config/runtime_config.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class WebMobileDownloadGate extends StatelessWidget {
  const WebMobileDownloadGate({
    super.key,
    required this.child,
    this.breakpoint = 576,
  });

  final Widget child;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= breakpoint) {
      return child;
    }
    return const _WebMobileDownloadPrompt();
  }
}

class _WebMobileDownloadPrompt extends StatelessWidget {
  const _WebMobileDownloadPrompt();

  Future<void> _openStore(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, webOnlyWindowName: '_blank');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localization = AppLocalizations.of(context)!;
    final hasAppleStore = RuntimeConfig.hasAppleStoreUrl;
    final hasAndroidStore = RuntimeConfig.hasAndroidStoreUrl;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.surface,
              colorScheme.primary.withValues(alpha: 0.08),
              colorScheme.secondary.withValues(alpha: 0.08),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: colorScheme.primary.withValues(alpha: 0.12),
                        ),
                        child: Icon(
                          Icons.phone_iphone_rounded,
                          color: colorScheme.primary,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        localization.webMobileAppOnlyTitle,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        localization.webMobileAppOnlyMessage,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: colorScheme.primary.withValues(alpha: 0.08),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.tablet_mac_rounded,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                localization.webMobileAppOnlyHint,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (hasAppleStore)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () =>
                                _openStore(RuntimeConfig.resolvedAppleStoreUrl),
                            icon: const Icon(Icons.download_rounded),
                            label: Text(localization.downloadOnAppStore),
                          ),
                        ),
                      if (hasAppleStore && hasAndroidStore)
                        const SizedBox(height: 12),
                      if (hasAndroidStore)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _openStore(
                              RuntimeConfig.resolvedAndroidStoreUrl,
                            ),
                            icon: const Icon(Icons.android_rounded),
                            label: Text(localization.getItOnGooglePlay),
                          ),
                        ),
                      if (!hasAppleStore && !hasAndroidStore) ...[
                        const SizedBox(height: 12),
                        Text(
                          localization.mobileStoreLinksUnavailable,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
