// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'DT Tracker';

  @override
  String get settings => 'Configuracion';

  @override
  String get account => 'Cuenta';

  @override
  String get tracking => 'Seguimiento';

  @override
  String get app => 'Aplicacion';

  @override
  String get language => 'Idioma';

  @override
  String get languageSubtitle => 'Elige el idioma de la aplicacion';

  @override
  String get systemDefault => 'Predeterminado del sistema';

  @override
  String get english => 'Ingles';

  @override
  String get spanish => 'Espanol';

  @override
  String get profile => 'Perfil';

  @override
  String get editProfileInformation => 'Edita la informacion de tu perfil';

  @override
  String get trackerEvents => 'Eventos del rastreador';

  @override
  String get viewTrackerActivity =>
      'Ve la actividad de geocercas y rastreadores';

  @override
  String get speedAlerts => 'Alertas de velocidad';

  @override
  String get configureSpeedAlerts => 'Configura alertas de limite de velocidad';

  @override
  String get speedAlertsComingSoon =>
      'Las alertas de velocidad estaran disponibles pronto';

  @override
  String get geofenceAlerts => 'Alertas de geocerca';

  @override
  String get geofenceAlertsDescription =>
      'Crea eventos cuando los vehiculos entren o salgan de zonas';

  @override
  String get geofences => 'Geocercas';

  @override
  String get manageGeofenceZones => 'Administra las zonas de geocerca';

  @override
  String get about => 'Acerca de';

  @override
  String get helpAndSupport => 'Ayuda y soporte';

  @override
  String get getHelpWithApp => 'Obten ayuda con la aplicacion';

  @override
  String get helpComingSoon =>
      'La ayuda y el soporte estaran disponibles pronto';

  @override
  String get signOut => 'Cerrar sesion';

  @override
  String get signOutConfirmation => 'Seguro que quieres cerrar sesion?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get user => 'Usuario';

  @override
  String get aboutDescription =>
      'Aplicacion de seguimiento GPS de vehiculos en tiempo real con geocercas y alertas.';

  @override
  String get vehicles => 'Vehiculos';

  @override
  String get map => 'Mapa';

  @override
  String get myVehicles => 'Mis vehiculos';

  @override
  String get addVehicle => 'Agregar vehiculo';

  @override
  String get vehicleDeleted => 'Vehiculo eliminado correctamente';

  @override
  String get events => 'Eventos';

  @override
  String get noTrackerEvents => 'Aun no hay eventos del rastreador';

  @override
  String get archiveEvent => 'Archivar evento';

  @override
  String get total => 'Total';

  @override
  String get online => 'En linea';

  @override
  String get moving => 'En movimiento';

  @override
  String get dateFormat => 'd MMM y';

  @override
  String get dateTimeFormat => 'd MMM y HH:mm';

  @override
  String get justNow => 'Ahora mismo';

  @override
  String timeAgoMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutos',
      one: '1 minuto',
    );
    return 'hace $_temp0';
  }

  @override
  String timeAgoHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas',
      one: '1 hora',
    );
    return 'hace $_temp0';
  }

  @override
  String timeAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
    );
    return 'hace $_temp0';
  }

  @override
  String timeAgoMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meses',
      one: '1 mes',
    );
    return 'hace $_temp0';
  }

  @override
  String timeAgoYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count anos',
      one: '1 ano',
    );
    return 'hace $_temp0';
  }

  @override
  String speedKilometersPerHour(String speed) {
    return '$speed km/h';
  }

  @override
  String distanceKilometers(String distance) {
    return '$distance km';
  }

  @override
  String distanceMeters(String distance) {
    return '$distance m';
  }

  @override
  String get speed => 'Velocidad';

  @override
  String get battery => 'Bateria';

  @override
  String get updated => 'Actualizado';

  @override
  String get history => 'Historial';

  @override
  String get navigate => 'Navegar';

  @override
  String get idle => 'Inactivo';

  @override
  String get offline => 'Sin conexion';

  @override
  String vehicleSummary(int total, int online) {
    return '$total en total - $online en linea';
  }

  @override
  String get noVehiclesWithTrackers => 'No hay vehiculos con rastreadores';

  @override
  String get noTripDataForDate => 'No hay datos de viaje para esta fecha';

  @override
  String get locationServicesEnabled => 'Servicios de ubicacion activados';

  @override
  String get locationPermissionDenied => 'Permiso de ubicacion denegado';

  @override
  String get tripReplay => 'Repeticion del viaje';

  @override
  String get realTimeGpsTracking => 'Seguimiento GPS en tiempo real';

  @override
  String get noGpsTracker => 'Sin rastreador GPS';

  @override
  String get linkGpsTrackerToTrack =>
      'Vincula un rastreador GPS para activar el seguimiento en tiempo real';

  @override
  String get gpsTrackerLinked => 'Rastreador GPS vinculado';

  @override
  String get lastUpdate => 'Ultima actualizacion';

  @override
  String get noVehiclesYet => 'Aun no hay vehiculos';

  @override
  String get addFirstVehicle =>
      'Agrega tu primer vehiculo para comenzar a rastrear su ubicacion y recibir actualizaciones en tiempo real.';

  @override
  String get welcomeBack => 'Bienvenido de nuevo';

  @override
  String get signInToContinueTracking =>
      'Inicia sesion para continuar el seguimiento';

  @override
  String get forgotPassword => 'Olvidaste tu contrasena?';

  @override
  String get signIn => 'Iniciar sesion';

  @override
  String get dontHaveAccount => 'No tienes una cuenta?';

  @override
  String get signUp => 'Registrarse';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get signUpToStartTracking => 'Registrate para comenzar el seguimiento';

  @override
  String get confirmPassword => 'Confirmar contrasena';

  @override
  String get confirmYourPassword => 'Confirma tu contrasena';

  @override
  String get alreadyHaveAccount => 'Ya tienes una cuenta?';

  @override
  String get resetPassword => 'Restablecer contrasena';

  @override
  String get resetPasswordInstructions =>
      'Ingresa tu correo para recibir un enlace de restablecimiento';

  @override
  String get sendResetLink => 'Enviar enlace';

  @override
  String get backToSignIn => 'Volver a iniciar sesion';

  @override
  String get checkYourEmail => 'Revisa tu correo';

  @override
  String get passwordResetSentTo => 'Enviamos un enlace de restablecimiento a:';

  @override
  String get resetPasswordInboxInstructions =>
      'Revisa tu bandeja de entrada y sigue el enlace para restablecer tu contrasena.';

  @override
  String get checkSpamFolder =>
      'Si no ves el correo, revisa la carpeta de spam.';

  @override
  String get resendEmail => 'Reenviar correo';

  @override
  String get email => 'Correo electronico';

  @override
  String get enterYourEmail => 'Ingresa tu correo';

  @override
  String get password => 'Contrasena';

  @override
  String get enterYourPassword => 'Ingresa tu contrasena';

  @override
  String get fullName => 'Nombre completo';

  @override
  String get enterYourFullName => 'Ingresa tu nombre completo';

  @override
  String get profileUpdated => 'Perfil actualizado';

  @override
  String get cameraPermissionDenied => 'Permiso de camara denegado';

  @override
  String get unableToSelectProfilePhoto =>
      'No se pudo seleccionar la foto de perfil';

  @override
  String get takePhoto => 'Tomar foto';

  @override
  String get chooseFromGallery => 'Elegir de la galeria';

  @override
  String get changeProfilePhoto => 'Cambiar foto de perfil';

  @override
  String get emailCannotBeChanged => 'Tu correo no se puede cambiar aqui.';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get setupPermissions => 'Configurar permisos';

  @override
  String get whyWeAsk => 'Por que lo pedimos';

  @override
  String get permissionsIntro =>
      'Permite estos permisos para activar el seguimiento y las alertas en tiempo real.';

  @override
  String get locationWhileUsingApp => 'Ubicacion (mientras usas la aplicacion)';

  @override
  String get locationTrackingRequired =>
      'Necesaria para el mapa y el seguimiento';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get notificationsRequired =>
      'Necesarias para avisarte sobre eventos del rastreador';

  @override
  String get requestAll => 'Solicitar todos';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get refresh => 'Actualizar';

  @override
  String get whyWeNeedThese => 'Por que necesitamos estos permisos';

  @override
  String get permissionsExplanation =>
      'Ubicacion: necesaria para mostrar tus vehiculos en el mapa y centrarlo en tu posicion.\n\nNotificaciones: se usan para informarte sobre eventos importantes del rastreador.\n\nPuedes cambiarlos cuando quieras en Configuracion.';

  @override
  String get ok => 'Aceptar';

  @override
  String get granted => 'Concedido';

  @override
  String get requiresSettings => 'Requiere configuracion';

  @override
  String get denied => 'Denegado';

  @override
  String get allow => 'Permitir';

  @override
  String get openSettings => 'Abrir configuracion';

  @override
  String get locationServices => 'Servicios de ubicacion';

  @override
  String get locationServicesRequired =>
      'Deben estar activados por el sistema para proporcionar actualizaciones GPS.';

  @override
  String get on => 'Activado';

  @override
  String get off => 'Desactivado';

  @override
  String get editGeofence => 'Editar geocerca';

  @override
  String get addGeofence => 'Agregar geocerca';

  @override
  String get geofenceUpdated => 'Geocerca actualizada';

  @override
  String get geofenceCreated => 'Geocerca creada';

  @override
  String get name => 'Nombre';

  @override
  String get radiusMeters => 'Radio (metros)';

  @override
  String get center => 'Centro';

  @override
  String get tapMapToSetCenter => 'Toca el mapa para establecer el centro.';

  @override
  String get trackerEvaluationDelay =>
      'Los cambios pueden tardar hasta un minuto en afectar la evaluacion del rastreador.';

  @override
  String get noLinkedVehicles =>
      'No hay vehiculos vinculados disponibles. Primero vincula un rastreador a un vehiculo.';

  @override
  String get triggerOnEnter => 'Activar al entrar';

  @override
  String get triggerOnExit => 'Activar al salir';

  @override
  String get active => 'Activo';

  @override
  String get createGeofence => 'Crear geocerca';

  @override
  String get selectLinkedVehicle => 'Selecciona al menos un vehiculo vinculado';

  @override
  String get enableGeofenceTrigger =>
      'Activa un disparador de entrada o salida';

  @override
  String get noGeofencesYet => 'Aun no hay geocercas';

  @override
  String get createZoneToMonitor =>
      'Crea una zona para monitorear vehiculos vinculados.';

  @override
  String get deleteGeofence => 'Eliminar geocerca?';

  @override
  String deleteNamedGeofence(String name) {
    return 'Eliminar \"$name\"?';
  }

  @override
  String get delete => 'Eliminar';

  @override
  String geofenceVehicleSummary(String radius, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$radius m | $count vehiculo$_temp0 vinculado$_temp1';
  }

  @override
  String get editVehicle => 'Editar vehiculo';

  @override
  String get vehicleDetails => 'Detalles del vehiculo';

  @override
  String get vehicleNotFound => 'Vehiculo no encontrado';

  @override
  String get vehicle => 'Vehiculo';

  @override
  String get color => 'Color';

  @override
  String get added => 'Agregado';

  @override
  String get trackerLinkedSuccessfully => 'Rastreador vinculado correctamente';

  @override
  String get trackerUnlinkedSuccessfully =>
      'Rastreador desvinculado correctamente';

  @override
  String get unlinkTracker => 'Desvincular rastreador';

  @override
  String get unlinkTrackerConfirmation =>
      'Seguro que quieres desvincular el rastreador GPS de este vehiculo? El rastreador estara disponible para vincularse a otro vehiculo.';

  @override
  String get unlink => 'Desvincular';

  @override
  String get vehicleUpdatedSuccessfully => 'Vehiculo actualizado correctamente';

  @override
  String get vehicleCreatedSuccessfully => 'Vehiculo creado correctamente';

  @override
  String get addImagesAfterVehicle =>
      'Puedes agregar imagenes despues de crear el vehiculo.';

  @override
  String get addPhotosAfterVehicle =>
      'Puedes agregar fotos despues de crear el vehiculo.';

  @override
  String get createVehicle => 'Crear vehiculo';

  @override
  String get requiredInformation => 'Informacion obligatoria';

  @override
  String get vehicleDetailsOptional => 'Detalles del vehiculo (opcional)';

  @override
  String get vehicleName => 'Nombre del vehiculo *';

  @override
  String get vehicleNameHint => 'p. ej., Mi auto';

  @override
  String get plateNumber => 'Numero de placa *';

  @override
  String get plateNumberHint => 'p. ej., ABC-123';

  @override
  String get brand => 'Marca';

  @override
  String get brandHint => 'p. ej., Toyota';

  @override
  String get model => 'Modelo';

  @override
  String get modelHint => 'p. ej., Corolla';

  @override
  String get year => 'Ano';

  @override
  String get yearHint => 'p. ej., 2020';

  @override
  String get photos => 'Fotos';

  @override
  String get add => 'Agregar';

  @override
  String get takePhotoTitle => 'Tomar foto';

  @override
  String get cameraAccessRequired => 'Se requiere acceso a la camara';

  @override
  String get photoLibraryAccessRequired => 'Se requiere acceso a la galeria';

  @override
  String enablePhotoPermission(String permission) {
    return 'Activa el acceso a $permission en Configuracion para agregar fotos.';
  }

  @override
  String get photoLibrary => 'Galeria';

  @override
  String get photosPermissionDenied => 'Permiso de fotos denegado';

  @override
  String failedToPickImage(String error) {
    return 'No se pudo seleccionar la imagen: $error';
  }

  @override
  String get deleteVehicle => 'Eliminar vehiculo';

  @override
  String deleteVehicleConfirmation(String name) {
    return 'Seguro que quieres eliminar \"$name\"?';
  }

  @override
  String unlinkTrackerOnDelete(String trackerId) {
    return 'El rastreador ($trackerId) se desvinculara y estara disponible para otro vehiculo.';
  }

  @override
  String get cannotUndo => 'Esta accion no se puede deshacer.';

  @override
  String get linkGpsTracker => 'Vincular rastreador GPS';

  @override
  String get howToLinkTracker => 'Como vincular un rastreador';

  @override
  String get linkTrackerInstructions =>
      '1. Busca el numero IMEI en tu rastreador GPS\n2. Ingresa el IMEI de 15 digitos\n3. Verifica la informacion del rastreador\n4. Confirma para vincularlo';

  @override
  String get imeiNumber => 'Numero IMEI';

  @override
  String get enterImei => 'Ingresa el IMEI de 15 digitos';

  @override
  String get imeiRequired => 'Ingresa el numero IMEI';

  @override
  String get imeiLength => 'El IMEI debe tener 15 digitos';

  @override
  String get verifyTracker => 'Verificar rastreador';

  @override
  String get trackerNotFound => 'No se encontro el rastreador o ya esta en uso';

  @override
  String get trackerFound => 'Rastreador encontrado';

  @override
  String get provider => 'Proveedor';

  @override
  String get linkTrackerToVehicle => 'Vincular rastreador al vehiculo';

  @override
  String get imeiHelp =>
      'El IMEI suele encontrarse en una etiqueta del dispositivo o en su documentacion. El escaneo de codigos QR estara disponible pronto.';

  @override
  String get mapType => 'Tipo de mapa';

  @override
  String get hideTraffic => 'Ocultar trafico';

  @override
  String get showTraffic => 'Mostrar trafico';

  @override
  String get zoomIn => 'Acercar';

  @override
  String get zoomOut => 'Alejar';

  @override
  String get myLocation => 'Mi ubicacion';

  @override
  String get fitAllVehicles => 'Ajustar todos los vehiculos';

  @override
  String get normal => 'Normal';

  @override
  String get satellite => 'Satelite';

  @override
  String get terrain => 'Terreno';

  @override
  String get hybrid => 'Hibrido';

  @override
  String get playbackSpeed => 'Velocidad de reproduccion';

  @override
  String speedMultiplier(String speed) {
    return 'Velocidad ${speed}x';
  }

  @override
  String get closeReplay => 'Cerrar repeticion';

  @override
  String get pauseReplay => 'Pausar repeticion';

  @override
  String get playReplay => 'Reproducir repeticion';

  @override
  String get restartReplay => 'Reiniciar repeticion';

  @override
  String get locationPermissionRequired => 'Se requiere permiso de ubicacion';

  @override
  String get locationPermissionPermanentlyDenied =>
      'El permiso de ubicacion esta denegado permanentemente. Activalo en la configuracion de la aplicacion para usar esta funcion.';

  @override
  String get enableLocationServices => 'Activar servicios de ubicacion';

  @override
  String get locationServicesTurnedOff =>
      'Los servicios de ubicacion estan desactivados.\n\nActivalos en la configuracion del sistema para usar Mi ubicacion y actualizaciones en tiempo real.';

  @override
  String get locationServicesOffBanner =>
      'Los servicios de ubicacion estan desactivados. Activalos para un seguimiento preciso.';

  @override
  String get enable => 'Activar';

  @override
  String get dismiss => 'Descartar';

  @override
  String openingNavigation(String name) {
    return 'Abriendo navegacion a $name...';
  }

  @override
  String get pageNotFound => 'Pagina no encontrada';

  @override
  String get goHome => 'Ir al inicio';

  @override
  String get grantPermission => 'Conceder permiso';

  @override
  String get tryAgain => 'Intentar de nuevo';

  @override
  String get cameraAccessDescription =>
      'Permite el acceso a la camara para tomar fotos de tu vehiculo.';

  @override
  String get photoLibraryAccessDescription =>
      'Permite el acceso a la galeria para seleccionar imagenes de tu vehiculo.';

  @override
  String get locationAccessDescription =>
      'Permite el acceso a la ubicacion para rastrear tu vehiculo.';

  @override
  String get backgroundLocationDescription =>
      'Permite el acceso a la ubicacion en segundo plano para seguimiento continuo.';

  @override
  String get notificationsDescription =>
      'Activa las notificaciones para recibir alertas sobre tus vehiculos.';

  @override
  String get storageAccessDescription =>
      'Permite el acceso al almacenamiento para guardar imagenes de vehiculos.';

  @override
  String get backgroundLocationRequired =>
      'Se requiere ubicacion en segundo plano';

  @override
  String get notificationsDisabled => 'Notificaciones desactivadas';

  @override
  String get storageAccessRequired => 'Se requiere acceso al almacenamiento';

  @override
  String get cameraAccessShort => 'Se requiere acceso a la camara';

  @override
  String get photoLibraryAccessShort => 'Se requiere acceso a la galeria';

  @override
  String get locationAccessShort => 'Se requiere acceso a la ubicacion';

  @override
  String get notificationsDisabledShort =>
      'Las notificaciones estan desactivadas';

  @override
  String get storageAccessShort => 'Se requiere acceso al almacenamiento';

  @override
  String get firstName => 'Nombre';

  @override
  String get enterYourFirstName => 'Ingresa tu nombre';

  @override
  String get lastName => 'Apellido paterno';

  @override
  String get enterYourLastName => 'Ingresa tu apellido paterno';

  @override
  String get secondLastName => 'Apellido materno';

  @override
  String get enterYourSecondLastName => 'Ingresa tu apellido materno';

  @override
  String get gender => 'Género';

  @override
  String get birthDate => 'Fecha de nacimiento';

  @override
  String get male => 'Masculino';

  @override
  String get female => 'Femenino';

  @override
  String get other => 'Otro';

  @override
  String get preferNotToSay => 'Prefiero no decirlo';

  @override
  String get selectGender => 'Selecciona tu género';

  @override
  String get selectBirthDate => 'Selecciona tu fecha de nacimiento';
}
