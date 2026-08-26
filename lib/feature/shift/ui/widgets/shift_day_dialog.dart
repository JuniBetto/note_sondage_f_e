import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:note_sondage/feature/notification/local/local_notification_service.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_assignment_create_request_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_availability_sondage_draft_request_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_replacement_candidate_entity.dart';
import 'package:note_sondage/feature/shift/domain/entities/shift_profile_entity.dart';
import 'package:note_sondage/feature/shift/domain/repositories/shift_repository.dart';
import 'package:note_sondage/feature/sondage/domain/entities/sondage_entity.dart';
import 'package:note_sondage/feature/sondage/ui/mobile/widgets/create_sondage_mobile.dart';
import 'package:note_sondage/feature/sondage/ui/web/widgets/create_sondage_web.dart';
import 'package:note_sondage/feature/sondage/ui/widgets/sondage_create_prefill.dart';
import 'package:note_sondage/feature/shift/ui/shift_absence_status.dart';
import 'package:note_sondage/feature/shift/ui/shift_assignment_access_policy.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_replacement_candidates_dialog.dart';
import 'package:note_sondage/feature/shift/ui/widgets/shift_swap_request_dialog.dart';
import 'package:note_sondage/feature/team/domain/entities/team_entity.dart';
import 'package:note_sondage/feature/team/domain/use_case/team_member/team_member_use_case.dart';
import 'package:note_sondage/languages/l10n/app_localizations.dart';
import 'package:note_sondage/theme/extensions/color_scheme/color_scheme.dart';
import 'package:note_sondage/ui/widgets/app_snackbar.dart';
import 'package:note_sondage/ui/widgets/anchored_dropdown_overlay.dart';
import 'package:note_sondage/ui/widgets/app_toggle_switch.dart';
import 'package:note_sondage/ui/widgets/custom_app_button.dart';
import 'package:note_sondage/ui/widgets/custom_dialog.dart';
import 'package:note_sondage/ui/widgets/submit_on_enter_scope.dart';

String _localizedShiftDayText(
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

String _defaultTeamMemberLabel(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Membro del team',
  en: 'Team member',
  fr: 'Membre de l\'equipe',
  es: 'Miembro del equipo',
);

String _undefinedRoleLabel(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Ruolo non definito',
  en: 'Undefined role',
  fr: 'Role non defini',
  es: 'Rol no definido',
);

String _localizedRoleLabel(BuildContext context, String rawRole) {
  final normalized = rawRole.trim();
  if (normalized.isEmpty) {
    return _undefinedRoleLabel(context);
  }
  switch (normalized.toLowerCase()) {
    case 'owner':
      return _localizedShiftDayText(
        context,
        it: 'Owner',
        en: 'Owner',
        fr: 'Proprietaire',
        es: 'Propietario',
      );
    case 'admin':
      return _localizedShiftDayText(
        context,
        it: 'Admin',
        en: 'Admin',
        fr: 'Admin',
        es: 'Admin',
      );
    case 'manager':
      return _localizedShiftDayText(
        context,
        it: 'Manager',
        en: 'Manager',
        fr: 'Manager',
        es: 'Manager',
      );
    case 'member':
      return _localizedShiftDayText(
        context,
        it: 'Membro',
        en: 'Member',
        fr: 'Membre',
        es: 'Miembro',
      );
    default:
      return normalized
          .split(RegExp(r'[_\s-]+'))
          .where((part) => part.isNotEmpty)
          .map(
            (part) =>
                '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
          )
          .join(' ');
  }
}

String _privateShiftLabel(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Privato (solo tu)',
  en: 'Private (only you)',
  fr: 'Prive (seulement vous)',
  es: 'Privado (solo tu)',
);

String _privateShiftDescription(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Turno visibile solo a te',
  en: 'Shift visible only to you',
  fr: 'Quart visible uniquement pour vous',
  es: 'Turno visible solo para ti',
);

String _openChangeOrSearchTeamText(BuildContext context) =>
    _localizedShiftDayText(
      context,
      it: 'Apri per cambiare team o cercarne uno',
      en: 'Open to change team or search for one',
      fr: 'Ouvrez pour changer d\'equipe ou en rechercher une',
      es: 'Abre para cambiar de equipo o buscar uno',
    );

String _assignToTeamLabel(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Assegna al team',
  en: 'Assign to team',
  fr: 'Assigner a l\'equipe',
  es: 'Asignar al equipo',
);

String _doNotAssignTeamText(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Non assegnare il turno a un team',
  en: 'Do not assign this shift to a team',
  fr: 'Ne pas assigner ce quart a une equipe',
  es: 'No asignar este turno a un equipo',
);

String _teamAvailableForPublicAssignmentText(BuildContext context) =>
    _localizedShiftDayText(
      context,
      it: 'Team disponibile per assegnazione pubblica',
      en: 'Team available for public assignment',
      fr: 'Equipe disponible pour une attribution publique',
      es: 'Equipo disponible para asignacion publica',
    );

String _assignToLabel(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Assegna a',
  en: 'Assign to',
  fr: 'Assigner a',
  es: 'Asignar a',
);

String _assignToDescription(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Puoi selezionare uno o piu membri specifici del team selezionato oppure assegnare il turno a tutti.',
  en: 'You can select one or more specific members of the selected team or assign the shift to everyone.',
  fr: 'Vous pouvez selectionner un ou plusieurs membres specifiques de l\'equipe selectionnee ou attribuer le quart a tout le monde.',
  es: 'Puedes seleccionar uno o mas miembros especificos del equipo seleccionado o asignar el turno a todos.',
);

String _assignToAllMembersLabel(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Tutti i membri del team',
  en: 'All team members',
  fr: 'Tous les membres de l\'equipe',
  es: 'Todos los miembros del equipo',
);

String _assignToAllMembersSubtitle(BuildContext context) =>
    _localizedShiftDayText(
      context,
      it: 'Assegna lo stesso turno a tutti',
      en: 'Assign the same shift to everyone',
      fr: 'Attribuer le meme quart a tout le monde',
      es: 'Asigna el mismo turno a todos',
    );

String _loadingTeamMembersText(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Caricamento membri del team...',
  en: 'Loading team members...',
  fr: 'Chargement des membres de l\'equipe...',
  es: 'Cargando miembros del equipo...',
);

String _noMembersForTeamText(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Nessun membro disponibile per questo team.',
  en: 'No members available for this team.',
  fr: 'Aucun membre disponible pour cette equipe.',
  es: 'No hay miembros disponibles para este equipo.',
);

String _notAssignableUntilActiveText(BuildContext context) =>
    _localizedShiftDayText(
      context,
      it: 'Non assegnabile finche l\'utente non e attivo',
      en: 'Not assignable until the user becomes active',
      fr: 'Non assignable tant que l\'utilisateur n\'est pas actif',
      es: 'No asignable hasta que el usuario este activo',
    );

String _noAvailableMembersForDateText(BuildContext context) =>
    _localizedShiftDayText(
      context,
      it: 'Nessun membro disponibile per questa data.',
      en: 'No members available for this date.',
      fr: 'Aucun membre disponible pour cette date.',
      es: 'No hay miembros disponibles para esta fecha.',
    );

String _commonShiftLabel(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Turno comune',
  en: 'Common shift',
  fr: 'Quart commun',
  es: 'Turno comun',
);

String _commonShiftSubtitle(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Usa il turno impostato sopra',
  en: 'Use the shift selected above',
  fr: 'Utiliser le quart defini ci-dessus',
  es: 'Usa el turno configurado arriba',
);

String _useDifferentProfilesLabel(BuildContext context) =>
    _localizedShiftDayText(
      context,
      it: 'Usa profili diversi per i membri selezionati',
      en: 'Use different profiles for selected members',
      fr: 'Utiliser des profils differents pour les membres selectionnes',
      es: 'Usa perfiles diferentes para los miembros seleccionados',
    );

String _useDifferentProfilesSubtitle(
  BuildContext context,
) => _localizedShiftDayText(
  context,
  it: 'Perfetto per assegnare mattina, pomeriggio e sera a persone diverse nello stesso team.',
  en: 'Perfect for assigning morning, afternoon and evening shifts to different people in the same team.',
  fr: 'Ideal pour attribuer matin, apres-midi et soir a des personnes differentes dans la meme equipe.',
  es: 'Perfecto para asignar manana, tarde y noche a personas diferentes dentro del mismo equipo.',
);

String _commonShiftMemberHint(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Se lasci "Turno comune", quel membro usera il turno impostato sopra.',
  en: 'If you keep "Common shift", that member will use the shift selected above.',
  fr: 'Si vous laissez "Quart commun", ce membre utilisera le quart defini ci-dessus.',
  es: 'Si dejas "Turno comun", ese miembro usara el turno configurado arriba.',
);

String _publicShiftReadOnlyBanner(
  BuildContext context,
) => _localizedShiftDayText(
  context,
  it: 'Turno pubblico - solo owner, admin o ruoli con permessi Admin/Manage possono modificarlo',
  en: 'Public shift - only owners, admins or roles with Admin/Manage permissions can edit it',
  fr: 'Quart public - seuls les proprietaires, admins ou roles avec permissions Admin/Manage peuvent le modifier',
  es: 'Turno publico: solo owners, admins o roles con permisos Admin/Manage pueden editarlo',
);

String _publicPersonalShiftReadOnlyBanner(BuildContext context) =>
    _localizedShiftDayText(
      context,
      it: 'Turno personale pubblico - solo il proprietario puo modificarlo',
      en: 'Public personal shift - only the owner can edit it',
      fr: 'Quart personnel public - seul le proprietaire peut le modifier',
      es: 'Turno personal publico: solo el propietario puede editarlo',
    );

String _publicVisibleToTeamTitle(BuildContext context) =>
    _localizedShiftDayText(
      context,
      it: 'Pubblico - visibile al team',
      en: 'Public - visible to the team',
      fr: 'Public - visible par l\'equipe',
      es: 'Publico: visible para el equipo',
    );

String _publicVisiblePersonalTitle(BuildContext context) =>
    _localizedShiftDayText(
      context,
      it: 'Pubblico - turno personale',
      en: 'Public - personal shift',
      fr: 'Public - quart personnel',
      es: 'Publico: turno personal',
    );

String _privateVisibleOnlyToYouTitle(BuildContext context) =>
    _localizedShiftDayText(
      context,
      it: 'Privato - solo tu',
      en: 'Private - only you',
      fr: 'Prive - seulement vous',
      es: 'Privado: solo tu',
    );

String _teamSelectedCreatesPublicShiftText(BuildContext context) =>
    _localizedShiftDayText(
      context,
      it: 'Con un team selezionato il turno viene creato come pubblico',
      en: 'With a selected team, the shift is created as public',
      fr: 'Avec une equipe selectionnee, le quart est cree comme public',
      es: 'Con un equipo seleccionado, el turno se crea como publico',
    );

String _sharedCalendarSeeShiftText(
  BuildContext context,
) => _localizedShiftDayText(
  context,
  it: 'Il turno resta personale ma visibile nel calendario condiviso',
  en: 'This shift stays personal but is visible in the shared calendar',
  fr: 'Ce quart reste personnel mais visible dans le calendrier partage',
  es: 'Este turno sigue siendo personal pero visible en el calendario compartido',
);

String _onlyYouCanSeeShiftText(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Solo tu puoi vedere questo turno',
  en: 'Only you can see this shift',
  fr: 'Seulement vous pouvez voir ce quart',
  es: 'Solo tu puedes ver este turno',
);

String _archiveTooltipText(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Archivia',
  en: 'Archive',
  fr: 'Archiver',
  es: 'Archivar',
);

String _requestShiftChangeTitle(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Richiedi modifica turno',
  en: 'Request shift change',
  fr: 'Demander une modification du service',
  es: 'Solicitar cambio de turno',
);

String _requestShiftChangeBanner(
  BuildContext context,
) => _localizedShiftDayText(
  context,
  it: 'Puoi proporre una modifica del tuo turno. La richiesta verra inviata ai gestori del team per approvazione.',
  en: 'You can propose a change to your shift. The request will be sent to the team managers for approval.',
  fr: 'Vous pouvez proposer une modification de votre service. La demande sera envoyee aux responsables de l\'equipe pour approbation.',
  es: 'Puedes proponer un cambio de tu turno. La solicitud se enviara a los responsables del equipo para su aprobacion.',
);

String _requestShiftChangeButton(BuildContext context) =>
    _requestShiftChangeTitle(context);

String _requestShiftSwapButton(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Sostituzione turno',
  en: 'Shift swap',
  fr: 'Echange de quart',
  es: 'Intercambio de turno',
);

String _findReplacementButton(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Cerca sostituto',
  en: 'Find replacement',
  fr: 'Trouver un remplacement',
  es: 'Buscar reemplazo',
);

String _pendingShiftChangeButton(BuildContext context) =>
    _localizedShiftDayText(
      context,
      it: 'Richiesta gia in attesa',
      en: 'Request already pending',
      fr: 'Demande deja en attente',
      es: 'Solicitud ya pendiente',
    );

String _pendingShiftChangeBanner(
  BuildContext context,
) => _localizedShiftDayText(
  context,
  it: 'Hai gia una richiesta di modifica turno in attesa. Finche non viene approvata o rifiutata non puoi inviarne un\'altra.',
  en: 'You already have a pending shift-change request. You cannot send another one until it is approved or rejected.',
  fr: 'Vous avez deja une demande de modification de service en attente. Vous ne pouvez pas en envoyer une autre tant qu\'elle n\'est pas approuvee ou refusee.',
  es: 'Ya tienes una solicitud de cambio de turno pendiente. No puedes enviar otra hasta que sea aprobada o rechazada.',
);

String _approvedShiftEditBanner(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'La richiesta oraria e stata approvata. Puoi modificare il turno, ma gli orari start e end restano bloccati su quelli approvati.',
  en: 'The time-change request was approved. You can edit the shift, but the start and end times stay locked to the approved values.',
  fr: 'La demande d\'horaire a ete approuvee. Vous pouvez modifier le service, mais les heures de debut et de fin restent verrouillees sur celles approuvees.',
  es: 'La solicitud de horario fue aprobada. Puedes editar el turno, pero la hora de inicio y fin queda bloqueada con los valores aprobados.',
);

String _notificationModeLabel(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Notifica',
  en: 'Notification',
  fr: 'Notification',
  es: 'Notificacion',
);

String _alarmModeLabel(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Sveglia',
  en: 'Alarm',
  fr: 'Alarme',
  es: 'Alarma',
);

String _alarmPermissionTitle(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Permesso sveglia',
  en: 'Alarm permission',
  fr: 'Autorisation alarme',
  es: 'Permiso de alarma',
);

String _alarmPermissionMessage(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Per far aprire lo schermo durante la sveglia del turno, abilita "Mostra sopra altre app" (o "Intent a schermo intero") nelle impostazioni dell\'app.',
  en: 'To wake the screen for a shift alarm, enable "Display over other apps" (or "Full screen intent") in the app settings.',
  fr: 'Pour reveiller l\'ecran pendant l\'alarme du quart, activez "Afficher par-dessus les autres applications" (ou "Intent plein ecran") dans les parametres de l\'application.',
  es: 'Para encender la pantalla durante la alarma del turno, activa "Mostrar sobre otras apps" (o "Intent de pantalla completa") en los ajustes de la app.',
);

String _searchShiftHintText(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Cerca turno...',
  en: 'Search shift...',
  fr: 'Rechercher un quart...',
  es: 'Buscar turno...',
);

String _addAlarmTitle(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Aggiungi sveglia',
  en: 'Add alarm',
  fr: 'Ajouter une alarme',
  es: 'Agregar alarma',
);

String _alarmMinutesLabel(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Minuti (negativi = prima)',
  en: 'Minutes (negative = before)',
  fr: 'Minutes (negatif = avant)',
  es: 'Minutos (negativo = antes)',
);

String _addLabel(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Aggiungi',
  en: 'Add',
  fr: 'Ajouter',
  es: 'Agregar',
);

String _shiftLabel(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Turno',
  en: 'Shift',
  fr: 'Quart',
  es: 'Turno',
);

String _shiftDetailsTitle(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Dettagli turno',
  en: 'Shift details',
  fr: 'Details du quart',
  es: 'Detalles del turno',
);

String _dateRowLabel(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Data',
  en: 'Date',
  fr: 'Date',
  es: 'Fecha',
);

String _memberRowLabel(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Membro',
  en: 'Member',
  fr: 'Membre',
  es: 'Miembro',
);

String _visibilityRowLabel(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Visibilita',
  en: 'Visibility',
  fr: 'Visibilite',
  es: 'Visibilidad',
);

String _sourceRowLabel(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Origine',
  en: 'Source',
  fr: 'Origine',
  es: 'Origen',
);

String _chatMessageSourceValue(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Messaggio chat',
  en: 'Chat message',
  fr: 'Message chat',
  es: 'Mensaje de chat',
);

String _sourceMessageTitle(BuildContext context) => _localizedShiftDayText(
  context,
  it: 'Origine chat',
  en: 'Chat source',
  fr: 'Origine chat',
  es: 'Origen chat',
);

String _sourceMessageDescription(
  BuildContext context,
) => _localizedShiftDayText(
  context,
  it: 'Questo turno nasce da un messaggio chat. Puoi completare i campi mancanti prima di salvarlo.',
  en: 'This shift comes from a chat message. You can complete the missing fields before saving it.',
  fr: 'Ce quart provient d un message chat. Vous pouvez completer les champs manquants avant de l enregistrer.',
  es: 'Este turno nace de un mensaje de chat. Puedes completar los campos que faltan antes de guardarlo.',
);

String _openLinkedConversationButtonLabel(BuildContext context) =>
    _localizedShiftDayText(
      context,
      it: 'Apri conversazione collegata',
      en: 'Open linked conversation',
      fr: 'Ouvrir la conversation liee',
      es: 'Abrir conversacion vinculada',
    );

String _yesLabel(BuildContext context) =>
    _localizedShiftDayText(context, it: 'Si', en: 'Yes', fr: 'Oui', es: 'Si');

String _noLabel(BuildContext context) =>
    _localizedShiftDayText(context, it: 'No', en: 'No', fr: 'Non', es: 'No');

String _privateShiftSummaryLabel(BuildContext context) =>
    _localizedShiftDayText(
      context,
      it: 'Turno privato',
      en: 'Private shift',
      fr: 'Quart prive',
      es: 'Turno privado',
    );

String _publicTeamShiftSummaryLabel(BuildContext context) =>
    _localizedShiftDayText(
      context,
      it: 'Turno pubblico del team',
      en: 'Public team shift',
      fr: 'Quart public d\'equipe',
      es: 'Turno publico del equipo',
    );

String _publicPersonalShiftSummaryLabel(BuildContext context) =>
    _localizedShiftDayText(
      context,
      it: 'Turno personale pubblico',
      en: 'Public personal shift',
      fr: 'Quart personnel public',
      es: 'Turno personal publico',
    );

/// A simplified view of a team member used inside the shift dialog.
class ShiftTeamMember {
  final String? userId; // Firebase UID when assignable
  final String email;
  final String roleLabel;
  final String? fullName;
  final bool isAssignable;
  final ShiftAbsenceStatus? absenceStatus;
  const ShiftTeamMember({
    required this.userId,
    required this.email,
    required this.roleLabel,
    this.fullName,
    this.isAssignable = true,
    this.absenceStatus,
  });

  String get primaryLabel => email.isNotEmpty
      ? email
      : fullName?.trim().isNotEmpty == true
      ? fullName!.trim()
      : 'Team member';

  bool get isAvailableForScheduling => absenceStatus == null;

  bool get isSelectable => isAssignable && isAvailableForScheduling;

  String? secondaryLabel(BuildContext context) {
    final parts = <String>[];
    if (roleLabel.trim().isNotEmpty) {
      parts.add(roleLabel);
    }
    final statusLabel = absenceStatus?.label(context).trim();
    if (statusLabel != null && statusLabel.isNotEmpty) {
      parts.add(statusLabel);
    }
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' • ');
  }

  String? disabledHint(BuildContext context) {
    if (!isAssignable) {
      return _notAssignableUntilActiveText(context);
    }
    final statusLabel = absenceStatus?.label(context).trim();
    if (statusLabel == null || statusLabel.isEmpty) {
      return null;
    }
    return _localizedShiftDayText(
      context,
      it: 'Fuori dalla schedulazione: $statusLabel',
      en: 'Unavailable for scheduling: $statusLabel',
      fr: 'Indisponible pour la planification : $statusLabel',
      es: 'No disponible para planificacion: $statusLabel',
    );
  }

  String displayLabel(BuildContext context) {
    if (email.isNotEmpty) return email;
    if (fullName?.trim().isNotEmpty == true) return fullName!.trim();
    return _defaultTeamMemberLabel(context);
  }

  String get searchLabel =>
      [primaryLabel, roleLabel, fullName ?? ''].join(' ').toLowerCase();
}

class ShiftMemberAssignmentPlan {
  const ShiftMemberAssignmentPlan({required this.targetUserId, this.profileId});

  final String targetUserId;
  final String? profileId;
}

/// Result of the day dialog.
class ShiftDayDialogResult {
  const ShiftDayDialogResult({
    this.profileId,
    required this.startTime,
    required this.endTime,
    required this.overnight,
    required this.alarmOffsets,
    this.note,
    this.deleted = false,
    this.archived = false,
    this.isPublic = false,
    this.teamId,
    this.targetUserIds = const [],
    this.memberAssignmentPlans = const [],
    this.scheduledDates = const [],
    this.requestedChange = false,
    this.requestedSwap = false,
    this.swapCandidateUserId,
    this.swapNote,
    this.contextType,
    this.contextId,
    this.sourceType,
    this.sourceId,
    this.sourceMessageId,
  });

  final String? profileId;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool overnight;
  final List<int> alarmOffsets;
  final String? note;
  final bool deleted;
  final bool archived;

  /// True → shift visible to all team members.
  final bool isPublic;
  final String? teamId;

  /// Firebase UIDs of the users who should receive this shift.
  /// Empty = assign only to the authenticated user (private).
  /// One entry = assign to that specific member.
  /// Multiple entries = assign to all selected members.
  final List<String> targetUserIds;

  /// Optional member-specific assignments. When present, each selected member
  /// can receive a different shift profile while reusing the same day/team flow.
  final List<ShiftMemberAssignmentPlan> memberAssignmentPlans;

  /// Days on which the shift should be created.
  final List<DateTime> scheduledDates;

  final bool requestedChange;
  final bool requestedSwap;
  final String? swapCandidateUserId;
  final String? swapNote;
  final String? contextType;
  final String? contextId;
  final String? sourceType;
  final String? sourceId;
  final String? sourceMessageId;
}

/// Modal bottom-sheet / dialog for assigning or editing a shift on a single day.
Future<ShiftDayDialogResult?> showShiftDayDialog({
  required BuildContext context,
  required DateTime date,
  required List<ShiftProfileEntity> profiles,
  List<TeamEntity> allTeams = const [],
  ShiftAssignmentEntity? existing,
  ShiftAssignmentCreateRequestEntity? initialDraft,
  String? initialTeamId,
  bool canManagePublicShifts = false,
  bool canRequestPublicShiftChanges = false,
  bool canRequestAssignmentSwap = false,
  bool hasPendingPublicShiftChangeRequest = false,
  bool canEditApprovedPublicShift = false,
  Map<String, ShiftAbsenceStatus> absenceStatusesByUserId = const {},
  List<String> suggestedUserIds = const <String>[],
  VoidCallback? onOpenLinkedConversation,

  /// Teams where the current user is owner (to enable team assignment).
  List<TeamEntityForView> ownerTeams = const [],
}) {
  final isWideLayout = MediaQuery.of(context).size.width >= 720;
  final sheet = _ShiftDaySheet(
    date: date,
    profiles: profiles,
    allTeams: allTeams,
    existing: existing,
    initialDraft: initialDraft,
    initialTeamId: initialTeamId,
    canManagePublicShifts: canManagePublicShifts,
    canRequestPublicShiftChanges: canRequestPublicShiftChanges,
    canRequestAssignmentSwap: canRequestAssignmentSwap,
    hasPendingPublicShiftChangeRequest: hasPendingPublicShiftChangeRequest,
    canEditApprovedPublicShift: canEditApprovedPublicShift,
    absenceStatusesByUserId: absenceStatusesByUserId,
    suggestedUserIds: suggestedUserIds,
    onOpenLinkedConversation: onOpenLinkedConversation,
    ownerTeams: ownerTeams,
    useDialogLayout: isWideLayout,
  );

  if (isWideLayout) {
    return showDialog<ShiftDayDialogResult>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: sheet,
      ),
    );
  }

  return showModalBottomSheet<ShiftDayDialogResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => sheet,
  );
}

class _ShiftDaySheet extends StatefulWidget {
  const _ShiftDaySheet({
    required this.date,
    required this.profiles,
    this.allTeams = const [],
    this.existing,
    this.initialDraft,
    this.initialTeamId,
    this.canManagePublicShifts = false,
    this.canRequestPublicShiftChanges = false,
    this.canRequestAssignmentSwap = false,
    this.hasPendingPublicShiftChangeRequest = false,
    this.canEditApprovedPublicShift = false,
    this.absenceStatusesByUserId = const {},
    this.suggestedUserIds = const <String>[],
    this.onOpenLinkedConversation,
    this.ownerTeams = const [],
    this.useDialogLayout = false,
  });

  final DateTime date;
  final List<ShiftProfileEntity> profiles;
  final List<TeamEntity> allTeams;
  final ShiftAssignmentEntity? existing;
  final ShiftAssignmentCreateRequestEntity? initialDraft;
  final String? initialTeamId;
  final bool canManagePublicShifts;
  final bool canRequestPublicShiftChanges;
  final bool canRequestAssignmentSwap;
  final bool hasPendingPublicShiftChangeRequest;
  final bool canEditApprovedPublicShift;
  final Map<String, ShiftAbsenceStatus> absenceStatusesByUserId;
  final List<String> suggestedUserIds;
  final VoidCallback? onOpenLinkedConversation;
  final List<TeamEntityForView> ownerTeams;
  final bool useDialogLayout;

  @override
  State<_ShiftDaySheet> createState() => _ShiftDaySheetState();
}

class _ShiftDaySheetState extends State<_ShiftDaySheet> {
  final TeamMemberUseCase _teamMemberUseCase =
      GetIt.instance<TeamMemberUseCase>();
  final LocalNotificationService _localNotifications =
      GetIt.instance<LocalNotificationService>();
  final ShiftRepository _shiftRepository = GetIt.instance<ShiftRepository>();

  ShiftProfileEntity? _selectedProfile;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _overnight;
  late List<int> _alarmOffsets;
  ShiftAlarmType _alarmType = ShiftAlarmType.alarm;
  late bool _isPublic;
  late bool _readOnly;
  late bool _requestModeActive;
  late DateTime _rangeEndDate;
  final _noteCtrl = TextEditingController();
  final Map<String, List<TeamMemberforView>> _membersByTeamId =
      <String, List<TeamMemberforView>>{};
  final Set<String> _loadingTeamIds = <String>{};

  // ── Team assignment state ──────────────────────────────────────────────────
  TeamEntityForView? _selectedTeam;
  final Set<String> _selectedMemberIds = <String>{};
  bool _assignToAllMembers = true;
  bool _useMemberSpecificProfiles = false;
  final Map<String, String?> _memberProfileIds = <String, String?>{};
  bool _loadingReplacementCandidates = false;
  bool _loadingWorkflowAutoReplaceCandidates = false;
  List<String> _workflowCompatibleSuggestedUserIds = const <String>[];
  Map<String, String> _workflowSuggestedCandidateLabels =
      const <String, String>{};

  bool get _hasOwnerTeams => widget.ownerTeams.isNotEmpty;
  bool get _existingHasTeamScope =>
      widget.existing != null &&
      ShiftAssignmentAccessPolicy.hasTeamScope(widget.existing!);
  bool get _canOpenRequestMode =>
      widget.existing != null &&
      widget.existing!.isPublic &&
      _existingHasTeamScope &&
      widget.canRequestPublicShiftChanges &&
      !widget.hasPendingPublicShiftChangeRequest &&
      !widget.canManagePublicShifts;
  bool get _hasPendingRequest =>
      widget.existing != null &&
      widget.existing!.isPublic &&
      _existingHasTeamScope &&
      widget.hasPendingPublicShiftChangeRequest &&
      !widget.canManagePublicShifts;
  bool get _requestMode => _requestModeActive;
  bool get _viewOnlyRequestMode =>
      _readOnly && (_canOpenRequestMode || _hasPendingRequest) && !_requestMode;
  bool get _canOpenSwapRequest =>
      widget.existing != null &&
      widget.canRequestAssignmentSwap &&
      _existingHasTeamScope &&
      !_requestMode &&
      !_approvedSelfEditMode;
  bool get _canSearchReplacementCandidates =>
      widget.existing != null &&
      widget.existing!.isPublic &&
      _existingHasTeamScope &&
      !_requestMode &&
      (widget.canManagePublicShifts ||
          widget.canRequestPublicShiftChanges ||
          widget.canRequestAssignmentSwap ||
          widget.canEditApprovedPublicShift);
  bool get _approvedSelfEditMode =>
      widget.existing != null &&
      widget.existing!.isPublic &&
      _existingHasTeamScope &&
      widget.canEditApprovedPublicShift &&
      !widget.canManagePublicShifts;
  bool get _timeLocked => _approvedSelfEditMode;
  bool get _isTeamScopedSelection => _selectedTeam != null;
  bool get _effectiveIsPublic => _isTeamScopedSelection || _isPublic;
  bool get _isSelectedTeamLoading {
    final teamId = _selectedTeam?.team.id;
    return teamId != null && _loadingTeamIds.contains(teamId);
  }

  List<ShiftTeamMember> get _workflowAutoReplaceMembers {
    if (_workflowCompatibleSuggestedUserIds.isEmpty) {
      return const <ShiftTeamMember>[];
    }
    final byUserId = <String, ShiftTeamMember>{
      for (final member in _teamMembers)
        if (member.userId != null && member.isSelectable)
          member.userId!: member,
    };
    final ordered = <ShiftTeamMember>[];
    for (final userId in _workflowCompatibleSuggestedUserIds) {
      final member = byUserId[userId];
      if (member != null) {
        ordered.add(member);
      }
    }
    return ordered;
  }

  ShiftTeamMember? get _primaryWorkflowAutoReplaceMember {
    final members = _workflowAutoReplaceMembers;
    if (members.isEmpty) {
      return null;
    }
    return members.first;
  }

  bool get _canAutoReplaceFromWorkflow =>
      !_readOnly &&
      !_requestMode &&
      widget.existing != null &&
      _primaryWorkflowAutoReplaceMember?.userId != null;
  bool get _isChatMessageWorkflowSource {
    final draftSourceType = widget.initialDraft?.sourceType
        ?.trim()
        .toLowerCase();
    if (draftSourceType == 'chat_message') {
      return true;
    }
    return widget.existing?.workflowContext.normalizedSourceType ==
        'chat_message';
  }

  TeamEntity? _findAnyTeamById(String? teamId) {
    final normalized = teamId?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return widget.allTeams.where((team) => team.id == normalized).firstOrNull;
  }

  String _resolvedProfileName(AppLocalizations localization) {
    final selectedName = _selectedProfile?.name.trim();
    if (selectedName != null && selectedName.isNotEmpty) {
      return selectedName;
    }
    final existingName = widget.existing?.profileName?.trim();
    if (existingName != null && existingName.isNotEmpty) {
      return existingName;
    }
    return localization.shiftReportDefaultProfile;
  }

  String _resolvedTeamName(BuildContext context) {
    final selectedName = _selectedTeam?.team.name.trim();
    if (selectedName != null && selectedName.isNotEmpty) {
      return selectedName;
    }
    final fallbackTeam = _findAnyTeamById(widget.existing?.teamId);
    final fallbackName = fallbackTeam?.name.trim();
    if (fallbackName != null && fallbackName.isNotEmpty) {
      return fallbackName;
    }
    if (_existingHasTeamScope) {
      return _localizedShiftDayText(
        context,
        it: 'Team non disponibile',
        en: 'Team unavailable',
        fr: 'Equipe indisponible',
        es: 'Equipo no disponible',
      );
    }
    return _privateShiftLabel(context);
  }

  String _formatRoleLabel(String rawRole) {
    return _localizedRoleLabel(context, rawRole);
  }

  List<ShiftTeamMember> get _teamMembers {
    if (_selectedTeam == null) return [];
    final members = _selectedTeam?.team.id != null
        ? (_membersByTeamId[_selectedTeam!.team.id!] ?? _selectedTeam!.members)
        : _selectedTeam!.members;
    return members.map((m) {
      final email = m.teamMember.userEmail.trim();
      final fullName = m.user?.fullName.trim() ?? '';
      final roleLabel = _formatRoleLabel(m.teamMember.roleId);
      final normalizedUserId = m.teamMember.userId?.trim();
      final resolvedUserId = normalizedUserId?.isNotEmpty == true
          ? normalizedUserId
          : null;
      return ShiftTeamMember(
        userId: resolvedUserId,
        email: email,
        roleLabel: roleLabel,
        fullName: fullName.isNotEmpty ? fullName : m.teamMember.initialName,
        isAssignable: resolvedUserId != null,
        absenceStatus: resolvedUserId == null
            ? null
            : widget.absenceStatusesByUserId[resolvedUserId],
      );
    }).toList();
  }

  List<String> get _resolvedTargetUserIds {
    if (_selectedTeam == null) return [];
    if (_assignToAllMembers) {
      // all members
      return _teamMembers
          .where((m) => m.isSelectable && m.userId != null)
          .map((m) => m.userId!)
          .toList();
    }
    return _teamMembers
        .where(
          (member) =>
              member.userId != null &&
              member.isSelectable &&
              _selectedMemberIds.contains(member.userId),
        )
        .map((member) => member.userId!)
        .toList();
  }

  bool get _hasValidTeamSelection {
    if (_selectedTeam == null) {
      return true;
    }
    if (_assignToAllMembers) {
      return _teamMembers.any((member) => member.isSelectable);
    }
    return _selectedSpecificMembers.isNotEmpty;
  }

  List<ShiftTeamMember> get _selectedSpecificMembers => _teamMembers
      .where(
        (member) =>
            member.userId != null &&
            _selectedMemberIds.contains(member.userId) &&
            member.isSelectable,
      )
      .toList();

  List<ShiftMemberAssignmentPlan> get _memberAssignmentPlans {
    if (!_useMemberSpecificProfiles ||
        _selectedTeam == null ||
        _assignToAllMembers ||
        _selectedMemberIds.length < 2) {
      return const [];
    }
    return _selectedSpecificMembers
        .map(
          (member) => ShiftMemberAssignmentPlan(
            targetUserId: member.userId!,
            profileId: _memberProfileIds[member.userId!],
          ),
        )
        .toList();
  }

  bool get _hasValidTimeRange {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (_requestMode) {
      return startMinutes != endMinutes;
    }
    if (_overnight) {
      return startMinutes != endMinutes;
    }
    return endMinutes > startMinutes;
  }

  bool _deriveOvernightFromTimes(TimeOfDay startTime, TimeOfDay endTime) {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return endMinutes <= startMinutes;
  }

  List<DateTime> get _scheduledDates {
    final start = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
    );
    final end = DateTime(
      _rangeEndDate.year,
      _rangeEndDate.month,
      _rangeEndDate.day,
    );
    final dates = <DateTime>[];
    var current = start;
    while (!current.isAfter(end)) {
      dates.add(current);
      current = DateTime(current.year, current.month, current.day + 1);
    }
    return dates;
  }

  @override
  void initState() {
    super.initState();
    _loadAlarmType();
    for (final ownerTeam in widget.ownerTeams) {
      final teamId = ownerTeam.team.id;
      if (teamId != null && ownerTeam.members.isNotEmpty) {
        _membersByTeamId[teamId] = ownerTeam.members;
      }
    }

    if (widget.existing != null) {
      final ex = widget.existing!;
      _selectedProfile = widget.profiles
          .where((p) => p.id == ex.profileId)
          .firstOrNull;
      _startTime = ex.startTime;
      _endTime = ex.endTime;
      _overnight = ex.overnight;
      _alarmOffsets = List.from(ex.alarmOffsets);
      _isPublic = ex.isPublic;
      _rangeEndDate = widget.date;
      _noteCtrl.text = ex.note ?? '';
      if (ex.teamId != null) {
        final manageableTeam = widget.ownerTeams
            .where((team) => team.team.id == ex.teamId)
            .firstOrNull;
        if (manageableTeam != null) {
          _selectedTeam = manageableTeam;
        } else {
          final fallbackTeam = _findAnyTeamById(ex.teamId);
          if (fallbackTeam != null) {
            _selectedTeam = TeamEntityForView(
              team: fallbackTeam,
              members: _membersByTeamId[fallbackTeam.id!] ?? const [],
            );
          }
        }
        // Pre-select the existing target member so an admin can see and
        // optionally change it when editing a team-scoped shift.
        if (ex.userId.isNotEmpty) {
          _assignToAllMembers = false;
          _selectedMemberIds.add(ex.userId);
        }
        if (manageableTeam != null) {
          unawaited(_ensureTeamMembersLoaded(_selectedTeam));
        }
      }
    } else {
      final initialDraft = widget.initialDraft;
      _selectedProfile = initialDraft?.profileId == null
          ? null
          : widget.profiles
                .where((profile) => profile.id == initialDraft!.profileId)
                .firstOrNull;
      _startTime =
          initialDraft?.startTime ??
          _selectedProfile?.startTime ??
          const TimeOfDay(hour: 7, minute: 0);
      _endTime =
          initialDraft?.endTime ??
          _selectedProfile?.endTime ??
          const TimeOfDay(hour: 16, minute: 0);
      _overnight =
          initialDraft?.overnight ?? _selectedProfile?.overnight ?? false;
      _alarmOffsets =
          initialDraft?.alarmOffsets != null &&
              initialDraft!.alarmOffsets!.isNotEmpty
          ? List<int>.from(initialDraft.alarmOffsets!)
          : (_selectedProfile?.alarmOffsets.isNotEmpty ?? false)
          ? List<int>.from(_selectedProfile!.alarmOffsets)
          : [-30, -15];
      _isPublic = initialDraft?.isPublic ?? false;
      _rangeEndDate = widget.date;
      _noteCtrl.text = initialDraft?.note?.trim() ?? '';
      final initialTeamId =
          initialDraft?.teamId?.trim() ?? widget.initialTeamId?.trim();
      if (initialTeamId != null && initialTeamId.isNotEmpty) {
        _selectedTeam = widget.ownerTeams
            .where((team) => team.team.id == initialTeamId)
            .firstOrNull;
        if (_selectedTeam != null) {
          unawaited(_ensureTeamMembersLoaded(_selectedTeam));
        }
      }
      final initialTargetUserId = initialDraft?.targetUserId?.trim();
      if (initialTargetUserId != null && initialTargetUserId.isNotEmpty) {
        _assignToAllMembers = false;
        _selectedMemberIds.add(initialTargetUserId);
      }
    }
    _requestModeActive = false;
    // Non-owners cannot edit existing public shifts
    _readOnly =
        !_requestMode &&
        !_approvedSelfEditMode &&
        !widget.canManagePublicShifts &&
        widget.existing != null &&
        widget.existing!.isPublic;
    if (widget.existing != null && widget.suggestedUserIds.isNotEmpty) {
      unawaited(_loadWorkflowAutoReplaceCandidates());
    }
  }

  void _enterRequestMode() {
    if (!_canOpenRequestMode || !mounted) {
      return;
    }
    setState(() {
      _requestModeActive = true;
      _readOnly = false;
      _overnight = _deriveOvernightFromTimes(_startTime, _endTime);
      _noteCtrl.clear();
    });
  }

  Future<void> _pickRangeEndDate(AppLocalizations loc) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeEndDate,
      firstDate: DateTime(widget.date.year, widget.date.month, widget.date.day),
      lastDate: DateTime(widget.date.year + 2, 12, 31),
      helpText: loc.shiftRepeatUntil,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _rangeEndDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  String _formatDateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _firstWorkflowSuggestedLabel() {
    for (final value in _workflowSuggestedCandidateLabels.values) {
      final normalized = value.trim();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return '';
  }

  String _workflowAutoReplaceTitle(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'it' => 'Copertura dal sondaggio',
      'fr' => 'Couverture depuis le sondage',
      'es' => 'Cobertura desde la encuesta',
      _ => 'Survey coverage',
    };
  }

  String _workflowAutoReplaceMessage(BuildContext context) {
    final primaryMember = _primaryWorkflowAutoReplaceMember;
    final candidateCount = _workflowAutoReplaceMembers.length;
    final candidateName =
        primaryMember?.displayLabel(context) ?? _firstWorkflowSuggestedLabel();
    return switch (Localizations.localeOf(context).languageCode) {
      'it' =>
        candidateCount <= 1
            ? 'Abbiamo trovato un collega disponibile e compatibile dal sondaggio: $candidateName.'
            : 'Abbiamo trovato $candidateCount colleghi disponibili e compatibili dal sondaggio. Useremo $candidateName come primo candidato senza vincoli.',
      'fr' =>
        candidateCount <= 1
            ? 'Nous avons trouve un collegue disponible et compatible depuis le sondage : $candidateName.'
            : 'Nous avons trouve $candidateCount collegues disponibles et compatibles depuis le sondage. Nous utiliserons $candidateName comme premier candidat sans contrainte.',
      'es' =>
        candidateCount <= 1
            ? 'Hemos encontrado un companero disponible y compatible desde la encuesta: $candidateName.'
            : 'Hemos encontrado $candidateCount companeros disponibles y compatibles desde la encuesta. Usaremos a $candidateName como primer candidato sin restricciones.',
      _ =>
        candidateCount <= 1
            ? 'We found one available and compatible teammate from the survey: $candidateName.'
            : 'We found $candidateCount available and compatible teammates from the survey. We will use $candidateName as the first eligible candidate.',
    };
  }

  String _workflowAutoReplaceButtonLabel(BuildContext context) {
    final primaryMember = _primaryWorkflowAutoReplaceMember;
    final candidateName =
        primaryMember?.displayLabel(context) ?? _firstWorkflowSuggestedLabel();
    return switch (Localizations.localeOf(context).languageCode) {
      'it' =>
        candidateName.isEmpty
            ? 'Sostituisci automaticamente'
            : 'Sostituisci con $candidateName',
      'fr' =>
        candidateName.isEmpty
            ? 'Remplacer automatiquement'
            : 'Remplacer par $candidateName',
      'es' =>
        candidateName.isEmpty
            ? 'Sustituir automaticamente'
            : 'Sustituir con $candidateName',
      _ =>
        candidateName.isEmpty
            ? 'Replace automatically'
            : 'Replace with $candidateName',
    };
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAlarmType() async {
    final type = await _localNotifications.getShiftAlarmType();
    if (!mounted) return;
    setState(() => _alarmType = type);
  }

  /// Richiede i permessi Android necessari per la modalità Sveglia e mostra
  /// un dialog informativo se `USE_FULL_SCREEN_INTENT` non è concesso.
  Future<void> _requestAlarmPermissionsIfNeeded() async {
    if (kIsWeb) return;
    final status = await _localNotifications.requestAlarmModePermissions();
    if (!mounted) return;
    if (!status.fullScreenIntent) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(_alarmPermissionTitle(context)),
          content: Text(_alarmPermissionMessage(context)),
          actions: [
            CustomAppButton(
              onPressed: () => Navigator.of(ctx).pop(),
              type: ButtonType.text,
              isActive: false,
              child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _ensureTeamMembersLoaded(TeamEntityForView? team) async {
    final teamId = team?.team.id;
    if (teamId == null) {
      return;
    }
    if (_loadingTeamIds.contains(teamId)) {
      return;
    }
    setState(() {
      _loadingTeamIds.add(teamId);
    });
    try {
      final members = await _teamMemberUseCase.getAllMembersByTeamId(teamId);
      if (!mounted) return;
      setState(() {
        _loadingTeamIds.remove(teamId);
        _membersByTeamId[teamId] = members
            .map((member) => TeamMemberforView(teamMember: member))
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingTeamIds.remove(teamId);
      });
    }
  }

  Future<void> _loadWorkflowAutoReplaceCandidates() async {
    final existing = widget.existing;
    if (existing == null ||
        widget.suggestedUserIds.isEmpty ||
        _loadingWorkflowAutoReplaceCandidates) {
      return;
    }

    setState(() {
      _loadingWorkflowAutoReplaceCandidates = true;
    });
    try {
      final result = await _shiftRepository.findReplacementCandidates(
        existing.id,
      );
      if (!mounted) {
        return;
      }
      final suggestedUserIds = widget.suggestedUserIds
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet();
      final compatibleSuggestedCandidates = result.candidates
          .where((candidate) => candidate.compatible)
          .where(
            (candidate) => suggestedUserIds.contains(candidate.userId.trim()),
          )
          .toList(growable: false);
      setState(() {
        _workflowCompatibleSuggestedUserIds = compatibleSuggestedCandidates
            .map((candidate) => candidate.userId.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false);
        _workflowSuggestedCandidateLabels = {
          for (final candidate in compatibleSuggestedCandidates)
            candidate.userId.trim(): candidate.displayName,
        };
        _loadingWorkflowAutoReplaceCandidates = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingWorkflowAutoReplaceCandidates = false;
      });
    }
  }

  void _applyProfile(ShiftProfileEntity p) {
    setState(() {
      _selectedProfile = p;
      if (!_timeLocked) {
        _startTime = p.startTime;
        _endTime = p.endTime;
        _overnight = p.overnight;
      }
      _alarmOffsets = List.from(p.alarmOffsets);
    });
  }

  Future<void> _submitShiftDay() async {
    if (_readOnly || !_hasValidTeamSelection || !_hasValidTimeRange) {
      return;
    }
    if (_alarmOffsets.isNotEmpty && _alarmType == ShiftAlarmType.alarm) {
      await _requestAlarmPermissionsIfNeeded();
      if (!mounted) {
        return;
      }
    }

    Navigator.of(context).pop(
      ShiftDayDialogResult(
        profileId: _selectedProfile?.id,
        startTime: _startTime,
        endTime: _endTime,
        overnight: _overnight,
        alarmOffsets: _alarmOffsets,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        isPublic: _effectiveIsPublic,
        teamId: _isTeamScopedSelection ? _selectedTeam?.team.id : null,
        targetUserIds: _resolvedTargetUserIds,
        memberAssignmentPlans: _memberAssignmentPlans,
        scheduledDates: _scheduledDates,
        contextType: widget.initialDraft?.contextType,
        contextId: widget.initialDraft?.contextId,
        sourceType: widget.initialDraft?.sourceType,
        sourceId: widget.initialDraft?.sourceId,
        sourceMessageId: widget.initialDraft?.sourceMessageId,
      ),
    );
  }

  Future<void> _autoReplaceFromWorkflow() async {
    final member = _primaryWorkflowAutoReplaceMember;
    if (member?.userId == null) {
      return;
    }
    setState(() {
      _assignToAllMembers = false;
      _useMemberSpecificProfiles = false;
      _selectedMemberIds
        ..clear()
        ..add(member!.userId!);
    });
    await _submitShiftDay();
  }

  void _submitShiftChangeRequest() {
    if (_readOnly || !_hasValidTimeRange) {
      return;
    }
    Navigator.of(context).pop(
      ShiftDayDialogResult(
        profileId: _selectedProfile?.id,
        startTime: _startTime,
        endTime: _endTime,
        overnight: _overnight,
        alarmOffsets: _alarmOffsets,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        isPublic: true,
        teamId: widget.existing?.teamId,
        requestedChange: true,
      ),
    );
  }

  Future<void> _startShiftSwapRequest() async {
    await _ensureTeamMembersLoaded(_selectedTeam);
    if (!mounted) {
      return;
    }
    final existing = widget.existing;
    if (existing == null || _selectedTeam == null) {
      return;
    }

    final candidates = _teamMembers
        .where((member) => member.userId != null && member.isSelectable)
        .where((member) => member.userId != existing.userId)
        .map((member) {
          final fullName = member.fullName?.trim();
          final email = member.email.trim();
          final label = fullName != null && fullName.isNotEmpty
              ? fullName
              : email;
          final subtitle = fullName != null && fullName.isNotEmpty
              ? email
              : null;
          return ShiftSwapCandidateOption(
            userId: member.userId!,
            label: label,
            subtitle: subtitle,
          );
        })
        .toList(growable: false);

    if (candidates.isEmpty) {
      final message = _localizedShiftDayText(
        context,
        it: 'Non ci sono colleghi disponibili in questo team per richiedere uno scambio.',
        en: 'There are no teammates available in this team for a swap.',
        fr: 'Aucun collegue disponible dans cette equipe pour demander un echange.',
        es: 'No hay companeros disponibles en este equipo para solicitar un intercambio.',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    final result = await showShiftSwapRequestDialog(
      context: context,
      shiftDateLabel: _formatDateLabel(widget.date),
      teamName: _resolvedTeamName(context),
      candidates: candidates,
    );
    if (result == null || !mounted) {
      return;
    }

    Navigator.of(context).pop(
      ShiftDayDialogResult(
        startTime: _startTime,
        endTime: _endTime,
        overnight: _overnight,
        alarmOffsets: _alarmOffsets,
        requestedSwap: true,
        swapCandidateUserId: result.candidateUserId,
        swapNote: result.note,
      ),
    );
  }

  Future<void> _openReplacementCandidates() async {
    final existing = widget.existing;
    if (existing == null || _loadingReplacementCandidates) {
      return;
    }

    setState(() {
      _loadingReplacementCandidates = true;
    });
    try {
      final response = await _shiftRepository.findReplacementCandidates(
        existing.id,
      );
      if (!mounted) {
        return;
      }
      await showShiftReplacementCandidatesDialog(
        context: context,
        result: response,
        onOpenAvailability: () => _openAvailabilitySondageDraft(response),
        onOfferReplacement: (candidate) =>
            _offerReplacement(response.assignmentId, candidate),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showResolvedError(
        context,
        error,
        fallback: _localizedShiftDayText(
          context,
          it: 'Non siamo riusciti a caricare i candidati per la copertura del turno.',
          en: 'We could not load replacement candidates for this shift.',
          fr: 'Nous n\'avons pas pu charger les candidats pour couvrir ce quart.',
          es: 'No hemos podido cargar los candidatos para cubrir este turno.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingReplacementCandidates = false;
        });
      }
    }
  }

  Future<void> _offerReplacement(
    String assignmentId,
    ShiftReplacementCandidateEntity candidate,
  ) async {
    try {
      await _shiftRepository.offerReplacement(
        assignmentId,
        candidateFirebaseUid: candidate.userId,
      );
      if (!mounted) {
        return;
      }
      AppSnackBar.showSuccess(
        context,
        _localizedShiftDayText(
          context,
          it: 'Richiesta inviata a ${candidate.displayName}.',
          en: 'Request sent to ${candidate.displayName}.',
          fr: 'Demande envoyee a ${candidate.displayName}.',
          es: 'Solicitud enviada a ${candidate.displayName}.',
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showResolvedError(
        context,
        error,
        fallback: _localizedShiftDayText(
          context,
          it: 'Non siamo riusciti a inviare la richiesta di sostituzione.',
          en: 'We could not send the replacement request.',
          fr: 'Nous n\'avons pas pu envoyer la demande de remplacement.',
          es: 'No hemos podido enviar la solicitud de reemplazo.',
        ),
      );
    }
  }

  Future<void> _openAvailabilitySondageDraft(
    ShiftReplacementCandidatesEntity result,
  ) async {
    final prefill = _buildAvailabilitySondagePrefill(result);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    _showAvailabilityDraftLoading();

    try {
      final draft = await _shiftRepository.createAvailabilitySondageDraft(
        result.assignmentId,
        ShiftAvailabilitySondageDraftRequestEntity(
          title: prefill.question,
          description: prefill.description,
          options: prefill.options,
          allowMultipleResponses: prefill.allowMultipleResponses,
          expiryDate: prefill.expiryDate,
        ),
      );
      if (!mounted) {
        return;
      }
      await _openAvailabilitySondageEditor(draft);
      return;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'createAvailabilitySondageDraft fallback triggered: $error\n$stackTrace',
        );
      }
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        AppSnackBar.showWarning(
          context,
          _localizedShiftDayText(
            context,
            it: 'Creazione automatica non riuscita. Apro il form precompilato.',
            en: 'Automatic draft creation failed. Opening the prefilled form.',
            fr: 'La creation automatique a echoue. Ouverture du formulaire pre-rempli.',
            es: 'La creacion automatica ha fallado. Se abre el formulario precargado.',
          ),
        );
      }
    } finally {
      if (rootNavigator.mounted && rootNavigator.canPop()) {
        rootNavigator.pop();
      }
    }

    if (!mounted) {
      return;
    }
    await _openAvailabilitySondagePrefillForm(prefill);
  }

  void _showAvailabilityDraftLoading() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _localizedShiftDayText(
                      dialogContext,
                      it: 'Sto preparando il draft del sondaggio...',
                      en: 'Preparing the survey draft...',
                      fr: 'Preparation du brouillon du sondage...',
                      es: 'Preparando el borrador de la encuesta...',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAvailabilitySondageEditor(SondageEntity draft) async {
    final title = _localizedShiftDayText(
      context,
      it: 'Modifica disponibilita',
      en: 'Edit availability survey',
      fr: 'Modifier le sondage de disponibilite',
      es: 'Editar encuesta de disponibilidad',
    );

    if (MediaQuery.of(context).size.width >= 720) {
      await CustomDialog(
        title: title,
        width: 760,
        child: CreateSondageWeb(initialSondage: draft),
      ).show(context);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: FractionallySizedBox(
            heightFactor: 0.92,
            child: CreateSondageMobile(initialSondage: draft),
          ),
        );
      },
    );
  }

  Future<void> _openAvailabilitySondagePrefillForm(
    SondageCreatePrefill prefill,
  ) async {
    final title = _localizedShiftDayText(
      context,
      it: 'Apri disponibilita',
      en: 'Open availability survey',
      fr: 'Ouvrir le sondage de disponibilite',
      es: 'Abrir encuesta de disponibilidad',
    );

    if (MediaQuery.of(context).size.width >= 720) {
      await CustomDialog(
        title: title,
        width: 760,
        child: CreateSondageWeb(initialPrefill: prefill),
      ).show(context);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: FractionallySizedBox(
            heightFactor: 0.92,
            child: CreateSondageMobile(initialPrefill: prefill),
          ),
        );
      },
    );
  }

  SondageCreatePrefill _buildAvailabilitySondagePrefill(
    ShiftReplacementCandidatesEntity result,
  ) {
    final shiftDateLabel = _formatDateLabel(result.shiftDate);
    final startTimeLabel = _formatTimeLabel(result.startTime);
    final endTimeLabel = _formatTimeLabel(result.endTime);
    final teamName = result.teamName?.trim();
    final sourceLabel = result.sourceUserDisplayName?.trim();
    final question = _localizedShiftDayText(
      context,
      it: 'Chi e disponibile per coprire il turno del $shiftDateLabel dalle $startTimeLabel alle $endTimeLabel?',
      en: 'Who is available to cover the shift on $shiftDateLabel from $startTimeLabel to $endTimeLabel?',
      fr: 'Qui est disponible pour couvrir le quart du $shiftDateLabel de $startTimeLabel a $endTimeLabel ?',
      es: 'Quien esta disponible para cubrir el turno del $shiftDateLabel de $startTimeLabel a $endTimeLabel?',
    );

    final descriptionParts = <String>[
      _localizedShiftDayText(
        context,
        it: 'Turno scoperto da coprire il $shiftDateLabel nella fascia $startTimeLabel - $endTimeLabel${result.overnight ? ' (+1 giorno)' : ''}.',
        en: 'Open shift to cover on $shiftDateLabel in the $startTimeLabel - $endTimeLabel window${result.overnight ? ' (+1 day)' : ''}.',
        fr: 'Quart ouvert a couvrir le $shiftDateLabel sur la plage $startTimeLabel - $endTimeLabel${result.overnight ? ' (+1 jour)' : ''}.',
        es: 'Turno abierto para cubrir el $shiftDateLabel en la franja $startTimeLabel - $endTimeLabel${result.overnight ? ' (+1 dia)' : ''}.',
      ),
      if (teamName != null && teamName.isNotEmpty)
        _localizedShiftDayText(
          context,
          it: 'Team: $teamName.',
          en: 'Team: $teamName.',
          fr: 'Equipe : $teamName.',
          es: 'Equipo: $teamName.',
        ),
      if (sourceLabel != null && sourceLabel.isNotEmpty)
        _localizedShiftDayText(
          context,
          it: 'Richiesta collegata al turno di $sourceLabel.',
          en: 'Request linked to $sourceLabel\'s shift.',
          fr: 'Demande liee au quart de $sourceLabel.',
          es: 'Solicitud vinculada al turno de $sourceLabel.',
        ),
    ];

    DateTime? expiryDate;
    final now = DateTime.now();
    final candidateExpiry = DateTime(
      result.shiftDate.year,
      result.shiftDate.month,
      result.shiftDate.day,
      result.startTime.hour,
      result.startTime.minute,
    );
    if (candidateExpiry.isAfter(now)) {
      expiryDate = candidateExpiry;
    }

    return SondageCreatePrefill(
      question: question,
      description: descriptionParts.join(' '),
      teamId: result.teamId,
      options: <String>[
        _localizedShiftDayText(
          context,
          it: 'Disponibile',
          en: 'Available',
          fr: 'Disponible',
          es: 'Disponible',
        ),
        _localizedShiftDayText(
          context,
          it: 'Non disponibile',
          en: 'Not available',
          fr: 'Indisponible',
          es: 'No disponible',
        ),
      ],
      expiryDate: expiryDate,
    );
  }

  String _formatTimeLabel(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final dateLabel =
        '${widget.date.day}/${widget.date.month}/${widget.date.year}';
    final appPrimary = colorScheme.primaryColor ?? colorScheme.primary;
    final appError = colorScheme.errorColor;
    final dialogBackground =
        colorScheme.dialogBackgroundColor ?? colorScheme.surface;
    final borderColor = colorScheme.borderColor ?? colorScheme.outlineVariant;
    final mutedSurface =
        colorScheme.bgDialogSecondary?.withValues(alpha: 0.75) ??
        colorScheme.surface;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        left: widget.useDialogLayout ? 0 : 12,
        right: widget.useDialogLayout ? 0 : 12,
        top: widget.useDialogLayout ? 0 : 12,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            (widget.useDialogLayout ? 0 : 12),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SubmitOnEnterScope(
          onSubmit: _readOnly
              ? null
              : (_requestMode
                    ? (_hasValidTimeRange ? _submitShiftChangeRequest : null)
                    : (_hasValidTeamSelection && _hasValidTimeRange
                          ? _submitShiftDay
                          : null)),
          child: Container(
            decoration: BoxDecoration(
              color: dialogBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor.withValues(alpha: 0.7)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!widget.useDialogLayout) ...[
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: borderColor.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                  // ── Title bar ─────────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _requestMode
                              ? '${_requestShiftChangeTitle(context)} - $dateLabel'
                              : (_viewOnlyRequestMode
                                    ? '${_shiftLabel(context)} - $dateLabel'
                                    : (widget.existing != null
                                          ? '${loc.editAction} - $dateLabel'
                                          : '${loc.addShift} - $dateLabel')),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (widget.existing != null &&
                          !_readOnly &&
                          !_requestMode &&
                          !_approvedSelfEditMode)
                        IconButton(
                          icon: Icon(
                            Icons.archive_outlined,
                            color: colorScheme.descriptionColor,
                          ),
                          tooltip: _archiveTooltipText(context),
                          onPressed: () => Navigator.of(context).pop(
                            ShiftDayDialogResult(
                              startTime: _startTime,
                              endTime: _endTime,
                              overnight: _overnight,
                              alarmOffsets: _alarmOffsets,
                              archived: true,
                            ),
                          ),
                        ),
                      if (widget.existing != null &&
                          !_readOnly &&
                          !_requestMode &&
                          !_approvedSelfEditMode)
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: appError),
                          tooltip: loc.removeAction,
                          onPressed: () => Navigator.of(context).pop(
                            ShiftDayDialogResult(
                              startTime: _startTime,
                              endTime: _endTime,
                              overnight: _overnight,
                              alarmOffsets: _alarmOffsets,
                              deleted: true,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        tooltip: loc.close,
                        onPressed: () => Navigator.of(context).pop(null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Read-only banner (public shift, non-owner) ────────────────
                  if (_readOnly || _requestMode || _approvedSelfEditMode)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: appPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: appPrimary.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.public, size: 16, color: appPrimary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _requestMode
                                  ? _requestShiftChangeBanner(context)
                                  : (_hasPendingRequest
                                        ? _pendingShiftChangeBanner(context)
                                        : (_approvedSelfEditMode
                                              ? _approvedShiftEditBanner(
                                                  context,
                                                )
                                              : (_existingHasTeamScope
                                                    ? _publicShiftReadOnlyBanner(
                                                        context,
                                                      )
                                                    : _publicPersonalShiftReadOnlyBanner(
                                                        context,
                                                      )))),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: appPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_viewOnlyRequestMode) ...[
                    _ShiftViewSection(
                      theme: theme,
                      borderColor: borderColor,
                      mutedSurface: mutedSurface,
                      dateLabel: dateLabel,
                      profileName: _resolvedProfileName(loc),
                      userName: widget.existing?.userName,
                      teamName: _resolvedTeamName(context),
                      startTime: _startTime,
                      endTime: _endTime,
                      overnight: _overnight,
                      note: _noteCtrl.text.trim(),
                      isPublic: _effectiveIsPublic,
                      hasTeamScope:
                          _isTeamScopedSelection || _existingHasTeamScope,
                      alarmOffsets: _alarmOffsets,
                      isChatMessageSource:
                          widget
                              .existing
                              ?.workflowContext
                              .normalizedSourceType ==
                          'chat_message',
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    // ── Profile selector ──────────────────────────────────────────
                    if (!_requestMode) ...[
                      Text(
                        loc.shiftProfile,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.descriptionColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.profiles.map((p) {
                          final selected = _selectedProfile?.id == p.id;
                          return GestureDetector(
                            onTap: _readOnly ? null : () => _applyProfile(p),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? p.displayColor.withValues(alpha: 0.2)
                                    : mutedSurface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected
                                      ? p.displayColor
                                      : borderColor,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: p.displayColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    p.name,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Time pickers ──────────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _TimePicker(
                            label: loc.shiftStart,
                            value: _startTime,
                            readOnly: _readOnly || _timeLocked,
                            onChanged: (t) => setState(() {
                              _startTime = t;
                              if (_requestMode) {
                                _overnight = _deriveOvernightFromTimes(
                                  _startTime,
                                  _endTime,
                                );
                              }
                            }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimePicker(
                            label: loc.shiftEnd,
                            value: _endTime,
                            readOnly: _readOnly || _timeLocked,
                            onChanged: (t) => setState(() {
                              _endTime = t;
                              if (_requestMode) {
                                _overnight = _deriveOvernightFromTimes(
                                  _startTime,
                                  _endTime,
                                );
                              }
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!widget.useDialogLayout && widget.existing == null)
                      const SizedBox(height: 12),
                    if (widget.existing == null)
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _readOnly ? null : () => _pickRangeEndDate(loc),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: loc.shiftRepeatUntil,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            isDense: true,
                            suffixIcon: const Icon(
                              Icons.calendar_today_outlined,
                            ),
                            helperText: loc.shiftRepeatUntilHelp,
                          ),
                          child: Text(_formatDateLabel(_rangeEndDate)),
                        ),
                      ),
                    const SizedBox(height: 8),

                    // ── Overnight toggle ──────────────────────────────────────────
                    if (!_requestMode)
                      AppSwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          loc.overnightShift,
                          style: theme.textTheme.bodySmall,
                        ),
                        value: _overnight,
                        onChanged: (_readOnly || _timeLocked)
                            ? null
                            : (v) => setState(() => _overnight = v),
                      ),
                    if (!_hasValidTimeRange)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          loc.shiftEndMustBeAfterStart,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: appError,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    // ── Alarm offsets ─────────────────────────────────────────────
                    if (!_requestMode) ...[
                      Text(
                        loc.alarms,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.descriptionColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _AlarmOffsetEditor(
                        offsets: _alarmOffsets,
                        readOnly: _readOnly,
                        onChanged: (offsets) =>
                            setState(() => _alarmOffsets = offsets),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // ── Alarm type toggle ─────────────────────────────────────────
                    if (!_readOnly && !_requestMode)
                      SegmentedButton<ShiftAlarmType>(
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          textStyle: theme.textTheme.labelSmall,
                        ),
                        selected: {_alarmType},
                        onSelectionChanged: (newSet) {
                          final selected = newSet.first;
                          setState(() => _alarmType = selected);
                          unawaited(
                            _localNotifications.setShiftAlarmType(selected),
                          );
                          if (selected == ShiftAlarmType.alarm) {
                            unawaited(_requestAlarmPermissionsIfNeeded());
                          }
                        },
                        segments: [
                          ButtonSegment(
                            value: ShiftAlarmType.notification,
                            label: Text(_notificationModeLabel(context)),
                            icon: const Icon(
                              Icons.notifications_outlined,
                              size: 16,
                            ),
                          ),
                          ButtonSegment(
                            value: ShiftAlarmType.alarm,
                            label: Text(_alarmModeLabel(context)),
                            icon: const Icon(Icons.alarm, size: 16),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),

                    // ── Note ──────────────────────────────────────────────────────
                    TextField(
                      controller: _noteCtrl,
                      readOnly: _readOnly,
                      decoration: InputDecoration(
                        labelText: loc.note,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        isDense: true,
                      ),
                      maxLines: 2,
                    ),
                    if (_isChatMessageWorkflowSource) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: appPrimary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: appPrimary.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 18,
                              color: appPrimary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _sourceMessageTitle(context),
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: appPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _sourceMessageDescription(context),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.descriptionColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.onOpenLinkedConversation != null) ...[
                        const SizedBox(height: 10),
                        CustomAppButton(
                          onPressed: widget.onOpenLinkedConversation,
                          type: ButtonType.outlined,
                          borderRadius: 10,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          isActive: true,
                          fullWidth: true,
                          leadingIcon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 18,
                          ),
                          child: Text(
                            _openLinkedConversationButtonLabel(context),
                          ),
                        ),
                      ],
                    ],
                    // ── Team assignment (managers: create + edit of public shifts) ──
                    if (!_requestMode &&
                        _hasOwnerTeams &&
                        (widget.existing == null ||
                            (widget.canManagePublicShifts &&
                                widget.existing!.isPublic))) ...[
                      const SizedBox(height: 12),
                      _TeamAssignmentSection(
                        ownerTeams: widget.ownerTeams,
                        selectedTeam: _selectedTeam,
                        selectedMemberIds: _selectedMemberIds,
                        assignToAllMembers: _assignToAllMembers,
                        suggestedUserIds: widget.suggestedUserIds.toSet(),
                        teamMembers: _teamMembers,
                        isLoadingMembers: _isSelectedTeamLoading,
                        onTeamChanged: (team) {
                          setState(() {
                            _selectedTeam = team;
                            _assignToAllMembers = true;
                            _useMemberSpecificProfiles = false;
                            _selectedMemberIds.clear();
                            if (team == null && widget.existing == null) {
                              _isPublic = false;
                            }
                          });
                          unawaited(_ensureTeamMembersLoaded(team));
                        },
                        onAssignToAllChanged: (value) => setState(() {
                          _assignToAllMembers = value;
                          if (value) {
                            _useMemberSpecificProfiles = false;
                          }
                          if (value) {
                            _selectedMemberIds.clear();
                          }
                        }),
                        onMemberToggled: (uid, selected) => setState(() {
                          _assignToAllMembers = false;
                          if (selected) {
                            _selectedMemberIds.add(uid);
                          } else {
                            _selectedMemberIds.remove(uid);
                            _memberProfileIds.remove(uid);
                          }
                          if (_selectedMemberIds.length < 2) {
                            _useMemberSpecificProfiles = false;
                          }
                        }),
                      ),
                    ],
                    if (!_requestMode &&
                        !_readOnly &&
                        widget.existing == null &&
                        _selectedTeam != null &&
                        !_assignToAllMembers &&
                        _selectedMemberIds.length > 1) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: mutedSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppSwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _useMemberSpecificProfiles,
                              onChanged: (value) => setState(() {
                                _useMemberSpecificProfiles = value;
                              }),
                              //title: const Text(''),
                              title: Text(_useDifferentProfilesLabel(context)),
                              subtitle: Text(
                                _useDifferentProfilesSubtitle(context),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.descriptionColor,
                                ),
                              ),
                            ),
                            if (_useMemberSpecificProfiles) ...[
                              const SizedBox(height: 8),
                              Text(
                                _commonShiftMemberHint(context),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.descriptionColor,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ..._selectedSpecificMembers.map((member) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _MemberSpecificProfileTile(
                                    label: member.displayLabel(context),
                                    subtitle: member.secondaryLabel(context),
                                    profiles: widget.profiles,
                                    selectedProfileId:
                                        _memberProfileIds[member.userId!],
                                    onProfileChanged: (profileId) =>
                                        setState(() {
                                          _memberProfileIds[member.userId!] =
                                              profileId;
                                        }),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // ── Visibility toggle (owners only) ───────────────────────────
                    if ((widget.canManagePublicShifts || _effectiveIsPublic) &&
                        !_requestMode &&
                        !_approvedSelfEditMode)
                      Container(
                        decoration: BoxDecoration(
                          color: _effectiveIsPublic
                              ? appPrimary.withValues(alpha: 0.08)
                              : mutedSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _effectiveIsPublic
                                ? appPrimary.withValues(alpha: 0.35)
                                : borderColor,
                          ),
                        ),
                        child: AppSwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                          value: _effectiveIsPublic,
                          onChanged:
                              widget.canManagePublicShifts &&
                                  !_isTeamScopedSelection
                              ? (v) => setState(() => _isPublic = v)
                              : null,
                          secondary: Icon(
                            _effectiveIsPublic
                                ? Icons.public
                                : Icons.lock_outline,
                            size: 18,
                            color: _effectiveIsPublic
                                ? appPrimary
                                : colorScheme.outline,
                          ),
                          title: Text(
                            _effectiveIsPublic
                                ? (_isTeamScopedSelection
                                      ? _publicVisibleToTeamTitle(context)
                                      : _publicVisiblePersonalTitle(context))
                                : _privateVisibleOnlyToYouTitle(context),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _effectiveIsPublic ? appPrimary : null,
                            ),
                          ),
                          subtitle: Text(
                            _isTeamScopedSelection
                                ? _teamSelectedCreatesPublicShiftText(context)
                                : _effectiveIsPublic
                                ? _sharedCalendarSeeShiftText(context)
                                : _onlyYouCanSeeShiftText(context),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.descriptionColor,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],

                  // ── Confirm / Close button ────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_requestMode &&
                            _canSearchReplacementCandidates) ...[
                          if (widget.suggestedUserIds.isNotEmpty &&
                              (_loadingWorkflowAutoReplaceCandidates ||
                                  _canAutoReplaceFromWorkflow)) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF22C55E,
                                ).withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF22C55E,
                                  ).withValues(alpha: 0.24),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _workflowAutoReplaceTitle(context),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.iconLabel,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _workflowAutoReplaceMessage(context),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.descriptionColor,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  CustomAppButton(
                                    onPressed: _canAutoReplaceFromWorkflow
                                        ? _autoReplaceFromWorkflow
                                        : null,
                                    type: ButtonType.filled,
                                    backgroundColor: const Color(0xFF16A34A),
                                    borderRadius: 10,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    isActive: _canAutoReplaceFromWorkflow,
                                    isLoading:
                                        _loadingWorkflowAutoReplaceCandidates,
                                    fullWidth: true,
                                    leadingIcon: const Icon(
                                      Icons.auto_fix_high_rounded,
                                      size: 18,
                                    ),
                                    child: Text(
                                      _workflowAutoReplaceButtonLabel(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          CustomAppButton(
                            onPressed: _openReplacementCandidates,
                            type: ButtonType.outlined,
                            borderRadius: 10,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            isActive: true,
                            isLoading: _loadingReplacementCandidates,
                            fullWidth: true,
                            leadingIcon: const Icon(
                              Icons.person_search_outlined,
                              size: 18,
                            ),
                            child: Text(_findReplacementButton(context)),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (_readOnly)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_canOpenRequestMode ||
                                  _canOpenSwapRequest ||
                                  _hasPendingRequest) ...[
                                Row(
                                  children: [
                                    if (_canOpenRequestMode ||
                                        _hasPendingRequest)
                                      Expanded(
                                        child: CustomAppButton(
                                          onPressed: _hasPendingRequest
                                              ? null
                                              : _enterRequestMode,
                                          type: ButtonType.filled,
                                          backgroundColor: appPrimary,
                                          borderRadius: 10,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          isActive: !_hasPendingRequest,
                                          fullWidth: true,
                                          child: Text(
                                            _hasPendingRequest
                                                ? _pendingShiftChangeButton(
                                                    context,
                                                  )
                                                : _requestShiftChangeButton(
                                                    context,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    if ((_canOpenRequestMode ||
                                            _hasPendingRequest) &&
                                        _canOpenSwapRequest)
                                      const SizedBox(width: 10),
                                    if (_canOpenSwapRequest)
                                      Expanded(
                                        child: CustomAppButton(
                                          onPressed: _hasPendingRequest
                                              ? null
                                              : _startShiftSwapRequest,
                                          type: ButtonType.outlined,
                                          borderRadius: 10,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          isActive: !_hasPendingRequest,
                                          fullWidth: true,
                                          child: Text(
                                            _requestShiftSwapButton(context),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (_hasPendingRequest) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _pendingShiftChangeBanner(context),
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.descriptionColor,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                              ],
                              CustomAppButton(
                                onPressed: () => Navigator.of(context).pop(),
                                type: ButtonType.outlined,
                                borderRadius: 10,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                isActive: true,
                                fullWidth: true,
                                child: Text(loc.close),
                              ),
                            ],
                          )
                        else
                          CustomAppButton(
                            onPressed:
                                (_requestMode
                                    ? !_hasValidTimeRange
                                    : (!_hasValidTeamSelection ||
                                          !_hasValidTimeRange))
                                ? null
                                : (_requestMode
                                      ? _submitShiftChangeRequest
                                      : _submitShiftDay),
                            type: ButtonType.filled,
                            backgroundColor: appPrimary,
                            borderRadius: 10,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            isActive: true,
                            fullWidth: true,
                            child: Text(
                              _requestMode
                                  ? _requestShiftChangeButton(context)
                                  : loc.save,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Section inside the shift dialog that lets an owner choose which team
/// (and which members) should receive the shift.
class _TeamAssignmentSection extends StatefulWidget {
  const _TeamAssignmentSection({
    required this.ownerTeams,
    required this.selectedTeam,
    required this.selectedMemberIds,
    required this.assignToAllMembers,
    required this.suggestedUserIds,
    required this.teamMembers,
    required this.isLoadingMembers,
    required this.onTeamChanged,
    required this.onAssignToAllChanged,
    required this.onMemberToggled,
  });

  final List<TeamEntityForView> ownerTeams;
  final TeamEntityForView? selectedTeam;
  final Set<String> selectedMemberIds;
  final bool assignToAllMembers;
  final Set<String> suggestedUserIds;
  final List<ShiftTeamMember> teamMembers;
  final bool isLoadingMembers;
  final ValueChanged<TeamEntityForView?> onTeamChanged;
  final ValueChanged<bool> onAssignToAllChanged;
  final void Function(String uid, bool selected) onMemberToggled;

  @override
  State<_TeamAssignmentSection> createState() => _TeamAssignmentSectionState();
}

class _ShiftViewSection extends StatelessWidget {
  const _ShiftViewSection({
    required this.theme,
    required this.borderColor,
    required this.mutedSurface,
    required this.dateLabel,
    required this.profileName,
    required this.userName,
    required this.teamName,
    required this.startTime,
    required this.endTime,
    required this.overnight,
    required this.note,
    required this.isPublic,
    required this.hasTeamScope,
    required this.alarmOffsets,
    required this.isChatMessageSource,
  });

  final ThemeData theme;
  final Color borderColor;
  final Color mutedSurface;
  final String dateLabel;
  final String profileName;
  final String? userName;
  final String? teamName;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool overnight;
  final String note;
  final bool isPublic;
  final bool hasTeamScope;
  final List<int> alarmOffsets;
  final bool isChatMessageSource;

  bool _hasMeaningfulValue(String? value) {
    if (value == null) {
      return false;
    }
    final trimmed = value.trim();
    return trimmed.isNotEmpty && trimmed != '-';
  }

  String _formatTime(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String? _formatAlarmOffsets() {
    if (alarmOffsets.isEmpty) {
      return null;
    }
    return alarmOffsets.map((value) => '$value min').join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final alarmsText = _formatAlarmOffsets();
    final rows = <({String label, String value})>[
      (label: _dateRowLabel(context), value: dateLabel),
      if (_hasMeaningfulValue(userName))
        (label: _memberRowLabel(context), value: userName!.trim()),
      if (_hasMeaningfulValue(teamName))
        (label: localization.team, value: teamName!.trim()),
      if (_hasMeaningfulValue(profileName))
        (label: localization.shiftProfile, value: profileName.trim()),
      (label: localization.shiftStart, value: _formatTime(startTime)),
      (label: localization.shiftEnd, value: _formatTime(endTime)),
      (
        label: localization.overnightShift,
        value: overnight ? _yesLabel(context) : _noLabel(context),
      ),
      (
        label: _visibilityRowLabel(context),
        value: !isPublic
            ? _privateShiftSummaryLabel(context)
            : (hasTeamScope
                  ? _publicTeamShiftSummaryLabel(context)
                  : _publicPersonalShiftSummaryLabel(context)),
      ),
      if (isChatMessageSource)
        (
          label: _sourceRowLabel(context),
          value: _chatMessageSourceValue(context),
        ),
      if (_hasMeaningfulValue(note))
        (label: localization.note, value: note.trim()),
      if (alarmsText != null) (label: localization.alarms, value: alarmsText),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: mutedSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _shiftDetailsTitle(context),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 112,
                    child: Text(
                      row.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(row.value, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamAssignmentSectionState extends State<_TeamAssignmentSection> {
  static const double _kDropdownListMaxHeight = 248;
  final TextEditingController _teamSearchController = TextEditingController();
  final ScrollController _teamScrollController = ScrollController();

  List<TeamEntityForView> get _filteredTeams {
    final query = _teamSearchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.ownerTeams;
    }
    return widget.ownerTeams.where((team) {
      final name = team.team.name.toLowerCase();
      final description = team.team.description.toLowerCase();
      return name.contains(query) || description.contains(query);
    }).toList();
  }

  bool get _showPrivateOptionInSearch {
    final query = _teamSearchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }
    return _privateShiftLabel(context).toLowerCase().contains(query);
  }

  String get _teamSelectionTitle =>
      widget.selectedTeam?.team.name ?? _privateShiftLabel(context);

  String get _teamSelectionSubtitle => widget.selectedTeam == null
      ? _privateShiftDescription(context)
      : _openChangeOrSearchTeamText(context);

  List<ShiftTeamMember> get _prioritizedTeamMembers {
    final members = widget.teamMembers
        .where(
          (member) =>
              member.isSelectable ||
              (member.userId != null &&
                  widget.selectedMemberIds.contains(member.userId)),
        )
        .toList(growable: false);
    members.sort((left, right) {
      final leftSuggested =
          left.userId != null && widget.suggestedUserIds.contains(left.userId);
      final rightSuggested =
          right.userId != null &&
          widget.suggestedUserIds.contains(right.userId);
      if (leftSuggested != rightSuggested) {
        return leftSuggested ? -1 : 1;
      }
      if (left.isSelectable != right.isSelectable) {
        return left.isSelectable ? -1 : 1;
      }
      return left
          .displayLabel(context)
          .toLowerCase()
          .compareTo(right.displayLabel(context).toLowerCase());
    });
    return members;
  }

  List<ShiftTeamMember> get _suggestedMembers => _prioritizedTeamMembers
      .where(
        (member) =>
            member.userId != null &&
            member.isSelectable &&
            widget.suggestedUserIds.contains(member.userId),
      )
      .toList(growable: false);

  @override
  void dispose() {
    _teamSearchController.dispose();
    _teamScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _TeamAssignmentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSelectedId = oldWidget.selectedTeam?.team.id;
    final newSelectedId = widget.selectedTeam?.team.id;
    if (oldSelectedId != newSelectedId) {
      _teamSearchController.clear();
    }
  }

  void _selectTeam(TeamEntityForView? team, VoidCallback close) {
    widget.onTeamChanged(team);
    setState(() => _teamSearchController.clear());
    close();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final prioritizedMembers = _prioritizedTeamMembers;
    final suggestedMembers = _suggestedMembers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _assignToTeamLabel(context),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.descriptionColor,
          ),
        ),
        const SizedBox(height: 6),
        AnchoredDropdownOverlay(
          triggerBuilder: (context, isOpen, toggle) => _DropdownTriggerCard(
            title: _teamSelectionTitle,
            subtitle: _teamSelectionSubtitle,
            isOpen: isOpen,
            onTap: toggle,
          ),
          overlayBuilder: (context, width, maxHeight, close) => ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: _InlineDropdownPanel(
              width: width,
              searchController: _teamSearchController,
              searchHintText: AppLocalizations.of(context)!.searchTeam,
              onSearchChanged: (_) => setState(() {}),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: _kDropdownListMaxHeight,
                ),
                child: Scrollbar(
                  controller: _teamScrollController,
                  thumbVisibility: _filteredTeams.length > 4,
                  child: ListView.separated(
                    controller: _teamScrollController,
                    shrinkWrap: true,
                    itemCount:
                        _filteredTeams.length +
                        (_showPrivateOptionInSearch ? 1 : 0) +
                        (_filteredTeams.isEmpty ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      if (_showPrivateOptionInSearch && index == 0) {
                        return _ProfileOptionTile(
                          label: _privateShiftLabel(context),
                          subtitle: _doNotAssignTeamText(context),
                          isSelected: widget.selectedTeam == null,
                          onTap: () => _selectTeam(null, close),
                        );
                      }
                      final teamIndex =
                          index - (_showPrivateOptionInSearch ? 1 : 0);
                      if (_filteredTeams.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                            color: colorScheme.surface,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 18,
                                color: colorScheme.descriptionColor,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)!.noTeamFound,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.descriptionColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final team = _filteredTeams[teamIndex];
                      final isSelected =
                          widget.selectedTeam?.team.id == team.team.id;
                      return _ProfileOptionTile(
                        label: team.team.name,
                        subtitle: team.team.description.trim().isNotEmpty
                            ? team.team.description
                            : _teamAvailableForPublicAssignmentText(context),
                        isSelected: isSelected,
                        onTap: () => _selectTeam(team, close),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        // ── Member selector (visible only when a team is selected) ──────
        if (widget.selectedTeam != null) ...[
          const SizedBox(height: 8),
          Text(
            _assignToLabel(context),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.descriptionColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _assignToDescription(context),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.descriptionColor,
            ),
          ),
          if (suggestedMembers.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.28),
                ),
              ),
              child: Text(
                _suggestedMembersHint(context, suggestedMembers.length),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.iconLabel,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          _MemberRadioTile(
            uid: null,
            label: _assignToAllMembersLabel(context),
            subtitle: _assignToAllMembersSubtitle(context),
            icon: Icons.groups_rounded,
            isSelected: widget.assignToAllMembers,
            enabled: widget.teamMembers.any((member) => member.isSelectable),
            onTap: !widget.teamMembers.any((member) => member.isSelectable)
                ? null
                : () => widget.onAssignToAllChanged(true),
          ),
          const SizedBox(height: 4),
          if (widget.teamMembers.isEmpty ||
              !widget.teamMembers.any((member) => member.isSelectable))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.bgDialogSecondary?.withValues(
                  alpha: 0.45,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      theme.colorScheme.borderColor ??
                      theme.colorScheme.outline,
                ),
              ),
              child: Row(
                children: [
                  if (widget.isLoadingMembers)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primaryColor,
                      ),
                    )
                  else
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.descriptionColor,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.isLoadingMembers
                          ? _loadingTeamMembersText(context)
                          : widget.teamMembers.isEmpty
                          ? _noMembersForTeamText(context)
                          : _noAvailableMembersForDateText(context),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            )
          else
            ...prioritizedMembers.map(
              (member) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _MemberRadioTile(
                  uid: member.userId,
                  label: member.displayLabel(context),
                  subtitle: member.secondaryLabel(context),
                  badgeLabel:
                      member.userId != null &&
                          widget.suggestedUserIds.contains(member.userId)
                      ? _surveyAvailableBadge(context)
                      : null,
                  icon: Icons.person_outline_rounded,
                  enabled: member.isSelectable,
                  disabledHint: member.disabledHint(context),
                  isSelected:
                      member.userId != null &&
                      widget.selectedMemberIds.contains(member.userId),
                  onTap: member.userId == null || !member.isSelectable
                      ? null
                      : () => widget.onMemberToggled(
                          member.userId!,
                          !widget.selectedMemberIds.contains(member.userId),
                        ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  String _surveyAvailableBadge(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'it' => 'Disponibile nel sondaggio',
      'fr' => 'Disponible dans le sondage',
      'es' => 'Disponible en la encuesta',
      _ => 'Available in survey',
    };
  }

  String _suggestedMembersHint(BuildContext context, int count) {
    return switch (Localizations.localeOf(context).languageCode) {
      'it' =>
        count == 1
            ? '1 collega ha risposto disponibile nel sondaggio collegato. Parti da qui per assegnare la copertura.'
            : '$count colleghi hanno risposto disponibile nel sondaggio collegato. Parti da qui per assegnare la copertura.',
      'fr' =>
        '$count collegue(s) ont repondu disponibles dans le sondage lie. Commencez ici pour attribuer la couverture.',
      'es' =>
        '$count companero(s) respondieron disponibles en la encuesta vinculada. Empieza aqui para asignar la cobertura.',
      _ =>
        '$count teammate(s) replied available in the linked survey. Start here to assign the coverage.',
    };
  }
}

class _MemberRadioTile extends StatelessWidget {
  const _MemberRadioTile({
    required this.uid,
    required this.label,
    this.subtitle,
    this.badgeLabel,
    this.disabledHint,
    required this.icon,
    required this.isSelected,
    this.enabled = true,
    this.onTap,
  });

  final String? uid;
  final String label;
  final String? subtitle;
  final String? badgeLabel;
  final String? disabledHint;
  final IconData icon;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appPrimary = colorScheme.primaryColor ?? colorScheme.primary;
    final borderColor = colorScheme.borderColor ?? colorScheme.outlineVariant;
    final mutedSurface =
        colorScheme.bgDialogSecondary?.withValues(alpha: 0.75) ??
        colorScheme.surface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: !enabled
              ? mutedSurface.withValues(alpha: 0.55)
              : isSelected
              ? appPrimary.withValues(alpha: 0.08)
              : mutedSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: !enabled
                ? borderColor.withValues(alpha: 0.6)
                : isSelected
                ? appPrimary.withValues(alpha: 0.45)
                : borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: !enabled
                  ? colorScheme.outline.withValues(alpha: 0.65)
                  : isSelected
                  ? appPrimary
                  : colorScheme.outline,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badgeLabel != null && badgeLabel!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF22C55E,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(
                              0xFF22C55E,
                            ).withValues(alpha: 0.24),
                          ),
                        ),
                        child: Text(
                          badgeLabel!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF166534),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: !enabled
                          ? colorScheme.descriptionColor
                          : isSelected
                          ? appPrimary
                          : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.descriptionColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (!enabled && disabledHint != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        disabledHint!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.descriptionColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, size: 16, color: appPrimary),
          ],
        ),
      ),
    );
  }
}

class _MemberSpecificProfileTile extends StatelessWidget {
  const _MemberSpecificProfileTile({
    required this.label,
    this.subtitle,
    required this.profiles,
    required this.selectedProfileId,
    required this.onProfileChanged,
  });

  final String label;
  final String? subtitle;
  final List<ShiftProfileEntity> profiles;
  final String? selectedProfileId;
  final ValueChanged<String?> onProfileChanged;

  String _profileSummary(BuildContext context) {
    if (selectedProfileId == null) {
      return _commonShiftLabel(context);
    }
    final profile = profiles
        .where((item) => item.id == selectedProfileId)
        .firstOrNull;
    if (profile == null) {
      return _commonShiftLabel(context);
    }
    return profile.name;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = colorScheme.borderColor ?? colorScheme.outlineVariant;
    final profile = profiles
        .where((item) => item.id == selectedProfileId)
        .firstOrNull;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: _MemberProfileDropdownContent(
        label: label,
        subtitle: subtitle,
        profiles: profiles,
        selectedProfileId: selectedProfileId,
        profileSummary: _profileSummary(context),
        profileDetails: profile == null
            ? null
            : _formatShiftProfileSchedule(profile),
        profileAccentColor: profile?.displayColor,
        onProfileChanged: onProfileChanged,
      ),
    );
  }
}

class _MemberProfileDropdownContent extends StatefulWidget {
  const _MemberProfileDropdownContent({
    required this.label,
    this.subtitle,
    required this.profiles,
    required this.selectedProfileId,
    required this.profileSummary,
    this.profileDetails,
    this.profileAccentColor,
    required this.onProfileChanged,
  });

  final String label;
  final String? subtitle;
  final List<ShiftProfileEntity> profiles;
  final String? selectedProfileId;
  final String profileSummary;
  final String? profileDetails;
  final Color? profileAccentColor;
  final ValueChanged<String?> onProfileChanged;

  @override
  State<_MemberProfileDropdownContent> createState() =>
      _MemberProfileDropdownContentState();
}

class _MemberProfileDropdownContentState
    extends State<_MemberProfileDropdownContent> {
  static const double _kDropdownListMaxHeight = 248;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _profileScrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _profileScrollController.dispose();
    super.dispose();
  }

  List<ShiftProfileEntity> get _filteredProfiles {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.profiles;
    }
    return widget.profiles.where((profile) {
      final haystack = '${profile.name} ${_formatShiftProfileSchedule(profile)}'
          .toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileAccentColor = widget.profileAccentColor;
    final triggerTitleColor = profileAccentColor ?? colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (widget.subtitle != null &&
                      widget.subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.descriptionColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: AnchoredDropdownOverlay(
                triggerBuilder: (context, isOpen, toggle) {
                  final accent =
                      colorScheme.primaryColor ?? colorScheme.primary;
                  final triggerBackground = profileAccentColor != null
                      ? profileAccentColor.withValues(alpha: 0.14)
                      : (isOpen
                            ? accent.withValues(alpha: 0.05)
                            : colorScheme.surface);
                  final triggerBorder = profileAccentColor != null
                      ? profileAccentColor.withValues(alpha: 0.45)
                      : (isOpen
                            ? accent.withValues(alpha: 0.45)
                            : colorScheme.outlineVariant);
                  return InkWell(
                    onTap: toggle,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: triggerBorder),
                        color: triggerBackground,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.profileSummary,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: triggerTitleColor,
                                  ),
                                ),
                                if (widget.profileDetails != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.profileDetails!,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: profileAccentColor != null
                                          ? triggerTitleColor.withValues(
                                              alpha: 0.85,
                                            )
                                          : colorScheme.descriptionColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isOpen
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: colorScheme.descriptionColor,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                overlayBuilder: (context, width, maxHeight, close) =>
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxHeight),
                      child: _InlineDropdownPanel(
                        width: width,
                        searchController: _searchController,
                        searchHintText: _searchShiftHintText(context),
                        onSearchChanged: (_) => setState(() {}),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: _kDropdownListMaxHeight,
                          ),
                          child: Scrollbar(
                            controller: _profileScrollController,
                            thumbVisibility: _filteredProfiles.length > 4,
                            child: ListView.separated(
                              controller: _profileScrollController,
                              shrinkWrap: true,
                              itemCount: _filteredProfiles.length + 1,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  final isSelected =
                                      widget.selectedProfileId == null;
                                  return _ProfileOptionTile(
                                    label: _commonShiftLabel(context),
                                    subtitle: _commonShiftSubtitle(context),
                                    isSelected: isSelected,
                                    onTap: () {
                                      widget.onProfileChanged(null);
                                      close();
                                    },
                                  );
                                }
                                final profile = _filteredProfiles[index - 1];
                                final isSelected =
                                    widget.selectedProfileId == profile.id;
                                return _ProfileOptionTile(
                                  label: profile.name,
                                  subtitle: _formatShiftProfileSchedule(
                                    profile,
                                  ),
                                  isSelected: isSelected,
                                  accentColor: profile.displayColor,
                                  onTap: () {
                                    widget.onProfileChanged(profile.id);
                                    close();
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DropdownTriggerCard extends StatelessWidget {
  const _DropdownTriggerCard({
    required this.title,
    required this.subtitle,
    required this.isOpen,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isOpen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = colorScheme.primaryColor ?? colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isOpen
                ? accent.withValues(alpha: 0.45)
                : colorScheme.outlineVariant,
          ),
          color: isOpen ? accent.withValues(alpha: 0.05) : colorScheme.surface,
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.descriptionColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isOpen
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: colorScheme.descriptionColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineDropdownPanel extends StatelessWidget {
  const _InlineDropdownPanel({
    required this.width,
    required this.searchController,
    required this.searchHintText,
    required this.child,
    this.onSearchChanged,
  });

  final double width;
  final TextEditingController searchController;
  final String searchHintText;
  final Widget child;
  final ValueChanged<String>? onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: searchHintText,
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Flexible(child: child),
        ],
      ),
    );
  }
}

class _ProfileOptionTile extends StatelessWidget {
  const _ProfileOptionTile({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    this.accentColor,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool isSelected;
  final Color? accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary =
        accentColor ?? (colorScheme.primaryColor ?? colorScheme.primary);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? primary.withValues(alpha: 0.45)
                : colorScheme.outlineVariant,
          ),
          color: isSelected
              ? primary.withValues(alpha: 0.08)
              : colorScheme.surface,
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.descriptionColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isSelected) Icon(Icons.check_circle, color: primary, size: 18),
          ],
        ),
      ),
    );
  }
}

String _formatShiftProfileSchedule(ShiftProfileEntity profile) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  final start =
      '${twoDigits(profile.startTime.hour)}:${twoDigits(profile.startTime.minute)}';
  final end =
      '${twoDigits(profile.endTime.hour)}:${twoDigits(profile.endTime.minute)}';
  return profile.overnight ? '$start - $end (+1)' : '$start - $end';
}

// ─────────────────────────────────────────────────────────────────────────────

class _TimePicker extends StatelessWidget {
  const _TimePicker({
    required this.label,
    required this.value,
    required this.onChanged,
    this.readOnly = false,
  });

  final String label;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: readOnly
          ? null
          : () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: value,
              );
              if (picked != null) onChanged(picked);
            },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.bgDialogSecondary?.withValues(alpha: 0.45),
          border: Border.all(
            color: theme.colorScheme.borderColor ?? theme.colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text(
                  value.format(context),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AlarmOffsetEditor extends StatelessWidget {
  const _AlarmOffsetEditor({
    required this.offsets,
    required this.onChanged,
    this.readOnly = false,
  });

  final List<int> offsets;
  final ValueChanged<List<int>> onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        ...offsets.map((offset) {
          final label = offset < 0 ? '$offset min' : '+$offset min';
          return Chip(
            label: Text(
              label,
              style: textTheme.bodySmall!.copyWith(
                color: colorScheme.textColor,
              ),
            ),
            deleteIcon: readOnly
                ? null
                : Icon(Icons.close, size: 14, color: colorScheme.textColor),
            elevation: 4,
            backgroundColor: colorScheme.bgColorNew,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: colorScheme.textColor!),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),

            // Forma a stadio
            //side: BorderSide.none,
            onDeleted: readOnly
                ? null
                : () {
                    final updated = List<int>.from(offsets)..remove(offset);
                    onChanged(updated);
                  },
          );
        }),
        if (!readOnly)
          ActionChip(
            avatar: Icon(Icons.add, size: 14, color: colorScheme.textColor),
            label: Text(
              _addLabel(context),
              style: textTheme.bodySmall!.copyWith(
                color: colorScheme.textColor,
              ),
            ),
            onPressed: () => _addOffset(context),
            elevation: 4,
            backgroundColor: colorScheme.bgColorNew,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: colorScheme.textColor!, width: 1),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            // Forma a stadio
            //side: BorderSide.none,
          ),
      ],
    );
  }

  void _addOffset(BuildContext context) async {
    final ctrl = TextEditingController(text: '-30');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_addAlarmTitle(context)),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: InputDecoration(
            labelText: _alarmMinutesLabel(context),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          CustomAppButton(
            onPressed: () => Navigator.of(ctx).pop(),
            type: ButtonType.text,
            isActive: false,
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          CustomAppButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              if (v != null) Navigator.of(ctx).pop(v);
            },
            type: ButtonType.filled,
            isActive: true,
            child: Text(_addLabel(context)),
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
