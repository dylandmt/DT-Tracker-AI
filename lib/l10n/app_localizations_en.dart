// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DT Tracker';

  @override
  String get settings => 'Settings';

  @override
  String get account => 'Account';

  @override
  String get tracking => 'Tracking';

  @override
  String get app => 'App';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'Choose the app language';

  @override
  String get systemDefault => 'System default';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Spanish';

  @override
  String get profile => 'Profile';

  @override
  String get editProfileInformation => 'Edit your profile information';

  @override
  String get trackerEvents => 'Tracker events';

  @override
  String get viewTrackerActivity => 'View geofence and tracker activity';

  @override
  String get speedAlerts => 'Speed alerts';

  @override
  String get configureSpeedAlerts => 'Configure speed limit alerts';

  @override
  String get speedAlertsComingSoon => 'Speed alerts coming soon';

  @override
  String get geofenceAlerts => 'Geofence alerts';

  @override
  String get geofenceAlertsDescription =>
      'Create events when vehicles enter or exit zones';

  @override
  String get geofences => 'Geofences';

  @override
  String get manageGeofenceZones => 'Manage geofence zones';

  @override
  String get about => 'About';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String get getHelpWithApp => 'Get help with the app';

  @override
  String get helpComingSoon => 'Help & Support coming soon';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirmation => 'Are you sure you want to sign out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get user => 'User';

  @override
  String get aboutDescription =>
      'Real-time GPS vehicle tracking app with geofencing and alerts.';

  @override
  String get vehicles => 'Vehicles';

  @override
  String get map => 'Map';

  @override
  String get myVehicles => 'My Vehicles';

  @override
  String get addVehicle => 'Add Vehicle';

  @override
  String get vehicleDeleted => 'Vehicle deleted successfully';

  @override
  String get events => 'Events';

  @override
  String get noTrackerEvents => 'No tracker events yet';

  @override
  String get archiveEvent => 'Archive event';

  @override
  String get total => 'Total';

  @override
  String get online => 'Online';

  @override
  String get moving => 'Moving';

  @override
  String get dateFormat => 'MMM d, y';

  @override
  String get dateTimeFormat => 'MMM d, y HH:mm';

  @override
  String get justNow => 'Just now';

  @override
  String timeAgoMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: '1 year ago',
    );
    return '$_temp0';
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
  String get speed => 'Speed';

  @override
  String get battery => 'Battery';

  @override
  String get updated => 'Updated';

  @override
  String get history => 'History';

  @override
  String get navigate => 'Navigate';

  @override
  String get idle => 'Idle';

  @override
  String get offline => 'Offline';

  @override
  String vehicleSummary(int total, int online) {
    return '$total total - $online online';
  }

  @override
  String get noVehiclesWithTrackers => 'No vehicles with trackers';

  @override
  String get noTripDataForDate => 'No trip data for this date';

  @override
  String get locationServicesEnabled => 'Location services enabled';

  @override
  String get locationPermissionDenied => 'Location permission denied';

  @override
  String get tripReplay => 'Trip replay';

  @override
  String get realTimeGpsTracking => 'Real-time GPS Tracking';

  @override
  String get noGpsTracker => 'No GPS Tracker';

  @override
  String get linkGpsTrackerToTrack =>
      'Link a GPS tracker to enable real-time tracking';

  @override
  String get gpsTrackerLinked => 'GPS Tracker Linked';

  @override
  String get lastUpdate => 'Last Update';

  @override
  String get noVehiclesYet => 'No Vehicles Yet';

  @override
  String get addFirstVehicle =>
      'Add your first vehicle to start tracking its location and get real-time updates.';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInToContinueTracking => 'Sign in to continue tracking';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get signIn => 'Sign In';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign Up';

  @override
  String get createAccount => 'Create Account';

  @override
  String get signUpToStartTracking => 'Sign up to start tracking';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmYourPassword => 'Confirm your password';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetPasswordInstructions =>
      'Enter your email to receive a password reset link';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get backToSignIn => 'Back to Sign In';

  @override
  String get checkYourEmail => 'Check Your Email';

  @override
  String get passwordResetSentTo => 'We\'ve sent a password reset link to:';

  @override
  String get resetPasswordInboxInstructions =>
      'Check your inbox and follow the link to reset your password.';

  @override
  String get checkSpamFolder =>
      'If you don\'t see the email, check your spam folder.';

  @override
  String get resendEmail => 'Resend Email';

  @override
  String get email => 'Email';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get password => 'Password';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get fullName => 'Full Name';

  @override
  String get enterYourFullName => 'Enter your full name';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get cameraPermissionDenied => 'Camera permission denied';

  @override
  String get unableToSelectProfilePhoto => 'Unable to select profile photo';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get changeProfilePhoto => 'Change profile photo';

  @override
  String get emailCannotBeChanged =>
      'Your email address cannot be changed here.';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get setupPermissions => 'Setup Permissions';

  @override
  String get whyWeAsk => 'Why we ask';

  @override
  String get permissionsIntro =>
      'Allow these permissions to enable real-time tracking and alerts.';

  @override
  String get locationWhileUsingApp => 'Location (While Using the App)';

  @override
  String get locationTrackingRequired =>
      'Required for map and tracking features';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsRequired =>
      'Needed to alert you about tracker events';

  @override
  String get requestAll => 'Request All';

  @override
  String get continueLabel => 'Continue';

  @override
  String get refresh => 'Refresh';

  @override
  String get whyWeNeedThese => 'Why We Need These';

  @override
  String get permissionsExplanation =>
      'Location: required to show your vehicles on the map and to center the map on your position.\n\nNotifications: used to inform you about important tracker events (e.g., status changes, alerts).\n\nYou can change these anytime in Settings.';

  @override
  String get ok => 'OK';

  @override
  String get granted => 'Granted';

  @override
  String get requiresSettings => 'Requires Settings';

  @override
  String get denied => 'Denied';

  @override
  String get allow => 'Allow';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get locationServices => 'Location Services';

  @override
  String get locationServicesRequired =>
      'Must be enabled by the system to provide GPS updates.';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get editGeofence => 'Edit Geofence';

  @override
  String get addGeofence => 'Add Geofence';

  @override
  String get geofenceUpdated => 'Geofence updated';

  @override
  String get geofenceCreated => 'Geofence created';

  @override
  String get name => 'Name';

  @override
  String get radiusMeters => 'Radius (meters)';

  @override
  String get center => 'Center';

  @override
  String get tapMapToSetCenter => 'Tap the map to set the center.';

  @override
  String get trackerEvaluationDelay =>
      'Changes can take up to one minute to affect tracker evaluation.';

  @override
  String get noLinkedVehicles =>
      'No linked vehicles are available. Link a tracker to a vehicle first.';

  @override
  String get triggerOnEnter => 'Trigger on enter';

  @override
  String get triggerOnExit => 'Trigger on exit';

  @override
  String get active => 'Active';

  @override
  String get createGeofence => 'Create geofence';

  @override
  String get selectLinkedVehicle => 'Select at least one linked vehicle';

  @override
  String get enableGeofenceTrigger => 'Enable an enter or exit trigger';

  @override
  String get noGeofencesYet => 'No geofences yet';

  @override
  String get createZoneToMonitor => 'Create a zone to monitor linked vehicles.';

  @override
  String get deleteGeofence => 'Delete geofence?';

  @override
  String deleteNamedGeofence(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get delete => 'Delete';

  @override
  String geofenceVehicleSummary(String radius, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vehicles',
      one: 'vehicle',
    );
    return '$radius m | $count linked $_temp0';
  }

  @override
  String get editVehicle => 'Edit Vehicle';

  @override
  String get vehicleDetails => 'Vehicle Details';

  @override
  String get vehicleNotFound => 'Vehicle not found';

  @override
  String get vehicle => 'Vehicle';

  @override
  String get color => 'Color';

  @override
  String get added => 'Added';

  @override
  String get trackerLinkedSuccessfully => 'Tracker linked successfully';

  @override
  String get trackerUnlinkedSuccessfully => 'Tracker unlinked successfully';

  @override
  String get unlinkTracker => 'Unlink Tracker';

  @override
  String get unlinkTrackerConfirmation =>
      'Are you sure you want to unlink the GPS tracker from this vehicle? The tracker will become available for linking to another vehicle.';

  @override
  String get unlink => 'Unlink';

  @override
  String get vehicleUpdatedSuccessfully => 'Vehicle updated successfully';

  @override
  String get vehicleCreatedSuccessfully => 'Vehicle created successfully';

  @override
  String get addImagesAfterVehicle =>
      'You can add images after creating the vehicle.';

  @override
  String get addPhotosAfterVehicle =>
      'You can add photos after creating the vehicle.';

  @override
  String get createVehicle => 'Create Vehicle';

  @override
  String get requiredInformation => 'Required Information';

  @override
  String get vehicleDetailsOptional => 'Vehicle Details (Optional)';

  @override
  String get vehicleName => 'Vehicle Name *';

  @override
  String get vehicleNameHint => 'e.g., My Car';

  @override
  String get plateNumber => 'Plate Number *';

  @override
  String get plateNumberHint => 'e.g., ABC-123';

  @override
  String get brand => 'Brand';

  @override
  String get brandHint => 'e.g., Toyota';

  @override
  String get model => 'Model';

  @override
  String get modelHint => 'e.g., Corolla';

  @override
  String get year => 'Year';

  @override
  String get yearHint => 'e.g., 2020';

  @override
  String get photos => 'Photos';

  @override
  String get add => 'Add';

  @override
  String get takePhotoTitle => 'Take Photo';

  @override
  String get cameraAccessRequired => 'Camera Access Required';

  @override
  String get photoLibraryAccessRequired => 'Photo Library Access Required';

  @override
  String enablePhotoPermission(String permission) {
    return 'Please enable $permission access in Settings to add photos.';
  }

  @override
  String get photoLibrary => 'Photo Library';

  @override
  String get photosPermissionDenied => 'Photos permission denied';

  @override
  String failedToPickImage(String error) {
    return 'Failed to pick image: $error';
  }

  @override
  String get deleteVehicle => 'Delete Vehicle';

  @override
  String deleteVehicleConfirmation(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String unlinkTrackerOnDelete(String trackerId) {
    return 'The tracker ($trackerId) will be unlinked and become available for linking to another vehicle.';
  }

  @override
  String get cannotUndo => 'This action cannot be undone.';

  @override
  String get linkGpsTracker => 'Link GPS Tracker';

  @override
  String get howToLinkTracker => 'How to link a tracker';

  @override
  String get linkTrackerInstructions =>
      '1. Find the IMEI number on your GPS tracker device\n2. Enter the 15-digit IMEI number below\n3. Verify the tracker information\n4. Confirm to link the tracker';

  @override
  String get imeiNumber => 'IMEI Number';

  @override
  String get enterImei => 'Enter 15-digit IMEI';

  @override
  String get imeiRequired => 'Please enter the IMEI number';

  @override
  String get imeiLength => 'IMEI must be 15 digits';

  @override
  String get verifyTracker => 'Verify Tracker';

  @override
  String get trackerNotFound => 'Tracker not found or already in use';

  @override
  String get trackerFound => 'Tracker Found';

  @override
  String get provider => 'Provider';

  @override
  String get linkTrackerToVehicle => 'Link Tracker to Vehicle';

  @override
  String get imeiHelp =>
      'The IMEI number can usually be found on a sticker on the device or in the device documentation. QR code scanning will be available soon.';

  @override
  String get mapType => 'Map type';

  @override
  String get hideTraffic => 'Hide traffic';

  @override
  String get showTraffic => 'Show traffic';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get myLocation => 'My location';

  @override
  String get fitAllVehicles => 'Fit all vehicles';

  @override
  String get normal => 'Normal';

  @override
  String get satellite => 'Satellite';

  @override
  String get terrain => 'Terrain';

  @override
  String get hybrid => 'Hybrid';

  @override
  String get playbackSpeed => 'Playback speed';

  @override
  String speedMultiplier(String speed) {
    return '${speed}x speed';
  }

  @override
  String get closeReplay => 'Close replay';

  @override
  String get pauseReplay => 'Pause replay';

  @override
  String get playReplay => 'Play replay';

  @override
  String get restartReplay => 'Restart replay';

  @override
  String get locationPermissionRequired => 'Location Permission Required';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Location permission is permanently denied. Please enable it in app settings to use this feature.';

  @override
  String get enableLocationServices => 'Enable Location Services';

  @override
  String get locationServicesTurnedOff =>
      'Location services are turned off.\n\nPlease enable them in system settings to use My Location and real-time updates.';

  @override
  String get locationServicesOffBanner =>
      'Location services are off. Enable them for accurate tracking.';

  @override
  String get enable => 'Enable';

  @override
  String get dismiss => 'Dismiss';

  @override
  String openingNavigation(String name) {
    return 'Opening navigation to $name...';
  }

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get goHome => 'Go Home';

  @override
  String get grantPermission => 'Grant Permission';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get cameraAccessDescription =>
      'Please allow camera access to take photos of your vehicle.';

  @override
  String get photoLibraryAccessDescription =>
      'Please allow photo library access to select images for your vehicle.';

  @override
  String get locationAccessDescription =>
      'Please allow location access to track your vehicle.';

  @override
  String get backgroundLocationDescription =>
      'Please allow background location access for continuous tracking.';

  @override
  String get notificationsDescription =>
      'Please enable notifications to receive alerts about your vehicles.';

  @override
  String get storageAccessDescription =>
      'Please allow storage access to save vehicle images.';

  @override
  String get backgroundLocationRequired => 'Background Location Required';

  @override
  String get notificationsDisabled => 'Notifications Disabled';

  @override
  String get storageAccessRequired => 'Storage Access Required';

  @override
  String get cameraAccessShort => 'Camera access is required';

  @override
  String get photoLibraryAccessShort => 'Photo library access is required';

  @override
  String get locationAccessShort => 'Location access is required';

  @override
  String get notificationsDisabledShort => 'Notifications are disabled';

  @override
  String get storageAccessShort => 'Storage access is required';

  @override
  String get firstName => 'First name';

  @override
  String get enterYourFirstName => 'Enter your first name';

  @override
  String get lastName => 'Last name';

  @override
  String get enterYourLastName => 'Enter your last name';

  @override
  String get secondLastName => 'Second last name';

  @override
  String get enterYourSecondLastName => 'Enter your second last name';

  @override
  String get gender => 'Gender';

  @override
  String get birthDate => 'Date of birth';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get other => 'Other';

  @override
  String get preferNotToSay => 'Prefer not to say';

  @override
  String get selectGender => 'Select your gender';

  @override
  String get selectBirthDate => 'Select your date of birth';
}
