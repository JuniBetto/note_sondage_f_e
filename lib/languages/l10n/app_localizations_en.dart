// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get register => 'Register';

  @override
  String get gladYouAreBack => 'Glad you\'re back.!';

  @override
  String get welcomeBack => 'Welcome back .!';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get justSomeInfoToGetStarted => 'Just some info to get started';

  @override
  String get fullName => 'Full name';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get pleaseEnterYourEmail => 'Please enter your email';

  @override
  String get resetPassword => 'Reset password';

  @override
  String get donthaveAnAccount => 'Don\'t have an account?';

  @override
  String get signup => 'Signup';

  @override
  String get home => 'Home';

  @override
  String get about => 'About';

  @override
  String get team => 'Team';

  @override
  String get settings => 'Settings';

  @override
  String get attendance => 'Attendance';

  @override
  String get clockingInOut => 'Clocking in/out';

  @override
  String get explorer => 'Explorer';

  @override
  String get sondage => 'Sondage';

  @override
  String get selectedTeam => 'Select Team';

  @override
  String get createTeam => 'Create Team';

  @override
  String get teamMember => 'Team Member';

  @override
  String member(num membersCount) {
    String _temp0 = intl.Intl.pluralLogic(
      membersCount,
      locale: localeName,
      other: '$membersCount members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get createNewTeam => 'Create new team';

  @override
  String get teamName => 'Team name';

  @override
  String get teamDescription => 'Team description';

  @override
  String get role => 'Role';

  @override
  String get permission => 'Permission';

  @override
  String get status => 'Status';

  @override
  String get selectedTeamcolor => 'Select team color';

  @override
  String get roleManager => 'Roles manager';

  @override
  String get permissionManager => 'Permissions manager';

  @override
  String get grantList => 'Grant list';

  @override
  String get createGrant => 'Create grant';

  @override
  String get roleList => 'Role list';

  @override
  String get createRole => 'Create role';

  @override
  String get permissionName => 'Permission name';

  @override
  String get permissionDescription => 'Permission description';

  @override
  String get save => 'Save';

  @override
  String get editRoleManager => 'Edit role manager';

  @override
  String get roleName => 'Role name';

  @override
  String get roleDescription => 'Role description';

  @override
  String get selectedPermission => 'Select Permission';

  @override
  String get editTeam => 'Edit team';

  @override
  String get language => 'Language';

  @override
  String get notification => 'Notification';

  @override
  String get contactUs => 'Contact us';

  @override
  String get privacy => 'Privacy';

  @override
  String get askQuestion => 'Ask a question';

  @override
  String get options => 'Options';

  @override
  String get option => 'Option';

  @override
  String get allowMultipleResponses => 'Allow multiple responses';

  @override
  String get makeResponsesAnonymous => 'Make responses anonymous';

  @override
  String get selectTeam => 'Select team';

  @override
  String get teamLabel => 'Team:';

  @override
  String get surveyCreatedSuccessfully => 'Survey created successfully!';

  @override
  String get create => 'Create';

  @override
  String get responses => 'responses';

  @override
  String get questions => 'questions';

  @override
  String get system => 'System';

  @override
  String get dark => 'Dark';

  @override
  String get light => 'Light';

  @override
  String get preferences => 'Preferences';

  @override
  String get manageYourPrivacySettings => 'Manage your privacy settings';

  @override
  String get getInTouchWithOurSupportTeam =>
      'Get in touch with our support team';

  @override
  String get themeTitle => 'Theme';

  @override
  String get languageTitle => 'Language';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get systemDefault => 'System Default';

  @override
  String get defaultLightTheme => 'Default light theme';

  @override
  String get darkThemeForLowLight => 'Dark theme for low light';

  @override
  String get followSystemSettings => 'Follow system settings';

  @override
  String get selectYourLanguage => 'Select your language';

  @override
  String get settingsNotification => 'Settings Notification';

  @override
  String get yourName => 'Your Name';

  @override
  String get yourEmail => 'Your Email';

  @override
  String get message => 'Message';

  @override
  String get submit => 'Submit';

  @override
  String get none => 'None';

  @override
  String get personalStatusClockingActions =>
      'Personal status clocking actions';

  @override
  String get clockedInAt => 'Clocked in at:';

  @override
  String get startBreakAt => 'Start break at:';

  @override
  String get endBreakAt => 'End break at:';

  @override
  String get clockedOutAt => 'Clocked out at:';

  @override
  String get allUsers => 'All users';

  @override
  String get clockInSuccessful => 'Clock In successful';

  @override
  String get clockOutSuccessful => 'Clock Out successful';

  @override
  String get teamCreatedSuccessfully => 'Team created successfully!';

  @override
  String get errorPrefix => 'Error:';

  @override
  String get memberAddedSuccessfully => 'Member added successfully!';

  @override
  String get memberErrorPrefix => 'Member error:';

  @override
  String get noTeamsFound => 'No teams found';

  @override
  String get roleCreatedSuccessfully => 'Role created successfully!';

  @override
  String get noRolesAvailable => 'No roles available';

  @override
  String get userList => 'User List';

  @override
  String get addUser => 'Add user';

  @override
  String get clearAll => 'Clear All';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get goBack => 'Go Back';

  @override
  String get errorDetailsDebug => 'Error Details (Debug)';

  @override
  String get aboutPageText => 'This is the About page';

  @override
  String get teamPageMobileText => 'This is the Team page for Mobile';

  @override
  String get noTeamMembersFound => 'No team members found.';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get selectMultiple => 'Select multiple';

  @override
  String get removeImage => 'Remove image';

  @override
  String get settingsWeb => 'Settings Web';

  @override
  String get webNavbar => 'Web Navbar';

  @override
  String get surveyMobile => 'Survey Mobile';
}
