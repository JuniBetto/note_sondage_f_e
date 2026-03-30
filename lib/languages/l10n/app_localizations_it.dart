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
  String get clockingInOut => 'La timbratura';

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
  String get roleManager => 'gezione dei ruoli';

  @override
  String get permissionManager => 'Gezione dei permessi';

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
  String get yourName => 'Il tuo Nome';

  @override
  String get yourEmail => 'La tua Email';

  @override
  String get message => 'Messaggio';

  @override
  String get submit => 'Invia';

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
}
