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
  String get deleteAccount => 'Desactivar cuenta';

  @override
  String get accountDeletionDialogMessage =>
      'Introduce el correo electrónico de la cuenta que quieres desactivar. Enviaremos un enlace de confirmación antes de bloquearla.';

  @override
  String get sendConfirmationEmail => 'Enviar correo de confirmación';

  @override
  String get accountDeletionRequestSentTitle => 'Revisa tu correo';

  @override
  String get accountDeletionRequestSentMessage =>
      'Si existe una cuenta para este correo, hemos enviado un enlace de confirmación para completar la desactivación.';

  @override
  String get accountDeletionRequestFailedTitle =>
      'No se pudo iniciar la desactivación';

  @override
  String get accountDeletionRequestFailedMessage =>
      'No pudimos enviar el correo de confirmación de desactivación en este momento. Inténtalo de nuevo más tarde.';

  @override
  String get accountDeletionOpenEmailTitle => 'Abre el correo de desactivación';

  @override
  String get accountDeletionOpenEmailMessage =>
      'Usa el enlace de confirmación recibido por correo para completar la desactivación de la cuenta.';

  @override
  String get accountDeletionConfirmedTitle => 'Cuenta desactivada';

  @override
  String get accountDeletionConfirmedMessage =>
      'Tu cuenta se ha desactivado correctamente. Ya puedes cerrar esta página.';

  @override
  String get accountDeletionFailedTitle => 'Desactivación no disponible';

  @override
  String get accountDeletionFailedMessage =>
      'No pudimos confirmar este enlace de desactivación. Solicita un nuevo correo e inténtalo de nuevo.';

  @override
  String get accountDeletionLoadingTitle => 'Confirmando desactivación';

  @override
  String get accountDeletionLoadingMessage =>
      'Estamos validando el enlace de desactivación de tu cuenta...';

  @override
  String get reactivateAccount => 'Reactivar cuenta';

  @override
  String get accountReactivationDialogMessage =>
      'Introduce el correo electrónico de la cuenta que quieres reactivar. Enviaremos un enlace de confirmación antes de restaurar el acceso.';

  @override
  String get accountReactivationRequestSentTitle => 'Revisa tu correo';

  @override
  String get accountReactivationRequestSentMessage =>
      'Si existe una cuenta para este correo, hemos enviado un enlace de confirmación para completar la reactivación.';

  @override
  String get accountReactivationRequestFailedTitle =>
      'No se pudo iniciar la reactivación';

  @override
  String get accountReactivationRequestFailedMessage =>
      'No pudimos enviar el correo de confirmación de reactivación en este momento. Inténtalo de nuevo más tarde.';

  @override
  String get accountReactivationOpenEmailTitle =>
      'Abre el correo de reactivación';

  @override
  String get accountReactivationOpenEmailMessage =>
      'Usa el enlace de confirmación recibido por correo para restaurar el acceso a tu cuenta.';

  @override
  String get accountReactivationConfirmedTitle => 'Cuenta reactivada';

  @override
  String get accountReactivationConfirmedMessage =>
      'Tu cuenta vuelve a estar activa. Ya puedes iniciar sesión.';

  @override
  String get accountReactivationFailedTitle => 'Reactivación no disponible';

  @override
  String get accountReactivationFailedMessage =>
      'No pudimos confirmar este enlace de reactivación. Solicita un nuevo correo e inténtalo de nuevo.';

  @override
  String get accountReactivationLoadingTitle => 'Confirmando reactivación';

  @override
  String get accountReactivationLoadingMessage =>
      'Estamos validando el enlace de reactivación de tu cuenta...';

  @override
  String get backToLogin => 'Volver al login';

  @override
  String get tryAgain => 'Intentar de nuevo';

  @override
  String get reviewTutorial => 'Ver tutorial otra vez';

  @override
  String get tutorialPrevious => 'Anterior';

  @override
  String get tutorialNext => 'Siguiente';

  @override
  String get tutorialSkip => 'Saltar';

  @override
  String get webMobileAppOnlyTitle => 'Descarga la app móvil';

  @override
  String get webMobileAppOnlyMessage =>
      'Esta experiencia web solo está disponible en pantallas grandes. En teléfonos con un ancho inferior a 576px, continúa desde la app móvil.';

  @override
  String get webMobileAppOnlyHint =>
      'Abre TeamManagement en una tablet o en escritorio, o instala la app desde tu tienda.';

  @override
  String get downloadOnAppStore => 'Descargar en App Store';

  @override
  String get getItOnGooglePlay => 'Disponible en Google Play';

  @override
  String get mobileStoreLinksUnavailable =>
      'Los enlaces de las tiendas aún no están configurados. Contacta con soporte o abre la app en una pantalla más grande.';

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
  String get clockingInOut => 'Fichaje';

  @override
  String get explorer => 'explorador';

  @override
  String get sondage => 'Encuesta';

  @override
  String get sondageChat => 'Encuesta/Chat';

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
  String get teamDetails => 'Detalles del equipo';

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
  String get notificationsSettingsIntro =>
      'Elige cómo recibir las actualizaciones y los recordatorios de turnos.';

  @override
  String get notificationsGeneral => 'General';

  @override
  String get emailNotifications => 'Notificaciones por correo';

  @override
  String get receiveUpdatesByEmail =>
      'Recibe actualizaciones por correo electrónico';

  @override
  String get pushNotifications => 'Notificaciones push';

  @override
  String get receivePushNotificationsOnYourDevice =>
      'Recibe notificaciones push en tu dispositivo';

  @override
  String get shiftReminders => 'Recordatorios de turnos';

  @override
  String get reminderMode => 'Modo de recordatorio';

  @override
  String get notificationReminderModeDescription =>
      'Elige en cada turno si quieres una notificación estándar o una alarma más intensa.';

  @override
  String get webBehavior => 'Comportamiento web';

  @override
  String get alarmBehaviorOnWeb =>
      'En la web, el modo Alarma usa las notificaciones del navegador. La pestaña debe permanecer abierta y el navegador controla el comportamiento final del sonido y la vibración.';

  @override
  String get howItWorks => 'Cómo funciona';

  @override
  String get notificationAndAlarmDifference =>
      'La notificación muestra un recordatorio normal. La alarma usa los ajustes de abajo y está pensada para alertas de turno más visibles.';

  @override
  String get alarmDelivery => 'Entrega de la alarma';

  @override
  String get alarmStyle => 'Estilo de alarma';

  @override
  String get webAlarmDeliveryDescription =>
      'Las notificaciones del navegador se usan mientras esta pestaña permanezca abierta. El sonido y la vibración son gestionados por el navegador y el sistema operativo.';

  @override
  String get alarmStyleDescription =>
      'Elige si el modo Alarma debe vibrar o reproducir un tono. Predeterminado: vibración.';

  @override
  String get alarmStyleDescriptionIos =>
      'En iPhone, el modo Alarma usa un tono. Las alarmas solo con vibración no están disponibles para las notificaciones locales.';

  @override
  String get vibrate => 'Vibración';

  @override
  String get ringtone => 'Tono';

  @override
  String get browserNotification => 'Notificación del navegador';

  @override
  String get notificationVisibility => 'Visibilidad de la notificación';

  @override
  String get alarmDuration => 'Duración de la alarma';

  @override
  String get webNotificationVisibilityDescription =>
      'Esto controla cuánto tiempo permanece visible la notificación del navegador después de aparecer.';

  @override
  String get alarmDurationAppliesOnlyToAlarmMode =>
      'Esta duración se aplica solo cuando un turno usa el modo Alarma.';

  @override
  String get activity => 'Actividad';

  @override
  String get surveyReminders => 'Recordatorios de encuestas';

  @override
  String get getRemindedAboutPendingSurveys =>
      'Recibe recordatorios sobre encuestas pendientes';

  @override
  String get teamUpdates => 'Actualizaciones del equipo';

  @override
  String get notificationsAboutTeamChanges =>
      'Notificaciones sobre cambios en el equipo';

  @override
  String get clockingAlerts => 'Alertas de fichaje';

  @override
  String get remindersToClockInAndOut =>
      'Recordatorios para fichar entrada y salida';

  @override
  String get shiftNotifications => 'Notificaciones de turnos';

  @override
  String get assignmentsUpdatesAndShiftReminders =>
      'Asignaciones, actualizaciones y recordatorios de turnos';

  @override
  String get debugTools => 'Herramientas de depuración';

  @override
  String get debugToolsBrowserMessage =>
      'Usa estas pruebas solo mientras depuras las notificaciones en este navegador.';

  @override
  String get debugToolsDeviceMessage =>
      'Usa estas pruebas solo mientras depuras las notificaciones en este dispositivo.';

  @override
  String get testNotificationNow => 'Probar notificación ahora';

  @override
  String get testAlarmIn10Seconds => 'Probar alarma en 10 s';

  @override
  String get testCurrentMode => 'Probar modo actual';

  @override
  String get alarmModeStatus => 'Estado del modo alarma';

  @override
  String get pendingRequests => 'Solicitudes pendientes';

  @override
  String get inspectRealShifts => 'Inspeccionar turnos reales';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get howWeProtectYourData => 'Cómo protegemos tus datos';

  @override
  String get dataProtection => 'Protección de datos';

  @override
  String get dataProtectionDescription =>
      'Tus datos están cifrados en reposo y en tránsito. Usamos protocolos de cifrado estándar de la industria para mantener tu información segura.';

  @override
  String get dataCollection => 'Recopilación de datos';

  @override
  String get dataCollectionDescription =>
      'Recopilamos solo los datos necesarios para ofrecer nuestros servicios. Esto incluye la información de tu cuenta, las respuestas a encuestas y los registros de fichaje.';

  @override
  String get dataSharing => 'Compartición de datos';

  @override
  String get dataSharingDescription =>
      'Nunca compartimos tus datos personales con terceros sin tu consentimiento explícito. Los datos del equipo se comparten solo dentro de tu organización.';

  @override
  String get dataRetention => 'Conservación de datos';

  @override
  String get dataRetentionDescription =>
      'Tus datos se conservan mientras tu cuenta esté activa. Tras la desactivación de la cuenta, los datos personales se eliminan de forma permanente en un plazo de 30 días.';

  @override
  String get yourRights => 'Tus derechos';

  @override
  String get yourRightsDescription =>
      'Tienes derecho a acceder, rectificar o eliminar tus datos personales en cualquier momento. Contacta con nuestro equipo de soporte para cualquier solicitud relacionada con la privacidad.';

  @override
  String get privacyLastUpdated => 'Última actualización: enero de 2025';

  @override
  String get yourName => 'Tu Nombre';

  @override
  String get yourEmail => 'Tu Email';

  @override
  String get message => 'Mensaje';

  @override
  String get submit => 'Enviar';

  @override
  String get contactUsDescription =>
      'Cuéntanos qué ocurrió y enviaremos el mensaje directamente a nuestro equipo de soporte.';

  @override
  String get contactUsDraftHint =>
      'Tu mensaje se enviará directamente a contactus@teammanagement.it.';

  @override
  String get contactUsReplyTime =>
      'Normalmente respondemos en 1-2 días laborables.';

  @override
  String get supportEmail => 'Correo de soporte';

  @override
  String get sendEmail => 'Enviar correo';

  @override
  String get copyEmail => 'Copiar correo';

  @override
  String get emailCopied =>
      'El correo de soporte se ha copiado al portapapeles.';

  @override
  String get couldNotOpenEmailApp =>
      'No hemos podido abrir tu aplicación de correo. Copia la dirección y envía el mensaje manualmente.';

  @override
  String get contactUsEmailSubject => 'Solicitud de soporte TeamManagement';

  @override
  String get contactUsTopicsTitle => 'Errores, comentarios, ideas de producto';

  @override
  String get contactUsTopicsBody =>
      'Usa este espacio para informar problemas, pedir ayuda o compartir mejoras que te gustaría ver en la aplicación.';

  @override
  String get contactUsFormHint =>
      'El mensaje incluirá tus datos para que soporte pueda responder más rápido.';

  @override
  String get contactUsSentSuccess => 'Tu mensaje se ha enviado al soporte.';

  @override
  String get contactUsSendFailed =>
      'No hemos podido enviar tu mensaje ahora mismo. Vuelve a intentarlo dentro de poco.';

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
  String get deleteTeamTitle => 'Eliminar equipo';

  @override
  String get deleteTeamMessage =>
      '¿Seguro que quieres eliminar este equipo? Esta acción no se puede deshacer.';

  @override
  String get deleteRoleTitle => 'Eliminar rol';

  @override
  String get deleteRoleMessage => '¿Seguro que quieres eliminar este rol?';

  @override
  String get defaultRole => 'Rol predeterminado';

  @override
  String get swipeToCreateRole => 'Desliza para crear un nuevo rol';

  @override
  String get searchTeamsByNameOrDescription =>
      'Buscar equipos por nombre o descripción';

  @override
  String get noTeamsMatchingSearch =>
      'No se encontraron equipos para esta búsqueda.';

  @override
  String get noArchivedTeams => 'No hay equipos archivados.';

  @override
  String get noVisibleTeams => 'No hay equipos visibles.';

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
  String get close => 'Cerrar';

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
  String get dashboardSubtitle =>
      'Aquí tienes un resumen rápido de tu espacio de trabajo';

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
  String get logoutConfirmation =>
      '¿Estás seguro de que quieres cerrar sesión?';

  @override
  String get clockInRequiredForBreak => 'Fichaje requerido para el descanso';

  @override
  String get endActiveBreak => 'Finalizar descanso';

  @override
  String get startActiveBreak => 'Iniciar descanso';

  @override
  String get selectTeamToClockIn =>
      'Por favor, seleccione un equipo para fichar';

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
  String get selectTeamToViewClockings =>
      'Por favor, seleccione un equipo para ver los fichajes';

  @override
  String get noClockingsForTeam =>
      'No se han encontrado fichajes para este equipo';

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
  String get deleteAction => 'Eliminar';

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
  String get noPermissionToEditSurvey =>
      'No tienes permiso para editar esta encuesta.';

  @override
  String get editSurvey => 'Editar encuesta';

  @override
  String get deleteSurvey => 'Eliminar encuesta';

  @override
  String get deleteSurveyTitle => 'Eliminar encuesta';

  @override
  String get deleteSurveyMessage =>
      '¿Seguro que quieres eliminar esta encuesta?';

  @override
  String get surveyDeleted => 'Encuesta eliminada.';

  @override
  String get archiveSurvey => 'Archivar encuesta';

  @override
  String get restoreSurvey => 'Restaurar encuesta';

  @override
  String get noDraftOrActiveSurveysAvailable =>
      'No hay borradores ni encuestas activas disponibles';

  @override
  String get noSurveysMatchingSearch =>
      'No se encontraron encuestas para esta búsqueda.';

  @override
  String get noArchivedSurveys => 'No hay encuestas archivadas.';

  @override
  String get noVisibleSurveys => 'No hay encuestas visibles.';

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
  String get noClockingsForFilter =>
      'No se encontraron fichajes para los filtros seleccionados';

  @override
  String get myShifts => 'Mis turnos';

  @override
  String get shiftCalendar => 'Calendario de turnos';

  @override
  String get shiftCalendarSubtitle => 'Tu calendario personal y del equipo';

  @override
  String get shiftTeamReportTitle => 'Informe de turnos del equipo';

  @override
  String get shiftTeamReportSubtitle =>
      'Filtra por período y usuarios, luego visualiza o descarga el informe.';

  @override
  String get shiftTeamReportTooltip => 'Informe de turnos del equipo';

  @override
  String get shiftTeamReportButton => 'Informe del equipo';

  @override
  String get shiftReportUnavailable =>
      'No hay ningún equipo gestionable disponible para el informe.';

  @override
  String get shiftReportStartDate => 'Fecha de inicio';

  @override
  String get shiftReportEndDate => 'Fecha de fin';

  @override
  String get shiftReportUsers => 'Usuarios a incluir';

  @override
  String get shiftReportRefresh => 'Actualizar informe';

  @override
  String get shiftReportPeriod => 'Período';

  @override
  String get shiftReportShifts => 'Turnos';

  @override
  String get shiftReportMode => 'Modo';

  @override
  String get shiftReportCalendarMode => 'Calendario';

  @override
  String get shiftReportTableMode => 'Tabla';

  @override
  String get shiftReportSelectTeam => 'Selecciona un equipo.';

  @override
  String get shiftReportNoResults =>
      'No se encontraron turnos para los filtros seleccionados.';

  @override
  String get shiftReportLoadError =>
      'No pudimos cargar el informe de turnos en este momento.';

  @override
  String get shiftReportGeneratedAt => 'Generado el';

  @override
  String get shiftReportDateColumn => 'Fecha';

  @override
  String get shiftReportUserColumn => 'Usuario';

  @override
  String get shiftReportProfileColumn => 'Perfil';

  @override
  String get shiftReportTypeColumn => 'Tipo';

  @override
  String get shiftReportDefaultProfile => 'Turno';

  @override
  String get shiftReportPrivateType => 'Privado';

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
  String get shiftRepeatUntil => 'Repetir hasta';

  @override
  String get shiftRepeatUntilHelp =>
      'Se creará un turno para cada día del intervalo seleccionado.';

  @override
  String get shiftEndMustBeAfterStart =>
      'La hora de fin debe ser posterior a la hora de inicio. Si el turno termina al día siguiente, activa Turno nocturno.';

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
  String get deleteShiftProfileConfirm =>
      '¿Estás seguro de que quieres eliminar este perfil?';

  @override
  String get deleteShiftTitle => 'Eliminar turno';

  @override
  String get deleteShiftMessage => '¿Seguro que quieres eliminar este turno?';

  @override
  String get publicProfile => 'Público';

  @override
  String get privateProfile => 'Privado';

  @override
  String get visibleToTeamMembers =>
      'Visible para todos los miembros del equipo';

  @override
  String get visibleOnlyToYou => 'Visible solo para ti';

  @override
  String get syncing => 'Sincronizando';

  @override
  String get customProfile => 'Perfiles personalizados';

  @override
  String get noShiftsThisMonth => 'Sin turnos este mes';

  @override
  String get systemProfile => 'Perfiles del sistema';

  @override
  String get clockingDateLabel => 'Fecha de fichaje';

  @override
  String get calendarWeek => 'Semana';

  @override
  String get calendarMonth => 'Mes';

  @override
  String get today => 'Hoy';

  @override
  String get clockingOverviewTitle => 'Resumen de fichaje';

  @override
  String get clockingOverviewDescription =>
      'Este encabezado presenta el área de fichaje y su propósito principal.';

  @override
  String get clockingCurrentStatusTitle => 'Estado actual';

  @override
  String get clockingCurrentStatusDescription =>
      'Esta sección te muestra al instante el estado de tu fichaje y la información principal del día.';

  @override
  String get personal => 'Personal';

  @override
  String get markVacation => 'Marcar vacaciones';

  @override
  String get markPermission => 'Marcar permiso';

  @override
  String get requestClocking => 'Solicitar fichaje';

  @override
  String get requestDecommit => 'Solicitar decommit';

  @override
  String get requestVacation => 'Solicitar vacaciones';

  @override
  String get requestPermission => 'Solicitar permiso';

  @override
  String get vacationStatus => 'Vacaciones';

  @override
  String get clockingOpenRecordAnotherDay =>
      'Tienes un fichaje abierto en otro día. Selecciónalo para continuar.';

  @override
  String dayAlreadyHasClocking(String date) {
    return 'Ya existe un fichaje para $date.';
  }

  @override
  String get manualClockingUseInlineForPastDays =>
      'Para días distintos de hoy, usa la sección de entrada manual de abajo.';

  @override
  String get manualClockingRequiresApproval =>
      'Para esta fecha debes pedir la aprobación de un manager o usar un equipo que gestionas.';

  @override
  String get selectedDayMarkedAsVacation =>
      'El día seleccionado está marcado como vacaciones.';

  @override
  String get clockingCurrentTimeOverlapsExistingRecord =>
      'La hora actual cae dentro de un fichaje o permiso ya registrado hoy.';

  @override
  String createClockingForDate(String date) {
    return 'Crear un fichaje para $date';
  }

  @override
  String get breakOnlyCurrentDay =>
      'Las pausas solo están disponibles para el día actual.';

  @override
  String get manualClockingTitle => 'Añadir fichaje';

  @override
  String manualClockingDescription(String date) {
    return 'Completa el fichaje para $date o añade más días pasados.';
  }

  @override
  String manualClockingSingleDayDescription(String date) {
    return 'Completa el fichaje para $date.';
  }

  @override
  String get manualClockingResolveOpenRecord =>
      'Tienes un fichaje abierto en otro día. Ciérralo o selecciona ese día antes de guardar un fichaje manual.';

  @override
  String get selectedDays => 'Días seleccionados';

  @override
  String get addDay => 'Añadir día';

  @override
  String get clockInLabel => 'Entrada';

  @override
  String get clockOutLabel => 'Salida';

  @override
  String get optionalNoteHint => 'Nota opcional';

  @override
  String get saving => 'Guardando...';

  @override
  String get saveClocking => 'Guardar fichaje';

  @override
  String get manualClockingTodayLiveOnly =>
      'Para hoy, usa las acciones en vivo de entrada, pausa y salida.';

  @override
  String get invalidBreakMinutes =>
      'El tiempo de pausa debe ser un número válido.';

  @override
  String get clockOutMustBeAfterClockIn =>
      'La hora de salida debe ser posterior a la de entrada.';

  @override
  String get breakMustBeShorterThanShift =>
      'La pausa debe ser más corta que la duración del turno.';

  @override
  String get manualClockingSavedSingle => 'Fichaje guardado con éxito.';

  @override
  String manualClockingSavedMultiple(int count) {
    return '$count fichajes guardados con éxito.';
  }

  @override
  String get manualClockingSaveError =>
      'No hemos podido guardar el fichaje manual.';

  @override
  String get manualClockingBackToTodayTooltip => 'Volver a hoy';

  @override
  String get manualClockingBackToTodayTitle => '¿Volver a hoy?';

  @override
  String get manualClockingBackToTodayMessage =>
      'Estás a punto de salir del modo de fichaje manual.\n\nSi quieres modificar un fichaje de un día pasado, tendrás que enviar una nueva solicitud de fichaje manual para ese día.';

  @override
  String get manualClockingBackToTodayConfirm => 'Volver a hoy';

  @override
  String get manualClockingOverlapTitle => 'Solapamiento detectado';

  @override
  String manualClockingOverlapMessage(
    String newRange,
    String existingRange,
    String newEndTime,
  ) {
    return 'El nuevo fichaje ($newRange) se solapa con un fichaje existente ($existingRange).\n\n¿Quieres acortar el fichaje existente para que termine a las $newEndTime?';
  }

  @override
  String get manualClockingOverlapConfirmAdjust => 'Sí, acortarlo';

  @override
  String get noTeamSelected => 'Ningún equipo seleccionado';

  @override
  String get changeOrSearchTeam => 'Abre para cambiar de equipo o buscar uno';

  @override
  String get teamAvailableForClocking => 'Equipo disponible para el fichaje';

  @override
  String get searchTeam => 'Buscar equipo...';

  @override
  String get noTeamFound => 'No se encontró ningún equipo';

  @override
  String get selectTeamFirst => 'Selecciona primero un equipo.';

  @override
  String get selectTeamBeforeVacation =>
      'Selecciona un equipo antes de marcar vacaciones.';

  @override
  String markSelectedDateAsVacation(String date) {
    return 'Marcar $date como vacaciones';
  }

  @override
  String get markSelectedDayAsVacationDescription =>
      'Esta acción marcará el día seleccionado como vacaciones.';

  @override
  String markPermissionForDate(String date) {
    return 'Marcar permiso para $date';
  }

  @override
  String get start => 'Inicio';

  @override
  String get end => 'Fin';

  @override
  String get permissionInvalidRange =>
      'La hora de fin debe ser posterior a la hora de inicio del permiso.';

  @override
  String get noAssignableMembersForTeam =>
      'No se encontraron miembros asignables para este equipo.';

  @override
  String get assignVacationToMember => 'Marcar vacaciones para un miembro';

  @override
  String get userLabel => 'Usuario';

  @override
  String optionalNoteFor(String name) {
    return 'Nota opcional para $name';
  }

  @override
  String get optionalRequestNoteHint => 'Nota opcional para la solicitud';

  @override
  String get clockingApprovalRequestHint =>
      'Puedes solicitar fichaje, decommit, vacaciones o permiso para el equipo y la fecha seleccionados.';

  @override
  String requestClockingForSelectedDate(String date) {
    return 'Solicitar fichaje para $date';
  }

  @override
  String requestDecommitForSelectedDate(String date) {
    return 'Solicitar decommit para $date';
  }

  @override
  String get noMembersAvailableForClockingRequest =>
      'No hay miembros disponibles para la solicitud de fichaje.';

  @override
  String get sendRequest => 'Enviar solicitud';

  @override
  String get clockingRequestSentSuccess =>
      'Solicitud de fichaje enviada con éxito.';

  @override
  String get clockingRequestSentError =>
      'No hemos podido enviar la solicitud de fichaje al miembro del equipo.';

  @override
  String get decommitRequestSentSuccess =>
      'Solicitud de decommit enviada con éxito.';

  @override
  String get decommitRequestSentError =>
      'No hemos podido enviar la solicitud de decommit.';

  @override
  String get vacationRequestSentSuccess =>
      'Solicitud de vacaciones enviada con éxito.';

  @override
  String get vacationRequestSentError =>
      'No hemos podido enviar la solicitud de vacaciones.';

  @override
  String get permissionRequestSentSuccess =>
      'Solicitud de permiso enviada con éxito.';

  @override
  String get permissionRequestSentError =>
      'No hemos podido enviar la solicitud de permiso.';

  @override
  String get approveRequest => 'Aprobar';

  @override
  String get rejectRequest => 'Rechazar';

  @override
  String get clockInDateTimeLabel => 'Entrada (AAAA-MM-DD HH:MM)';

  @override
  String get clockOutDateTimeLabel => 'Salida (AAAA-MM-DD HH:MM)';

  @override
  String get chatTitle => 'Chat';

  @override
  String get chatLive => 'En vivo';

  @override
  String get chatTeamTitle => 'Chat de equipo';

  @override
  String get chatRefresh => 'Actualizar';

  @override
  String get chatChooseConversation => 'Elige una conversación';

  @override
  String get chatListDescriptionWeb =>
      'Selecciona un canal del equipo o vuelve a abrir una de tus conversaciones directas.';

  @override
  String get chatListDescriptionMobile =>
      'Abre un canal del equipo o vuelve a una de tus conversaciones directas.';

  @override
  String get chatTeamChannels => 'Canales del equipo';

  @override
  String get chatDirectChats => 'Chats directos';

  @override
  String get chatNoDirectContacts =>
      'Aquí aparecerá el historial de tus chats directos.';

  @override
  String get chatNoTeamsAvailable =>
      'No hay equipos disponibles para el chat en este momento.';

  @override
  String get chatChooseTeamHeader => 'Elige un equipo para empezar a chatear.';

  @override
  String chatHeaderDirectDescription(String name) {
    return 'Chat directo con $name';
  }

  @override
  String chatHeaderTeamDescription(String name) {
    return 'Chat del equipo $name';
  }

  @override
  String get chatRefreshed => 'Chat actualizado.';

  @override
  String get chatLoadTeamsError => 'No pudimos cargar tus equipos de chat.';

  @override
  String get chatLoadConversationError =>
      'No pudimos cargar esta conversación.';

  @override
  String get chatSendMessageError => 'No pudimos enviar el mensaje.';

  @override
  String get chatReactionUpdateError => 'No pudimos actualizar la reacción.';

  @override
  String get chatDeleteError => 'No pudimos eliminar el mensaje.';

  @override
  String get chatReactTitle => 'Reaccionar al mensaje';

  @override
  String get chatReactHint => 'Elige una reacción emoji.';

  @override
  String get chatDeleteTitle => 'Eliminar mensaje';

  @override
  String get chatDeleteMessage => '¿Quieres eliminar este mensaje?';

  @override
  String get chatYouLabel => 'Tú';

  @override
  String get chatTimelineBeginning => 'La conversación empieza aquí';

  @override
  String chatTimelineActive(String name) {
    return '$name está activo';
  }

  @override
  String chatTimelineResumed(String duration) {
    return 'Conversación reanudada después de $duration';
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
      other: '$days días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get chatReplyAction => 'Responder';

  @override
  String get chatLoadingOlderMessages => 'Cargando mensajes anteriores...';

  @override
  String get chatNoMessagesYet => 'Todavía no hay mensajes';

  @override
  String get chatEmptyDescription =>
      'Escribe el primer mensaje para empezar esta conversación.';

  @override
  String get chatSeen => 'Visto';

  @override
  String get chatDeletedMessage => 'Mensaje eliminado';

  @override
  String get chatAttachmentFallback => 'Adjunto';

  @override
  String get chatOpenDocument => 'Abrir documento';

  @override
  String get chatOpenSharedConversation =>
      'Abrir la conversación compartida del equipo.';

  @override
  String get chatOpenConversation => 'Abrir conversación';

  @override
  String chatDirectConversationInTeam(String teamName) {
    return 'Conversación directa en $teamName';
  }

  @override
  String get chatDirectActionDescription =>
      'Abre un chat privado con este miembro del equipo.';

  @override
  String get chatOpenDirectAction => 'Abrir chat directo';

  @override
  String get chatReturnToChatList => 'Volver a la lista de chats';

  @override
  String get chatReturnToTeamList => 'Volver a la lista de equipos';

  @override
  String get chatComposerHint => 'Escribe un mensaje';

  @override
  String get chatPickImage => 'Agregar imagen';

  @override
  String get chatPickDocument => 'Agregar documento';

  @override
  String get chatAddEmoji => 'Agregar emoji';

  @override
  String chatReplyingTo(String name) {
    return 'Responder a $name';
  }

  @override
  String get chatCancelReply => 'Cancelar respuesta';

  @override
  String get chatImageReadyToSend => 'Imagen lista para enviar';

  @override
  String get chatDocumentReadyToSend => 'Documento listo para enviar';

  @override
  String get chatRemoveAttachment => 'Quitar adjunto';

  @override
  String get chatJustNow => 'ahora mismo';

  @override
  String chatMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'hace $minutes min',
      one: 'hace 1 min',
    );
    return '$_temp0';
  }

  @override
  String chatHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'hace $hours h',
      one: 'hace 1 h',
    );
    return '$_temp0';
  }

  @override
  String get chatYesterday => 'ayer';

  @override
  String chatDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'hace $days días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }
}
