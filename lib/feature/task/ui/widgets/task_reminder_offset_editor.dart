import 'package:flutter/material.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';

/// Chip editor per gli offset dei promemoria del task — stesso pattern UI
/// dell'`_AlarmOffsetEditor` di Shift (minuti relativi, negativi = prima).
///
/// Condiviso tra l'editor completo del task (creatore/manager) e il foglio
/// leggero "il mio promemoria" (chiunque sia creatore o assegnatario).
class TaskReminderOffsetEditor extends StatelessWidget {
  const TaskReminderOffsetEditor({
    super.key,
    required this.offsets,
    required this.onChanged,
  });

  final List<int> offsets;
  final ValueChanged<List<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        ...offsets.map((offset) {
          final label = offset < 0 ? '$offset min' : '+$offset min';
          return Chip(
            label: Text(label, style: theme.textTheme.bodySmall),
            deleteIcon: const Icon(Icons.close, size: 14),
            onDeleted: () {
              final updated = List<int>.from(offsets)..remove(offset);
              onChanged(updated);
            },
          );
        }),
        ActionChip(
          avatar: const Icon(Icons.add, size: 14),
          label: Text(taskReminderAddLabel(context)),
          onPressed: () => _addOffset(context),
        ),
      ],
    );
  }

  Future<void> _addOffset(BuildContext context) async {
    final ctrl = TextEditingController(text: '-30');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(taskReminderAddDialogTitle(ctx)),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: InputDecoration(
            labelText: taskReminderMinutesLabel(ctx),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              if (v != null) Navigator.of(ctx).pop(v);
            },
            child: Text(taskReminderAddLabel(ctx)),
          ),
        ],
      ),
    );
    if (result != null && !offsets.contains(result)) {
      final updated = List<int>.from(offsets)
        ..add(result)
        ..sort();
      onChanged(updated);
    }
  }
}

String _localizedTaskReminderText(
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

String taskReminderSectionLabel(BuildContext context) =>
    _localizedTaskReminderText(
      context,
      it: 'Promemoria',
      en: 'Reminders',
      fr: 'Rappels',
      es: 'Recordatorios',
    );

String taskReminderAddDialogTitle(BuildContext context) =>
    _localizedTaskReminderText(
      context,
      it: 'Aggiungi promemoria',
      en: 'Add reminder',
      fr: 'Ajouter un rappel',
      es: 'Agregar recordatorio',
    );

String taskReminderMinutesLabel(BuildContext context) =>
    _localizedTaskReminderText(
      context,
      it: 'Minuti (negativi = prima)',
      en: 'Minutes (negative = before)',
      fr: 'Minutes (negatif = avant)',
      es: 'Minutos (negativo = antes)',
    );

String taskReminderAddLabel(BuildContext context) => _localizedTaskReminderText(
  context,
  it: 'Aggiungi',
  en: 'Add',
  fr: 'Ajouter',
  es: 'Agregar',
);

String taskReminderAnchorDueAtLabel(BuildContext context) =>
    _localizedTaskReminderText(
      context,
      it: 'Alla scadenza',
      en: 'At due date',
      fr: "A l'echeance",
      es: 'En la fecha limite',
    );

String taskReminderAnchorStartAtLabel(BuildContext context) =>
    _localizedTaskReminderText(
      context,
      it: "All'inizio",
      en: 'At start date',
      fr: 'Au debut',
      es: 'Al inicio',
    );

String taskMyReminderSheetTitle(BuildContext context) =>
    _localizedTaskReminderText(
      context,
      it: 'Il mio promemoria',
      en: 'My reminder',
      fr: 'Mon rappel',
      es: 'Mi recordatorio',
    );

String taskMyReminderSheetSubtitle(BuildContext context) =>
    _localizedTaskReminderText(
      context,
      it:
          'Questo promemoria e\' solo tuo: non modifica quello di nessun altro su questo task.',
      en:
          "This reminder is yours alone: it doesn't change anyone else's on this task.",
      fr:
          "Ce rappel n'appartient qu'a vous : il ne modifie celui de personne d'autre sur cette tache.",
      es:
          'Este recordatorio es solo tuyo: no cambia el de nadie mas en esta tarea.',
    );

String taskMyReminderSaveAction(BuildContext context) =>
    _localizedTaskReminderText(
      context,
      it: 'Salva promemoria',
      en: 'Save reminder',
      fr: 'Enregistrer le rappel',
      es: 'Guardar recordatorio',
    );

String taskMyReminderSetAction(BuildContext context) =>
    _localizedTaskReminderText(
      context,
      it: 'Il mio promemoria',
      en: 'My reminder',
      fr: 'Mon rappel',
      es: 'Mi recordatorio',
    );

String taskMyReminderSaveError(BuildContext context) =>
    _localizedTaskReminderText(
      context,
      it: 'Impossibile salvare il promemoria. Riprova.',
      en: 'Unable to save the reminder. Please try again.',
      fr: "Impossible d'enregistrer le rappel. Reessayez.",
      es: 'No se pudo guardar el recordatorio. Intentalo de nuevo.',
    );

String taskMyReminderNoAnchorHint(BuildContext context) =>
    _localizedTaskReminderText(
      context,
      it:
          'Questo task non ha ancora una data di scadenza o di inizio: aggiungine una per poter ricevere il promemoria.',
      en:
          "This task doesn't have a due or start date yet: add one so the reminder can fire.",
      fr:
          "Cette tache n'a pas encore de date d'echeance ou de debut : ajoutez-en une pour recevoir le rappel.",
      es:
          'Esta tarea aun no tiene fecha de vencimiento ni de inicio: agrega una para poder recibir el recordatorio.',
    );
