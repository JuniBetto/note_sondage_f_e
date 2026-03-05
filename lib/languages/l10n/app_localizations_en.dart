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
}
