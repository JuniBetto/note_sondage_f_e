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
  String get justSomeInfoToGetStarted => 'Solo algo de información para comenzar';

  @override
  String get fullName => 'Nombre completo';

  @override
  String get confirmPassword => 'Confirmar contraseña';

  @override
  String get pleaseEnterYourEmail => 'Por favor, introduce tu correo electrónico';

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
  String get clockingInOut => 'Fichaje';

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
  String get manageYourPrivacySettings => 'Gestiona tu configuración de privacidad';

  @override
  String get getInTouchWithOurSupportTeam => 'Ponte en contacto con nuestro equipo de soporte';

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

  @override
  String get progress => 'Progreso';

  @override
  String get createdDate => 'Fecha de creación';

  @override
  String get expiryDate => 'Fecha de vencimiento';

  @override
  String get dashboardSubtitle => 'Aquí tienes un resumen rápido de tu espacio de trabajo';

  @override
  String get quickActions => 'Acciones rápidas';

  @override
  String get recentActivity => 'Actividad reciente';

  @override
  String get activeTeams => 'Equipos activos';

  @override
  String get activeSurveys => 'Encuestas activas';

  @override
  String get todayClocking => 'Fichaje de hoy';

  @override
  String get totalMembers => 'Miembros totales';

  @override
  String get viewAll => 'Ver todo';

  @override
  String get noRecentActivity => 'Sin actividad reciente';

  @override
  String get getStarted => 'Comienza explorando tu espacio de trabajo';

  @override
  String get logoutConfirmation => '¿Estás seguro de que quieres cerrar sesión?';

  @override
  String get clockInRequiredForBreak => 'Fichaje requerido para el descanso';

  @override
  String get endActiveBreak => 'Finalizar descanso';

  @override
  String get startActiveBreak => 'Iniciar descanso';

  @override
  String get selectTeamToClockIn => 'Por favor, seleccione un equipo para fichar';

  @override
  String get allDates => 'Todas las fechas';

  @override
  String get teamClockings => 'Fichajes del equipo';

  @override
  String get downloadPdf => 'Descargar PDF';

  @override
  String get clockingOwnerHint => 'Propietario del fichaje';

  @override
  String get searchByNameOrTeam => 'Buscar por nombre o equipo...';

  @override
  String get resetFilters => 'Restablecer filtros';

  @override
  String get reset => 'Restablecer';

  @override
  String get selectTeamToViewClockings => 'Por favor, seleccione un equipo para ver los fichajes';

  @override
  String get noClockingsForTeam => 'No se han encontrado fichajes para este equipo';

  @override
  String get committed => 'Confirmado';

  @override
  String get decommitted => 'Anulado';

  @override
  String get editClocking => 'Editar fichaje';

  @override
  String get breakMinutes => 'Descanso (minutos)';

  @override
  String get note => 'Nota';

  @override
  String get invalidDateFormat => 'Formato de fecha inválido';

  @override
  String get noClockingsToExport => 'No hay fichajes disponibles para exportar';

  @override
  String get ownerOnly => 'Solo propietario';

  @override
  String get decommit => 'Anular';

  @override
  String get commit => 'Confirmar';

  @override
  String get editAction => 'Editar';

  @override
  String get noActionAvailable => 'Ninguna acción disponible';

  @override
  String get setExpiry => 'Establecer fecha de caducidad';

  @override
  String get invitationSent => 'Invitación enviada con éxito';

  @override
  String get noActiveMembersYet => 'Aún no hay miembros activos';

  @override
  String get editRoleTooltip => 'Editar rol';

  @override
  String get removeAction => 'Eliminar';

  @override
  String get selectRole => 'Seleccionar un rol';

  @override
  String get pendingInvitations => 'Invitaciones pendientes';

  @override
  String get cancelInvitation => 'Cancelar invitación';

  @override
  String get inviteStatusAccepted => 'Aceptada';

  @override
  String get inviteStatusRejected => 'Rechazada';

  @override
  String get inviteStatusUnregistered => 'Registro pendiente';

  @override
  String get inviteStatusPending => 'Pendiente';

  @override
  String get memberStatusInvited => 'Invitado';

  @override
  String get memberStatusInactive => 'Inactivo';

  @override
  String get memberStatusSuspended => 'Suspendido';

  @override
  String exportPdfError(Object error) {
    return 'Error al exportar PDF: $error';
  }

  @override
  String get surveyNotFound => 'Encuesta no encontrada';

  @override
  String get focus => 'Enfoque';

  @override
  String get noOptionsAvailable => 'No hay opciones disponibles';

  @override
  String get alreadyVoted => 'Ya has votado';

  @override
  String get cannotVote => 'No puedes votar';

  @override
  String get publish => 'Publicar';

  @override
  String get closeSurvey => 'Cerrar Encuesta';

  @override
  String get statusActive => 'Activo';

  @override
  String get statusDraft => 'Borrador';

  @override
  String get statusClosed => 'Cerrado';

  @override
  String get statusCompleted => 'Completado';

  @override
  String get statusPublished => 'Publicado';

  @override
  String votes(int count) {
    return '$count votos';
  }

  @override
  String activeTurnOn(String teamName) {
    return 'Turno activo en $teamName';
  }

  @override
  String get openYourTurn => 'Abrir tu turno';

  @override
  String get loadingClockingState => 'Cargando estado de fichaje...';

  @override
  String get noClockingsForFilter => 'No se encontraron fichajes para los filtros seleccionados';

  @override
  String get myShifts => 'Mis turnos';

  @override
  String get shiftCalendar => 'Calendario de turnos';

  @override
  String get shiftCalendarSubtitle => 'Your personal and team shift schedule';

  @override
  String get addShift => 'Agregar turno';

  @override
  String get shiftProfile => 'Perfil de turno';

  @override
  String get shiftStart => 'Inicio';

  @override
  String get shiftEnd => 'Fin';

  @override
  String get overnightShift => 'Turno nocturno';

  @override
  String get alarms => 'Alarmas';

  @override
  String get createCustomProfile => 'Crear perfil personalizado';

  @override
  String get editShiftProfile => 'Editar perfil';

  @override
  String get shiftProfileName => 'Nombre del perfil';

  @override
  String get shiftColor => 'Color';

  @override
  String get deleteShiftProfileConfirm => '¿Estás seguro de que quieres eliminar este perfil?';

  @override
  String get customProfile => 'Perfiles personalizados';

  @override
  String get noShiftsThisMonth => 'Sin turnos este mes';

  @override
  String get systemProfile => 'Perfiles del sistema';
}
