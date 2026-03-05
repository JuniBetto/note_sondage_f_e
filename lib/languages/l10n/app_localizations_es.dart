// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get login => 'Login';

  @override
  String get register => 'Registrarse';

  @override
  String get gladYouAreBack => '¡Qué alegría verte de nuevo.!';

  @override
  String get welcomeBack => '¡Bienvenido de nuevo.!';

  @override
  String get email => 'Correo electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get justSomeInfoToGetStarted =>
      'Solo algo de información para comenzar';

  @override
  String get fullName => 'Nombre completo';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get pleaseEnterYourEmail =>
      'Por favor, introduce tu correo electrónico';

  @override
  String get resetPassword => 'Restablecer contraseña';

  @override
  String get donthaveAnAccount => '¿No tienes una cuenta? Regístrate';

  @override
  String get signup => 'Registro';

  @override
  String get home => 'Inicio';

  @override
  String get about => 'Acerca de';

  @override
  String get team => 'Equipo';

  @override
  String get settings => 'configuración';

  @override
  String get attendance => 'Asistencia';

  @override
  String get clockingInOut => 'El fichaje';

  @override
  String get explorer => 'explorador';

  @override
  String get sondage => 'Encuesta';

  @override
  String get selectedTeam => 'seleccionar equipo';

  @override
  String get createTeam => 'Crear equipo';

  @override
  String get teamMember => 'Mimebro del equipo';

  @override
  String member(num membersCount) {
    String _temp0 = intl.Intl.pluralLogic(
      membersCount,
      locale: localeName,
      other: '$membersCount miembros',
      one: '1 miembro',
    );
    return '$_temp0';
  }

  @override
  String get createNewTeam => 'Crear nuevo equipo';

  @override
  String get teamName => 'Nombre del equipo';

  @override
  String get teamDescription => 'Descripción del equipo';

  @override
  String get role => 'Papel';

  @override
  String get permission => 'Permiso';

  @override
  String get status => 'Estado';

  @override
  String get selectedTeamcolor => 'Seleccionar el color del equipo';

  @override
  String get roleManager => 'Administrador de roles';

  @override
  String get permissionManager => 'Administrador de permisos';

  @override
  String get grantList => 'Lista de subvenciones';

  @override
  String get createGrant => 'Crear subvención';

  @override
  String get roleList => 'Lista de roles';

  @override
  String get createRole => 'Crear rol';

  @override
  String get permissionName => 'Nombre del permiso';

  @override
  String get permissionDescription => 'Descripción del permiso';

  @override
  String get save => 'Guardar';

  @override
  String get editRoleManager => 'Permiso de edición';

  @override
  String get roleName => 'Nombre rol';

  @override
  String get roleDescription => 'Descripción del rol';

  @override
  String get selectedPermission => 'Seleccionar permiso';

  @override
  String get editTeam => 'equipo edición';

  @override
  String get language => 'Idioma';

  @override
  String get notification => 'Notificación';

  @override
  String get contactUs => 'Contáctenos';

  @override
  String get privacy => 'Privacidad';
}
