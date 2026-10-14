import 'package:flutter/widgets.dart';
import 'package:note_sondage/feature/clocking/domain/entities/clocking_record_entity.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

String _byLanguage(
  BuildContext context, {
  required String it,
  required String en,
  required String fr,
  required String es,
}) {
  switch (Localizations.localeOf(context).languageCode.toLowerCase()) {
    case 'it':
      return it;
    case 'fr':
      return fr;
    case 'es':
      return es;
    default:
      return en;
  }
}

/// Etichetta tradotta dello stato di una timbratura, nella lingua dell'app.
String localizedClockingStatusLabel(
  BuildContext context,
  ClockingStatus status,
) {
  final loc = AppLocalizations.of(context)!;
  switch (status) {
    case ClockingStatus.committed:
      return loc.committed;
    case ClockingStatus.decommitted:
      return loc.decommitted;
    case ClockingStatus.vacation:
      return loc.vacationStatus;
    case ClockingStatus.permission:
      return loc.permission;
    case ClockingStatus.clockedIn:
      return _byLanguage(
        context,
        it: 'Entrata registrata',
        en: 'Clocked in',
        fr: 'Pointé',
        es: 'Fichado',
      );
    case ClockingStatus.onBreak:
      return _byLanguage(
        context,
        it: 'In pausa',
        en: 'On break',
        fr: 'En pause',
        es: 'En pausa',
      );
    case ClockingStatus.sick:
      return _byLanguage(
        context,
        it: 'Malattia',
        en: 'Sick',
        fr: 'Maladie',
        es: 'Baja médica',
      );
    case ClockingStatus.absent:
      return _byLanguage(
        context,
        it: 'Assente',
        en: 'Absent',
        fr: 'Absent',
        es: 'Ausente',
      );
    case ClockingStatus.late:
      return _byLanguage(
        context,
        it: 'In ritardo',
        en: 'Late',
        fr: 'En retard',
        es: 'Con retraso',
      );
  }
}

String localizedOwnClockingBadge(BuildContext context) => _byLanguage(
  context,
  it: 'La tua timbratura',
  en: 'Your clocking',
  fr: 'Votre pointage',
  es: 'Tu fichaje',
);

String localizedMemberClockingBadge(BuildContext context) => _byLanguage(
  context,
  it: 'Timbratura membro',
  en: 'Member clocking',
  fr: 'Pointage du membre',
  es: 'Fichaje del miembro',
);
