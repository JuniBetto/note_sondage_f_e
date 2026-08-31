import 'package:flutter/material.dart';
import 'package:note_sondage/core/config/runtime_config.dart';
import 'package:url_launcher/url_launcher.dart';

enum PublicLegalDocument { privacy, terms }

class PublicLegalLinks {
  static Uri uriFor(Locale locale, PublicLegalDocument document) {
    final languageCode = _supportedLanguageCode(locale.languageCode);
    final localizedPrefix = languageCode == 'it' ? '' : '/$languageCode';
    final slug = document == PublicLegalDocument.privacy ? 'privacy' : 'terms';

    return Uri.parse(
      '${RuntimeConfig.resolvedMarketingSiteUrl}$localizedPrefix/$slug',
    );
  }

  static Future<void> open(Locale locale, PublicLegalDocument document) async {
    await launchUrl(
      uriFor(locale, document),
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );
  }

  static String _supportedLanguageCode(String rawLanguageCode) {
    switch (rawLanguageCode.toLowerCase()) {
      case 'en':
      case 'fr':
      case 'es':
        return rawLanguageCode.toLowerCase();
      default:
        return 'it';
    }
  }
}
