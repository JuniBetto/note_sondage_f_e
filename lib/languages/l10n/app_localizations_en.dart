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
  String get deleteAccount => 'Deactivate account';

  @override
  String get accountDeletionDialogMessage =>
      'Enter the email address of the account you want to deactivate. We will send a confirmation link before disabling it.';

  @override
  String get sendConfirmationEmail => 'Send confirmation email';

  @override
  String get accountDeletionRequestSentTitle => 'Check your email';

  @override
  String get accountDeletionRequestSentMessage =>
      'If an account exists for this email, we sent a confirmation link to complete the deactivation.';

  @override
  String get accountDeletionRequestFailedTitle =>
      'Unable to start deactivation';

  @override
  String get accountDeletionRequestFailedMessage =>
      'We could not send the deactivation confirmation email right now. Please try again.';

  @override
  String get accountDeletionOpenEmailTitle => 'Open the deactivation email';

  @override
  String get accountDeletionOpenEmailMessage =>
      'Use the deactivation confirmation link from your email to finish disabling the account.';

  @override
  String get accountDeletionConfirmedTitle => 'Account deactivated';

  @override
  String get accountDeletionConfirmedMessage =>
      'Your account has been disabled successfully. You can close this page.';

  @override
  String get accountDeletionFailedTitle => 'Deactivation unavailable';

  @override
  String get accountDeletionFailedMessage =>
      'We could not confirm this deactivation link. Request a new email and try again.';

  @override
  String get accountDeletionLoadingTitle => 'Confirming deactivation';

  @override
  String get accountDeletionLoadingMessage =>
      'We are validating your account deactivation link...';

  @override
  String get reactivateAccount => 'Reactivate account';

  @override
  String get accountReactivationDialogMessage =>
      'Enter the email address of the account you want to reactivate. We will send a confirmation link before restoring access.';

  @override
  String get accountReactivationRequestSentTitle => 'Check your email';

  @override
  String get accountReactivationRequestSentMessage =>
      'If an account exists for this email, we sent a confirmation link to complete the reactivation.';

  @override
  String get accountReactivationRequestFailedTitle =>
      'Unable to start reactivation';

  @override
  String get accountReactivationRequestFailedMessage =>
      'We could not send the reactivation confirmation email right now. Please try again.';

  @override
  String get accountReactivationOpenEmailTitle => 'Open the reactivation email';

  @override
  String get accountReactivationOpenEmailMessage =>
      'Use the reactivation confirmation link from your email to restore access to your account.';

  @override
  String get accountReactivationConfirmedTitle => 'Account reactivated';

  @override
  String get accountReactivationConfirmedMessage =>
      'Your account is active again. You can sign in now.';

  @override
  String get accountReactivationFailedTitle => 'Reactivation unavailable';

  @override
  String get accountReactivationFailedMessage =>
      'We could not confirm this reactivation link. Request a new email and try again.';

  @override
  String get accountReactivationLoadingTitle => 'Confirming reactivation';

  @override
  String get accountReactivationLoadingMessage =>
      'We are validating your account reactivation link...';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get tryAgain => 'Try again';

  @override
  String get reviewTutorial => 'Review tutorial';

  @override
  String get tutorialPrevious => 'Previous';

  @override
  String get tutorialNext => 'Next';

  @override
  String get tutorialSkip => 'Skip';

  @override
  String get webMobileAppOnlyTitle => 'Get the mobile app';

  @override
  String get webMobileAppOnlyMessage =>
      'This web experience is available only on larger screens. On phones smaller than 576px, please continue with the mobile app.';

  @override
  String get webMobileAppOnlyHint =>
      'Open Note Sondage on tablet or desktop, or install the app from your store.';

  @override
  String get downloadOnAppStore => 'Download on the App Store';

  @override
  String get getItOnGooglePlay => 'Get it on Google Play';

  @override
  String get mobileStoreLinksUnavailable =>
      'Store links are not configured yet. Please contact support or open the app on a larger screen.';

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
  String get teamDetails => 'Team details';

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
  String get notificationsSettingsIntro =>
      'Choose how updates and shift reminders reach you.';

  @override
  String get notificationsGeneral => 'General';

  @override
  String get emailNotifications => 'Email Notifications';

  @override
  String get receiveUpdatesByEmail => 'Receive updates via email';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get receivePushNotificationsOnYourDevice =>
      'Receive push notifications on your device';

  @override
  String get shiftReminders => 'Shift reminders';

  @override
  String get reminderMode => 'Reminder mode';

  @override
  String get notificationReminderModeDescription =>
      'Choose in each shift whether you want a standard notification or a stronger alarm.';

  @override
  String get webBehavior => 'Web behavior';

  @override
  String get alarmBehaviorOnWeb =>
      'On web, Alarm mode uses browser notifications. The tab must stay open and the browser controls the final sound and vibration behavior.';

  @override
  String get howItWorks => 'How it works';

  @override
  String get notificationAndAlarmDifference =>
      'Notification shows a normal reminder. Alarm uses the settings below and is meant for stronger shift alerts.';

  @override
  String get alarmDelivery => 'Alarm delivery';

  @override
  String get alarmStyle => 'Alarm style';

  @override
  String get webAlarmDeliveryDescription =>
      'Browser notifications are used while this tab is open. Sound and vibration are managed by the browser and operating system.';

  @override
  String get alarmStyleDescription =>
      'Choose whether Alarm mode should vibrate or play a ringtone. Default: Vibrate.';

  @override
  String get alarmStyleDescriptionIos =>
      'On iPhone, Alarm mode uses a ringtone. Vibration-only alarms are not available for local notifications.';

  @override
  String get vibrate => 'Vibrate';

  @override
  String get ringtone => 'Ringtone';

  @override
  String get browserNotification => 'Browser notification';

  @override
  String get notificationVisibility => 'Notification visibility';

  @override
  String get alarmDuration => 'Alarm duration';

  @override
  String get webNotificationVisibilityDescription =>
      'This controls how long the browser notification stays visible after it appears.';

  @override
  String get alarmDurationAppliesOnlyToAlarmMode =>
      'This duration applies only when a shift uses Alarm mode.';

  @override
  String get activity => 'Activity';

  @override
  String get surveyReminders => 'Survey Reminders';

  @override
  String get getRemindedAboutPendingSurveys =>
      'Get reminded about pending surveys';

  @override
  String get teamUpdates => 'Team Updates';

  @override
  String get notificationsAboutTeamChanges =>
      'Notifications about team changes';

  @override
  String get clockingAlerts => 'Clocking Alerts';

  @override
  String get remindersToClockInAndOut => 'Reminders to clock in and out';

  @override
  String get shiftNotifications => 'Shift Notifications';

  @override
  String get assignmentsUpdatesAndShiftReminders =>
      'Assignments, updates and shift reminders';

  @override
  String get debugTools => 'Debug tools';

  @override
  String get debugToolsBrowserMessage =>
      'Use these tests only while debugging notifications in this browser.';

  @override
  String get debugToolsDeviceMessage =>
      'Use these tests only while debugging notifications on this device.';

  @override
  String get testNotificationNow => 'Test notification now';

  @override
  String get testAlarmIn10Seconds => 'Test alarm in 10s';

  @override
  String get testCurrentMode => 'Test current mode';

  @override
  String get alarmModeStatus => 'Alarm mode status';

  @override
  String get pendingRequests => 'Pending requests';

  @override
  String get inspectRealShifts => 'Inspect real shifts';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get howWeProtectYourData => 'How we protect your data';

  @override
  String get dataProtection => 'Data Protection';

  @override
  String get dataProtectionDescription =>
      'Your data is encrypted at rest and in transit. We use industry-standard encryption protocols to ensure your information remains secure.';

  @override
  String get dataCollection => 'Data Collection';

  @override
  String get dataCollectionDescription =>
      'We collect only the data necessary to provide our services. This includes your account information, survey responses, and clocking records.';

  @override
  String get dataSharing => 'Data Sharing';

  @override
  String get dataSharingDescription =>
      'We never share your personal data with third parties without your explicit consent. Team data is shared only within your organization.';

  @override
  String get dataRetention => 'Data Retention';

  @override
  String get dataRetentionDescription =>
      'Your data is retained for as long as your account is active. After account deactivation, personal data is permanently removed within 30 days.';

  @override
  String get yourRights => 'Your Rights';

  @override
  String get yourRightsDescription =>
      'You have the right to access, rectify, or delete your personal data at any time. Contact our support team for any privacy-related requests.';

  @override
  String get privacyLastUpdated => 'Last updated: January 2025';

  @override
  String get yourName => 'Your Name';

  @override
  String get yourEmail => 'Your Email';

  @override
  String get message => 'Message';

  @override
  String get submit => 'Submit';

  @override
  String get contactUsDescription =>
      'Tell us what happened and we will send it directly to our support team.';

  @override
  String get contactUsDraftHint =>
      'Your message will be sent directly to contactus@teammanagement.it.';

  @override
  String get contactUsReplyTime => 'We usually reply within 1-2 business days.';

  @override
  String get supportEmail => 'Support email';

  @override
  String get sendEmail => 'Send email';

  @override
  String get copyEmail => 'Copy email';

  @override
  String get emailCopied => 'Support email copied to clipboard.';

  @override
  String get couldNotOpenEmailApp =>
      'We could not open your email app. Copy the address and send the message manually.';

  @override
  String get contactUsEmailSubject => 'Note Sondage support request';

  @override
  String get contactUsTopicsTitle => 'Bugs, feedback, product ideas';

  @override
  String get contactUsTopicsBody =>
      'Use this space to report issues, ask for help, or share improvements you would love to see.';

  @override
  String get contactUsFormHint =>
      'The message will include your details so support can reply faster.';

  @override
  String get contactUsSentSuccess => 'Your message has been sent to support.';

  @override
  String get contactUsSendFailed =>
      'We could not send your message right now. Please try again shortly.';

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
  String get close => 'Close';

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
  String get shiftRepeatUntil => 'Repeat until';

  @override
  String get shiftRepeatUntilHelp =>
      'A shift will be created for each day in the selected interval.';

  @override
  String get shiftEndMustBeAfterStart =>
      'End time must be after start time. If the shift ends the next day, enable Overnight Shift.';

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
