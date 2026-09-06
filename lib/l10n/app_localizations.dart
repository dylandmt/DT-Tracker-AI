import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'DT Tracker'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @tracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get tracking;

  /// No description provided for @app.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get app;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the app language'**
  String get languageSubtitle;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfileInformation.
  ///
  /// In en, this message translates to:
  /// **'Edit your profile information'**
  String get editProfileInformation;

  /// No description provided for @trackerEvents.
  ///
  /// In en, this message translates to:
  /// **'Tracker events'**
  String get trackerEvents;

  /// No description provided for @viewTrackerActivity.
  ///
  /// In en, this message translates to:
  /// **'View geofence and tracker activity'**
  String get viewTrackerActivity;

  /// No description provided for @speedAlerts.
  ///
  /// In en, this message translates to:
  /// **'Speed alerts'**
  String get speedAlerts;

  /// No description provided for @configureSpeedAlerts.
  ///
  /// In en, this message translates to:
  /// **'Configure speed limit alerts'**
  String get configureSpeedAlerts;

  /// No description provided for @speedAlertsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Speed alerts coming soon'**
  String get speedAlertsComingSoon;

  /// No description provided for @geofenceAlerts.
  ///
  /// In en, this message translates to:
  /// **'Geofence alerts'**
  String get geofenceAlerts;

  /// No description provided for @geofenceAlertsDescription.
  ///
  /// In en, this message translates to:
  /// **'Create events when vehicles enter or exit zones'**
  String get geofenceAlertsDescription;

  /// No description provided for @emailAlerts.
  ///
  /// In en, this message translates to:
  /// **'Email alerts'**
  String get emailAlerts;

  /// No description provided for @emailAlertsDescription.
  ///
  /// In en, this message translates to:
  /// **'Receive tracker and geofence alerts by email'**
  String get emailAlertsDescription;

  /// No description provided for @geofences.
  ///
  /// In en, this message translates to:
  /// **'Geofences'**
  String get geofences;

  /// No description provided for @manageGeofenceZones.
  ///
  /// In en, this message translates to:
  /// **'Manage geofence zones'**
  String get manageGeofenceZones;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @getHelpWithApp.
  ///
  /// In en, this message translates to:
  /// **'Get help with the app'**
  String get getHelpWithApp;

  /// No description provided for @helpComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Help & Support coming soon'**
  String get helpComingSoon;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Real-time GPS vehicle tracking app with geofencing and alerts.'**
  String get aboutDescription;

  /// No description provided for @vehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get vehicles;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @myVehicles.
  ///
  /// In en, this message translates to:
  /// **'My Vehicles'**
  String get myVehicles;

  /// No description provided for @addVehicle.
  ///
  /// In en, this message translates to:
  /// **'Add Vehicle'**
  String get addVehicle;

  /// No description provided for @vehicleDeleted.
  ///
  /// In en, this message translates to:
  /// **'Vehicle deleted successfully'**
  String get vehicleDeleted;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @noTrackerEvents.
  ///
  /// In en, this message translates to:
  /// **'No tracker events yet'**
  String get noTrackerEvents;

  /// No description provided for @archiveEvent.
  ///
  /// In en, this message translates to:
  /// **'Archive event'**
  String get archiveEvent;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @moving.
  ///
  /// In en, this message translates to:
  /// **'Moving'**
  String get moving;

  /// No description provided for @dateFormat.
  ///
  /// In en, this message translates to:
  /// **'MMM d, y'**
  String get dateFormat;

  /// No description provided for @dateTimeFormat.
  ///
  /// In en, this message translates to:
  /// **'MMM d, y HH:mm'**
  String get dateTimeFormat;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @timeAgoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String timeAgoMinutes(int count);

  /// No description provided for @timeAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String timeAgoHours(int count);

  /// No description provided for @timeAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String timeAgoDays(int count);

  /// No description provided for @timeAgoMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month ago} other{{count} months ago}}'**
  String timeAgoMonths(int count);

  /// No description provided for @timeAgoYears.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year ago} other{{count} years ago}}'**
  String timeAgoYears(int count);

  /// No description provided for @speedKilometersPerHour.
  ///
  /// In en, this message translates to:
  /// **'{speed} km/h'**
  String speedKilometersPerHour(String speed);

  /// No description provided for @distanceKilometers.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String distanceKilometers(String distance);

  /// No description provided for @distanceMeters.
  ///
  /// In en, this message translates to:
  /// **'{distance} m'**
  String distanceMeters(String distance);

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get battery;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @idle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get idle;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @vehicleSummary.
  ///
  /// In en, this message translates to:
  /// **'{total} total - {online} online'**
  String vehicleSummary(int total, int online);

  /// No description provided for @noVehiclesWithTrackers.
  ///
  /// In en, this message translates to:
  /// **'No vehicles with trackers'**
  String get noVehiclesWithTrackers;

  /// No description provided for @noTripDataForDate.
  ///
  /// In en, this message translates to:
  /// **'No trip data for this date'**
  String get noTripDataForDate;

  /// No description provided for @locationServicesEnabled.
  ///
  /// In en, this message translates to:
  /// **'Location services enabled'**
  String get locationServicesEnabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// No description provided for @tripReplay.
  ///
  /// In en, this message translates to:
  /// **'Trip replay'**
  String get tripReplay;

  /// No description provided for @realTimeGpsTracking.
  ///
  /// In en, this message translates to:
  /// **'Real-time GPS Tracking'**
  String get realTimeGpsTracking;

  /// No description provided for @noGpsTracker.
  ///
  /// In en, this message translates to:
  /// **'No GPS Tracker'**
  String get noGpsTracker;

  /// No description provided for @linkGpsTrackerToTrack.
  ///
  /// In en, this message translates to:
  /// **'Link a GPS tracker to enable real-time tracking'**
  String get linkGpsTrackerToTrack;

  /// No description provided for @gpsTrackerLinked.
  ///
  /// In en, this message translates to:
  /// **'GPS Tracker Linked'**
  String get gpsTrackerLinked;

  /// No description provided for @lastUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last Update'**
  String get lastUpdate;

  /// No description provided for @noVehiclesYet.
  ///
  /// In en, this message translates to:
  /// **'No Vehicles Yet'**
  String get noVehiclesYet;

  /// No description provided for @addFirstVehicle.
  ///
  /// In en, this message translates to:
  /// **'Add your first vehicle to start tracking its location and get real-time updates.'**
  String get addFirstVehicle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInToContinueTracking.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue tracking'**
  String get signInToContinueTracking;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @signUpToStartTracking.
  ///
  /// In en, this message translates to:
  /// **'Sign up to start tracking'**
  String get signUpToStartTracking;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmYourPassword;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @resetPasswordInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a password reset link'**
  String get resetPasswordInstructions;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get backToSignIn;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check Your Email'**
  String get checkYourEmail;

  /// No description provided for @passwordResetSentTo.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a password reset link to:'**
  String get passwordResetSentTo;

  /// No description provided for @resetPasswordInboxInstructions.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox and follow the link to reset your password.'**
  String get resetPasswordInboxInstructions;

  /// No description provided for @checkSpamFolder.
  ///
  /// In en, this message translates to:
  /// **'If you don\'t see the email, check your spam folder.'**
  String get checkSpamFolder;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend Email'**
  String get resendEmail;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied'**
  String get cameraPermissionDenied;

  /// No description provided for @unableToSelectProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Unable to select profile photo'**
  String get unableToSelectProfilePhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get changeProfilePhoto;

  /// No description provided for @emailCannotBeChanged.
  ///
  /// In en, this message translates to:
  /// **'Your email address cannot be changed here.'**
  String get emailCannotBeChanged;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @setupPermissions.
  ///
  /// In en, this message translates to:
  /// **'Setup Permissions'**
  String get setupPermissions;

  /// No description provided for @whyWeAsk.
  ///
  /// In en, this message translates to:
  /// **'Why we ask'**
  String get whyWeAsk;

  /// No description provided for @permissionsIntro.
  ///
  /// In en, this message translates to:
  /// **'Allow these permissions to enable real-time tracking and alerts.'**
  String get permissionsIntro;

  /// No description provided for @locationWhileUsingApp.
  ///
  /// In en, this message translates to:
  /// **'Location (While Using the App)'**
  String get locationWhileUsingApp;

  /// No description provided for @locationTrackingRequired.
  ///
  /// In en, this message translates to:
  /// **'Required for map and tracking features'**
  String get locationTrackingRequired;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsRequired.
  ///
  /// In en, this message translates to:
  /// **'Needed to alert you about tracker events'**
  String get notificationsRequired;

  /// No description provided for @requestAll.
  ///
  /// In en, this message translates to:
  /// **'Request All'**
  String get requestAll;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @whyWeNeedThese.
  ///
  /// In en, this message translates to:
  /// **'Why We Need These'**
  String get whyWeNeedThese;

  /// No description provided for @permissionsExplanation.
  ///
  /// In en, this message translates to:
  /// **'Location: required to show your vehicles on the map and to center the map on your position.\n\nNotifications: used to inform you about important tracker events (e.g., status changes, alerts).\n\nYou can change these anytime in Settings.'**
  String get permissionsExplanation;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @granted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get granted;

  /// No description provided for @requiresSettings.
  ///
  /// In en, this message translates to:
  /// **'Requires Settings'**
  String get requiresSettings;

  /// No description provided for @denied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get denied;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @locationServices.
  ///
  /// In en, this message translates to:
  /// **'Location Services'**
  String get locationServices;

  /// No description provided for @locationServicesRequired.
  ///
  /// In en, this message translates to:
  /// **'Must be enabled by the system to provide GPS updates.'**
  String get locationServicesRequired;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @editGeofence.
  ///
  /// In en, this message translates to:
  /// **'Edit Geofence'**
  String get editGeofence;

  /// No description provided for @addGeofence.
  ///
  /// In en, this message translates to:
  /// **'Add Geofence'**
  String get addGeofence;

  /// No description provided for @geofenceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Geofence updated'**
  String get geofenceUpdated;

  /// No description provided for @geofenceCreated.
  ///
  /// In en, this message translates to:
  /// **'Geofence created'**
  String get geofenceCreated;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @radiusMeters.
  ///
  /// In en, this message translates to:
  /// **'Radius (meters)'**
  String get radiusMeters;

  /// No description provided for @center.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get center;

  /// No description provided for @tapMapToSetCenter.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to set the center.'**
  String get tapMapToSetCenter;

  /// No description provided for @trackerEvaluationDelay.
  ///
  /// In en, this message translates to:
  /// **'Changes can take up to one minute to affect tracker evaluation.'**
  String get trackerEvaluationDelay;

  /// No description provided for @noLinkedVehicles.
  ///
  /// In en, this message translates to:
  /// **'No linked vehicles are available. Link a tracker to a vehicle first.'**
  String get noLinkedVehicles;

  /// No description provided for @triggerOnEnter.
  ///
  /// In en, this message translates to:
  /// **'Trigger on enter'**
  String get triggerOnEnter;

  /// No description provided for @triggerOnExit.
  ///
  /// In en, this message translates to:
  /// **'Trigger on exit'**
  String get triggerOnExit;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @createGeofence.
  ///
  /// In en, this message translates to:
  /// **'Create geofence'**
  String get createGeofence;

  /// No description provided for @selectLinkedVehicle.
  ///
  /// In en, this message translates to:
  /// **'Select at least one linked vehicle'**
  String get selectLinkedVehicle;

  /// No description provided for @enableGeofenceTrigger.
  ///
  /// In en, this message translates to:
  /// **'Enable an enter or exit trigger'**
  String get enableGeofenceTrigger;

  /// No description provided for @noGeofencesYet.
  ///
  /// In en, this message translates to:
  /// **'No geofences yet'**
  String get noGeofencesYet;

  /// No description provided for @createZoneToMonitor.
  ///
  /// In en, this message translates to:
  /// **'Create a zone to monitor linked vehicles.'**
  String get createZoneToMonitor;

  /// No description provided for @deleteGeofence.
  ///
  /// In en, this message translates to:
  /// **'Delete geofence?'**
  String get deleteGeofence;

  /// No description provided for @deleteNamedGeofence.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteNamedGeofence(String name);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @geofenceVehicleSummary.
  ///
  /// In en, this message translates to:
  /// **'{radius} m | {count} linked {count, plural, =1{vehicle} other{vehicles}}'**
  String geofenceVehicleSummary(String radius, int count);

  /// No description provided for @editVehicle.
  ///
  /// In en, this message translates to:
  /// **'Edit Vehicle'**
  String get editVehicle;

  /// No description provided for @vehicleDetails.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Details'**
  String get vehicleDetails;

  /// No description provided for @vehicleNotFound.
  ///
  /// In en, this message translates to:
  /// **'Vehicle not found'**
  String get vehicleNotFound;

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @added.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get added;

  /// No description provided for @trackerLinkedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Tracker linked successfully'**
  String get trackerLinkedSuccessfully;

  /// No description provided for @trackerUnlinkedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Tracker unlinked successfully'**
  String get trackerUnlinkedSuccessfully;

  /// No description provided for @unlinkTracker.
  ///
  /// In en, this message translates to:
  /// **'Unlink Tracker'**
  String get unlinkTracker;

  /// No description provided for @unlinkTrackerConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unlink the GPS tracker from this vehicle? The tracker will become available for linking to another vehicle.'**
  String get unlinkTrackerConfirmation;

  /// No description provided for @unlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get unlink;

  /// No description provided for @vehicleUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Vehicle updated successfully'**
  String get vehicleUpdatedSuccessfully;

  /// No description provided for @vehicleCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Vehicle created successfully'**
  String get vehicleCreatedSuccessfully;

  /// No description provided for @addImagesAfterVehicle.
  ///
  /// In en, this message translates to:
  /// **'You can add images after creating the vehicle.'**
  String get addImagesAfterVehicle;

  /// No description provided for @addPhotosAfterVehicle.
  ///
  /// In en, this message translates to:
  /// **'You can add photos after creating the vehicle.'**
  String get addPhotosAfterVehicle;

  /// No description provided for @createVehicle.
  ///
  /// In en, this message translates to:
  /// **'Create Vehicle'**
  String get createVehicle;

  /// No description provided for @requiredInformation.
  ///
  /// In en, this message translates to:
  /// **'Required Information'**
  String get requiredInformation;

  /// No description provided for @vehicleDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Details (Optional)'**
  String get vehicleDetailsOptional;

  /// No description provided for @vehicleName.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Name *'**
  String get vehicleName;

  /// No description provided for @vehicleNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., My Car'**
  String get vehicleNameHint;

  /// No description provided for @plateNumber.
  ///
  /// In en, this message translates to:
  /// **'Plate Number *'**
  String get plateNumber;

  /// No description provided for @plateNumberHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., ABC-123'**
  String get plateNumberHint;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @brandHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Toyota'**
  String get brandHint;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @modelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Corolla'**
  String get modelHint;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @yearHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 2020'**
  String get yearHint;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @takePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhotoTitle;

  /// No description provided for @cameraAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera Access Required'**
  String get cameraAccessRequired;

  /// No description provided for @photoLibraryAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Photo Library Access Required'**
  String get photoLibraryAccessRequired;

  /// No description provided for @enablePhotoPermission.
  ///
  /// In en, this message translates to:
  /// **'Please enable {permission} access in Settings to add photos.'**
  String enablePhotoPermission(String permission);

  /// No description provided for @photoLibrary.
  ///
  /// In en, this message translates to:
  /// **'Photo Library'**
  String get photoLibrary;

  /// No description provided for @photosPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Photos permission denied'**
  String get photosPermissionDenied;

  /// No description provided for @failedToPickImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image: {error}'**
  String failedToPickImage(String error);

  /// No description provided for @deleteVehicle.
  ///
  /// In en, this message translates to:
  /// **'Delete Vehicle'**
  String get deleteVehicle;

  /// No description provided for @deleteVehicleConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteVehicleConfirmation(String name);

  /// No description provided for @unlinkTrackerOnDelete.
  ///
  /// In en, this message translates to:
  /// **'The tracker ({trackerId}) will be unlinked and become available for linking to another vehicle.'**
  String unlinkTrackerOnDelete(String trackerId);

  /// No description provided for @cannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get cannotUndo;

  /// No description provided for @linkGpsTracker.
  ///
  /// In en, this message translates to:
  /// **'Link GPS Tracker'**
  String get linkGpsTracker;

  /// No description provided for @howToLinkTracker.
  ///
  /// In en, this message translates to:
  /// **'How to link a tracker'**
  String get howToLinkTracker;

  /// No description provided for @linkTrackerInstructions.
  ///
  /// In en, this message translates to:
  /// **'1. Find the IMEI number on your GPS tracker device\n2. Enter the 15-digit IMEI number below\n3. Verify the tracker information\n4. Confirm to link the tracker'**
  String get linkTrackerInstructions;

  /// No description provided for @imeiNumber.
  ///
  /// In en, this message translates to:
  /// **'IMEI Number'**
  String get imeiNumber;

  /// No description provided for @enterImei.
  ///
  /// In en, this message translates to:
  /// **'Enter 15-digit IMEI'**
  String get enterImei;

  /// No description provided for @imeiRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the IMEI number'**
  String get imeiRequired;

  /// No description provided for @imeiLength.
  ///
  /// In en, this message translates to:
  /// **'IMEI must be 15 digits'**
  String get imeiLength;

  /// No description provided for @verifyTracker.
  ///
  /// In en, this message translates to:
  /// **'Verify Tracker'**
  String get verifyTracker;

  /// No description provided for @trackerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Tracker not found or already in use'**
  String get trackerNotFound;

  /// No description provided for @trackerFound.
  ///
  /// In en, this message translates to:
  /// **'Tracker Found'**
  String get trackerFound;

  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// No description provided for @linkTrackerToVehicle.
  ///
  /// In en, this message translates to:
  /// **'Link Tracker to Vehicle'**
  String get linkTrackerToVehicle;

  /// No description provided for @imeiHelp.
  ///
  /// In en, this message translates to:
  /// **'The IMEI number can usually be found on a sticker on the device or in the device documentation. QR code scanning will be available soon.'**
  String get imeiHelp;

  /// No description provided for @mapType.
  ///
  /// In en, this message translates to:
  /// **'Map type'**
  String get mapType;

  /// No description provided for @hideTraffic.
  ///
  /// In en, this message translates to:
  /// **'Hide traffic'**
  String get hideTraffic;

  /// No description provided for @showTraffic.
  ///
  /// In en, this message translates to:
  /// **'Show traffic'**
  String get showTraffic;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get myLocation;

  /// No description provided for @fitAllVehicles.
  ///
  /// In en, this message translates to:
  /// **'Fit all vehicles'**
  String get fitAllVehicles;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @satellite.
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get satellite;

  /// No description provided for @terrain.
  ///
  /// In en, this message translates to:
  /// **'Terrain'**
  String get terrain;

  /// No description provided for @hybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get hybrid;

  /// No description provided for @playbackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get playbackSpeed;

  /// No description provided for @speedMultiplier.
  ///
  /// In en, this message translates to:
  /// **'{speed}x speed'**
  String speedMultiplier(String speed);

  /// No description provided for @closeReplay.
  ///
  /// In en, this message translates to:
  /// **'Close replay'**
  String get closeReplay;

  /// No description provided for @pauseReplay.
  ///
  /// In en, this message translates to:
  /// **'Pause replay'**
  String get pauseReplay;

  /// No description provided for @playReplay.
  ///
  /// In en, this message translates to:
  /// **'Play replay'**
  String get playReplay;

  /// No description provided for @restartReplay.
  ///
  /// In en, this message translates to:
  /// **'Restart replay'**
  String get restartReplay;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location Permission Required'**
  String get locationPermissionRequired;

  /// No description provided for @locationPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission is permanently denied. Please enable it in app settings to use this feature.'**
  String get locationPermissionPermanentlyDenied;

  /// No description provided for @enableLocationServices.
  ///
  /// In en, this message translates to:
  /// **'Enable Location Services'**
  String get enableLocationServices;

  /// No description provided for @locationServicesTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are turned off.\n\nPlease enable them in system settings to use My Location and real-time updates.'**
  String get locationServicesTurnedOff;

  /// No description provided for @locationServicesOffBanner.
  ///
  /// In en, this message translates to:
  /// **'Location services are off. Enable them for accurate tracking.'**
  String get locationServicesOffBanner;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @openingNavigation.
  ///
  /// In en, this message translates to:
  /// **'Opening navigation to {name}...'**
  String openingNavigation(String name);

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHome;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @cameraAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Please allow camera access to take photos of your vehicle.'**
  String get cameraAccessDescription;

  /// No description provided for @photoLibraryAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Please allow photo library access to select images for your vehicle.'**
  String get photoLibraryAccessDescription;

  /// No description provided for @locationAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Please allow location access to track your vehicle.'**
  String get locationAccessDescription;

  /// No description provided for @backgroundLocationDescription.
  ///
  /// In en, this message translates to:
  /// **'Please allow background location access for continuous tracking.'**
  String get backgroundLocationDescription;

  /// No description provided for @notificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enable notifications to receive alerts about your vehicles.'**
  String get notificationsDescription;

  /// No description provided for @storageAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Please allow storage access to save vehicle images.'**
  String get storageAccessDescription;

  /// No description provided for @backgroundLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Background Location Required'**
  String get backgroundLocationRequired;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications Disabled'**
  String get notificationsDisabled;

  /// No description provided for @storageAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage Access Required'**
  String get storageAccessRequired;

  /// No description provided for @cameraAccessShort.
  ///
  /// In en, this message translates to:
  /// **'Camera access is required'**
  String get cameraAccessShort;

  /// No description provided for @photoLibraryAccessShort.
  ///
  /// In en, this message translates to:
  /// **'Photo library access is required'**
  String get photoLibraryAccessShort;

  /// No description provided for @locationAccessShort.
  ///
  /// In en, this message translates to:
  /// **'Location access is required'**
  String get locationAccessShort;

  /// No description provided for @notificationsDisabledShort.
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled'**
  String get notificationsDisabledShort;

  /// No description provided for @storageAccessShort.
  ///
  /// In en, this message translates to:
  /// **'Storage access is required'**
  String get storageAccessShort;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @enterYourFirstName.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get enterYourFirstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @enterYourLastName.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name'**
  String get enterYourLastName;

  /// No description provided for @secondLastName.
  ///
  /// In en, this message translates to:
  /// **'Second last name'**
  String get secondLastName;

  /// No description provided for @enterYourSecondLastName.
  ///
  /// In en, this message translates to:
  /// **'Enter your second last name'**
  String get enterYourSecondLastName;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @birthDate.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get birthDate;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @preferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get preferNotToSay;

  /// No description provided for @selectGender.
  ///
  /// In en, this message translates to:
  /// **'Select your gender'**
  String get selectGender;

  /// No description provided for @selectBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Select your date of birth'**
  String get selectBirthDate;

  /// No description provided for @trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get trips;

  /// No description provided for @tripHistory.
  ///
  /// In en, this message translates to:
  /// **'Trip history'**
  String get tripHistory;

  /// No description provided for @noTripsYet.
  ///
  /// In en, this message translates to:
  /// **'No completed trips yet'**
  String get noTripsYet;

  /// No description provided for @startTrip.
  ///
  /// In en, this message translates to:
  /// **'Start trip'**
  String get startTrip;

  /// No description provided for @endTrip.
  ///
  /// In en, this message translates to:
  /// **'End trip'**
  String get endTrip;

  /// No description provided for @activeTrip.
  ///
  /// In en, this message translates to:
  /// **'Active trip'**
  String get activeTrip;

  /// No description provided for @selectVehicleToStartTrip.
  ///
  /// In en, this message translates to:
  /// **'Select a linked vehicle to begin a trip.'**
  String get selectVehicleToStartTrip;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @tracker.
  ///
  /// In en, this message translates to:
  /// **'Tracker'**
  String get tracker;

  /// No description provided for @tripDetails.
  ///
  /// In en, this message translates to:
  /// **'Trip details'**
  String get tripDetails;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @maxSpeed.
  ///
  /// In en, this message translates to:
  /// **'Max speed'**
  String get maxSpeed;

  /// No description provided for @averageSpeed.
  ///
  /// In en, this message translates to:
  /// **'Average speed'**
  String get averageSpeed;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @loadingTripHistory.
  ///
  /// In en, this message translates to:
  /// **'Loading route history...'**
  String get loadingTripHistory;

  /// No description provided for @colorWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get colorWhite;

  /// No description provided for @colorBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get colorBlack;

  /// No description provided for @colorSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get colorSilver;

  /// No description provided for @colorGray.
  ///
  /// In en, this message translates to:
  /// **'Gray'**
  String get colorGray;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get colorYellow;

  /// No description provided for @colorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// No description provided for @colorBrown.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get colorBrown;

  /// No description provided for @colorBeige.
  ///
  /// In en, this message translates to:
  /// **'Beige'**
  String get colorBeige;

  /// No description provided for @colorGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get colorGold;

  /// No description provided for @vehicleYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get vehicleYear;

  /// No description provided for @geofenceEnterEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Geofence entered'**
  String get geofenceEnterEventTitle;

  /// No description provided for @geofenceEnterEventMessage.
  ///
  /// In en, this message translates to:
  /// **'Your vehicle {vehicleName} entered {geofenceName}.'**
  String geofenceEnterEventMessage(String vehicleName, String geofenceName);

  /// No description provided for @geofenceEnterEventMessageWithoutGeofence.
  ///
  /// In en, this message translates to:
  /// **'Your vehicle {vehicleName} entered a geofence.'**
  String geofenceEnterEventMessageWithoutGeofence(String vehicleName);

  /// No description provided for @geofenceExitEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Geofence exited'**
  String get geofenceExitEventTitle;

  /// No description provided for @geofenceExitEventMessage.
  ///
  /// In en, this message translates to:
  /// **'Your vehicle {vehicleName} exited {geofenceName}.'**
  String geofenceExitEventMessage(String vehicleName, String geofenceName);

  /// No description provided for @geofenceExitEventMessageWithoutGeofence.
  ///
  /// In en, this message translates to:
  /// **'Your vehicle {vehicleName} exited a geofence.'**
  String geofenceExitEventMessageWithoutGeofence(String vehicleName);

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get getStarted;

  /// No description provided for @onboardingVehiclesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your vehicles, always close'**
  String get onboardingVehiclesTitle;

  /// No description provided for @onboardingVehiclesBody.
  ///
  /// In en, this message translates to:
  /// **'Keep the important vehicles in one simple place.'**
  String get onboardingVehiclesBody;

  /// No description provided for @onboardingMapTitle.
  ///
  /// In en, this message translates to:
  /// **'See what matters in real time'**
  String get onboardingMapTitle;

  /// No description provided for @onboardingMapBody.
  ///
  /// In en, this message translates to:
  /// **'Open the map to see each vehicle\'s latest location.'**
  String get onboardingMapBody;

  /// No description provided for @onboardingAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay one step ahead'**
  String get onboardingAlertsTitle;

  /// No description provided for @onboardingAlertsBody.
  ///
  /// In en, this message translates to:
  /// **'Get notified when a vehicle enters or leaves your important zones.'**
  String get onboardingAlertsBody;

  /// No description provided for @onboardingReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re ready to move with confidence'**
  String get onboardingReadyTitle;

  /// No description provided for @onboardingReadyBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll help you keep every trip in sight.'**
  String get onboardingReadyBody;

  /// No description provided for @restartGuide.
  ///
  /// In en, this message translates to:
  /// **'View app guide'**
  String get restartGuide;

  /// No description provided for @restartGuideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See the welcome guide and tips again'**
  String get restartGuideSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
