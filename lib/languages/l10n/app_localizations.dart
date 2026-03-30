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
  /// **'Clocking in/out'**
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

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @personalStatusClockingActions.
  ///
  /// In en, this message translates to:
  /// **'Personal status clocking actions'**
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
