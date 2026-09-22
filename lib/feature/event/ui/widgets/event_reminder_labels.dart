import 'package:flutter/material.dart';

/// Testi localizzati per i promemoria degli eventi — stesso pattern di
/// `_localizedTaskReminderText` in `task_reminder_offset_editor.dart`. Il
/// chip editor stesso ([TaskReminderOffsetEditor]) e' riutilizzato cosi'
/// com'e' dal feature "event" (i suoi testi interni non sono specifici del
/// task), quindi qui servono solo le stringhe specifiche dell'event.
String _localizedEventReminderText(
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

String eventReminderSectionLabel(BuildContext context) =>
    _localizedEventReminderText(
      context,
      it: 'Promemoria',
      en: 'Reminders',
      fr: 'Rappels',
      es: 'Recordatorios',
    );

String eventReminderAnchorStartsAtLabel(BuildContext context) =>
    _localizedEventReminderText(
      context,
      it: "All'inizio",
      en: 'At start',
      fr: 'Au debut',
      es: 'Al inicio',
    );

String eventReminderAnchorEndsAtLabel(BuildContext context) =>
    _localizedEventReminderText(
      context,
      it: 'Alla fine',
      en: 'At end',
      fr: 'A la fin',
      es: 'Al final',
    );

String eventMyReminderSheetTitle(BuildContext context) =>
    _localizedEventReminderText(
      context,
      it: 'Il mio promemoria',
      en: 'My reminder',
      fr: 'Mon rappel',
      es: 'Mi recordatorio',
    );

String eventMyReminderSheetSubtitle(BuildContext context) =>
    _localizedEventReminderText(
      context,
      it:
          'Questo promemoria e\' solo tuo: non modifica quello di nessun altro su questo evento.',
      en:
          "This reminder is yours alone: it doesn't change anyone else's on this event.",
      fr:
          "Ce rappel n'appartient qu'a vous : il ne modifie celui de personne d'autre sur cet evenement.",
      es:
          'Este recordatorio es solo tuyo: no cambia el de nadie mas en este evento.',
    );

String eventMyReminderSaveAction(BuildContext context) =>
    _localizedEventReminderText(
      context,
      it: 'Salva promemoria',
      en: 'Save reminder',
      fr: 'Enregistrer le rappel',
      es: 'Guardar recordatorio',
    );

String eventMyReminderSetAction(BuildContext context) =>
    _localizedEventReminderText(
      context,
      it: 'Il mio promemoria',
      en: 'My reminder',
      fr: 'Mon rappel',
      es: 'Mi recordatorio',
    );

String eventMyReminderSaveError(BuildContext context) =>
    _localizedEventReminderText(
      context,
      it: 'Impossibile salvare il promemoria. Riprova.',
      en: 'Unable to save the reminder. Please try again.',
      fr: "Impossible d'enregistrer le rappel. Reessayez.",
      es: 'No se pudo guardar el recordatorio. Intentalo de nuevo.',
    );

String eventMyReminderNoAnchorHint(BuildContext context) =>
    _localizedEventReminderText(
      context,
      it:
          'Questo evento non ha ancora una data di inizio: aggiungine una per poter ricevere il promemoria.',
      en:
          "This event doesn't have a start date yet: add one so the reminder can fire.",
      fr:
          "Cet evenement n'a pas encore de date de debut : ajoutez-en une pour recevoir le rappel.",
      es:
          'Este evento aun no tiene fecha de inicio: agrega una para poder recibir el recordatorio.',
    );
