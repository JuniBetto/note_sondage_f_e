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
  String get logout => 'Cerra sesion';

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

  @override
  String get askQuestion => 'Haz una pregunta';

  @override
  String get options => 'Opciones';

  @override
  String get option => 'Opción';

  @override
  String get allowMultipleResponses => 'Permitir múltiples respuestas';

  @override
  String get makeResponsesAnonymous => 'Hacer las respuestas anónimas';

  @override
  String get selectTeam => 'Seleccionar equipo';

  @override
  String get teamLabel => 'Equipo:';

  @override
  String get surveyCreatedSuccessfully => '¡Encuesta creada con éxito!';

  @override
  String get create => 'Crear';

  @override
  String get responses => 'respuestas';

  @override
  String get questions => 'preguntas';

  @override
  String get system => 'Sistema';

  @override
  String get dark => 'Oscuro';

  @override
  String get light => 'Claro';

  @override
  String get preferences => 'Preferencias';

  @override
  String get manageYourPrivacySettings =>
      'Gestiona tu configuración de privacidad';

  @override
  String get getInTouchWithOurSupportTeam =>
      'Ponte en contacto con nuestro equipo de soporte';

  @override
  String get themeTitle => 'Tema';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get lightMode => 'Modo Claro';

  @override
  String get darkMode => 'Modo Oscuro';

  @override
  String get systemDefault => 'Predeterminado del Sistema';

  @override
  String get defaultLightTheme => 'Tema claro predeterminado';

  @override
  String get darkThemeForLowLight => 'Tema oscuro para poca luz';

  @override
  String get followSystemSettings => 'Seguir la configuración del sistema';

  @override
  String get selectYourLanguage => 'Selecciona tu idioma';

  @override
  String get settingsNotification => 'Configuración de Notificaciones';

  @override
  String get yourName => 'Tu Nombre';

  @override
  String get yourEmail => 'Tu Email';

  @override
  String get message => 'Mensaje';

  @override
  String get submit => 'Enviar';

  @override
  String get none => 'Ninguno';

  @override
  String get personalStatusClockingActions => 'Acciones personales de fichaje';

  @override
  String get clockedInAt => 'Entrada a las:';

  @override
  String get startBreakAt => 'Inicio de pausa a las:';

  @override
  String get endBreakAt => 'Fin de pausa a las:';

  @override
  String get clockedOutAt => 'Salida a las:';

  @override
  String get allUsers => 'Todos los usuarios';

  @override
  String get clockInSuccessful => 'Fichaje de entrada exitoso';

  @override
  String get clockOutSuccessful => 'Fichaje de salida exitoso';

  @override
  String get teamCreatedSuccessfully => '¡Equipo creado con éxito!';

  @override
  String get errorPrefix => 'Error:';

  @override
  String get memberAddedSuccessfully => '¡Miembro añadido con éxito!';

  @override
  String get memberErrorPrefix => 'Error de miembro:';

  @override
  String get noTeamsFound => 'No se encontraron equipos';

  @override
  String get roleCreatedSuccessfully => '¡Rol creado con éxito!';

  @override
  String get noRolesAvailable => 'No hay roles disponibles';

  @override
  String get userList => 'Lista de usuarios';

  @override
  String get addUser => 'Añadir usuario';

  @override
  String get clearAll => 'Borrar todo';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get goBack => 'Volver';

  @override
  String get errorDetailsDebug => 'Detalles del error (Debug)';

  @override
  String get aboutPageText => 'Esta es la página Acerca de';

  @override
  String get teamPageMobileText => 'Esta es la página de Equipo para Móvil';

  @override
  String get noTeamMembersFound => 'No se encontraron miembros del equipo.';

  @override
  String get takePhoto => 'Tomar foto';

  @override
  String get chooseFromGallery => 'Elegir de la galería';

  @override
  String get selectMultiple => 'Seleccionar múltiples';

  @override
  String get removeImage => 'Eliminar imagen';

  @override
  String get settingsWeb => 'Configuración Web';

  @override
  String get webNavbar => 'Barra de navegación Web';

  @override
  String get surveyMobile => 'Encuesta Móvil';
}
