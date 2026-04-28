// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get login => 'Entre';

  @override
  String get logout => 'Deconnexion';

  @override
  String get register => 'S\'inscrire';

  @override
  String get gladYouAreBack => 'Content de vous revoir.!';

  @override
  String get welcomeBack => 'Bon retour.!';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get justSomeInfoToGetStarted => 'Quelques informations pour commencer';

  @override
  String get fullName => 'Nom complet';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get pleaseEnterYourEmail => 'Veuillez saisir votre adresse e-mail';

  @override
  String get resetPassword => 'Réinitialiser le mot de passe';

  @override
  String get donthaveAnAccount => 'Vous n\'avez pas de compte ? Inscrivez-vous';

  @override
  String get signup => 'Inscription';

  @override
  String get home => 'Accueil';

  @override
  String get about => 'À propos';

  @override
  String get team => 'Équipe';

  @override
  String get settings => 'Configuraion';

  @override
  String get attendance => 'Presence';

  @override
  String get clockingInOut => 'Pointage';

  @override
  String get explorer => 'explorateur';

  @override
  String get sondage => 'Sondage';

  @override
  String get selectedTeam => 'Selection equipe';

  @override
  String get createTeam => 'Cree equipe';

  @override
  String get teamMember => 'effectif del l\'equipe';

  @override
  String member(num membersCount) {
    String _temp0 = intl.Intl.pluralLogic(
      membersCount,
      locale: localeName,
      other: '$membersCount membres',
      one: '1 membre',
    );
    return '$_temp0';
  }

  @override
  String get createNewTeam => 'Créer une nouvelle équipe';

  @override
  String get teamName => 'Nom de l\'équipe';

  @override
  String get teamDescription => 'Description de l\'équipe';

  @override
  String get role => 'Role';

  @override
  String get permission => 'Permission';

  @override
  String get status => 'Statut';

  @override
  String get selectedTeamcolor => 'Selectione la couleur de l\'equipe';

  @override
  String get roleManager => 'Gestione des ruoles';

  @override
  String get permissionManager => 'Gestione des permissions';

  @override
  String get grantList => 'Liste des permissions';

  @override
  String get createGrant => 'Cree une permission';

  @override
  String get roleList => 'Liste des ruoles';

  @override
  String get createRole => 'Cree un ruole';

  @override
  String get permissionName => 'Nom de la permission';

  @override
  String get permissionDescription => 'Description de la permission';

  @override
  String get save => 'Enregister';

  @override
  String get editRoleManager => 'Modificier permission';

  @override
  String get roleName => 'Nom du role';

  @override
  String get roleDescription => 'Description du role';

  @override
  String get selectedPermission => 'Selection de la Permission';

  @override
  String get editTeam => 'Modifier equipe';

  @override
  String get language => 'Langue';

  @override
  String get notification => 'Notification';

  @override
  String get contactUs => 'Contactez nous';

  @override
  String get privacy => 'Confidentialité';

  @override
  String get askQuestion => 'Posez une question';

  @override
  String get options => 'Options';

  @override
  String get option => 'Option';

  @override
  String get allowMultipleResponses => 'Autoriser plusieurs réponses';

  @override
  String get makeResponsesAnonymous => 'Rendre les réponses anonymes';

  @override
  String get selectTeam => 'Sélectionner une équipe';

  @override
  String get teamLabel => 'Équipe:';

  @override
  String get surveyCreatedSuccessfully => 'Sondage créé avec succès!';

  @override
  String get create => 'Créer';

  @override
  String get responses => 'réponses';

  @override
  String get questions => 'questions';

  @override
  String get system => 'Système';

  @override
  String get dark => 'Sombre';

  @override
  String get light => 'Clair';

  @override
  String get preferences => 'Préférences';

  @override
  String get manageYourPrivacySettings =>
      'Gérez vos paramètres de confidentialité';

  @override
  String get getInTouchWithOurSupportTeam =>
      'Contactez notre équipe d\'assistance';

  @override
  String get themeTitle => 'Thème';

  @override
  String get languageTitle => 'Langue';

  @override
  String get lightMode => 'Mode Clair';

  @override
  String get darkMode => 'Mode Sombre';

  @override
  String get systemDefault => 'Par Défaut du Système';

  @override
  String get defaultLightTheme => 'Thème clair par défaut';

  @override
  String get darkThemeForLowLight => 'Thème sombre pour faible lumière';

  @override
  String get followSystemSettings => 'Suivre les paramètres système';

  @override
  String get selectYourLanguage => 'Sélectionnez votre langue';

  @override
  String get settingsNotification => 'Paramètres de Notification';

  @override
  String get yourName => 'Votre Nom';

  @override
  String get yourEmail => 'Votre Email';

  @override
  String get message => 'Message';

  @override
  String get submit => 'Soumettre';

  @override
  String get none => 'Aucun';

  @override
  String get personalStatusClockingActions =>
      'Actions personnelles de pointage';

  @override
  String get clockedInAt => 'Arrivée à:';

  @override
  String get startBreakAt => 'Début de pause à:';

  @override
  String get endBreakAt => 'Fin de pause à:';

  @override
  String get clockedOutAt => 'Départ à:';

  @override
  String get allUsers => 'Tous les utilisateurs';

  @override
  String get clockInSuccessful => 'Pointage d\'entrée réussi';

  @override
  String get clockOutSuccessful => 'Pointage de sortie réussi';

  @override
  String get teamCreatedSuccessfully => 'Équipe créée avec succès!';

  @override
  String get errorPrefix => 'Erreur:';

  @override
  String get memberAddedSuccessfully => 'Membre ajouté avec succès!';

  @override
  String get memberErrorPrefix => 'Erreur membre:';

  @override
  String get noTeamsFound => 'Aucune équipe trouvée';

  @override
  String get roleCreatedSuccessfully => 'Rôle créé avec succès!';

  @override
  String get noRolesAvailable => 'Aucun rôle disponible';

  @override
  String get userList => 'Liste des utilisateurs';

  @override
  String get addUser => 'Ajouter un utilisateur';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get goBack => 'Retourner';

  @override
  String get errorDetailsDebug => 'Détails de l\'erreur (Debug)';

  @override
  String get aboutPageText => 'Ceci est la page À propos';

  @override
  String get teamPageMobileText => 'Ceci est la page Équipe pour Mobile';

  @override
  String get noTeamMembersFound => 'Aucun membre de l\'équipe trouvé.';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get chooseFromGallery => 'Choisir dans la galerie';

  @override
  String get selectMultiple => 'Sélection multiple';

  @override
  String get removeImage => 'Supprimer l\'image';

  @override
  String get settingsWeb => 'Paramètres Web';

  @override
  String get webNavbar => 'Barre de navigation Web';

  @override
  String get surveyMobile => 'Sondage Mobile';

  @override
  String get progress => 'Progrès';

  @override
  String get createdDate => 'Date de création';

  @override
  String get expiryDate => 'Date d\'expiration';

  @override
  String get dashboardSubtitle =>
      'Voici un aperçu rapide de votre espace de travail';

  @override
  String get quickActions => 'Actions rapides';

  @override
  String get recentActivity => 'Activité récente';

  @override
  String get activeTeams => 'Équipes actives';

  @override
  String get activeSurveys => 'Sondages actifs';

  @override
  String get todayClocking => 'Pointage d\'aujourd\'hui';

  @override
  String get totalMembers => 'Membres totaux';

  @override
  String get viewAll => 'Voir tout';

  @override
  String get noRecentActivity => 'Aucune activité récente';

  @override
  String get getStarted => 'Commencez par explorer votre espace de travail';

  @override
  String get logoutConfirmation => 'Êtes-vous sûr de vouloir vous déconnecter?';

  @override
  String get clockInRequiredForBreak => 'Pointage requis pour la pause';

  @override
  String get endActiveBreak => 'Terminer la pause';

  @override
  String get startActiveBreak => 'Commencer la pause';

  @override
  String get selectTeamToClockIn =>
      'Veuillez sélectionner une équipe pour pointer';

  @override
  String get allDates => 'Toutes les dates';

  @override
  String get teamClockings => 'Pointages d\'équipe';

  @override
  String get downloadPdf => 'Télécharger le PDF';

  @override
  String get clockingOwnerHint => 'Propriétaire du pointage';

  @override
  String get searchByNameOrTeam => 'Rechercher par nom ou équipe...';

  @override
  String get resetFilters => 'Réinitialiser les filtres';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get selectTeamToViewClockings =>
      'Veuillez sélectionner une équipe per voir les pointages';

  @override
  String get noClockingsForTeam => 'Aucun pointage trouvé pour cette équipe';

  @override
  String get committed => 'Confirmé';

  @override
  String get decommitted => 'Annulé';

  @override
  String get editClocking => 'Modifier le pointage';

  @override
  String get breakMinutes => 'Pause (minutes)';

  @override
  String get note => 'Note';

  @override
  String get invalidDateFormat => 'Format de date invalide';

  @override
  String get noClockingsToExport =>
      'Aucun pointage disponible pour l\'exportation';

  @override
  String get ownerOnly => 'Propriétaire uniquement';

  @override
  String get decommit => 'Annuler';

  @override
  String get commit => 'Confirmer';

  @override
  String get editAction => 'Modifier';

  @override
  String get noActionAvailable => 'Aucune action disponible';

  @override
  String get setExpiry => 'Définir la date d\'expiration';

  @override
  String get invitationSent => 'Invitation envoyée avec succès';

  @override
  String get noActiveMembersYet => 'Aucun membre actif pour le moment';

  @override
  String get editRoleTooltip => 'Modifier le rôle';

  @override
  String get removeAction => 'Supprimer';

  @override
  String get selectRole => 'Sélectionner un rôle';

  @override
  String get pendingInvitations => 'Invitations en attente';

  @override
  String get cancelInvitation => 'Annuler l\'invitation';

  @override
  String get inviteStatusAccepted => 'Acceptée';

  @override
  String get inviteStatusRejected => 'Refusée';

  @override
  String get inviteStatusUnregistered => 'En attente d\'inscription';

  @override
  String get inviteStatusPending => 'En attente';

  @override
  String get memberStatusInvited => 'Invité';

  @override
  String get memberStatusInactive => 'Inactif';

  @override
  String get memberStatusSuspended => 'Suspendu';

  @override
  String exportPdfError(Object error) {
    return 'Erreur lors de l\'exportation du PDF: $error';
  }

  @override
  String get surveyNotFound => 'Sondage non trouvé';

  @override
  String get focus => 'Focus';

  @override
  String get noOptionsAvailable => 'Aucune option disponible';

  @override
  String get alreadyVoted => 'Vous avez déjà voté';

  @override
  String get cannotVote => 'Vous ne pouvez pas voter';

  @override
  String get publish => 'Publier';

  @override
  String get closeSurvey => 'Fermer le Sondage';

  @override
  String get statusActive => 'Actif';

  @override
  String get statusDraft => 'Brouillon';

  @override
  String get statusClosed => 'Fermé';

  @override
  String get statusCompleted => 'Terminé';

  @override
  String get statusPublished => 'Publié';

  @override
  String votes(int count) {
    return '$count votes';
  }

  @override
  String activeTurnOn(String teamName) {
    return 'Tour actif sur $teamName';
  }

  @override
  String get openYourTurn => 'Ouvrir votre tour';

  @override
  String get loadingClockingState => 'Chargement de l\'état de pointage...';

  @override
  String get noClockingsForFilter =>
      'Aucun pointage trouvé pour les filtres sélectionnés';

  @override
  String get myShifts => 'Mes quarts';

  @override
  String get shiftCalendar => 'Calendrier des quarts';

  @override
  String get addShift => 'Ajouter un quart';

  @override
  String get shiftProfile => 'Profil de quart';

  @override
  String get shiftStart => 'Début';

  @override
  String get shiftEnd => 'Fin';

  @override
  String get overnightShift => 'Quart de nuit';

  @override
  String get alarms => 'Alarmes';

  @override
  String get createCustomProfile => 'Créer un profil personnalisé';

  @override
  String get editShiftProfile => 'Modifier le profil';

  @override
  String get shiftProfileName => 'Nom du profil';

  @override
  String get shiftColor => 'Couleur';

  @override
  String get deleteShiftProfileConfirm =>
      'Voulez-vous vraiment supprimer ce profil ?';

  @override
  String get customProfile => 'Profils personnalisés';

  @override
  String get noShiftsThisMonth => 'Aucun quart ce mois-ci';

  @override
  String get systemProfile => 'Profils système';
}
