import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:note_sondage/feature/event/domain/entities/event_text_size.dart';
import 'package:note_sondage/feature/event/ui/event_text_size_cubit.dart';

import '../../../../theme/extensions/color_scheme/color_scheme.dart';

/// Compact "Aa" menu button letting the user pick how large text renders
/// across the Event feature's mobile views (see [EventTextSizeCubit]) — a
/// menu rather than an inline row since there are six size levels.
class EventTextSizeToggle extends StatelessWidget {
  const EventTextSizeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = colorScheme.borderColor ?? colorScheme.outlineVariant;
    final accent = colorScheme.primaryColor ?? colorScheme.primary;
    final cubit = GetIt.instance<EventTextSizeCubit>();

    return BlocBuilder<EventTextSizeCubit, EventTextSize>(
      bloc: cubit,
      builder: (context, selected) {
        return PopupMenuButton<EventTextSize>(
          tooltip: _textSizeMenuTooltip(context),
          initialValue: selected,
          onSelected: cubit.setSize,
          color: colorScheme.dialogBackgroundColor ?? colorScheme.surface,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor.withValues(alpha: 0.6)),
          ),
          itemBuilder: (menuContext) => EventTextSize.values.map((size) {
            final isSelected = size == selected;
            return PopupMenuItem<EventTextSize>(
              value: size,
              height: 52,
              padding: EdgeInsets.zero,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accent.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 26,
                      child: Text(
                        'Aa',
                        style: TextStyle(
                          fontSize: (11 + size.scaleFactor * 7).clamp(11, 21),
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? accent
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _labelFor(menuContext, size),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected ? accent : colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_rounded, size: 16, color: accent),
                  ],
                ),
              ),
            );
          }).toList(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.format_size_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String _labelFor(BuildContext context, EventTextSize size) => switch (size) {
  EventTextSize.tiny => _tinyTextLabel(context),
  EventTextSize.extraSmall => _extraSmallTextLabel(context),
  EventTextSize.compact => _compactTextLabel(context),
  EventTextSize.small => _smallTextLabel(context),
  EventTextSize.medium => _mediumTextLabel(context),
  EventTextSize.large => _largeTextLabel(context),
};

String _localizedEventTextSizeText(
  BuildContext context, {
  required String it,
  required String en,
  String? fr,
  String? es,
}) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'it':
      return it;
    case 'fr':
      return fr ?? en;
    case 'es':
      return es ?? en;
    default:
      return en;
  }
}

String _textSizeMenuTooltip(BuildContext context) =>
    _localizedEventTextSizeText(
      context,
      it: 'Dimensione testo',
      en: 'Text size',
      fr: 'Taille du texte',
      es: 'Tamano de texto',
    );

String _tinyTextLabel(BuildContext context) => _localizedEventTextSizeText(
  context,
  it: 'Minuscolo',
  en: 'Tiny',
  fr: 'Minuscule',
  es: 'Minimo',
);

String _extraSmallTextLabel(BuildContext context) =>
    _localizedEventTextSizeText(
      context,
      it: 'Molto piccolo',
      en: 'Extra small',
      fr: 'Tres petit',
      es: 'Muy pequeno',
    );

String _compactTextLabel(BuildContext context) => _localizedEventTextSizeText(
  context,
  it: 'Compatto',
  en: 'Compact',
  fr: 'Compact',
  es: 'Compacto',
);

String _smallTextLabel(BuildContext context) => _localizedEventTextSizeText(
  context,
  it: 'Piccolo',
  en: 'Small',
  fr: 'Petit',
  es: 'Pequeno',
);

String _mediumTextLabel(BuildContext context) => _localizedEventTextSizeText(
  context,
  it: 'Medio',
  en: 'Medium',
  fr: 'Moyen',
  es: 'Mediano',
);

String _largeTextLabel(BuildContext context) => _localizedEventTextSizeText(
  context,
  it: 'Grande',
  en: 'Large',
  fr: 'Grand',
  es: 'Grande',
);
