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
  String get gladYouAreBack => 'Content de vous revoir !';

  @override
  String get welcomeBack => 'Bon retour !';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié';

  @override
  String get deleteAccount => 'Désactiver le compte';

  @override
  String get permanentlyDeleteAccount => 'Supprimer le compte';

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
  String get accountErasureDialogMessage =>
      'Saisissez l\'adresse e-mail du compte à supprimer définitivement. Nous enverrons un lien de confirmation avant de retirer vos données.';

  @override
  String get accountErasureRequestSentTitle => 'Vérifiez votre e-mail';

  @override
  String get accountErasureRequestSentMessage =>
      'Si un compte existe pour cet e-mail, nous avons envoyé un lien de confirmation pour terminer la suppression définitive.';

  @override
  String get accountErasureRequestFailedTitle =>
      'Impossible de démarrer la suppression du compte';

  @override
  String get accountErasureRequestFailedMessage =>
      'Nous n\'avons pas pu envoyer l\'e-mail de confirmation de suppression définitive pour le moment. Réessayez plus tard.';

  @override
  String get accountErasureOpenEmailTitle => 'Ouvrez l\'e-mail de suppression';

  @override
  String get accountErasureOpenEmailMessage =>
      'Utilisez le lien de confirmation de suppression définitive reçu par e-mail pour supprimer le compte et ses données.';

  @override
  String get accountErasureConfirmedTitle => 'Compte supprimé';

  @override
  String get accountErasureConfirmedMessage =>
      'Votre compte et les données associées ont été supprimés définitivement. Vous pouvez fermer cette page.';

  @override
  String get accountErasureFailedTitle => 'Suppression du compte indisponible';

  @override
  String get accountErasureFailedMessage =>
      'Nous n\'avons pas pu confirmer ce lien de suppression définitive. Demandez un nouvel e-mail et réessayez.';

  @override
  String get accountErasureLoadingTitle =>
      'Confirmation de la suppression du compte';

  @override
  String get accountErasureLoadingMessage =>
      'Nous vérifions votre lien de suppression définitive du compte...';

  @override
  String get accountErasureReadyTitle => 'Confirmer la suppression définitive';

  @override
  String get accountErasureReadyMessage =>
      'Cette action supprime définitivement votre compte et les données associées. Elle est irréversible.';

  @override
  String get confirmAccountErasure => 'Supprimer définitivement le compte';

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
  String get reviewTutorial => 'Revoir le tutoriel';

  @override
  String get videoTutorial => 'Tutoriel vidéo';

  @override
  String get tutorialPrevious => 'Précédent';

  @override
  String get tutorialNext => 'Suivant';

  @override
  String get tutorialSkip => 'Passer';

  @override
  String get webMobileAppOnlyTitle => 'Téléchargez l\'application mobile';

  @override
  String get webMobileAppOnlyMessage =>
      'Cette expérience web est disponible uniquement sur les grands écrans. Sur les téléphones de moins de 576px, utilisez l\'application mobile.';

  @override
  String get webMobileAppOnlyHint =>
      'Ouvrez TeamManagement sur tablette ou ordinateur, ou installez l\'application depuis votre store.';

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
  String get planningTabLabel => 'Planification';

  @override
  String get explorer => 'explorateur';

  @override
  String get sondage => 'Sondage';

  @override
  String get sondageChat => 'Sondage/Chat';

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
  String get selectDateRange => 'Selectionner une periode';

  @override
  String get selectDateRangeHint =>
      'Touchez une date de debut, puis une date de fin';

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
  String get saveTeam => 'Enregistrer equipe';

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
  String get notificationsSettingsIntro =>
      'Choisissez comment recevoir les mises à jour et les rappels de service.';

  @override
  String get notificationsGeneral => 'Général';

  @override
  String get emailNotifications => 'Notifications par e-mail';

  @override
  String get receiveUpdatesByEmail => 'Recevez les mises à jour par e-mail';

  @override
  String get pushNotifications => 'Notifications push';

  @override
  String get receivePushNotificationsOnYourDevice =>
      'Recevez des notifications push sur votre appareil';

  @override
  String get shiftReminders => 'Rappels de service';

  @override
  String get reminderMode => 'Mode de rappel';

  @override
  String get notificationReminderModeDescription =>
      'Choisissez pour chaque service si vous voulez une notification standard ou une alerte plus forte.';

  @override
  String get webBehavior => 'Comportement web';

  @override
  String get alarmBehaviorOnWeb =>
      'Sur le web, le mode Alarme utilise les notifications du navigateur. L\'onglet doit rester ouvert et le navigateur contrôle le comportement final du son et des vibrations.';

  @override
  String get howItWorks => 'Comment ça marche';

  @override
  String get notificationAndAlarmDifference =>
      'La notification affiche un rappel normal. L\'alarme utilise les réglages ci-dessous et sert à des alertes de service plus visibles.';

  @override
  String get alarmDelivery => 'Diffusion de l\'alarme';

  @override
  String get alarmStyle => 'Style de l\'alarme';

  @override
  String get webAlarmDeliveryDescription =>
      'Les notifications du navigateur sont utilisées tant que cet onglet reste ouvert. Le son et les vibrations sont gérés par le navigateur et le système d\'exploitation.';

  @override
  String get alarmStyleDescription =>
      'Choisissez si le mode Alarme doit vibrer ou jouer une sonnerie. Par défaut : vibration.';

  @override
  String get alarmStyleDescriptionIos =>
      'Sur iPhone, le mode Alarme utilise une sonnerie. Les alarmes uniquement par vibration ne sont pas disponibles pour les notifications locales.';

  @override
  String get vibrate => 'Vibration';

  @override
  String get ringtone => 'Sonnerie';

  @override
  String get browserNotification => 'Notification du navigateur';

  @override
  String get notificationVisibility => 'Visibilité de la notification';

  @override
  String get alarmDuration => 'Durée de l\'alarme';

  @override
  String get webNotificationVisibilityDescription =>
      'Cela contrôle combien de temps la notification du navigateur reste visible après son apparition.';

  @override
  String get alarmDurationAppliesOnlyToAlarmMode =>
      'Cette durée s\'applique uniquement lorsqu\'un service utilise le mode Alarme.';

  @override
  String get activity => 'Activité';

  @override
  String get surveyReminders => 'Rappels de sondage';

  @override
  String get getRemindedAboutPendingSurveys =>
      'Recevez des rappels pour les sondages en attente';

  @override
  String get teamUpdates => 'Mises à jour d\'équipe';

  @override
  String get notificationsAboutTeamChanges =>
      'Notifications sur les changements de l\'équipe';

  @override
  String get clockingAlerts => 'Alertes de pointage';

  @override
  String get remindersToClockInAndOut =>
      'Rappels pour pointer l\'entrée et la sortie';

  @override
  String get shiftNotifications => 'Notifications de service';

  @override
  String get assignmentsUpdatesAndShiftReminders =>
      'Affectations, mises à jour et rappels de service';

  @override
  String get taskNotifications => 'Notifications de tâches';

  @override
  String get taskNotificationsSubtitle =>
      'Rappels pour les tâches qui vous sont assignées ou proches de l\'échéance';

  @override
  String get eventNotifications => 'Notifications d\'événements';

  @override
  String get eventNotificationsSubtitle =>
      'Nouveaux événements, modifications et rappels de calendrier';

  @override
  String get debugTools => 'Outils de débogage';

  @override
  String get debugToolsBrowserMessage =>
      'Utilisez ces tests uniquement pendant le débogage des notifications dans ce navigateur.';

  @override
  String get debugToolsDeviceMessage =>
      'Utilisez ces tests uniquement pendant le débogage des notifications sur cet appareil.';

  @override
  String get testNotificationNow => 'Tester la notification maintenant';

  @override
  String get testAlarmIn10Seconds => 'Tester l\'alarme dans 10 s';

  @override
  String get testCurrentMode => 'Tester le mode actuel';

  @override
  String get alarmModeStatus => 'État du mode alarme';

  @override
  String get pendingRequests => 'Demandes en attente';

  @override
  String get inspectRealShifts => 'Inspecter les vrais services';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get termsOfService => 'Conditions d\'utilisation';

  @override
  String get howWeProtectYourData => 'Comment nous protégeons vos données';

  @override
  String get dataProtection => 'Protection des données';

  @override
  String get dataProtectionDescription =>
      'Vos données sont chiffrées au repos et en transit. Nous utilisons des protocoles de chiffrement standard du secteur pour garantir la sécurité de vos informations.';

  @override
  String get dataCollection => 'Collecte des données';

  @override
  String get dataCollectionDescription =>
      'Nous collectons uniquement les données nécessaires pour fournir nos services. Cela inclut les informations du compte, les réponses aux sondages et les enregistrements de pointage.';

  @override
  String get dataSharing => 'Partage des données';

  @override
  String get dataSharingDescription =>
      'Nous ne partageons jamais vos données personnelles avec des tiers sans votre consentement explicite. Les données d\'équipe sont partagées uniquement au sein de votre organisation.';

  @override
  String get dataRetention => 'Conservation des données';

  @override
  String get dataRetentionDescription =>
      'Vos données sont conservées tant que votre compte est actif. Après la désactivation du compte, les données personnelles sont supprimées définitivement en 1 an.';

  @override
  String get yourRights => 'Vos droits';

  @override
  String get yourRightsDescription =>
      'Vous avez le droit d\'accéder, de rectifier ou de supprimer vos données personnelles à tout moment. Contactez notre équipe support pour toute demande liée à la confidentialité.';

  @override
  String get privacyLastUpdated => 'Dernière mise à jour : 31 août 2026';

  @override
  String get reviewPublicLegalPages => 'Pages juridiques publiques';

  @override
  String get reviewPublicLegalPagesDescription =>
      'Consultez sur le site la politique de confidentialité et les conditions d\'utilisation publiques les plus récentes.';

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
      'Expliquez-nous ce qui s\'est passé et nous enverrons le message directement à notre équipe support.';

  @override
  String get contactUsDraftHint =>
      'Votre message sera envoyé directement à contactus@teammanagement.it.';

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
  String get contactUsEmailSubject => 'Demande de support TeamManagement';

  @override
  String get contactUsTopicsTitle => 'Bugs, retours, idées produit';

  @override
  String get contactUsTopicsBody =>
      'Utilisez cet espace pour signaler des problèmes, demander de l\'aide ou partager les améliorations que vous aimeriez voir.';

  @override
  String get contactUsFormHint =>
      'Le message inclura vos informations afin que le support puisse répondre plus rapidement.';

  @override
  String get contactUsSentSuccess =>
      'Votre message a bien été envoyé au support.';

  @override
  String get contactUsSendFailed =>
      'Nous n\'avons pas pu envoyer votre message pour le moment. Réessayez dans un instant.';

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
  String get deleteTeamTitle => 'Supprimer l\'équipe';

  @override
  String get deleteTeamMessage =>
      'Voulez-vous vraiment supprimer cette équipe ? Cette action est irréversible.';

  @override
  String get teamDeletedSuccess => 'Equipe supprimee avec succes.';

  @override
  String get deleteRoleTitle => 'Supprimer le rôle';

  @override
  String get deleteRoleMessage => 'Voulez-vous vraiment supprimer ce rôle ?';

  @override
  String get defaultRole => 'Rôle par défaut';

  @override
  String get swipeToCreateRole => 'Glissez pour créer un nouveau rôle';

  @override
  String get searchTeamsByNameOrDescription =>
      'Rechercher des équipes par nom ou description';

  @override
  String get noTeamsMatchingSearch =>
      'Aucune équipe trouvée pour cette recherche.';

  @override
  String get noArchivedTeams => 'Aucune équipe archivée.';

  @override
  String get noVisibleTeams => 'Aucune équipe visible.';

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
  String get myOpenTasks => 'Tâches ouvertes';

  @override
  String get unreadChatMessages => 'Messages non lus';

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
  String get deleteAction => 'Supprimer';

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
  String get noPermissionToEditSurvey =>
      'Vous n\'avez pas l\'autorisation de modifier ce sondage.';

  @override
  String get editSurvey => 'Modifier le sondage';

  @override
  String get deleteSurvey => 'Supprimer le sondage';

  @override
  String get deleteSurveyTitle => 'Supprimer le sondage';

  @override
  String get deleteSurveyMessage =>
      'Voulez-vous vraiment supprimer ce sondage ?';

  @override
  String get surveyDeleted => 'Sondage supprimé.';

  @override
  String get archiveSurvey => 'Archiver le sondage';

  @override
  String get restoreSurvey => 'Restaurer le sondage';

  @override
  String get noDraftOrActiveSurveysAvailable =>
      'Aucun brouillon ou sondage actif disponible';

  @override
  String get noSurveysMatchingSearch =>
      'Aucun sondage trouvé pour cette recherche.';

  @override
  String get noArchivedSurveys => 'Aucun sondage archivé.';

  @override
  String get noVisibleSurveys => 'Aucun sondage visible.';

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
  String get list => 'Liste';

  @override
  String get refresh => 'Actualiser';

  @override
  String get sondageListSubtitle =>
      'Brouillons et sondages actifs de vos équipes';

  @override
  String get sondageFeedSubtitle =>
      'Flux unifié des brouillons personnels, des brouillons d\'équipe visibles et des sondages actifs.';

  @override
  String get sondageCountDraft => 'Brouillons';

  @override
  String get sondageCountActive => 'Actifs';

  @override
  String get sondageCountClosed => 'Fermés';

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
  String get myEvents => 'Mes événements';

  @override
  String get shiftCalendar => 'Calendrier des quarts';

  @override
  String get shiftCalendarSubtitle => 'Votre calendrier personnel et d\'équipe';

  @override
  String get shiftTeamReportTitle => 'Rapport des quarts d\'équipe';

  @override
  String get shiftTeamReportSubtitle =>
      'Filtrez par période et par utilisateurs, puis prévisualisez ou téléchargez le rapport.';

  @override
  String get shiftTeamReportTooltip => 'Rapport des quarts d\'équipe';

  @override
  String get shiftTeamReportButton => 'Rapport d\'équipe';

  @override
  String get shiftReportUnavailable =>
      'Aucune équipe gérable n\'est disponible pour le rapport.';

  @override
  String get shiftReportStartDate => 'Date de début';

  @override
  String get shiftReportEndDate => 'Date de fin';

  @override
  String get shiftReportUsers => 'Utilisateurs à inclure';

  @override
  String get shiftReportRefresh => 'Actualiser le rapport';

  @override
  String get shiftReportPeriod => 'Période';

  @override
  String get shiftReportShifts => 'Quarts';

  @override
  String get shiftReportMode => 'Mode';

  @override
  String get shiftReportCalendarMode => 'Calendrier';

  @override
  String get shiftReportTableMode => 'Tableau';

  @override
  String get shiftReportSelectTeam => 'Sélectionnez une équipe.';

  @override
  String get shiftReportNoResults =>
      'Aucun quart trouvé pour les filtres sélectionnés.';

  @override
  String get shiftReportLoadError =>
      'Nous n\'avons pas pu charger le rapport des quarts pour le moment.';

  @override
  String get shiftReportGeneratedAt => 'Généré le';

  @override
  String get shiftReportDateColumn => 'Date';

  @override
  String get shiftReportUserColumn => 'Utilisateur';

  @override
  String get shiftReportProfileColumn => 'Profil';

  @override
  String get shiftReportTypeColumn => 'Type';

  @override
  String get shiftReportDefaultProfile => 'Quart';

  @override
  String get shiftReportPrivateType => 'Privé';

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
  String get shiftProfileCreatedSuccess =>
      'Profil personnalisé créé avec succès.';

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
  String get shiftProfileDeletedSuccess => 'Profil supprime avec succes.';

  @override
  String get deleteShiftTitle => 'Supprimer le quart';

  @override
  String get deleteShiftMessage => 'Voulez-vous vraiment supprimer ce quart ?';

  @override
  String shiftAssignmentDeletedSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quarts supprimes avec succes.',
      one: 'Quart supprime avec succes.',
    );
    return '$_temp0';
  }

  @override
  String get publicProfile => 'Public';

  @override
  String get privateProfile => 'Privé';

  @override
  String get visibleToTeamMembers =>
      'Visible par tous les membres de l\'équipe';

  @override
  String get visibleOnlyToYou => 'Visible uniquement par vous';

  @override
  String get syncing => 'Synchronisation';

  @override
  String shiftEntriesForDate(String date) {
    return 'Quarts du $date';
  }

  @override
  String get noArchivedShifts => 'Aucun quart archivé.';

  @override
  String get openAction => 'Ouvrir';

  @override
  String get restoreAction => 'Restaurer';

  @override
  String get selectMonth => 'Sélectionner le mois';

  @override
  String get selectYear => 'Sélectionner l\'année';

  @override
  String shiftCalendarPublicAssignments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quarts publics visibles pour l\'équipe',
      one: '1 quart public visible pour l\'équipe',
    );
    return '$_temp0';
  }

  @override
  String get shiftCalendarPrivateAssignments => 'Quarts privés';

  @override
  String shiftCalendarMoreEntries(int count) {
    return '+$count autres';
  }

  @override
  String get deleteAllShiftsForDayTooltip =>
      'Supprimer tous les quarts de ce jour';

  @override
  String get deleteAllShiftsForDayTitle => 'Supprimer tous les quarts';

  @override
  String deleteAllShiftsForDayMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Etes-vous sur de vouloir supprimer les $count quarts assignes ce jour?',
      one: 'Etes-vous sur de vouloir supprimer le quart assigne ce jour?',
    );
    return '$_temp0';
  }

  @override
  String get shiftAutoPlanPreviewTitle => 'Apercu Auto Planner';

  @override
  String get shiftAutoPlanPreviewStatusFeasible => 'Faisable';

  @override
  String get shiftAutoPlanPreviewStatusNeedsReview => 'A verifier';

  @override
  String get shiftAutoPlanPreviewReadyDescription =>
      'Cet apercu est pret : le calendrier ci-dessous montre les shifts prevus avant la confirmation finale.';

  @override
  String get shiftAutoPlanPreviewNeedsReviewDescription =>
      'Cet apercu montre des problemes de couverture ou de contraintes. La confirmation reste desactivee tant que ce n\'est pas faisable.';

  @override
  String get shiftAutoPlanPreviewSummaryTitle => 'Resume';

  @override
  String get shiftAutoPlanPreviewNewShifts => 'Nouveaux shifts';

  @override
  String get shiftAutoPlanPreviewPreserved => 'Conserves';

  @override
  String get shiftAutoPlanPreviewToRemove => 'A supprimer';

  @override
  String get shiftAutoPlanPreviewUncoveredSlots => 'Couvertures manquantes';

  @override
  String get shiftAutoPlanPreviewWarningsTitle => 'Avertissements du planner';

  @override
  String get shiftAutoPlanPreviewCalendarTitle => 'Calendrier preview';

  @override
  String get shiftAutoPlanPreviewCalendarDescription =>
      'Touchez un jour pour voir le detail des shifts prevus et des actions planifiees.';

  @override
  String get shiftAutoPlanPreviewEmpty =>
      'Aucune modification proposee pour cette periode.';

  @override
  String get shiftAutoPlanPreviewBack => 'Retour';

  @override
  String get shiftAutoPlanPreviewConfirmCreate => 'Confirmer et creer';

  @override
  String get shiftAutoPlanPreviewConfirmError =>
      'Nous n\'avons pas pu confirmer cet apercu du planner.';

  @override
  String get shiftAutoPlanPreviewDayDescription =>
      'Shifts prevus pour cette journee.';

  @override
  String get shiftAutoPlanPreviewDefaultShiftTitle => 'Shift';

  @override
  String get shiftAutoPlanPreviewActionNew => 'Nouveau';

  @override
  String get shiftAutoPlanPreviewActionKeep => 'Garder';

  @override
  String get shiftAutoPlanPreviewActionRemove => 'Supprimer';

  @override
  String get customProfile => 'Profils personnalisés';

  @override
  String get noShiftsThisMonth => 'Aucun quart ce mois-ci';

  @override
  String get systemProfile => 'Profils système';

  @override
  String get clockingDateLabel => 'Date de pointage';

  @override
  String get calendarWeek => 'Semaine';

  @override
  String get calendarMonth => 'Mois';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get clockingOverviewTitle => 'Vue d\'ensemble du pointage';

  @override
  String get clockingOverviewDescription =>
      'Cet en-tête présente la zone de pointage et son objectif principal.';

  @override
  String get clockingCurrentStatusTitle => 'Statut actuel';

  @override
  String get clockingCurrentStatusDescription =>
      'Cette section vous montre immédiatement l\'état de votre pointage et les informations principales de la journée.';

  @override
  String get teamClockingRequirementTitle => 'Pointage obligatoire';

  @override
  String get teamClockingRequirementDescription =>
      'Si activé, chaque membre de l\'équipe doit enregistrer un pointage, des congés ou une permission.';

  @override
  String get teamClockingRequirementDefaultInfo =>
      'Par défaut : Non. Lorsque activé, le système envoie un rappel à l\'utilisateur et alerte le propriétaire si un pointage est manquant ou encore ouvert.';

  @override
  String get teamClockingRequirementStartDateTitle => 'Date de début';

  @override
  String get teamClockingRequirementStartDateSubtitle =>
      'Les notifications de pointage obligatoire commencent à partir de cette date.';

  @override
  String get teamClockingRequirementEndDateTitle => 'Date de fin';

  @override
  String get teamClockingRequirementEndDateSubtitle =>
      'Si définie, les notifications s\'arrêtent après cette date. Laissez vide pour les garder actives sans échéance.';

  @override
  String get teamClockingRequirementNoEndDate => 'Aucune date de fin';

  @override
  String get teamClockingRequirementClearEndDate => 'Supprimer la date de fin';

  @override
  String get teamClockingRequirementUserReminderTitle => 'Rappel utilisateur';

  @override
  String get teamClockingRequirementUserReminderSubtitle =>
      'Heure de rappel dans le fuseau horaire local de chaque membre.';

  @override
  String get teamClockingRequirementMissingCheckTitle =>
      'Contrôle de pointage manquant';

  @override
  String get teamClockingRequirementMissingCheckSubtitle =>
      'Après cette heure dans le fuseau horaire du membre, le propriétaire est alerté si une saisie est manquante.';

  @override
  String get teamClockingRequirementOpenCheckTitle =>
      'Contrôle de pointage ouvert';

  @override
  String get teamClockingRequirementOpenCheckSubtitle =>
      'Après cette heure dans le fuseau horaire du membre, le propriétaire est alerté si un pointage est encore ouvert.';

  @override
  String get teamClockingRequirementAddOverrideTooltip =>
      'Ajouter une heure personnalisée pour un membre';

  @override
  String get teamClockingRequirementChooseMember => 'Choisir un membre';

  @override
  String get personal => 'Personnel';

  @override
  String get markVacation => 'Marquer des congés';

  @override
  String get markPermission => 'Marquer une permission';

  @override
  String get requestClocking => 'Demander un pointage';

  @override
  String get requestDecommit => 'Demander un décommit';

  @override
  String get requestVacation => 'Demander des congés';

  @override
  String get requestPermission => 'Demander une permission';

  @override
  String get vacationStatus => 'Congés';

  @override
  String clockingOpenRecordAnotherDay(String teamName, String date) {
    return 'Vous avez un pointage ouvert sur $teamName le $date. Sélectionnez-le pour continuer.';
  }

  @override
  String dayAlreadyHasClocking(String date) {
    return 'Un pointage existe déjà pour $date.';
  }

  @override
  String get manualClockingUseInlineForPastDays =>
      'Pour les jours différents d\'aujourd\'hui, utilisez la section de saisie manuelle ci-dessous.';

  @override
  String get manualClockingRequiresApproval =>
      'Pour cette date, demandez l\'approbation d\'un manager ou utilisez une équipe que vous gérez.';

  @override
  String get selectedDayMarkedAsVacation =>
      'Le jour sélectionné est marqué comme congé.';

  @override
  String get clockingCurrentTimeOverlapsExistingRecord =>
      'L\'heure actuelle tombe dans un pointage ou une permission deja enregistres aujourd\'hui.';

  @override
  String createClockingForDate(String date) {
    return 'Créer un pointage pour $date';
  }

  @override
  String get breakOnlyCurrentDay =>
      'Les pauses sont disponibles uniquement pour le jour en cours.';

  @override
  String get manualClockingTitle => 'Ajouter un pointage';

  @override
  String manualClockingDescription(String date) {
    return 'Complétez le pointage pour $date ou ajoutez d\'autres jours passés.';
  }

  @override
  String manualClockingSingleDayDescription(String date) {
    return 'Complétez le pointage pour $date.';
  }

  @override
  String manualClockingResolveOpenRecord(String teamName, String date) {
    return 'Vous avez un pointage ouvert sur $teamName le $date. Fermez-le ou sélectionnez ce jour avant d\'enregistrer un pointage manuel.';
  }

  @override
  String get selectedDays => 'Jours sélectionnés';

  @override
  String get addDay => 'Ajouter un jour';

  @override
  String get clockInLabel => 'Pointage d\'entrée';

  @override
  String get clockOutLabel => 'Pointage de sortie';

  @override
  String get optionalNoteHint => 'Note facultative';

  @override
  String get saving => 'Enregistrement...';

  @override
  String get saveClocking => 'Enregistrer le pointage';

  @override
  String get manualClockingTodayLiveOnly =>
      'Pour aujourd\'hui, utilisez les actions en direct de pointage d\'entrée, pause et pointage de sortie.';

  @override
  String get invalidBreakMinutes =>
      'La durée de pause doit être un nombre valide.';

  @override
  String get clockOutMustBeAfterClockIn =>
      'L\'heure de sortie doit être postérieure à l\'heure d\'entrée.';

  @override
  String get breakMustBeShorterThanShift =>
      'La pause doit être plus courte que la durée du service.';

  @override
  String get manualClockingSavedSingle => 'Pointage enregistré avec succès.';

  @override
  String manualClockingSavedMultiple(int count) {
    return '$count pointages enregistrés avec succès.';
  }

  @override
  String get manualClockingSaveError =>
      'Nous n\'avons pas pu enregistrer le pointage manuel.';

  @override
  String get manualClockingBackToTodayTooltip => 'Revenir à aujourd\'hui';

  @override
  String get manualClockingBackToTodayTitle => 'Revenir à aujourd\'hui ?';

  @override
  String get manualClockingBackToTodayMessage =>
      'Vous êtes sur le point de quitter le mode de pointage manuel.\n\nSi vous souhaitez modifier un pointage d\'un jour passé, vous devrez envoyer une nouvelle demande de pointage manuel pour ce jour.';

  @override
  String get manualClockingBackToTodayConfirm => 'Revenir à aujourd\'hui';

  @override
  String get manualClockingOverlapTitle => 'Chevauchement détecté';

  @override
  String manualClockingOverlapMessage(
    String newRange,
    String existingRange,
    String newEndTime,
  ) {
    return 'Le nouveau pointage ($newRange) chevauche un pointage existant ($existingRange).\n\nVoulez-vous raccourcir le pointage existant pour qu\'il se termine à $newEndTime ?';
  }

  @override
  String get manualClockingOverlapConfirmAdjust => 'Oui, raccourcir';

  @override
  String get clockingEditOpenRecordConflict =>
      'Il existe un pointage ouvert ce jour-là. Fermez-le avant d\'enregistrer cette modification.';

  @override
  String get clockingEditOverlapConflict =>
      'Ce pointage chevauche un pointage ou une autorisation existante.';

  @override
  String get noTeamSelected => 'Aucune équipe sélectionnée';

  @override
  String get changeOrSearchTeam =>
      'Ouvrez pour changer d\'équipe ou en rechercher une';

  @override
  String get teamAvailableForClocking => 'Équipe disponible pour le pointage';

  @override
  String get searchTeam => 'Rechercher une équipe...';

  @override
  String get noTeamFound => 'Aucune équipe trouvée';

  @override
  String get selectTeamFirst => 'Sélectionnez d\'abord une équipe.';

  @override
  String get selectTeamBeforeVacation =>
      'Sélectionnez une équipe avant de marquer des congés.';

  @override
  String markSelectedDateAsVacation(String date) {
    return 'Marquer $date comme congé';
  }

  @override
  String get markSelectedDayAsVacationDescription =>
      'Cette action marquera le jour sélectionné comme congé.';

  @override
  String markPermissionForDate(String date) {
    return 'Marquer une permission pour $date';
  }

  @override
  String get start => 'Début';

  @override
  String get end => 'Fin';

  @override
  String get permissionInvalidRange =>
      'L\'heure de fin doit être postérieure à l\'heure de début de la permission.';

  @override
  String get noAssignableMembersForTeam =>
      'Aucun membre assignable trouvé pour cette équipe.';

  @override
  String get assignVacationToMember => 'Marquer des congés pour un membre';

  @override
  String get userLabel => 'Utilisateur';

  @override
  String optionalNoteFor(String name) {
    return 'Note facultative pour $name';
  }

  @override
  String get optionalRequestNoteHint => 'Note facultative pour la demande';

  @override
  String get clockingApprovalRequestHint =>
      'Vous pouvez demander un pointage, un décommit, des congés ou une permission pour l\'équipe et la date sélectionnées.';

  @override
  String requestClockingForSelectedDate(String date) {
    return 'Demander un pointage pour $date';
  }

  @override
  String requestDecommitForSelectedDate(String date) {
    return 'Demander un décommit pour $date';
  }

  @override
  String get noMembersAvailableForClockingRequest =>
      'Aucun membre disponible pour la demande de pointage.';

  @override
  String get sendRequest => 'Envoyer la demande';

  @override
  String get clockingRequestSentSuccess =>
      'Demande de pointage envoyée avec succès.';

  @override
  String get clockingRequestSentError =>
      'Nous n\'avons pas pu envoyer la demande de pointage au membre de l\'équipe.';

  @override
  String get requestUnlockOpenRecord => 'Demander le déverrouillage';

  @override
  String requestUnlockOpenRecordDescription(String date) {
    return 'Vous avez un pointage ouvert du $date que vous ne pouvez pas fermer vous-même. Demandez au manager de le déverrouiller pour pouvoir le fermer.';
  }

  @override
  String get unlockRequestSentSuccess =>
      'Demande de déverrouillage envoyée avec succès.';

  @override
  String get unlockRequestSentError =>
      'Nous n\'avons pas pu envoyer la demande de déverrouillage.';

  @override
  String get decommitRequestSentSuccess =>
      'Demande de décommit envoyée avec succès.';

  @override
  String get decommitRequestSentError =>
      'Nous n\'avons pas pu envoyer la demande de décommit.';

  @override
  String get vacationRequestSentSuccess =>
      'Demande de congé envoyée avec succès.';

  @override
  String get vacationRequestSentError =>
      'Nous n\'avons pas pu envoyer la demande de congé.';

  @override
  String get permissionRequestSentSuccess =>
      'Demande de permission envoyée avec succès.';

  @override
  String get permissionRequestSentError =>
      'Nous n\'avons pas pu envoyer la demande de permission.';

  @override
  String get approveRequest => 'Approuver';

  @override
  String get rejectRequest => 'Refuser';

  @override
  String get clockInDateTimeLabel => 'Pointage d\'entrée (AAAA-MM-JJ HH:MM)';

  @override
  String get clockOutDateTimeLabel => 'Pointage de sortie (AAAA-MM-JJ HH:MM)';

  @override
  String get chatTitle => 'Chat';

  @override
  String get chatLive => 'En direct';

  @override
  String get chatTeamTitle => 'Chat d\'équipe';

  @override
  String get chatRefresh => 'Actualiser';

  @override
  String get chatChooseConversation => 'Choisissez une conversation';

  @override
  String get chatListDescriptionWeb =>
      'Sélectionnez un canal d\'équipe ou rouvrez l\'une de vos conversations directes.';

  @override
  String get chatListDescriptionMobile =>
      'Ouvrez un canal d\'équipe ou revenez dans l\'une de vos conversations directes.';

  @override
  String get chatTeamChannels => 'Canaux d\'équipe';

  @override
  String get chatDirectChats => 'Chats directs';

  @override
  String get chatNoDirectContacts =>
      'L\'historique de vos conversations directes apparaîtra ici.';

  @override
  String get chatNoTeamsAvailable =>
      'Aucune équipe disponible pour le chat pour le moment.';

  @override
  String get chatChooseTeamHeader =>
      'Choisissez une équipe pour commencer à discuter.';

  @override
  String chatHeaderDirectDescription(String name) {
    return 'Conversation directe avec $name';
  }

  @override
  String chatHeaderTeamDescription(String name) {
    return 'Chat de l\'équipe $name';
  }

  @override
  String get chatRefreshed => 'Chat actualisé.';

  @override
  String get chatLoadTeamsError =>
      'Nous n\'avons pas pu charger vos équipes de chat.';

  @override
  String get chatLoadConversationError =>
      'Nous n\'avons pas pu charger cette conversation.';

  @override
  String get chatSendMessageError => 'Nous n\'avons pas pu envoyer le message.';

  @override
  String get chatReactionUpdateError =>
      'Nous n\'avons pas pu mettre à jour la réaction.';

  @override
  String get chatDeleteError => 'Nous n\'avons pas pu supprimer le message.';

  @override
  String get chatReactTitle => 'Réagir au message';

  @override
  String get chatReactHint => 'Choisissez une réaction emoji.';

  @override
  String get chatDeleteTitle => 'Supprimer le message';

  @override
  String get chatDeleteMessage => 'Voulez-vous supprimer ce message ?';

  @override
  String get chatYouLabel => 'Vous';

  @override
  String get chatTimelineBeginning => 'La conversation commence ici';

  @override
  String chatTimelineActive(String name) {
    return '$name est actif';
  }

  @override
  String chatTimelineResumed(String duration) {
    return 'Conversation reprise après $duration';
  }

  @override
  String chatDurationMinutesShort(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '1 min',
    );
    return '$_temp0';
  }

  @override
  String chatDurationHoursShort(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours h',
      one: '1 h',
    );
    return '$_temp0';
  }

  @override
  String chatDurationDaysShort(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get chatReplyAction => 'Répondre';

  @override
  String get chatLoadingOlderMessages => 'Chargement des anciens messages...';

  @override
  String get chatNoMessagesYet => 'Aucun message pour le moment';

  @override
  String get chatEmptyDescription =>
      'Écrivez le premier message pour démarrer cette conversation.';

  @override
  String get chatSeen => 'Vu';

  @override
  String get chatDeletedMessage => 'Message supprimé';

  @override
  String get chatAttachmentFallback => 'Pièce jointe';

  @override
  String get chatOpenDocument => 'Ouvrir le document';

  @override
  String get chatOpenSharedConversation =>
      'Ouvrir la conversation partagée de l\'équipe.';

  @override
  String get chatOpenConversation => 'Ouvrir la conversation';

  @override
  String chatDirectConversationInTeam(String teamName) {
    return 'Conversation directe dans $teamName';
  }

  @override
  String get chatDirectActionDescription =>
      'Ouvrez un chat privé avec ce membre de l\'équipe.';

  @override
  String get chatOpenDirectAction => 'Ouvrir le chat direct';

  @override
  String get chatReturnToChatList => 'Retour à la liste des chats';

  @override
  String get chatReturnToTeamList => 'Retour à la liste des équipes';

  @override
  String get chatComposerHint => 'Écris un message';

  @override
  String get chatPickImage => 'Ajouter une image';

  @override
  String get chatPickDocument => 'Ajouter un document';

  @override
  String get chatAddEmoji => 'Ajouter un emoji';

  @override
  String chatReplyingTo(String name) {
    return 'Réponse à $name';
  }

  @override
  String get chatCancelReply => 'Annuler la réponse';

  @override
  String get chatImageReadyToSend => 'Image prête à être envoyée';

  @override
  String get chatDocumentReadyToSend => 'Document prêt à être envoyé';

  @override
  String get chatRemoveAttachment => 'Retirer la pièce jointe';

  @override
  String get chatJustNow => 'à l\'instant';

  @override
  String chatMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'il y a $minutes min',
      one: 'il y a 1 min',
    );
    return '$_temp0';
  }

  @override
  String chatHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'il y a $hours h',
      one: 'il y a 1 h',
    );
    return '$_temp0';
  }

  @override
  String get chatYesterday => 'hier';

  @override
  String chatDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'il y a $days jours',
      one: 'il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileDescription =>
      'Gérez les informations affichées pour votre compte.';

  @override
  String get profileProviderEmail => 'E-mail';

  @override
  String get profileProviderPhone => 'Téléphone';

  @override
  String get profileProviderAnonymous => 'Anonyme';

  @override
  String get profileEmailVerified => 'E-mail vérifié';

  @override
  String get profileEmailNotVerified => 'E-mail non vérifié';

  @override
  String get profileAvatarHint =>
      'Touchez l\'avatar pour choisir une nouvelle image de profil.';

  @override
  String get profileEmailReadOnlyHint =>
      'L\'e-mail ne peut pas être modifié depuis cette page.';

  @override
  String get profileFullNameRequired => 'Le nom complet est obligatoire.';

  @override
  String get profileFullNameMinLength =>
      'Le nom complet doit contenir au moins 2 caractères.';

  @override
  String get profileFullNameMaxLength =>
      'Le nom complet doit contenir au maximum 80 caractères.';

  @override
  String get profileNoChangesTitle => 'Aucune modification détectée';

  @override
  String get profileNoChangesMessage =>
      'Modifiez au moins un champ avant d\'enregistrer votre profil.';

  @override
  String get profileDuplicateIdentityError =>
      'Un autre utilisateur existe déjà avec le même nom et la même adresse e-mail.';

  @override
  String get profileSaveFallbackError =>
      'Nous ne pouvons pas enregistrer votre profil pour le moment. Veuillez réessayer.';

  @override
  String get profileSaveSuccessTitle => 'Profil mis à jour';

  @override
  String get profileSaveSuccessMessage =>
      'Les informations de votre profil ont été enregistrées avec succès.';

  @override
  String get profileTwoFactorTitle => 'Authentification à deux facteurs';

  @override
  String get profileTwoFactorEnabledDescription =>
      'Votre compte nécessite une deuxième étape de vérification lors de la connexion.';

  @override
  String get profileTwoFactorDisabledDescription =>
      'Ajoutez une application d\'authentification pour une protection supplémentaire.';

  @override
  String get profileTwoFactorPhoneUnsupported =>
      'L\'authentification à deux facteurs n\'est pas disponible pour les comptes uniquement par téléphone.';

  @override
  String get profileTwoFactorVerifyEmailFirst =>
      'Vérifiez d\'abord votre adresse e-mail. Ensuite, appuyez sur \"J\'ai vérifié mon e-mail\" et vous verrez la configuration TOTP avec la clé secrète, le QR code et la première étape de vérification.';

  @override
  String get profileTwoFactorVerifiedAction => 'J\'ai vérifié mon e-mail';

  @override
  String get profileTwoFactorResendEmailAction =>
      'Renvoyer l\'e-mail de vérification';

  @override
  String get profileTwoFactorPendingSetup =>
      'Demande d\'inscription détectée. Terminez la configuration de votre application d\'authentification.';

  @override
  String get profileTwoFactorAddMethod => 'Ajouter une autre méthode';

  @override
  String get profileTwoFactorCompleteSetup => 'Terminer la configuration';

  @override
  String get profileTwoFactorEnableAction => 'Activer la 2FA';

  @override
  String get profileTwoFactorEnabledSuccessTitle => '2FA activée';

  @override
  String get profileTwoFactorEnabledSuccessMessage =>
      'L\'authentification à deux facteurs a été activée avec succès.';

  @override
  String get profileTwoFactorEmailVerifiedTitle => 'E-mail vérifié';

  @override
  String get profileTwoFactorEmailVerifiedMessage =>
      'Votre e-mail est vérifié. Vous pouvez maintenant activer la 2FA avec une application d\'authentification.';

  @override
  String get profileTwoFactorVerificationPendingTitle =>
      'Vérification en attente';

  @override
  String get profileTwoFactorVerificationPendingMessage =>
      'Votre e-mail apparaît encore comme non vérifié. Ouvrez le lien de vérification dans votre boîte mail, puis réessayez.';

  @override
  String get profileTwoFactorRefreshFailedTitle => 'Actualisation échouée';

  @override
  String get profileTwoFactorRefreshFailedMessage =>
      'Nous n\'avons pas pu actualiser votre statut de vérification pour le moment. Veuillez réessayer.';

  @override
  String get profileTwoFactorVerificationSentTitle =>
      'E-mail de vérification envoyé';

  @override
  String get profileTwoFactorVerificationSentMessage =>
      'Nous avons envoyé un nouvel e-mail de vérification. Ouvrez le lien reçu, puis appuyez sur \"J\'ai vérifié mon e-mail\".';

  @override
  String get profileTwoFactorSendFailedTitle =>
      'Impossible d\'envoyer l\'e-mail';

  @override
  String get profileTwoFactorSendFailedMessage =>
      'Nous n\'avons pas pu envoyer un nouvel e-mail de vérification pour le moment. Veuillez réessayer.';

  @override
  String get taskPageTitle => 'Tâches';

  @override
  String get taskPriorityLow => 'Faible';

  @override
  String get taskPriorityMedium => 'Moyenne';

  @override
  String get taskPriorityHigh => 'Élevée';

  @override
  String get taskStatusOpen => 'Ouvert';

  @override
  String get taskStatusInProgress => 'En cours';

  @override
  String get taskStatusBlocked => 'Bloqué';

  @override
  String get taskStatusDone => 'Terminé';

  @override
  String get taskStatusCanceled => 'Annulé';

  @override
  String get taskHeaderTitle => 'Tâches opérationnelles de l\'équipe';

  @override
  String get taskHeaderSubtitle =>
      'Organisez le travail opérationnel, les suivis et les actions issues du chat, des tours ou des besoins de l\'équipe.';

  @override
  String get taskNewTaskAction => 'Nouvelle tâche';

  @override
  String get taskNewTaskActionShort => 'Nouveau';

  @override
  String get taskSummaryTotal => 'Total';

  @override
  String get taskSummaryOpen => 'Ouvertes';

  @override
  String get taskSummaryDone => 'Terminées';

  @override
  String get taskTeamLabel => 'Équipe';

  @override
  String get taskSearchHint => 'Rechercher par titre, description ou assigné';

  @override
  String get taskFilterActive => 'Actives';

  @override
  String get taskFilterArchived => 'Archivées';

  @override
  String get taskFilterAll => 'Toutes';

  @override
  String get taskSelectTaskPrompt =>
      'Sélectionnez une tâche dans la liste pour voir ses détails.';

  @override
  String get taskViewModeList => 'Vue liste';

  @override
  String get taskViewModeTable => 'Vue tableau';

  @override
  String get taskViewModeTimeline => 'Vue chronologique';

  @override
  String get taskViewModeCalendar => 'Vue calendrier';

  @override
  String get taskTimelineEmptyState =>
      'Aucune tâche avec une date de début ou d\'échéance dans cette période.';

  @override
  String get taskNoTeamsAvailable =>
      'Aucune équipe disponible pour les tâches.';

  @override
  String get taskLoadTeamTasksError =>
      'Impossible de charger les tâches de l\'équipe.';

  @override
  String get taskLoadArchivedTasksError =>
      'Impossible de charger les tâches archivées.';

  @override
  String get taskCreatePermissionDenied =>
      'Seuls les propriétaires, administrateurs ou rôles avec permissions Admin/Manage peuvent créer des tâches.';

  @override
  String get taskCreateSuccess => 'Tâche créée avec succès.';

  @override
  String get taskUpdateSuccess => 'Tâche mise à jour.';

  @override
  String get taskAssignedLabel => 'Assigné';

  @override
  String get taskArchivedLabel => 'Archivé';

  @override
  String get taskStartDateLabel => 'Date de début';

  @override
  String get taskStartAfterDueError =>
      'La date de début ne doit pas être postérieure à l\'échéance.';

  @override
  String get taskDueDateLabel => 'Échéance';

  @override
  String get taskDueDateNotSet => 'Non définie';

  @override
  String get taskNoDueDate => 'Aucune échéance';

  @override
  String get taskCreatedByLabel => 'Créé par';

  @override
  String get taskUpdatedLabel => 'Mis à jour';

  @override
  String get taskSourceChatMessage => 'Origine : message de chat';

  @override
  String get taskOpenLinkedConversation => 'Ouvrir la conversation liée';

  @override
  String get taskUpdateStatusLabel => 'Mettre à jour le statut';

  @override
  String get taskUpdateStatusError =>
      'Impossible de mettre à jour le statut de la tâche.';

  @override
  String get taskEditAction => 'Modifier la tâche';

  @override
  String get taskArchiveAction => 'Archiver la tâche';

  @override
  String get taskRestoreAction => 'Restaurer la tâche';

  @override
  String get taskArchiveSuccess => 'Tâche archivée.';

  @override
  String get taskArchiveError => 'Impossible d\'archiver la tâche.';

  @override
  String get taskRestoreSuccess => 'Tâche restaurée.';

  @override
  String get taskRestoreError => 'Impossible de restaurer la tâche.';

  @override
  String get taskDeletePermanentlyAction => 'Supprimer definitivement';

  @override
  String get taskDeletePermanentlyTitle =>
      'Supprimer definitivement la tache ?';

  @override
  String get taskDeletePermanentlyMessage =>
      'Cette action est irreversible. La tache sera definitivement supprimee du systeme.';

  @override
  String get taskDeletePermanentlySuccess => 'Tache supprimee definitivement.';

  @override
  String get taskDeletePermanentlyError => 'Impossible de supprimer la tache.';

  @override
  String get taskEmptyArchivedTitle => 'Aucune tâche archivée';

  @override
  String get taskEmptyActiveTitle => 'Aucune tâche active';

  @override
  String get taskEmptyArchivedSubtitle =>
      'Les tâches archivées de cette équipe apparaîtront ici.';

  @override
  String get taskEmptyActiveSubtitleManage =>
      'Il n\'y a pas encore de tâches actives pour cette équipe. Vous pouvez en créer une ici ou depuis le chat.';

  @override
  String get taskEmptyActiveSubtitleReadOnly =>
      'Il n\'y a actuellement aucune tâche active pour cette équipe.';

  @override
  String get taskSaveError =>
      'Impossible d\'enregistrer la tâche. Réessayez bientôt.';

  @override
  String get taskContextSectionTitle => 'Contexte';

  @override
  String get taskContextSectionSubtitle =>
      'Définissez l\'équipe et le contenu de la tâche.';

  @override
  String get taskSelectTeamError => 'Sélectionnez une équipe';

  @override
  String get taskTitleLabel => 'Titre';

  @override
  String get taskTitleRequiredError => 'Le titre est obligatoire';

  @override
  String get taskDescriptionLabel => 'Description';

  @override
  String get taskPlanningSectionTitle => 'Planification';

  @override
  String get taskPlanningSectionSubtitle =>
      'Définissez la priorité et l\'échéance.';

  @override
  String get taskPriorityLabel => 'Priorité';

  @override
  String get taskAssignmentSectionTitle => 'Attribution';

  @override
  String get taskAssignmentSectionSubtitle => 'Choisissez qui suit la tâche.';

  @override
  String get taskAssignToLabel => 'Assigner à';

  @override
  String get taskUnassignedOption => 'Non assigné';

  @override
  String get taskSourceChatBanner =>
      'Cette tâche conservera le lien vers le message de chat source.';

  @override
  String get taskSaveChangesAction => 'Enregistrer les modifications';

  @override
  String get taskCreateAction => 'Créer une tâche';

  @override
  String get taskCloseAction => 'Fermer';

  @override
  String get taskMyTasksTitle => 'Mes tâches';

  @override
  String get taskMyTasksSubtitle =>
      'Tâches qui vous sont assignées ou que vous avez créées, dans toutes les équipes, plus les tâches personnelles';

  @override
  String get taskPersonalToggleLabel => 'Tâche personnelle';

  @override
  String get taskPersonalToggleSubtitle =>
      'Non liée à une équipe — visible et gérable uniquement par vous';

  @override
  String get eventPageTitle => 'Événements';

  @override
  String get eventNavShowcaseDescription =>
      'Gérez ici les événements de calendrier hors shift, comme les réunions ou moments partagés de l\'équipe.';

  @override
  String get eventHeaderTitle => 'Événements du calendrier';

  @override
  String get eventHeaderSubtitle =>
      'Rendez-vous, réunions et moments partagés de l\'équipe, séparés des tâches et des shifts.';

  @override
  String get eventMyEventsTitle => 'Mes événements';

  @override
  String get eventMyEventsSubtitle =>
      'Événements que vous avez créés ou auxquels vous avez été ajouté, dans toutes les équipes';

  @override
  String get eventActiveFilterLabel => 'Actifs';

  @override
  String get eventArchivedFilterLabel => 'Archivés';

  @override
  String get eventNewEventAction => 'Nouvel événement';

  @override
  String get eventEditEventTitle => 'Modifier l\'événement';

  @override
  String get eventTitleLabel => 'Titre';

  @override
  String get eventDescriptionLabel => 'Description';

  @override
  String get eventAllDayLabel => 'Toute la journée';

  @override
  String eventStartLabel(Object value) {
    return 'Début : $value';
  }

  @override
  String eventEndLabel(Object value) {
    return 'Fin : $value';
  }

  @override
  String get eventEndNotSet => 'Fin non définie';

  @override
  String get eventRemoveEndAction => 'Supprimer la fin';

  @override
  String get eventLocationLabel => 'Lieu';

  @override
  String get eventCreatedByLabel => 'Créé par';

  @override
  String get eventScheduleLabel => 'Quand';

  @override
  String get eventParticipantsLabel => 'Participants';

  @override
  String get eventParticipantsEmptyTeam =>
      'Cette équipe n\'a pas encore d\'autres membres à ajouter.';

  @override
  String get eventTitleRequiredError => 'Le titre est obligatoire.';

  @override
  String get eventNoParticipants => 'Aucun participant indiqué';

  @override
  String get eventChipLabel => 'Événement';

  @override
  String get eventScheduleAllDaySuffix => 'toute la journée';

  @override
  String eventSourceLabel(Object source) {
    return 'Source : $source';
  }

  @override
  String get eventEditAction => 'Modifier';

  @override
  String get eventRestoreAction => 'Restaurer';

  @override
  String get eventArchiveAction => 'Archiver';

  @override
  String get eventDeleteAction => 'Supprimer';

  @override
  String get deleteEventTitle => 'Supprimer l\'evenement';

  @override
  String get deleteEventMessage =>
      'Voulez-vous vraiment supprimer definitivement cet evenement ? Cette action est irreversible.';

  @override
  String get eventEmptyArchivedTitle => 'Aucun événement archivé';

  @override
  String get eventEmptyActiveTitle => 'Aucun événement actif';

  @override
  String get eventEmptyArchivedSubtitle =>
      'Les événements archivés apparaîtront ici.';

  @override
  String get eventEmptyActiveSubtitle =>
      'Utilisez cette section pour les réunions, rendez-vous ou moments partagés non liés aux shifts.';

  @override
  String get eventMyEventsEmptyTitle => 'Aucun événement pour l\'instant';

  @override
  String get eventMyEventsEmptySubtitle =>
      'Les événements que vous créez ou auxquels vous êtes ajouté comme participant, dans n\'importe quelle équipe, apparaîtront ici.';

  @override
  String get eventCreateSuccess => 'Événement créé.';

  @override
  String get eventUpdateSuccess => 'Événement mis à jour.';

  @override
  String eventSaveError(Object error) {
    return 'Impossible d\'enregistrer l\'événement : $error';
  }

  @override
  String get eventRestoreSuccess => 'Événement restauré.';

  @override
  String get eventArchiveSuccess => 'Événement archivé.';

  @override
  String eventOperationFailedError(Object error) {
    return 'L\'opération a échoué : $error';
  }

  @override
  String get eventDeletePermanentlySuccess =>
      'Événement définitivement supprimé.';

  @override
  String eventDeleteError(Object error) {
    return 'Impossible de supprimer l\'événement : $error';
  }

  @override
  String eventLoadError(Object error) {
    return 'Impossible de charger les événements : $error';
  }

  @override
  String eventLoadArchivedError(Object error) {
    return 'Impossible de charger les archivés : $error';
  }

  @override
  String get eventViewModeCard => 'Vue en cartes';

  @override
  String get eventViewModeCalendar => 'Vue calendrier';

  @override
  String get eventCalendarDayLabel => 'Jour';

  @override
  String get eventCalendarWeekLabel => 'Semaine';

  @override
  String get eventCalendarMonthLabel => 'Mois';

  @override
  String eventCalendarMoreLabel(Object count) {
    return '+$count autres';
  }

  @override
  String get eventPersonalEventNotice =>
      'Ceci est un événement personnel — visible uniquement par vous.';

  @override
  String get eventCalendarPeriodLabel => 'Periode';

  @override
  String get eventCalendarPickPeriodHint =>
      'Choisissez une periode a afficher.';

  @override
  String get eventCalendarEditPeriodLabel => 'Modifier';

  @override
  String get tutorialChatHeaderTitle => 'En-tête de la conversation';

  @override
  String get tutorialChatHeaderMobileDescription =>
      'Vérifiez ici quelle conversation est ouverte et revenez rapidement à la liste des conversations.';

  @override
  String get tutorialChatMessagesTitle => 'Messages';

  @override
  String get tutorialChatMessagesMobileDescription =>
      'Parcourez ici les messages, les réactions et les pièces jointes dans l\'ordre chronologique.';

  @override
  String get tutorialChatWriteMessageTitle => 'Écrire un message';

  @override
  String get tutorialChatComposerMobileDescription =>
      'Utilisez cette zone pour écrire, joindre des fichiers ou des images et envoyer rapidement un nouveau message.';

  @override
  String get tutorialChatOverviewTitle => 'Vue d\'ensemble des conversations';

  @override
  String get tutorialChatOverviewMobileDescription =>
      'Commencez ici pour choisir rapidement une conversation parmi les canaux d\'équipe et les conversations privées.';

  @override
  String get tutorialChatTeamChannelsTitle => 'Canaux d\'équipe';

  @override
  String get tutorialChatTeamChannelsMobileDescription =>
      'Cette section regroupe les conversations partagées de vos équipes, avec leur statut et un aperçu des messages récents.';

  @override
  String get tutorialChatDirectChatsTitle => 'Conversations privées';

  @override
  String get tutorialChatDirectChatsMobileDescription =>
      'Retrouvez ici les conversations privées déjà entamées avec les membres de vos équipes.';

  @override
  String get tutorialChatHeaderWebDescription =>
      'Cet en-tête indique la conversation ouverte et permet de revenir rapidement à la liste des conversations.';

  @override
  String get tutorialChatTimelineTitle => 'Historique des messages';

  @override
  String get tutorialChatTimelineWebDescription =>
      'Parcourez la conversation ici, consultez les réactions et ouvrez les pièces jointes partagées.';

  @override
  String get tutorialChatComposerTitle => 'Zone de rédaction';

  @override
  String get tutorialChatComposerWebDescription =>
      'Depuis cette zone, vous pouvez écrire, joindre des documents ou des images et envoyer un nouveau message.';

  @override
  String get tutorialChatOverviewWebDescription =>
      'Commencez ici pour choisir une conversation d\'équipe ou rouvrir une conversation privée existante.';

  @override
  String get tutorialChatTeamChannelsWebDescription =>
      'Ces cartes présentent les canaux partagés de vos équipes, avec un résumé et un accès rapide à chaque conversation.';

  @override
  String get tutorialChatDirectChatsWebDescription =>
      'Retrouvez ici les conversations privées déjà entamées avec d\'autres membres de l\'équipe.';

  @override
  String get tutorialClockingStatusTitle => 'Statut actuel';

  @override
  String get tutorialClockingStatusDescription =>
      'Cette section vous donne un aperçu immédiat de votre statut de pointage et des principales informations de la journée.';

  @override
  String get tutorialClockingActionsTitle => 'Actions de pointage';

  @override
  String get tutorialClockingActionsDescription =>
      'Utilisez cette zone pour choisir l\'équipe concernée et enregistrer votre entrée ou votre sortie.';

  @override
  String get tutorialClockingHistoryTitle => 'Historique des pointages';

  @override
  String get tutorialClockingHistoryDescription =>
      'Consultez ici les changements de statut et l\'historique, y compris les enregistrements filtrés par équipe sélectionnée.';

  @override
  String get tutorialClockingOverviewTitle => 'Vue d\'ensemble des pointages';

  @override
  String get tutorialClockingOverviewDescription =>
      'Cet en-tête présente l\'espace de pointage et sa fonction principale.';

  @override
  String get tutorialEventFilterTitle => 'Filtrer les événements';

  @override
  String get tutorialEventFilterDescription =>
      'Passez des événements actifs aux événements archivés en un geste.';

  @override
  String get tutorialEventListTitle => 'Liste des événements';

  @override
  String get tutorialEventListDescription =>
      'Vos événements en vue liste ou calendrier : touchez une carte pour en consulter les détails.';

  @override
  String get tutorialEventCreateTitle => 'Nouvel événement';

  @override
  String get tutorialEventCreateDescription =>
      'Créez rapidement un événement autre qu\'un quart de travail, par exemple une réunion.';

  @override
  String get tutorialShiftCalendarArchiveTitle => 'Calendrier et archives';

  @override
  String get tutorialShiftCalendarArchiveMobileDescription =>
      'Utilisez ce sélecteur pour passer du calendrier actif aux archives des quarts masqués.';

  @override
  String get tutorialShiftArchiveTitle => 'Archives des quarts';

  @override
  String get tutorialShiftCalendarTitle => 'Calendrier des quarts';

  @override
  String get tutorialShiftArchiveMobileDescription =>
      'Cette vue présente les quarts archivés et permet de les restaurer si nécessaire.';

  @override
  String get tutorialShiftCalendarMobileDescription =>
      'Touchez un jour pour créer ou modifier les quarts de cette date.';

  @override
  String get tutorialShiftCalendarArchiveWebDescription =>
      'Utilisez ce sélecteur pour passer de la vue calendrier à la vue des quarts archivés.';

  @override
  String get tutorialShiftCalendarViewTitle => 'Vue calendrier';

  @override
  String get tutorialShiftArchiveWebDescription =>
      'Retrouvez ici les quarts archivés et restaurez-les si nécessaire.';

  @override
  String get tutorialShiftCalendarWebDescription =>
      'Sélectionnez un jour du calendrier pour créer ou modifier des quarts.';

  @override
  String get tutorialShiftProfilesTitle => 'Profils de quart';

  @override
  String get tutorialShiftProfilesDescription =>
      'Utilisez ce panneau latéral pour créer et réutiliser des profils de quart prédéfinis.';

  @override
  String get tutorialSurveyOverviewTitle => 'Vue d\'ensemble des sondages';

  @override
  String get tutorialSurveyOverviewDescription =>
      'Cet en-tête présente le fil en un coup d\'œil et permet d\'actualiser les données des sondages.';

  @override
  String get tutorialSurveySearchHint =>
      'Rechercher un sondage, une équipe ou une option';

  @override
  String get tutorialSurveyQuickStatsTitle => 'Statistiques rapides';

  @override
  String get tutorialSurveyQuickStatsDescription =>
      'Consultez le nombre de sondages en brouillon, actifs et clôturés actuellement présents dans le fil.';

  @override
  String get tutorialSurveyListTitle => 'Liste des sondages';

  @override
  String get tutorialSurveyListMobileDescription =>
      'Utilisez cette liste pour ouvrir, modifier ou supprimer vos sondages ou ceux de vos équipes.';

  @override
  String get tutorialSurveyFeedTitle => 'Fil des sondages';

  @override
  String get tutorialSurveyFeedDescription =>
      'Utilisez cette section pour consulter le fil des sondages, l\'actualiser et ouvrir la page de création.';

  @override
  String get tutorialSurveyFeedStatsTitle => 'Statistiques du fil';

  @override
  String get tutorialSurveyFeedStatsDescription =>
      'Ces indicateurs résument les sondages en brouillon, actifs et clôturés de votre fil.';

  @override
  String get tutorialSurveyListWebDescription =>
      'Voici la zone principale du fil : ouvrez, modifiez ou supprimez des sondages depuis cet espace.';

  @override
  String get tutorialTaskFilterTitle => 'Filtrer les tâches';

  @override
  String get tutorialTaskFilterDescription =>
      'Filtrez les tâches par statut ou passez à la vue des archives.';

  @override
  String get tutorialTaskListTitle => 'Liste des tâches';

  @override
  String get tutorialTaskListDescription =>
      'Retrouvez toutes vos tâches ici : touchez une carte pour ouvrir ses détails et la gérer.';

  @override
  String get tutorialTaskCreateTitle => 'Nouvelle tâche';

  @override
  String get tutorialTaskCreateDescription =>
      'Créez rapidement une nouvelle tâche personnelle ou d\'équipe.';

  @override
  String get tutorialTeamNameDescriptionTitle => 'Nom et description';

  @override
  String get tutorialTeamNameMobileDescription =>
      'Commencez par donner à l\'équipe un nom clair et, si nécessaire, une courte description pour que chacun comprenne son objectif.';

  @override
  String get tutorialTeamColorTitle => 'Couleur de l\'équipe';

  @override
  String get tutorialTeamColorMobileDescription =>
      'Choisissez la couleur qui permettra de reconnaître facilement cette équipe dans toute l\'application.';

  @override
  String get tutorialTeamMembersTitle => 'Membres de l\'équipe';

  @override
  String get tutorialTeamMembersMobileDescription =>
      'Utilisez cette section pour choisir les membres de l\'équipe et préparer les invitations avant sa création.';

  @override
  String get tutorialTeamCreateTitle => 'Créer l\'équipe';

  @override
  String get tutorialTeamCreateMobileDescription =>
      'Une fois le nom, la couleur et les membres définis, utilisez ce bouton pour créer l\'équipe et envoyer les invitations éventuelles.';

  @override
  String get tutorialTeamListTitle => 'Liste des équipes';

  @override
  String get tutorialTeamListDescription =>
      'Cette section contient toutes vos équipes. Touchez une équipe pour ouvrir ses détails et la gérer.';

  @override
  String get tutorialTeamLayoutTitle => 'Affichage des équipes';

  @override
  String get tutorialTeamLayoutDescription =>
      'Passez ici de la grille à la liste selon que vous préférez une vue d\'ensemble visuelle ou une liste plus compacte.';

  @override
  String get tutorialTeamNewTitle => 'Nouvelle équipe';

  @override
  String get tutorialTeamNewDescription =>
      'Ouvrez ici la page de création pour configurer une nouvelle équipe avec son nom, sa couleur et ses membres.';

  @override
  String get tutorialTeamListLayoutTitle => 'Disposition de la liste';

  @override
  String get tutorialTeamListLayoutDescription =>
      'Modifiez ici l\'affichage des équipes en choisissant une disposition en grille ou en liste.';

  @override
  String get tutorialTeamAreaTitle => 'Espace des équipes';

  @override
  String get tutorialTeamAreaDescription =>
      'Cet espace contient toutes les équipes disponibles. Cliquez sur une carte pour ouvrir les détails de l\'équipe sélectionnée.';

  @override
  String get tutorialTeamNameWebDescription =>
      'Utilisez cette section pour définir l\'identité de la nouvelle équipe avec un nom clair et une courte description.';

  @override
  String get tutorialTeamColorWebTitle => 'Couleur';

  @override
  String get tutorialTeamColorWebDescription =>
      'Choisissez une couleur distinctive pour reconnaître plus facilement l\'équipe dans toute l\'application.';

  @override
  String get tutorialTeamMembersWebTitle => 'Membres';

  @override
  String get tutorialTeamMembersWebDescription =>
      'Ajoutez ici les personnes à inviter pour préparer l\'équipe avant l\'enregistrement final.';

  @override
  String get tutorialTeamCreateWebTitle => 'Création de l\'équipe';

  @override
  String get tutorialTeamCreateWebDescription =>
      'Une fois tout prêt, utilisez ce bouton pour créer l\'équipe et envoyer les invitations préparées.';

  @override
  String get tutorialNavigationTeamsMobileDescription =>
      'Explorez les équipes, ouvrez leurs détails et gérez la collaboration depuis cet espace.';

  @override
  String get tutorialNavigationPlanningDescription =>
      'Retrouvez ici les quarts, les tâches, les événements et les pointages : tout ce qu\'il vous faut pour planifier et suivre votre journée de travail.';

  @override
  String get tutorialNavigationSurveysMobileDescription =>
      'Consultez ici les sondages disponibles et suivez leur progression.';

  @override
  String get tutorialNavigationHomeMobileDescription =>
      'Cet écran vous donne un aperçu rapide des informations les plus importantes.';

  @override
  String get tutorialNavigationTitle => 'Navigation';

  @override
  String get tutorialNavigationBarDescription =>
      'Utilisez la barre inférieure pour passer rapidement d\'une section principale de l\'application à une autre.';

  @override
  String get tutorialSettingsProfileTitle => 'Profil';

  @override
  String get tutorialSettingsProfileMobileDescription =>
      'Touchez cette carte pour ouvrir votre profil et modifier les informations de votre compte.';

  @override
  String get tutorialSettingsPreferencesDescription =>
      'Personnalisez ici le thème, la langue et les notifications selon vos préférences.';

  @override
  String get tutorialSettingsSupportTitle => 'Confidentialité et assistance';

  @override
  String get tutorialSettingsSupportDescription =>
      'Cette section regroupe les informations sur la confidentialité, les contacts et les options d\'assistance.';

  @override
  String get tutorialNavigationSidebarDescription =>
      'Utilisez cette barre latérale pour passer rapidement d\'un espace principal de l\'application à un autre.';

  @override
  String get tutorialNavigationNotificationsDescription =>
      'Retrouvez ici vos dernières alertes, invitations et mises à jour sans quitter la page actuelle.';

  @override
  String get tutorialNavigationTeamsWebDescription =>
      'Gérez les équipes, les membres et les principales actions de collaboration depuis cet espace.';

  @override
  String get tutorialNavigationClockingDescription =>
      'Utilisez cette section pour enregistrer rapidement les entrées, les sorties et les pauses.';

  @override
  String get tutorialNavigationSurveysWebDescription =>
      'Retrouvez ici les sondages, ouvrez-les et suivez facilement leur statut.';

  @override
  String get tutorialNavigationShiftsDescription =>
      'Cette page regroupe vos quarts et les informations pratiques associées.';

  @override
  String get tutorialNavigationTasksDescription =>
      'Suivez ici les tâches de l\'équipe avec leur statut, leur priorité et leur attribution.';

  @override
  String get tutorialNavigationChatDescription =>
      'Suivez ici la conversation de l\'équipe et envoyez des messages en temps réel.';

  @override
  String get tutorialNavigationHomeWebDescription =>
      'Le tableau de bord présente les informations essentielles de votre espace de travail.';

  @override
  String get tutorialSettingsProfileWebDescription =>
      'Ouvrez votre profil ici pour mettre à jour les principales informations de votre compte.';

  @override
  String get tutorialSettingsMenuTitle => 'Menu des paramètres';

  @override
  String get tutorialSettingsMenuDescription =>
      'Utilisez cette colonne pour passer rapidement entre la langue, les notifications, la confidentialité et l\'assistance.';

  @override
  String get tutorialSettingsAccountProfileTitle => 'Profil du compte';

  @override
  String get tutorialSettingsNotificationsDescription =>
      'Choisissez ici comment recevoir les mises à jour et les alertes importantes.';

  @override
  String get tutorialSettingsContactDescription =>
      'Cet espace regroupe les moyens utiles pour contacter l\'assistance.';

  @override
  String get tutorialSettingsPrivacyDescription =>
      'Consultez dans cette section les informations sur la confidentialité et la protection des données.';

  @override
  String get tutorialSettingsAccountDescription =>
      'Mettez à jour ici votre profil, votre sécurité et vos préférences personnelles.';

  @override
  String get tutorialSettingsLanguageDescription =>
      'Choisissez la langue dans laquelle vous préférez utiliser l\'application.';

  @override
  String get tutorialHomeWelcomeTitle => 'Bienvenue sur votre tableau de bord';

  @override
  String get tutorialHomeWelcomeDescription =>
      'Cette section supérieure présente le contexte de la journée et un premier aperçu de votre espace de travail.';

  @override
  String get tutorialHomeStatsTitle => 'Statistiques clés';

  @override
  String get tutorialHomeStatsDescription =>
      'Ces cartes résument en un coup d\'œil vos équipes actives, membres, sondages, pointages et quarts du jour.';

  @override
  String get tutorialHomeNotificationsTitle => 'Notifications en attente';

  @override
  String get tutorialHomeNotificationsDescription =>
      'Cette section contient les invitations, demandes et notifications qui nécessitent encore votre attention.';

  @override
  String get tutorialHomeQuickActionsTitle => 'Actions rapides';

  @override
  String get tutorialHomeQuickActionsDescription =>
      'Utilisez ces raccourcis pour accéder directement aux espaces principaux et lancer rapidement une action.';

  @override
  String get tutorialHomeActivityTitle => 'Activité récente';

  @override
  String get tutorialHomeActivityDescription =>
      'Cette liste permet de suivre l\'activité récente des équipes, des quarts, des pointages et des sondages.';
}
