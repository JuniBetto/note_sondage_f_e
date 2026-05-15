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
  String get deleteAccount => 'Désactiver le compte';

  @override
  String get accountDeletionDialogMessage =>
      'Saisissez l\'adresse e-mail du compte à désactiver. Nous enverrons un lien de confirmation avant de le bloquer.';

  @override
  String get sendConfirmationEmail => 'Envoyer l\'e-mail de confirmation';

  @override
  String get accountDeletionRequestSentTitle => 'Vérifiez votre e-mail';

  @override
  String get accountDeletionRequestSentMessage =>
      'Si un compte existe pour cet e-mail, nous avons envoyé un lien de confirmation pour terminer la désactivation.';

  @override
  String get accountDeletionRequestFailedTitle =>
      'Impossible de démarrer la désactivation';

  @override
  String get accountDeletionRequestFailedMessage =>
      'Nous n\'avons pas pu envoyer l\'e-mail de confirmation de désactivation pour le moment. Réessayez plus tard.';

  @override
  String get accountDeletionOpenEmailTitle =>
      'Ouvrez l\'e-mail de désactivation';

  @override
  String get accountDeletionOpenEmailMessage =>
      'Utilisez le lien de confirmation reçu par e-mail pour terminer la désactivation du compte.';

  @override
  String get accountDeletionConfirmedTitle => 'Compte désactivé';

  @override
  String get accountDeletionConfirmedMessage =>
      'Votre compte a bien été désactivé. Vous pouvez fermer cette page.';

  @override
  String get accountDeletionFailedTitle => 'Désactivation indisponible';

  @override
  String get accountDeletionFailedMessage =>
      'Nous n\'avons pas pu confirmer ce lien de désactivation. Demandez un nouvel e-mail et réessayez.';

  @override
  String get accountDeletionLoadingTitle => 'Confirmation de la désactivation';

  @override
  String get accountDeletionLoadingMessage =>
      'Nous vérifions votre lien de désactivation du compte...';

  @override
  String get reactivateAccount => 'Réactiver le compte';

  @override
  String get accountReactivationDialogMessage =>
      'Saisissez l\'adresse e-mail du compte à réactiver. Nous enverrons un lien de confirmation avant de rétablir l\'accès.';

  @override
  String get accountReactivationRequestSentTitle => 'Vérifiez votre e-mail';

  @override
  String get accountReactivationRequestSentMessage =>
      'Si un compte existe pour cet e-mail, nous avons envoyé un lien de confirmation pour terminer la réactivation.';

  @override
  String get accountReactivationRequestFailedTitle =>
      'Impossible de démarrer la réactivation';

  @override
  String get accountReactivationRequestFailedMessage =>
      'Nous n\'avons pas pu envoyer l\'e-mail de confirmation de réactivation pour le moment. Réessayez plus tard.';

  @override
  String get accountReactivationOpenEmailTitle =>
      'Ouvrez l\'e-mail de réactivation';

  @override
  String get accountReactivationOpenEmailMessage =>
      'Utilisez le lien de confirmation reçu par e-mail pour rétablir l\'accès à votre compte.';

  @override
  String get accountReactivationConfirmedTitle => 'Compte réactivé';

  @override
  String get accountReactivationConfirmedMessage =>
      'Votre compte est de nouveau actif. Vous pouvez vous connecter maintenant.';

  @override
  String get accountReactivationFailedTitle => 'Réactivation indisponible';

  @override
  String get accountReactivationFailedMessage =>
      'Nous n\'avons pas pu confirmer ce lien de réactivation. Demandez un nouvel e-mail et réessayez.';

  @override
  String get accountReactivationLoadingTitle =>
      'Confirmation de la réactivation';

  @override
  String get accountReactivationLoadingMessage =>
      'Nous vérifions votre lien de réactivation du compte...';

  @override
  String get backToLogin => 'Retour au login';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get webMobileAppOnlyTitle => 'Téléchargez l\'application mobile';

  @override
  String get webMobileAppOnlyMessage =>
      'Cette expérience web est disponible uniquement sur les grands écrans. Sur les téléphones de moins de 576px, utilisez l\'application mobile.';

  @override
  String get webMobileAppOnlyHint =>
      'Ouvrez Note Sondage sur tablette ou ordinateur, ou installez l\'application depuis votre store.';

  @override
  String get downloadOnAppStore => 'Télécharger sur l\'App Store';

  @override
  String get getItOnGooglePlay => 'Disponible sur Google Play';

  @override
  String get mobileStoreLinksUnavailable =>
      'Les liens vers les stores ne sont pas encore configurés. Contactez le support ou ouvrez l\'application sur un écran plus grand.';

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
  String get teamDetails => 'Details de l\'equipe';

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
  String get contactUsDescription =>
      'Expliquez-nous ce qui s\'est passé et nous ouvrirons votre application e-mail avec un brouillon prêt à envoyer.';

  @override
  String get contactUsDraftHint =>
      'Votre application e-mail s\'ouvrira avec Junibetto@gmail.com déjà sélectionné comme destinataire.';

  @override
  String get contactUsReplyTime =>
      'Nous répondons généralement sous 1 à 2 jours ouvrables.';

  @override
  String get supportEmail => 'E-mail de support';

  @override
  String get sendEmail => 'Envoyer un e-mail';

  @override
  String get copyEmail => 'Copier l\'e-mail';

  @override
  String get emailCopied =>
      'L\'e-mail de support a été copié dans le presse-papiers.';

  @override
  String get couldNotOpenEmailApp =>
      'Nous n\'avons pas pu ouvrir votre application e-mail. Copiez l\'adresse et envoyez le message manuellement.';

  @override
  String get contactUsEmailSubject => 'Demande de support Note Sondage';

  @override
  String get contactUsTopicsTitle => 'Bugs, retours, idées produit';

  @override
  String get contactUsTopicsBody =>
      'Utilisez cet espace pour signaler des problèmes, demander de l\'aide ou partager les améliorations que vous aimeriez voir.';

  @override
  String get contactUsFormHint =>
      'Le brouillon inclura vos informations afin que le support puisse répondre plus rapidement.';

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
  String get close => 'Fermer';

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
  String get shiftCalendarSubtitle => 'Your personal and team shift schedule';

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
  String get shiftRepeatUntil => 'Répéter jusqu\'au';

  @override
  String get shiftRepeatUntilHelp =>
      'Un quart sera créé pour chaque jour de l\'intervalle sélectionné.';

  @override
  String get shiftEndMustBeAfterStart =>
      'L\'heure de fin doit être postérieure à l\'heure de début. Si le quart se termine le lendemain, activez Quart de nuit.';

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
