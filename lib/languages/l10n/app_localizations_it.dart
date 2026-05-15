// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get login => 'Accesso';

  @override
  String get logout => 'disconnessione';

  @override
  String get register => 'Registrati';

  @override
  String get gladYouAreBack => 'Siamo felici di riaverti.!';

  @override
  String get welcomeBack => 'Bentornato.!';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Password dimenticata';

  @override
  String get deleteAccount => 'Disattiva account';

  @override
  String get accountDeletionDialogMessage =>
      'Inserisci l\'email dell\'account che vuoi disattivare. Ti invieremo un link di conferma prima di bloccarlo.';

  @override
  String get sendConfirmationEmail => 'Invia email di conferma';

  @override
  String get accountDeletionRequestSentTitle => 'Controlla la tua email';

  @override
  String get accountDeletionRequestSentMessage =>
      'Se esiste un account con questa email, abbiamo inviato un link di conferma per completare la disattivazione.';

  @override
  String get accountDeletionRequestFailedTitle =>
      'Impossibile avviare la disattivazione';

  @override
  String get accountDeletionRequestFailedMessage =>
      'Non siamo riusciti a inviare l\'email di conferma della disattivazione. Riprova tra poco.';

  @override
  String get accountDeletionOpenEmailTitle => 'Apri l\'email di disattivazione';

  @override
  String get accountDeletionOpenEmailMessage =>
      'Usa il link di conferma ricevuto via email per completare la disattivazione dell\'account.';

  @override
  String get accountDeletionConfirmedTitle => 'Account disattivato';

  @override
  String get accountDeletionConfirmedMessage =>
      'Il tuo account è stato disattivato con successo. Ora puoi chiudere questa pagina.';

  @override
  String get accountDeletionFailedTitle => 'Disattivazione non disponibile';

  @override
  String get accountDeletionFailedMessage =>
      'Non siamo riusciti a confermare questo link di disattivazione. Richiedi una nuova email e riprova.';

  @override
  String get accountDeletionLoadingTitle => 'Conferma disattivazione';

  @override
  String get accountDeletionLoadingMessage =>
      'Stiamo verificando il link di disattivazione del tuo account...';

  @override
  String get reactivateAccount => 'Riattiva account';

  @override
  String get accountReactivationDialogMessage =>
      'Inserisci l\'email dell\'account che vuoi riattivare. Ti invieremo un link di conferma prima di ripristinare l\'accesso.';

  @override
  String get accountReactivationRequestSentTitle => 'Controlla la tua email';

  @override
  String get accountReactivationRequestSentMessage =>
      'Se esiste un account con questa email, abbiamo inviato un link di conferma per completare la riattivazione.';

  @override
  String get accountReactivationRequestFailedTitle =>
      'Impossibile avviare la riattivazione';

  @override
  String get accountReactivationRequestFailedMessage =>
      'Non siamo riusciti a inviare l\'email di conferma della riattivazione. Riprova tra poco.';

  @override
  String get accountReactivationOpenEmailTitle =>
      'Apri l\'email di riattivazione';

  @override
  String get accountReactivationOpenEmailMessage =>
      'Usa il link di conferma ricevuto via email per ripristinare l\'accesso al tuo account.';

  @override
  String get accountReactivationConfirmedTitle => 'Account riattivato';

  @override
  String get accountReactivationConfirmedMessage =>
      'Il tuo account è di nuovo attivo. Ora puoi accedere.';

  @override
  String get accountReactivationFailedTitle => 'Riattivazione non disponibile';

  @override
  String get accountReactivationFailedMessage =>
      'Non siamo riusciti a confermare questo link di riattivazione. Richiedi una nuova email e riprova.';

  @override
  String get accountReactivationLoadingTitle => 'Conferma riattivazione';

  @override
  String get accountReactivationLoadingMessage =>
      'Stiamo verificando il link di riattivazione del tuo account...';

  @override
  String get backToLogin => 'Torna al login';

  @override
  String get tryAgain => 'Riprova';

  @override
  String get reviewTutorial => 'Rivedi tutorial';

  @override
  String get tutorialPrevious => 'Indietro';

  @override
  String get tutorialNext => 'Avanti';

  @override
  String get tutorialSkip => 'Salta';

  @override
  String get webMobileAppOnlyTitle => 'Scarica l\'app mobile';

  @override
  String get webMobileAppOnlyMessage =>
      'Questa esperienza web è disponibile solo su schermi più grandi. Sui telefoni con larghezza inferiore a 576px, continua dall\'app mobile.';

  @override
  String get webMobileAppOnlyHint =>
      'Apri Note Sondage da tablet o desktop, oppure installa l\'app dal tuo store.';

  @override
  String get downloadOnAppStore => 'Scarica su App Store';

  @override
  String get getItOnGooglePlay => 'Scarica da Google Play';

  @override
  String get mobileStoreLinksUnavailable =>
      'I link agli store non sono ancora configurati. Contatta il supporto oppure apri l\'app da uno schermo più grande.';

  @override
  String get continueWithGoogle => 'Continua con Google';

  @override
  String get justSomeInfoToGetStarted =>
      'Solo alcune informazioni per iniziare';

  @override
  String get fullName => 'Nome completo';

  @override
  String get confirmPassword => 'Conferma password';

  @override
  String get pleaseEnterYourEmail => 'Per favore, inserisci la tua email';

  @override
  String get resetPassword => 'Reimposta password';

  @override
  String get donthaveAnAccount => 'Non hai un account? Registrati';

  @override
  String get signup => 'Iscrizione';

  @override
  String get home => 'Home';

  @override
  String get about => 'Chi siamo';

  @override
  String get team => 'Team';

  @override
  String get settings => 'Impostazioni';

  @override
  String get attendance => 'Frequenza';

  @override
  String get clockingInOut => 'Timbratura';

  @override
  String get explorer => 'esploratore';

  @override
  String get sondage => 'Sondaggio';

  @override
  String get selectedTeam => 'Seleziona squadra';

  @override
  String get createTeam => 'Creare squadra';

  @override
  String get teamMember => 'Membri della squadra';

  @override
  String member(num membersCount) {
    String _temp0 = intl.Intl.pluralLogic(
      membersCount,
      locale: localeName,
      other: '$membersCount membri',
      one: '1 membro',
    );
    return '$_temp0';
  }

  @override
  String get createNewTeam => 'Crea una nuova squadra';

  @override
  String get teamName => 'Nome della squadra';

  @override
  String get teamDescription => 'Descrizione del team';

  @override
  String get role => 'Ruolo';

  @override
  String get permission => 'Permesso';

  @override
  String get status => 'Stato';

  @override
  String get selectedTeamcolor => 'Seleziona il colore della squadra';

  @override
  String get roleManager => 'gestione dei ruoli';

  @override
  String get permissionManager => 'gestione dei permessi';

  @override
  String get grantList => 'List dei permessi';

  @override
  String get createGrant => 'Creare un permesso';

  @override
  String get roleList => 'Lista dei ruoli';

  @override
  String get createRole => 'Crea un ruolo';

  @override
  String get permissionName => 'Nome della Permissione';

  @override
  String get permissionDescription => 'Descrizione della permissione';

  @override
  String get save => 'Salvare';

  @override
  String get editRoleManager => 'Modifica permesso';

  @override
  String get roleName => 'Nome del ruolo';

  @override
  String get roleDescription => 'Descrizione del ruolo';

  @override
  String get selectedPermission => 'Selezionare la Permissione';

  @override
  String get editTeam => 'Modificare squadra';

  @override
  String get teamDetails => 'Dettagli squadra';

  @override
  String get language => 'Lingua';

  @override
  String get notification => 'Notification';

  @override
  String get contactUs => 'Contattaci';

  @override
  String get privacy => 'Privacy';

  @override
  String get askQuestion => 'Fai una domanda';

  @override
  String get options => 'Opzioni';

  @override
  String get option => 'Opzione';

  @override
  String get allowMultipleResponses => 'Consenti più risposte';

  @override
  String get makeResponsesAnonymous => 'Rendi anonimi le risposte';

  @override
  String get selectTeam => 'Seleziona squadra';

  @override
  String get teamLabel => 'Squadra:';

  @override
  String get surveyCreatedSuccessfully => 'Sondaggio creato con successo!';

  @override
  String get create => 'Crea';

  @override
  String get responses => 'risposte';

  @override
  String get questions => 'domande';

  @override
  String get system => 'Sistema';

  @override
  String get dark => 'Scuro';

  @override
  String get light => 'Chiaro';

  @override
  String get preferences => 'Preferenze';

  @override
  String get manageYourPrivacySettings =>
      'Gestisci le tue impostazioni sulla privacy';

  @override
  String get getInTouchWithOurSupportTeam =>
      'Mettiti in contatto con il nostro team di supporto';

  @override
  String get themeTitle => 'Tema';

  @override
  String get languageTitle => 'Lingua';

  @override
  String get lightMode => 'Modalità Chiara';

  @override
  String get darkMode => 'Modalità Scura';

  @override
  String get systemDefault => 'Predefinito del Sistema';

  @override
  String get defaultLightTheme => 'Tema chiaro predefinito';

  @override
  String get darkThemeForLowLight => 'Tema scuro per poca luce';

  @override
  String get followSystemSettings => 'Segui le impostazioni di sistema';

  @override
  String get selectYourLanguage => 'Seleziona la tua lingua';

  @override
  String get settingsNotification => 'Impostazioni Notifiche';

  @override
  String get notificationsSettingsIntro =>
      'Scegli come ricevere aggiornamenti e promemoria dei turni.';

  @override
  String get notificationsGeneral => 'Generale';

  @override
  String get emailNotifications => 'Notifiche email';

  @override
  String get receiveUpdatesByEmail => 'Ricevi aggiornamenti via email';

  @override
  String get pushNotifications => 'Notifiche push';

  @override
  String get receivePushNotificationsOnYourDevice =>
      'Ricevi notifiche push sul tuo dispositivo';

  @override
  String get shiftReminders => 'Promemoria turni';

  @override
  String get reminderMode => 'Modalità promemoria';

  @override
  String get notificationReminderModeDescription =>
      'Scegli in ogni turno se vuoi una notifica standard o un allarme più forte.';

  @override
  String get webBehavior => 'Comportamento web';

  @override
  String get alarmBehaviorOnWeb =>
      'Sul web, la modalità Allarme usa le notifiche del browser. La scheda deve restare aperta e il browser controlla il comportamento finale di suono e vibrazione.';

  @override
  String get howItWorks => 'Come funziona';

  @override
  String get notificationAndAlarmDifference =>
      'La notifica mostra un promemoria normale. L\'allarme usa le impostazioni qui sotto ed è pensato per avvisi turno più evidenti.';

  @override
  String get alarmDelivery => 'Consegna allarme';

  @override
  String get alarmStyle => 'Stile allarme';

  @override
  String get webAlarmDeliveryDescription =>
      'Le notifiche del browser vengono usate mentre questa scheda resta aperta. Suono e vibrazione sono gestiti dal browser e dal sistema operativo.';

  @override
  String get alarmStyleDescription =>
      'Scegli se la modalità Allarme deve vibrare o riprodurre una suoneria. Predefinito: vibrazione.';

  @override
  String get alarmStyleDescriptionIos =>
      'Su iPhone, la modalità Allarme usa una suoneria. Gli allarmi solo vibrazione non sono disponibili per le notifiche locali.';

  @override
  String get vibrate => 'Vibrazione';

  @override
  String get ringtone => 'Suoneria';

  @override
  String get browserNotification => 'Notifica browser';

  @override
  String get notificationVisibility => 'Visibilità notifica';

  @override
  String get alarmDuration => 'Durata allarme';

  @override
  String get webNotificationVisibilityDescription =>
      'Controlla per quanto tempo la notifica browser resta visibile dopo la comparsa.';

  @override
  String get alarmDurationAppliesOnlyToAlarmMode =>
      'Questa durata si applica solo quando un turno usa la modalità Allarme.';

  @override
  String get activity => 'Attività';

  @override
  String get surveyReminders => 'Promemoria sondaggi';

  @override
  String get getRemindedAboutPendingSurveys =>
      'Ricevi promemoria sui sondaggi in attesa';

  @override
  String get teamUpdates => 'Aggiornamenti team';

  @override
  String get notificationsAboutTeamChanges =>
      'Notifiche sui cambiamenti del team';

  @override
  String get clockingAlerts => 'Avvisi timbratura';

  @override
  String get remindersToClockInAndOut =>
      'Promemoria per timbrare entrata e uscita';

  @override
  String get shiftNotifications => 'Notifiche turni';

  @override
  String get assignmentsUpdatesAndShiftReminders =>
      'Assegnazioni, aggiornamenti e promemoria turni';

  @override
  String get debugTools => 'Strumenti debug';

  @override
  String get debugToolsBrowserMessage =>
      'Usa questi test solo mentre stai verificando le notifiche in questo browser.';

  @override
  String get debugToolsDeviceMessage =>
      'Usa questi test solo mentre stai verificando le notifiche su questo dispositivo.';

  @override
  String get testNotificationNow => 'Testa notifica ora';

  @override
  String get testAlarmIn10Seconds => 'Testa allarme tra 10s';

  @override
  String get testCurrentMode => 'Testa modalità attuale';

  @override
  String get alarmModeStatus => 'Stato modalità allarme';

  @override
  String get pendingRequests => 'Richieste in attesa';

  @override
  String get inspectRealShifts => 'Ispeziona turni reali';

  @override
  String get privacyPolicy => 'Informativa sulla privacy';

  @override
  String get howWeProtectYourData => 'Come proteggiamo i tuoi dati';

  @override
  String get dataProtection => 'Protezione dei dati';

  @override
  String get dataProtectionDescription =>
      'I tuoi dati sono criptati a riposo e in transito. Usiamo protocolli di cifratura standard del settore per mantenere sicure le tue informazioni.';

  @override
  String get dataCollection => 'Raccolta dei dati';

  @override
  String get dataCollectionDescription =>
      'Raccogliamo solo i dati necessari per fornire i nostri servizi. Questo include informazioni account, risposte ai sondaggi e registrazioni di timbratura.';

  @override
  String get dataSharing => 'Condivisione dei dati';

  @override
  String get dataSharingDescription =>
      'Non condividiamo mai i tuoi dati personali con terze parti senza il tuo consenso esplicito. I dati del team sono condivisi solo all\'interno della tua organizzazione.';

  @override
  String get dataRetention => 'Conservazione dei dati';

  @override
  String get dataRetentionDescription =>
      'I tuoi dati vengono conservati finché il tuo account è attivo. Dopo la disattivazione dell\'account, i dati personali vengono rimossi definitivamente entro 30 giorni.';

  @override
  String get yourRights => 'I tuoi diritti';

  @override
  String get yourRightsDescription =>
      'Hai il diritto di accedere, rettificare o cancellare i tuoi dati personali in qualsiasi momento. Contatta il supporto per richieste legate alla privacy.';

  @override
  String get privacyLastUpdated => 'Ultimo aggiornamento: gennaio 2025';

  @override
  String get yourName => 'Il tuo Nome';

  @override
  String get yourEmail => 'La tua Email';

  @override
  String get message => 'Messaggio';

  @override
  String get submit => 'Invia';

  @override
  String get contactUsDescription =>
      'Raccontaci cosa è successo e apriremo la tua app email con una bozza già pronta da inviare.';

  @override
  String get contactUsDraftHint =>
      'La tua app email si aprirà con Junibetto@gmail.com già selezionata come destinatario.';

  @override
  String get contactUsReplyTime =>
      'Di solito rispondiamo entro 1-2 giorni lavorativi.';

  @override
  String get supportEmail => 'Email supporto';

  @override
  String get sendEmail => 'Invia email';

  @override
  String get copyEmail => 'Copia email';

  @override
  String get emailCopied =>
      'L\'email di supporto è stata copiata negli appunti.';

  @override
  String get couldNotOpenEmailApp =>
      'Non siamo riusciti ad aprire la tua app email. Copia l\'indirizzo e invia il messaggio manualmente.';

  @override
  String get contactUsEmailSubject => 'Richiesta supporto Note Sondage';

  @override
  String get contactUsTopicsTitle => 'Bug, feedback, idee prodotto';

  @override
  String get contactUsTopicsBody =>
      'Usa questo spazio per segnalare problemi, chiedere aiuto o condividere miglioramenti che vorresti vedere nell\'app.';

  @override
  String get contactUsFormHint =>
      'La bozza includerà i tuoi dettagli, così il supporto potrà risponderti più velocemente.';

  @override
  String get none => 'Nessuno';

  @override
  String get personalStatusClockingActions => 'Azioni personali di timbratura';

  @override
  String get clockedInAt => 'Entrata alle:';

  @override
  String get startBreakAt => 'Inizio pausa alle:';

  @override
  String get endBreakAt => 'Fine pausa alle:';

  @override
  String get clockedOutAt => 'Uscita alle:';

  @override
  String get allUsers => 'Tutti gli utenti';

  @override
  String get clockInSuccessful => 'Entrata registrata con successo';

  @override
  String get clockOutSuccessful => 'Uscita registrata con successo';

  @override
  String get teamCreatedSuccessfully => 'Team creato con successo!';

  @override
  String get errorPrefix => 'Errore:';

  @override
  String get memberAddedSuccessfully => 'Membro aggiunto con successo!';

  @override
  String get memberErrorPrefix => 'Errore membro:';

  @override
  String get noTeamsFound => 'Nessun team trovato';

  @override
  String get roleCreatedSuccessfully => 'Ruolo creato con successo!';

  @override
  String get noRolesAvailable => 'Nessun ruolo disponibile';

  @override
  String get userList => 'Lista utenti';

  @override
  String get addUser => 'Aggiungi utente';

  @override
  String get clearAll => 'Cancella tutto';

  @override
  String get cancel => 'Annulla';

  @override
  String get close => 'Chiudi';

  @override
  String get confirm => 'Conferma';

  @override
  String get saveChanges => 'Salva modifiche';

  @override
  String get goBack => 'Torna indietro';

  @override
  String get errorDetailsDebug => 'Dettagli errore (Debug)';

  @override
  String get aboutPageText => 'Questa è la pagina Chi siamo';

  @override
  String get teamPageMobileText => 'Questa è la pagina Team per Mobile';

  @override
  String get noTeamMembersFound => 'Nessun membro del team trovato.';

  @override
  String get takePhoto => 'Scatta foto';

  @override
  String get chooseFromGallery => 'Scegli dalla galleria';

  @override
  String get selectMultiple => 'Seleziona multiple';

  @override
  String get removeImage => 'Rimuovi immagine';

  @override
  String get settingsWeb => 'Impostazioni Web';

  @override
  String get webNavbar => 'Barra di navigazione Web';

  @override
  String get surveyMobile => 'Sondaggio Mobile';

  @override
  String get progress => 'Progresso';

  @override
  String get createdDate => 'Data creazione';

  @override
  String get expiryDate => 'Data scadenza';

  @override
  String get dashboardSubtitle =>
      'Ecco un rapido riepilogo del tuo spazio di lavoro';

  @override
  String get quickActions => 'Azioni rapide';

  @override
  String get recentActivity => 'Attività recente';

  @override
  String get activeTeams => 'Team attivi';

  @override
  String get activeSurveys => 'Sondaggi attivi';

  @override
  String get todayClocking => 'Timbratura di oggi';

  @override
  String get totalMembers => 'Membri totali';

  @override
  String get viewAll => 'Vedi tutto';

  @override
  String get noRecentActivity => 'Nessuna attività recente';

  @override
  String get getStarted => 'Inizia esplorando il tuo spazio di lavoro';

  @override
  String get logoutConfirmation => 'Sei sicuro di voler uscire?';

  @override
  String get clockInRequiredForBreak => 'Timbratura richiesta per la pausa';

  @override
  String get endActiveBreak => 'Termina Pausa';

  @override
  String get startActiveBreak => 'Inizia Pausa';

  @override
  String get selectTeamToClockIn => 'Seleziona un team per timbrare';

  @override
  String get allDates => 'Tutte le date';

  @override
  String get teamClockings => 'Timbrature del Team';

  @override
  String get downloadPdf => 'Scarica PDF';

  @override
  String get clockingOwnerHint => 'Proprietario Timbratura';

  @override
  String get searchByNameOrTeam => 'Cerca per nome o team...';

  @override
  String get resetFilters => 'Resetta Filtri';

  @override
  String get reset => 'Resetta';

  @override
  String get selectTeamToViewClockings =>
      'Seleziona un team per vedere le timbrature';

  @override
  String get noClockingsForTeam => 'Nessuna timbratura trovata per questo team';

  @override
  String get committed => 'Confermato';

  @override
  String get decommitted => 'Annullato';

  @override
  String get editClocking => 'Modifica Timbratura';

  @override
  String get breakMinutes => 'Pausa (minuti)';

  @override
  String get note => 'Nota';

  @override
  String get invalidDateFormat => 'Formato data non valido';

  @override
  String get noClockingsToExport =>
      'Nessuna timbratura disponibile da esportare';

  @override
  String get ownerOnly => 'Solo Proprietario';

  @override
  String get decommit => 'Annulla';

  @override
  String get commit => 'Conferma';

  @override
  String get editAction => 'Modifica';

  @override
  String get noActionAvailable => 'Nessuna azione disponibile';

  @override
  String get setExpiry => 'Imposta data di scadenza';

  @override
  String get invitationSent => 'Invitazione inviata con successo';

  @override
  String get noActiveMembersYet => 'Nessun membro attivo al momento';

  @override
  String get editRoleTooltip => 'Modifica Ruolo';

  @override
  String get removeAction => 'Rimuovi';

  @override
  String get selectRole => 'Seleziona un ruolo';

  @override
  String get pendingInvitations => 'Inviti in attesa';

  @override
  String get cancelInvitation => 'Annulla Invito';

  @override
  String get inviteStatusAccepted => 'Accettato';

  @override
  String get inviteStatusRejected => 'Rifiutato';

  @override
  String get inviteStatusUnregistered => 'Registrazione in attesa';

  @override
  String get inviteStatusPending => 'In attesa';

  @override
  String get memberStatusInvited => 'Invitato';

  @override
  String get memberStatusInactive => 'Inattivo';

  @override
  String get memberStatusSuspended => 'Sospeso';

  @override
  String exportPdfError(Object error) {
    return 'Errore esportazione PDF: $error';
  }

  @override
  String get surveyNotFound => 'Sondaggio non trovato';

  @override
  String get focus => 'Focus';

  @override
  String get noOptionsAvailable => 'Nessuna opzione disponibile';

  @override
  String get alreadyVoted => 'Hai già votato';

  @override
  String get cannotVote => 'Non puoi votare';

  @override
  String get publish => 'Pubblica';

  @override
  String get closeSurvey => 'Chiudi Sondaggio';

  @override
  String get statusActive => 'Attivo';

  @override
  String get statusDraft => 'Bozza';

  @override
  String get statusClosed => 'Chiuso';

  @override
  String get statusCompleted => 'Completato';

  @override
  String get statusPublished => 'Pubblicato';

  @override
  String votes(int count) {
    return '$count voti';
  }

  @override
  String activeTurnOn(String teamName) {
    return 'Turno attivo su $teamName';
  }

  @override
  String get openYourTurn => 'Apri il tuo turno';

  @override
  String get loadingClockingState => 'Caricamento stato timbratura...';

  @override
  String get noClockingsForFilter =>
      'Nessuna timbratura trovata per i filtri selezionati';

  @override
  String get myShifts => 'I miei turni';

  @override
  String get shiftCalendar => 'Calendario turni';

  @override
  String get shiftCalendarSubtitle => 'Il tuo calendario personale e del team';

  @override
  String get addShift => 'Aggiungi turno';

  @override
  String get shiftProfile => 'Profilo turno';

  @override
  String get shiftStart => 'Inizio';

  @override
  String get shiftEnd => 'Fine';

  @override
  String get overnightShift => 'Turno notturno';

  @override
  String get shiftRepeatUntil => 'Ripeti fino al';

  @override
  String get shiftRepeatUntilHelp =>
      'Verrà creato un turno per ogni giorno dell\'intervallo selezionato.';

  @override
  String get shiftEndMustBeAfterStart =>
      'L\'orario di fine deve essere successivo all\'orario di inizio. Se il turno finisce il giorno dopo, attiva Turno notturno.';

  @override
  String get alarms => 'Allarmi';

  @override
  String get createCustomProfile => 'Crea profilo personalizzato';

  @override
  String get editShiftProfile => 'Modifica profilo';

  @override
  String get shiftProfileName => 'Nome profilo';

  @override
  String get shiftColor => 'Colore';

  @override
  String get deleteShiftProfileConfirm =>
      'Sei sicuro di voler eliminare questo profilo?';

  @override
  String get customProfile => 'Profili personalizzati';

  @override
  String get noShiftsThisMonth => 'Nessun turno questo mese';

  @override
  String get systemProfile => 'Profili di sistema';
}
