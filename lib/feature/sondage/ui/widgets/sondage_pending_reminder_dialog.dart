import 'package:flutter/material.dart';
import 'package:note_sondage/feature/team/domain/entities/team_member_entity.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';

class SondagePendingReminderDialog extends StatefulWidget {
  const SondagePendingReminderDialog({
    super.key,
    required this.sondageName,
    required this.pendingMembers,
  });

  final String sondageName;
  final List<TeamMemberEntity> pendingMembers;

  static Future<List<String>?> show(
    BuildContext context, {
    required String sondageName,
    required List<TeamMemberEntity> pendingMembers,
  }) async {
    final useBottomSheet = MediaQuery.sizeOf(context).width < 900;
    if (useBottomSheet) {
      return showModalBottomSheet<List<String>>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.84,
          child: SondagePendingReminderDialog(
            sondageName: sondageName,
            pendingMembers: pendingMembers,
          ),
        ),
      );
    }

    return showDialog<List<String>>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: SizedBox(
          width: 520,
          child: SondagePendingReminderDialog(
            sondageName: sondageName,
            pendingMembers: pendingMembers,
          ),
        ),
      ),
    );
  }

  @override
  State<SondagePendingReminderDialog> createState() =>
      _SondagePendingReminderDialogState();
}

class _SondagePendingReminderDialogState
    extends State<SondagePendingReminderDialog> {
  late final Set<String> _selectedUserIds;

  @override
  void initState() {
    super.initState();
    _selectedUserIds = widget.pendingMembers
        .map((member) => member.userId ?? '')
        .where((userId) => userId.isNotEmpty)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final strings = _ReminderStrings.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            strings.subtitle(widget.sondageName),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: Text(strings.allPending),
                      selected:
                          _selectedUserIds.length ==
                          widget.pendingMembers.length,
                      onSelected: (_) {
                        setState(() {
                          _selectedUserIds
                            ..clear()
                            ..addAll(
                              widget.pendingMembers
                                  .map((member) => member.userId ?? '')
                                  .where((userId) => userId.isNotEmpty),
                            );
                        });
                      },
                    ),
                    FilterChip(
                      label: Text(strings.clearSelection),
                      selected: _selectedUserIds.isEmpty,
                      onSelected: (_) {
                        setState(_selectedUserIds.clear);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    itemCount: widget.pendingMembers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final member = widget.pendingMembers[index];
                      final userId = member.userId ?? '';
                      final selected = _selectedUserIds.contains(userId);
                      return CheckboxListTile(
                        value: selected,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        title: Text(_memberLabel(member)),
                        subtitle: Text(member.userEmail),
                        onChanged: userId.isEmpty
                            ? null
                            : (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedUserIds.add(userId);
                                  } else {
                                    _selectedUserIds.remove(userId);
                                  }
                                });
                              },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _selectedUserIds.isEmpty
                            ? null
                            : () => Navigator.of(
                                context,
                              ).pop(_selectedUserIds.toList()),
                        icon: const Icon(Icons.notifications_active_rounded),
                        label: Text(strings.sendReminder),
                        style: ElevatedButton.styleFrom(
    backgroundColor: colorScheme.bgNavbarbutton,
    ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _memberLabel(TeamMemberEntity member) {
    final initialName = member.initialName?.trim();
    if (initialName != null && initialName.isNotEmpty) {
      return initialName;
    }
    return member.userEmail.trim().isNotEmpty
        ? member.userEmail.trim()
        : (member.userId ?? 'User');
  }
}

class _ReminderStrings {
  const _ReminderStrings._({
    required this.title,
    required this.subtitleBuilder,
    required this.allPending,
    required this.clearSelection,
    required this.sendReminder,
  });

  final String title;
  final String Function(String sondageName) subtitleBuilder;
  final String allPending;
  final String clearSelection;
  final String sendReminder;

  String subtitle(String sondageName) => subtitleBuilder(sondageName);

  static _ReminderStrings of(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'it' => _it,
      'fr' => _fr,
      'es' => _es,
      _ => _en,
    };
  }

  static const _ReminderStrings _en = _ReminderStrings._(
    title: 'Survey reminder',
    subtitleBuilder: _subtitleEn,
    allPending: 'All pending users',
    clearSelection: 'Clear selection',
    sendReminder: 'Send reminder',
  );

  static const _ReminderStrings _it = _ReminderStrings._(
    title: 'Promemoria sondaggio',
    subtitleBuilder: _subtitleIt,
    allPending: 'Tutti i non votanti',
    clearSelection: 'Pulisci selezione',
    sendReminder: 'Invia promemoria',
  );

  static const _ReminderStrings _fr = _ReminderStrings._(
    title: 'Rappel du sondage',
    subtitleBuilder: _subtitleFr,
    allPending: 'Tous les membres en attente',
    clearSelection: 'Effacer la selection',
    sendReminder: 'Envoyer le rappel',
  );

  static const _ReminderStrings _es = _ReminderStrings._(
    title: 'Recordatorio de encuesta',
    subtitleBuilder: _subtitleEs,
    allPending: 'Todos los pendientes',
    clearSelection: 'Limpiar seleccion',
    sendReminder: 'Enviar recordatorio',
  );

  static String _subtitleEn(String sondageName) =>
      'Select who should receive a reminder for "$sondageName".';
  static String _subtitleIt(String sondageName) =>
      'Seleziona chi deve ricevere un promemoria per "$sondageName".';
  static String _subtitleFr(String sondageName) =>
      'Selectionnez les membres qui doivent recevoir un rappel pour "$sondageName".';
  static String _subtitleEs(String sondageName) =>
      'Selecciona quienes deben recibir un recordatorio para "$sondageName".';
}
