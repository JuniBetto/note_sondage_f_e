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
  String get clockingInOut => 'Clock in/out';

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
      'Personal status clock in actions';

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

  @override
  String get progress => 'Progress';

  @override
  String get createdDate => 'Created date';

  @override
  String get expiryDate => 'Expiry date';

  @override
  String get dashboardSubtitle => 'Here\'s a quick overview of your workspace';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get activeTeams => 'Active Teams';

  @override
  String get activeSurveys => 'Active Surveys';

  @override
  String get todayClocking => 'Today\'s Clocking';

  @override
  String get totalMembers => 'Total Members';

  @override
  String get viewAll => 'View All';

  @override
  String get noRecentActivity => 'No recent activity';

  @override
  String get getStarted => 'Get started by exploring your workspace';

  @override
  String get logoutConfirmation => 'Are you sure you want to log out?';

  @override
  String get clockInRequiredForBreak => 'Clock in required for break';

  @override
  String get endActiveBreak => 'End Break';

  @override
  String get startActiveBreak => 'Start Break';

  @override
  String get selectTeamToClockIn => 'Please select a team to clock in';

  @override
  String get allDates => 'All Dates';

  @override
  String get teamClockings => 'Team Clockings';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get clockingOwnerHint => 'Clock in Owner';

  @override
  String get searchByNameOrTeam => 'Search by name or team...';

  @override
  String get resetFilters => 'Reset Filters';

  @override
  String get reset => 'Reset';

  @override
  String get selectTeamToViewClockings =>
      'Please select a team to view clockings';

  @override
  String get noClockingsForTeam => 'No clockings found for this team';

  @override
  String get committed => 'Committed';

  @override
  String get decommitted => 'Decommitted';

  @override
  String get editClocking => 'Edit Clocking';

  @override
  String get breakMinutes => 'Break (minutes)';

  @override
  String get note => 'Note';

  @override
  String get invalidDateFormat => 'Invalid date format';

  @override
  String get noClockingsToExport => 'No clockings available to export';

  @override
  String get ownerOnly => 'Owner Only';

  @override
  String get decommit => 'Decommit';

  @override
  String get commit => 'Commit';

  @override
  String get editAction => 'Edit';

  @override
  String get noActionAvailable => 'No action available';

  @override
  String get setExpiry => 'Set Expiry Date';

  @override
  String get invitationSent => 'Invitation sent successfully';

  @override
  String get noActiveMembersYet => 'No active members yet';

  @override
  String get editRoleTooltip => 'Edit Role';

  @override
  String get removeAction => 'Remove';

  @override
  String get selectRole => 'Select a role';

  @override
  String get pendingInvitations => 'Pending Invitations';

  @override
  String get cancelInvitation => 'Cancel Invitation';

  @override
  String get inviteStatusAccepted => 'Accepted';

  @override
  String get inviteStatusRejected => 'Rejected';

  @override
  String get inviteStatusUnregistered => 'Pending Registration';

  @override
  String get inviteStatusPending => 'Pending';

  @override
  String get memberStatusInvited => 'Invited';

  @override
  String get memberStatusInactive => 'Inactive';

  @override
  String get memberStatusSuspended => 'Suspended';

  @override
  String exportPdfError(Object error) {
    return 'Error exporting PDF: $error';
  }

  @override
  String get surveyNotFound => 'Survey not found';

  @override
  String get focus => 'Focus';

  @override
  String get noOptionsAvailable => 'No options available';

  @override
  String get alreadyVoted => 'You have already voted';

  @override
  String get cannotVote => 'You cannot vote';

  @override
  String get publish => 'Publish';

  @override
  String get closeSurvey => 'Close Survey';

  @override
  String get statusActive => 'Active';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusClosed => 'Closed';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusPublished => 'Published';

  @override
  String votes(int count) {
    return '$count votes';
  }

  @override
  String activeTurnOn(String teamName) {
    return 'Active turn on $teamName';
  }

  @override
  String get openYourTurn => 'Open your turn';

  @override
  String get loadingClockingState => 'Loading clock in state...';

  @override
  String get noClockingsForFilter =>
      'No clockings found for the selected filters';

  @override
  String get myShifts => 'My Shifts';

  @override
  String get shiftCalendar => 'Shift Calendar';

  @override
  String get shiftCalendarSubtitle => 'Your personal and team shift schedule';

  @override
  String get addShift => 'Add Shift';

  @override
  String get shiftProfile => 'Shift Profile';

  @override
  String get shiftStart => 'Start';

  @override
  String get shiftEnd => 'End';

  @override
  String get overnightShift => 'Overnight Shift';

  @override
  String get alarms => 'Alarms';

  @override
  String get createCustomProfile => 'Create Custom Profile';

  @override
  String get editShiftProfile => 'Edit Profile';

  @override
  String get shiftProfileName => 'Profile Name';

  @override
  String get shiftColor => 'Color';

  @override
  String get deleteShiftProfileConfirm =>
      'Are you sure you want to delete this profile?';

  @override
  String get customProfile => 'Custom Profiles';

  @override
  String get noShiftsThisMonth => 'No shifts this month';

  @override
  String get systemProfile => 'System Profiles';
}
