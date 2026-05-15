import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

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
    Locale('fr'),
    Locale('it'),
  ];

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @gladYouAreBack.
  ///
  /// In en, this message translates to:
  /// **'Glad you\'re back.!'**
  String get gladYouAreBack;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back .!'**
  String get welcomeBack;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPassword;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Deactivate account'**
  String get deleteAccount;

  /// No description provided for @accountDeletionDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter the email address of the account you want to deactivate. We will send a confirmation link before disabling it.'**
  String get accountDeletionDialogMessage;

  /// No description provided for @sendConfirmationEmail.
  ///
  /// In en, this message translates to:
  /// **'Send confirmation email'**
  String get sendConfirmationEmail;

  /// No description provided for @accountDeletionRequestSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get accountDeletionRequestSentTitle;

  /// No description provided for @accountDeletionRequestSentMessage.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, we sent a confirmation link to complete the deactivation.'**
  String get accountDeletionRequestSentMessage;

  /// No description provided for @accountDeletionRequestFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to start deactivation'**
  String get accountDeletionRequestFailedTitle;

  /// No description provided for @accountDeletionRequestFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not send the deactivation confirmation email right now. Please try again.'**
  String get accountDeletionRequestFailedMessage;

  /// No description provided for @accountDeletionOpenEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Open the deactivation email'**
  String get accountDeletionOpenEmailTitle;

  /// No description provided for @accountDeletionOpenEmailMessage.
  ///
  /// In en, this message translates to:
  /// **'Use the deactivation confirmation link from your email to finish disabling the account.'**
  String get accountDeletionOpenEmailMessage;

  /// No description provided for @accountDeletionConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account deactivated'**
  String get accountDeletionConfirmedTitle;

  /// No description provided for @accountDeletionConfirmedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been disabled successfully. You can close this page.'**
  String get accountDeletionConfirmedMessage;

  /// No description provided for @accountDeletionFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivation unavailable'**
  String get accountDeletionFailedTitle;

  /// No description provided for @accountDeletionFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm this deactivation link. Request a new email and try again.'**
  String get accountDeletionFailedMessage;

  /// No description provided for @accountDeletionLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirming deactivation'**
  String get accountDeletionLoadingTitle;

  /// No description provided for @accountDeletionLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'We are validating your account deactivation link...'**
  String get accountDeletionLoadingMessage;

  /// No description provided for @reactivateAccount.
  ///
  /// In en, this message translates to:
  /// **'Reactivate account'**
  String get reactivateAccount;

  /// No description provided for @accountReactivationDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter the email address of the account you want to reactivate. We will send a confirmation link before restoring access.'**
  String get accountReactivationDialogMessage;

  /// No description provided for @accountReactivationRequestSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get accountReactivationRequestSentTitle;

  /// No description provided for @accountReactivationRequestSentMessage.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, we sent a confirmation link to complete the reactivation.'**
  String get accountReactivationRequestSentMessage;

  /// No description provided for @accountReactivationRequestFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to start reactivation'**
  String get accountReactivationRequestFailedTitle;

  /// No description provided for @accountReactivationRequestFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not send the reactivation confirmation email right now. Please try again.'**
  String get accountReactivationRequestFailedMessage;

  /// No description provided for @accountReactivationOpenEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Open the reactivation email'**
  String get accountReactivationOpenEmailTitle;

  /// No description provided for @accountReactivationOpenEmailMessage.
  ///
  /// In en, this message translates to:
  /// **'Use the reactivation confirmation link from your email to restore access to your account.'**
  String get accountReactivationOpenEmailMessage;

  /// No description provided for @accountReactivationConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account reactivated'**
  String get accountReactivationConfirmedTitle;

  /// No description provided for @accountReactivationConfirmedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account is active again. You can sign in now.'**
  String get accountReactivationConfirmedMessage;

  /// No description provided for @accountReactivationFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Reactivation unavailable'**
  String get accountReactivationFailedTitle;

  /// No description provided for @accountReactivationFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm this reactivation link. Request a new email and try again.'**
  String get accountReactivationFailedMessage;

  /// No description provided for @accountReactivationLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirming reactivation'**
  String get accountReactivationLoadingTitle;

  /// No description provided for @accountReactivationLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'We are validating your account reactivation link...'**
  String get accountReactivationLoadingMessage;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @reviewTutorial.
  ///
  /// In en, this message translates to:
  /// **'Review tutorial'**
  String get reviewTutorial;

  /// No description provided for @tutorialPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get tutorialPrevious;

  /// No description provided for @tutorialNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tutorialNext;

  /// No description provided for @tutorialSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tutorialSkip;

  /// No description provided for @webMobileAppOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Get the mobile app'**
  String get webMobileAppOnlyTitle;

  /// No description provided for @webMobileAppOnlyMessage.
  ///
  /// In en, this message translates to:
  /// **'This web experience is available only on larger screens. On phones smaller than 576px, please continue with the mobile app.'**
  String get webMobileAppOnlyMessage;

  /// No description provided for @webMobileAppOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Open Note Sondage on tablet or desktop, or install the app from your store.'**
  String get webMobileAppOnlyHint;

  /// No description provided for @downloadOnAppStore.
  ///
  /// In en, this message translates to:
  /// **'Download on the App Store'**
  String get downloadOnAppStore;

  /// No description provided for @getItOnGooglePlay.
  ///
  /// In en, this message translates to:
  /// **'Get it on Google Play'**
  String get getItOnGooglePlay;

  /// No description provided for @mobileStoreLinksUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Store links are not configured yet. Please contact support or open the app on a larger screen.'**
  String get mobileStoreLinksUnavailable;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @justSomeInfoToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Just some info to get started'**
  String get justSomeInfoToGetStarted;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @pleaseEnterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterYourEmail;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @donthaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get donthaveAnAccount;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Signup'**
  String get signup;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @clockingInOut.
  ///
  /// In en, this message translates to:
  /// **'Clock in/out'**
  String get clockingInOut;

  /// No description provided for @explorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get explorer;

  /// No description provided for @sondage.
  ///
  /// In en, this message translates to:
  /// **'Sondage'**
  String get sondage;

  /// No description provided for @selectedTeam.
  ///
  /// In en, this message translates to:
  /// **'Select Team'**
  String get selectedTeam;

  /// No description provided for @createTeam.
  ///
  /// In en, this message translates to:
  /// **'Create Team'**
  String get createTeam;

  /// No description provided for @teamMember.
  ///
  /// In en, this message translates to:
  /// **'Team Member'**
  String get teamMember;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'{membersCount, plural, =1{1 member} other{{membersCount} members}}'**
  String member(num membersCount);

  /// No description provided for @createNewTeam.
  ///
  /// In en, this message translates to:
  /// **'Create new team'**
  String get createNewTeam;

  /// No description provided for @teamName.
  ///
  /// In en, this message translates to:
  /// **'Team name'**
  String get teamName;

  /// No description provided for @teamDescription.
  ///
  /// In en, this message translates to:
  /// **'Team description'**
  String get teamDescription;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @permission.
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get permission;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @selectedTeamcolor.
  ///
  /// In en, this message translates to:
  /// **'Select team color'**
  String get selectedTeamcolor;

  /// No description provided for @roleManager.
  ///
  /// In en, this message translates to:
  /// **'Roles manager'**
  String get roleManager;

  /// No description provided for @permissionManager.
  ///
  /// In en, this message translates to:
  /// **'Permissions manager'**
  String get permissionManager;

  /// No description provided for @grantList.
  ///
  /// In en, this message translates to:
  /// **'Grant list'**
  String get grantList;

  /// No description provided for @createGrant.
  ///
  /// In en, this message translates to:
  /// **'Create grant'**
  String get createGrant;

  /// No description provided for @roleList.
  ///
  /// In en, this message translates to:
  /// **'Role list'**
  String get roleList;

  /// No description provided for @createRole.
  ///
  /// In en, this message translates to:
  /// **'Create role'**
  String get createRole;

  /// No description provided for @permissionName.
  ///
  /// In en, this message translates to:
  /// **'Permission name'**
  String get permissionName;

  /// No description provided for @permissionDescription.
  ///
  /// In en, this message translates to:
  /// **'Permission description'**
  String get permissionDescription;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @editRoleManager.
  ///
  /// In en, this message translates to:
  /// **'Edit role manager'**
  String get editRoleManager;

  /// No description provided for @roleName.
  ///
  /// In en, this message translates to:
  /// **'Role name'**
  String get roleName;

  /// No description provided for @roleDescription.
  ///
  /// In en, this message translates to:
  /// **'Role description'**
  String get roleDescription;

  /// No description provided for @selectedPermission.
  ///
  /// In en, this message translates to:
  /// **'Select Permission'**
  String get selectedPermission;

  /// No description provided for @editTeam.
  ///
  /// In en, this message translates to:
  /// **'Edit team'**
  String get editTeam;

  /// No description provided for @teamDetails.
  ///
  /// In en, this message translates to:
  /// **'Team details'**
  String get teamDetails;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @askQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask a question'**
  String get askQuestion;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @option.
  ///
  /// In en, this message translates to:
  /// **'Option'**
  String get option;

  /// No description provided for @allowMultipleResponses.
  ///
  /// In en, this message translates to:
  /// **'Allow multiple responses'**
  String get allowMultipleResponses;

  /// No description provided for @makeResponsesAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Make responses anonymous'**
  String get makeResponsesAnonymous;

  /// No description provided for @selectTeam.
  ///
  /// In en, this message translates to:
  /// **'Select team'**
  String get selectTeam;

  /// No description provided for @teamLabel.
  ///
  /// In en, this message translates to:
  /// **'Team:'**
  String get teamLabel;

  /// No description provided for @surveyCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Survey created successfully!'**
  String get surveyCreatedSuccessfully;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @responses.
  ///
  /// In en, this message translates to:
  /// **'responses'**
  String get responses;

  /// No description provided for @questions.
  ///
  /// In en, this message translates to:
  /// **'questions'**
  String get questions;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @manageYourPrivacySettings.
  ///
  /// In en, this message translates to:
  /// **'Manage your privacy settings'**
  String get manageYourPrivacySettings;

  /// No description provided for @getInTouchWithOurSupportTeam.
  ///
  /// In en, this message translates to:
  /// **'Get in touch with our support team'**
  String get getInTouchWithOurSupportTeam;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @defaultLightTheme.
  ///
  /// In en, this message translates to:
  /// **'Default light theme'**
  String get defaultLightTheme;

  /// No description provided for @darkThemeForLowLight.
  ///
  /// In en, this message translates to:
  /// **'Dark theme for low light'**
  String get darkThemeForLowLight;

  /// No description provided for @followSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Follow system settings'**
  String get followSystemSettings;

  /// No description provided for @selectYourLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select your language'**
  String get selectYourLanguage;

  /// No description provided for @settingsNotification.
  ///
  /// In en, this message translates to:
  /// **'Settings Notification'**
  String get settingsNotification;

  /// No description provided for @notificationsSettingsIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose how updates and shift reminders reach you.'**
  String get notificationsSettingsIntro;

  /// No description provided for @notificationsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get notificationsGeneral;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @receiveUpdatesByEmail.
  ///
  /// In en, this message translates to:
  /// **'Receive updates via email'**
  String get receiveUpdatesByEmail;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @receivePushNotificationsOnYourDevice.
  ///
  /// In en, this message translates to:
  /// **'Receive push notifications on your device'**
  String get receivePushNotificationsOnYourDevice;

  /// No description provided for @shiftReminders.
  ///
  /// In en, this message translates to:
  /// **'Shift reminders'**
  String get shiftReminders;

  /// No description provided for @reminderMode.
  ///
  /// In en, this message translates to:
  /// **'Reminder mode'**
  String get reminderMode;

  /// No description provided for @notificationReminderModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose in each shift whether you want a standard notification or a stronger alarm.'**
  String get notificationReminderModeDescription;

  /// No description provided for @webBehavior.
  ///
  /// In en, this message translates to:
  /// **'Web behavior'**
  String get webBehavior;

  /// No description provided for @alarmBehaviorOnWeb.
  ///
  /// In en, this message translates to:
  /// **'On web, Alarm mode uses browser notifications. The tab must stay open and the browser controls the final sound and vibration behavior.'**
  String get alarmBehaviorOnWeb;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorks;

  /// No description provided for @notificationAndAlarmDifference.
  ///
  /// In en, this message translates to:
  /// **'Notification shows a normal reminder. Alarm uses the settings below and is meant for stronger shift alerts.'**
  String get notificationAndAlarmDifference;

  /// No description provided for @alarmDelivery.
  ///
  /// In en, this message translates to:
  /// **'Alarm delivery'**
  String get alarmDelivery;

  /// No description provided for @alarmStyle.
  ///
  /// In en, this message translates to:
  /// **'Alarm style'**
  String get alarmStyle;

  /// No description provided for @webAlarmDeliveryDescription.
  ///
  /// In en, this message translates to:
  /// **'Browser notifications are used while this tab is open. Sound and vibration are managed by the browser and operating system.'**
  String get webAlarmDeliveryDescription;

  /// No description provided for @alarmStyleDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose whether Alarm mode should vibrate or play a ringtone. Default: Vibrate.'**
  String get alarmStyleDescription;

  /// No description provided for @alarmStyleDescriptionIos.
  ///
  /// In en, this message translates to:
  /// **'On iPhone, Alarm mode uses a ringtone. Vibration-only alarms are not available for local notifications.'**
  String get alarmStyleDescriptionIos;

  /// No description provided for @vibrate.
  ///
  /// In en, this message translates to:
  /// **'Vibrate'**
  String get vibrate;

  /// No description provided for @ringtone.
  ///
  /// In en, this message translates to:
  /// **'Ringtone'**
  String get ringtone;

  /// No description provided for @browserNotification.
  ///
  /// In en, this message translates to:
  /// **'Browser notification'**
  String get browserNotification;

  /// No description provided for @notificationVisibility.
  ///
  /// In en, this message translates to:
  /// **'Notification visibility'**
  String get notificationVisibility;

  /// No description provided for @alarmDuration.
  ///
  /// In en, this message translates to:
  /// **'Alarm duration'**
  String get alarmDuration;

  /// No description provided for @webNotificationVisibilityDescription.
  ///
  /// In en, this message translates to:
  /// **'This controls how long the browser notification stays visible after it appears.'**
  String get webNotificationVisibilityDescription;

  /// No description provided for @alarmDurationAppliesOnlyToAlarmMode.
  ///
  /// In en, this message translates to:
  /// **'This duration applies only when a shift uses Alarm mode.'**
  String get alarmDurationAppliesOnlyToAlarmMode;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @surveyReminders.
  ///
  /// In en, this message translates to:
  /// **'Survey Reminders'**
  String get surveyReminders;

  /// No description provided for @getRemindedAboutPendingSurveys.
  ///
  /// In en, this message translates to:
  /// **'Get reminded about pending surveys'**
  String get getRemindedAboutPendingSurveys;

  /// No description provided for @teamUpdates.
  ///
  /// In en, this message translates to:
  /// **'Team Updates'**
  String get teamUpdates;

  /// No description provided for @notificationsAboutTeamChanges.
  ///
  /// In en, this message translates to:
  /// **'Notifications about team changes'**
  String get notificationsAboutTeamChanges;

  /// No description provided for @clockingAlerts.
  ///
  /// In en, this message translates to:
  /// **'Clocking Alerts'**
  String get clockingAlerts;

  /// No description provided for @remindersToClockInAndOut.
  ///
  /// In en, this message translates to:
  /// **'Reminders to clock in and out'**
  String get remindersToClockInAndOut;

  /// No description provided for @shiftNotifications.
  ///
  /// In en, this message translates to:
  /// **'Shift Notifications'**
  String get shiftNotifications;

  /// No description provided for @assignmentsUpdatesAndShiftReminders.
  ///
  /// In en, this message translates to:
  /// **'Assignments, updates and shift reminders'**
  String get assignmentsUpdatesAndShiftReminders;

  /// No description provided for @debugTools.
  ///
  /// In en, this message translates to:
  /// **'Debug tools'**
  String get debugTools;

  /// No description provided for @debugToolsBrowserMessage.
  ///
  /// In en, this message translates to:
  /// **'Use these tests only while debugging notifications in this browser.'**
  String get debugToolsBrowserMessage;

  /// No description provided for @debugToolsDeviceMessage.
  ///
  /// In en, this message translates to:
  /// **'Use these tests only while debugging notifications on this device.'**
  String get debugToolsDeviceMessage;

  /// No description provided for @testNotificationNow.
  ///
  /// In en, this message translates to:
  /// **'Test notification now'**
  String get testNotificationNow;

  /// No description provided for @testAlarmIn10Seconds.
  ///
  /// In en, this message translates to:
  /// **'Test alarm in 10s'**
  String get testAlarmIn10Seconds;

  /// No description provided for @testCurrentMode.
  ///
  /// In en, this message translates to:
  /// **'Test current mode'**
  String get testCurrentMode;

  /// No description provided for @alarmModeStatus.
  ///
  /// In en, this message translates to:
  /// **'Alarm mode status'**
  String get alarmModeStatus;

  /// No description provided for @pendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending requests'**
  String get pendingRequests;

  /// No description provided for @inspectRealShifts.
  ///
  /// In en, this message translates to:
  /// **'Inspect real shifts'**
  String get inspectRealShifts;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @howWeProtectYourData.
  ///
  /// In en, this message translates to:
  /// **'How we protect your data'**
  String get howWeProtectYourData;

  /// No description provided for @dataProtection.
  ///
  /// In en, this message translates to:
  /// **'Data Protection'**
  String get dataProtection;

  /// No description provided for @dataProtectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Your data is encrypted at rest and in transit. We use industry-standard encryption protocols to ensure your information remains secure.'**
  String get dataProtectionDescription;

  /// No description provided for @dataCollection.
  ///
  /// In en, this message translates to:
  /// **'Data Collection'**
  String get dataCollection;

  /// No description provided for @dataCollectionDescription.
  ///
  /// In en, this message translates to:
  /// **'We collect only the data necessary to provide our services. This includes your account information, survey responses, and clocking records.'**
  String get dataCollectionDescription;

  /// No description provided for @dataSharing.
  ///
  /// In en, this message translates to:
  /// **'Data Sharing'**
  String get dataSharing;

  /// No description provided for @dataSharingDescription.
  ///
  /// In en, this message translates to:
  /// **'We never share your personal data with third parties without your explicit consent. Team data is shared only within your organization.'**
  String get dataSharingDescription;

  /// No description provided for @dataRetention.
  ///
  /// In en, this message translates to:
  /// **'Data Retention'**
  String get dataRetention;

  /// No description provided for @dataRetentionDescription.
  ///
  /// In en, this message translates to:
  /// **'Your data is retained for as long as your account is active. After account deactivation, personal data is permanently removed within 30 days.'**
  String get dataRetentionDescription;

  /// No description provided for @yourRights.
  ///
  /// In en, this message translates to:
  /// **'Your Rights'**
  String get yourRights;

  /// No description provided for @yourRightsDescription.
  ///
  /// In en, this message translates to:
  /// **'You have the right to access, rectify, or delete your personal data at any time. Contact our support team for any privacy-related requests.'**
  String get yourRightsDescription;

  /// No description provided for @privacyLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: January 2025'**
  String get privacyLastUpdated;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get yourName;

  /// No description provided for @yourEmail.
  ///
  /// In en, this message translates to:
  /// **'Your Email'**
  String get yourEmail;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @contactUsDescription.
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened and we will open your email app with a ready-to-send draft.'**
  String get contactUsDescription;

  /// No description provided for @contactUsDraftHint.
  ///
  /// In en, this message translates to:
  /// **'Your email app will open with Junibetto@gmail.com already selected as recipient.'**
  String get contactUsDraftHint;

  /// No description provided for @contactUsReplyTime.
  ///
  /// In en, this message translates to:
  /// **'We usually reply within 1-2 business days.'**
  String get contactUsReplyTime;

  /// No description provided for @supportEmail.
  ///
  /// In en, this message translates to:
  /// **'Support email'**
  String get supportEmail;

  /// No description provided for @sendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send email'**
  String get sendEmail;

  /// No description provided for @copyEmail.
  ///
  /// In en, this message translates to:
  /// **'Copy email'**
  String get copyEmail;

  /// No description provided for @emailCopied.
  ///
  /// In en, this message translates to:
  /// **'Support email copied to clipboard.'**
  String get emailCopied;

  /// No description provided for @couldNotOpenEmailApp.
  ///
  /// In en, this message translates to:
  /// **'We could not open your email app. Copy the address and send the message manually.'**
  String get couldNotOpenEmailApp;

  /// No description provided for @contactUsEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'Note Sondage support request'**
  String get contactUsEmailSubject;

  /// No description provided for @contactUsTopicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bugs, feedback, product ideas'**
  String get contactUsTopicsTitle;

  /// No description provided for @contactUsTopicsBody.
  ///
  /// In en, this message translates to:
  /// **'Use this space to report issues, ask for help, or share improvements you would love to see.'**
  String get contactUsTopicsBody;

  /// No description provided for @contactUsFormHint.
  ///
  /// In en, this message translates to:
  /// **'The draft will include your details so support can reply faster.'**
  String get contactUsFormHint;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @personalStatusClockingActions.
  ///
  /// In en, this message translates to:
  /// **'Personal status clock in actions'**
  String get personalStatusClockingActions;

  /// No description provided for @clockedInAt.
  ///
  /// In en, this message translates to:
  /// **'Clocked in at:'**
  String get clockedInAt;

  /// No description provided for @startBreakAt.
  ///
  /// In en, this message translates to:
  /// **'Start break at:'**
  String get startBreakAt;

  /// No description provided for @endBreakAt.
  ///
  /// In en, this message translates to:
  /// **'End break at:'**
  String get endBreakAt;

  /// No description provided for @clockedOutAt.
  ///
  /// In en, this message translates to:
  /// **'Clocked out at:'**
  String get clockedOutAt;

  /// No description provided for @allUsers.
  ///
  /// In en, this message translates to:
  /// **'All users'**
  String get allUsers;

  /// No description provided for @clockInSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Clock In successful'**
  String get clockInSuccessful;

  /// No description provided for @clockOutSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Clock Out successful'**
  String get clockOutSuccessful;

  /// No description provided for @teamCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Team created successfully!'**
  String get teamCreatedSuccessfully;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error:'**
  String get errorPrefix;

  /// No description provided for @memberAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Member added successfully!'**
  String get memberAddedSuccessfully;

  /// No description provided for @memberErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Member error:'**
  String get memberErrorPrefix;

  /// No description provided for @noTeamsFound.
  ///
  /// In en, this message translates to:
  /// **'No teams found'**
  String get noTeamsFound;

  /// No description provided for @roleCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Role created successfully!'**
  String get roleCreatedSuccessfully;

  /// No description provided for @noRolesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No roles available'**
  String get noRolesAvailable;

  /// No description provided for @userList.
  ///
  /// In en, this message translates to:
  /// **'User List'**
  String get userList;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add user'**
  String get addUser;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @errorDetailsDebug.
  ///
  /// In en, this message translates to:
  /// **'Error Details (Debug)'**
  String get errorDetailsDebug;

  /// No description provided for @aboutPageText.
  ///
  /// In en, this message translates to:
  /// **'This is the About page'**
  String get aboutPageText;

  /// No description provided for @teamPageMobileText.
  ///
  /// In en, this message translates to:
  /// **'This is the Team page for Mobile'**
  String get teamPageMobileText;

  /// No description provided for @noTeamMembersFound.
  ///
  /// In en, this message translates to:
  /// **'No team members found.'**
  String get noTeamMembersFound;

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

  /// No description provided for @selectMultiple.
  ///
  /// In en, this message translates to:
  /// **'Select multiple'**
  String get selectMultiple;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get removeImage;

  /// No description provided for @settingsWeb.
  ///
  /// In en, this message translates to:
  /// **'Settings Web'**
  String get settingsWeb;

  /// No description provided for @webNavbar.
  ///
  /// In en, this message translates to:
  /// **'Web Navbar'**
  String get webNavbar;

  /// No description provided for @surveyMobile.
  ///
  /// In en, this message translates to:
  /// **'Survey Mobile'**
  String get surveyMobile;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @createdDate.
  ///
  /// In en, this message translates to:
  /// **'Created date'**
  String get createdDate;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get expiryDate;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s a quick overview of your workspace'**
  String get dashboardSubtitle;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @activeTeams.
  ///
  /// In en, this message translates to:
  /// **'Active Teams'**
  String get activeTeams;

  /// No description provided for @activeSurveys.
  ///
  /// In en, this message translates to:
  /// **'Active Surveys'**
  String get activeSurveys;

  /// No description provided for @todayClocking.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Clocking'**
  String get todayClocking;

  /// No description provided for @totalMembers.
  ///
  /// In en, this message translates to:
  /// **'Total Members'**
  String get totalMembers;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started by exploring your workspace'**
  String get getStarted;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmation;

  /// No description provided for @clockInRequiredForBreak.
  ///
  /// In en, this message translates to:
  /// **'Clock in required for break'**
  String get clockInRequiredForBreak;

  /// No description provided for @endActiveBreak.
  ///
  /// In en, this message translates to:
  /// **'End Break'**
  String get endActiveBreak;

  /// No description provided for @startActiveBreak.
  ///
  /// In en, this message translates to:
  /// **'Start Break'**
  String get startActiveBreak;

  /// No description provided for @selectTeamToClockIn.
  ///
  /// In en, this message translates to:
  /// **'Please select a team to clock in'**
  String get selectTeamToClockIn;

  /// No description provided for @allDates.
  ///
  /// In en, this message translates to:
  /// **'All Dates'**
  String get allDates;

  /// No description provided for @teamClockings.
  ///
  /// In en, this message translates to:
  /// **'Team Clockings'**
  String get teamClockings;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @clockingOwnerHint.
  ///
  /// In en, this message translates to:
  /// **'Clock in Owner'**
  String get clockingOwnerHint;

  /// No description provided for @searchByNameOrTeam.
  ///
  /// In en, this message translates to:
  /// **'Search by name or team...'**
  String get searchByNameOrTeam;

  /// No description provided for @resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset Filters'**
  String get resetFilters;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @selectTeamToViewClockings.
  ///
  /// In en, this message translates to:
  /// **'Please select a team to view clockings'**
  String get selectTeamToViewClockings;

  /// No description provided for @noClockingsForTeam.
  ///
  /// In en, this message translates to:
  /// **'No clockings found for this team'**
  String get noClockingsForTeam;

  /// No description provided for @committed.
  ///
  /// In en, this message translates to:
  /// **'Committed'**
  String get committed;

  /// No description provided for @decommitted.
  ///
  /// In en, this message translates to:
  /// **'Decommitted'**
  String get decommitted;

  /// No description provided for @editClocking.
  ///
  /// In en, this message translates to:
  /// **'Edit Clocking'**
  String get editClocking;

  /// No description provided for @breakMinutes.
  ///
  /// In en, this message translates to:
  /// **'Break (minutes)'**
  String get breakMinutes;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @invalidDateFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid date format'**
  String get invalidDateFormat;

  /// No description provided for @noClockingsToExport.
  ///
  /// In en, this message translates to:
  /// **'No clockings available to export'**
  String get noClockingsToExport;

  /// No description provided for @ownerOnly.
  ///
  /// In en, this message translates to:
  /// **'Owner Only'**
  String get ownerOnly;

  /// No description provided for @decommit.
  ///
  /// In en, this message translates to:
  /// **'Decommit'**
  String get decommit;

  /// No description provided for @commit.
  ///
  /// In en, this message translates to:
  /// **'Commit'**
  String get commit;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @noActionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No action available'**
  String get noActionAvailable;

  /// No description provided for @setExpiry.
  ///
  /// In en, this message translates to:
  /// **'Set Expiry Date'**
  String get setExpiry;

  /// No description provided for @invitationSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent successfully'**
  String get invitationSent;

  /// No description provided for @noActiveMembersYet.
  ///
  /// In en, this message translates to:
  /// **'No active members yet'**
  String get noActiveMembersYet;

  /// No description provided for @editRoleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit Role'**
  String get editRoleTooltip;

  /// No description provided for @removeAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAction;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select a role'**
  String get selectRole;

  /// No description provided for @pendingInvitations.
  ///
  /// In en, this message translates to:
  /// **'Pending Invitations'**
  String get pendingInvitations;

  /// No description provided for @cancelInvitation.
  ///
  /// In en, this message translates to:
  /// **'Cancel Invitation'**
  String get cancelInvitation;

  /// No description provided for @inviteStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get inviteStatusAccepted;

  /// No description provided for @inviteStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get inviteStatusRejected;

  /// No description provided for @inviteStatusUnregistered.
  ///
  /// In en, this message translates to:
  /// **'Pending Registration'**
  String get inviteStatusUnregistered;

  /// No description provided for @inviteStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get inviteStatusPending;

  /// No description provided for @memberStatusInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get memberStatusInvited;

  /// No description provided for @memberStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get memberStatusInactive;

  /// No description provided for @memberStatusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get memberStatusSuspended;

  /// No description provided for @exportPdfError.
  ///
  /// In en, this message translates to:
  /// **'Error exporting PDF: {error}'**
  String exportPdfError(Object error);

  /// No description provided for @surveyNotFound.
  ///
  /// In en, this message translates to:
  /// **'Survey not found'**
  String get surveyNotFound;

  /// No description provided for @focus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focus;

  /// No description provided for @noOptionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No options available'**
  String get noOptionsAvailable;

  /// No description provided for @alreadyVoted.
  ///
  /// In en, this message translates to:
  /// **'You have already voted'**
  String get alreadyVoted;

  /// No description provided for @cannotVote.
  ///
  /// In en, this message translates to:
  /// **'You cannot vote'**
  String get cannotVote;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @closeSurvey.
  ///
  /// In en, this message translates to:
  /// **'Close Survey'**
  String get closeSurvey;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get statusPublished;

  /// Number of votes for an option
  ///
  /// In en, this message translates to:
  /// **'{count} votes'**
  String votes(int count);

  /// Message showing active turn on a team
  ///
  /// In en, this message translates to:
  /// **'Active turn on {teamName}'**
  String activeTurnOn(String teamName);

  /// No description provided for @openYourTurn.
  ///
  /// In en, this message translates to:
  /// **'Open your turn'**
  String get openYourTurn;

  /// No description provided for @loadingClockingState.
  ///
  /// In en, this message translates to:
  /// **'Loading clock in state...'**
  String get loadingClockingState;

  /// No description provided for @noClockingsForFilter.
  ///
  /// In en, this message translates to:
  /// **'No clockings found for the selected filters'**
  String get noClockingsForFilter;

  /// No description provided for @myShifts.
  ///
  /// In en, this message translates to:
  /// **'My Shifts'**
  String get myShifts;

  /// No description provided for @shiftCalendar.
  ///
  /// In en, this message translates to:
  /// **'Shift Calendar'**
  String get shiftCalendar;

  /// No description provided for @shiftCalendarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your personal and team shift schedule'**
  String get shiftCalendarSubtitle;

  /// No description provided for @addShift.
  ///
  /// In en, this message translates to:
  /// **'Add Shift'**
  String get addShift;

  /// No description provided for @shiftProfile.
  ///
  /// In en, this message translates to:
  /// **'Shift Profile'**
  String get shiftProfile;

  /// No description provided for @shiftStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get shiftStart;

  /// No description provided for @shiftEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get shiftEnd;

  /// No description provided for @overnightShift.
  ///
  /// In en, this message translates to:
  /// **'Overnight Shift'**
  String get overnightShift;

  /// No description provided for @shiftRepeatUntil.
  ///
  /// In en, this message translates to:
  /// **'Repeat until'**
  String get shiftRepeatUntil;

  /// No description provided for @shiftRepeatUntilHelp.
  ///
  /// In en, this message translates to:
  /// **'A shift will be created for each day in the selected interval.'**
  String get shiftRepeatUntilHelp;

  /// No description provided for @shiftEndMustBeAfterStart.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time. If the shift ends the next day, enable Overnight Shift.'**
  String get shiftEndMustBeAfterStart;

  /// No description provided for @alarms.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get alarms;

  /// No description provided for @createCustomProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Custom Profile'**
  String get createCustomProfile;

  /// No description provided for @editShiftProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editShiftProfile;

  /// No description provided for @shiftProfileName.
  ///
  /// In en, this message translates to:
  /// **'Profile Name'**
  String get shiftProfileName;

  /// No description provided for @shiftColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get shiftColor;

  /// No description provided for @deleteShiftProfileConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this profile?'**
  String get deleteShiftProfileConfirm;

  /// No description provided for @customProfile.
  ///
  /// In en, this message translates to:
  /// **'Custom Profiles'**
  String get customProfile;

  /// No description provided for @noShiftsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No shifts this month'**
  String get noShiftsThisMonth;

  /// No description provided for @systemProfile.
  ///
  /// In en, this message translates to:
  /// **'System Profiles'**
  String get systemProfile;
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
      <String>['en', 'es', 'fr', 'it'].contains(locale.languageCode);

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
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
