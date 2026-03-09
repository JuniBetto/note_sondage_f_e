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
}
