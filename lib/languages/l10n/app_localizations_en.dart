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
      'Open TeamManagement on tablet or desktop, or install the app from your store.';

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
  String get sondageChat => 'Sondage/Chat';

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
  String get contactUsEmailSubject => 'TeamManagement support request';

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
  String get deleteTeamTitle => 'Delete team';

  @override
  String get deleteTeamMessage =>
      'Are you sure you want to delete this team? This action cannot be undone.';

  @override
  String get deleteRoleTitle => 'Delete role';

  @override
  String get deleteRoleMessage => 'Are you sure you want to delete this role?';

  @override
  String get defaultRole => 'Default role';

  @override
  String get swipeToCreateRole => 'Swipe to create a new role';

  @override
  String get searchTeamsByNameOrDescription =>
      'Search teams by name or description';

  @override
  String get noTeamsMatchingSearch => 'No teams found for this search.';

  @override
  String get noArchivedTeams => 'No archived teams.';

  @override
  String get noVisibleTeams => 'No visible teams.';

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
  String get deleteAction => 'Delete';

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
  String get noPermissionToEditSurvey =>
      'You do not have permission to edit this survey.';

  @override
  String get editSurvey => 'Edit survey';

  @override
  String get deleteSurvey => 'Delete survey';

  @override
  String get deleteSurveyTitle => 'Delete survey';

  @override
  String get deleteSurveyMessage => 'Do you really want to delete this survey?';

  @override
  String get surveyDeleted => 'Survey deleted.';

  @override
  String get archiveSurvey => 'Archive survey';

  @override
  String get restoreSurvey => 'Restore survey';

  @override
  String get noDraftOrActiveSurveysAvailable =>
      'No draft or active surveys available';

  @override
  String get noSurveysMatchingSearch => 'No surveys found for this search.';

  @override
  String get noArchivedSurveys => 'No archived surveys.';

  @override
  String get noVisibleSurveys => 'No visible surveys.';

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
  String get shiftTeamReportTitle => 'Team shift report';

  @override
  String get shiftTeamReportSubtitle =>
      'Filter by period and users, then preview or download the report.';

  @override
  String get shiftTeamReportTooltip => 'Team shift report';

  @override
  String get shiftTeamReportButton => 'Team report';

  @override
  String get shiftReportUnavailable =>
      'No manageable team available for reporting.';

  @override
  String get shiftReportStartDate => 'Start date';

  @override
  String get shiftReportEndDate => 'End date';

  @override
  String get shiftReportUsers => 'Users to include';

  @override
  String get shiftReportRefresh => 'Refresh report';

  @override
  String get shiftReportPeriod => 'Period';

  @override
  String get shiftReportShifts => 'Shifts';

  @override
  String get shiftReportMode => 'Mode';

  @override
  String get shiftReportCalendarMode => 'Calendar';

  @override
  String get shiftReportTableMode => 'Table';

  @override
  String get shiftReportSelectTeam => 'Select a team.';

  @override
  String get shiftReportNoResults =>
      'No shifts found for the selected filters.';

  @override
  String get shiftReportLoadError =>
      'We could not load the shift report right now.';

  @override
  String get shiftReportGeneratedAt => 'Generated at';

  @override
  String get shiftReportDateColumn => 'Date';

  @override
  String get shiftReportUserColumn => 'User';

  @override
  String get shiftReportProfileColumn => 'Profile';

  @override
  String get shiftReportTypeColumn => 'Type';

  @override
  String get shiftReportDefaultProfile => 'Shift';

  @override
  String get shiftReportPrivateType => 'Private';

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
  String get deleteShiftTitle => 'Delete shift';

  @override
  String get deleteShiftMessage =>
      'Are you sure you want to delete this shift?';

  @override
  String get publicProfile => 'Public';

  @override
  String get privateProfile => 'Private';

  @override
  String get visibleToTeamMembers => 'Visible to all team members';

  @override
  String get visibleOnlyToYou => 'Visible only to you';

  @override
  String get syncing => 'Syncing';

  @override
  String get customProfile => 'Custom Profiles';

  @override
  String get noShiftsThisMonth => 'No shifts this month';

  @override
  String get systemProfile => 'System Profiles';

  @override
  String get clockingDateLabel => 'Clocking date';

  @override
  String get calendarWeek => 'Week';

  @override
  String get calendarMonth => 'Month';

  @override
  String get today => 'Today';

  @override
  String get clockingOverviewTitle => 'Clocking overview';

  @override
  String get clockingOverviewDescription =>
      'This header introduces the clocking area and its main purpose.';

  @override
  String get clockingCurrentStatusTitle => 'Current status';

  @override
  String get clockingCurrentStatusDescription =>
      'This section gives you an instant view of your clocking status and the main information for the current day.';

  @override
  String get personal => 'Personal';

  @override
  String get markVacation => 'Mark vacation';

  @override
  String get markPermission => 'Mark permission';

  @override
  String get requestClocking => 'Request clocking';

  @override
  String get requestDecommit => 'Request decommit';

  @override
  String get requestVacation => 'Request vacation';

  @override
  String get requestPermission => 'Request permission';

  @override
  String get vacationStatus => 'Vacation';

  @override
  String get clockingOpenRecordAnotherDay =>
      'You have an open clocking on another day. Select it to continue.';

  @override
  String dayAlreadyHasClocking(String date) {
    return 'A clocking already exists for $date.';
  }

  @override
  String get manualClockingUseInlineForPastDays =>
      'For days other than today, use the manual entry section below.';

  @override
  String get manualClockingRequiresApproval =>
      'For this date, ask a manager for clocking approval or use a team you manage.';

  @override
  String get selectedDayMarkedAsVacation =>
      'The selected day is marked as vacation.';

  @override
  String get clockingCurrentTimeOverlapsExistingRecord =>
      'The current time falls inside a clocking or permission already recorded today.';

  @override
  String createClockingForDate(String date) {
    return 'Create a clocking for $date';
  }

  @override
  String get breakOnlyCurrentDay =>
      'Breaks are available only for the current day.';

  @override
  String get manualClockingTitle => 'Add clocking';

  @override
  String manualClockingDescription(String date) {
    return 'Fill in the clocking for $date or add more past days.';
  }

  @override
  String manualClockingSingleDayDescription(String date) {
    return 'Fill in the clocking for $date.';
  }

  @override
  String get manualClockingResolveOpenRecord =>
      'You have an open clocking on another day. Close it or select that day before saving a manual clocking.';

  @override
  String get selectedDays => 'Selected days';

  @override
  String get addDay => 'Add day';

  @override
  String get clockInLabel => 'Clock-in';

  @override
  String get clockOutLabel => 'Clock-out';

  @override
  String get optionalNoteHint => 'Optional note';

  @override
  String get saving => 'Saving...';

  @override
  String get saveClocking => 'Save clocking';

  @override
  String get manualClockingTodayLiveOnly =>
      'For today, use the live clock-in, break, and clock-out actions.';

  @override
  String get invalidBreakMinutes => 'Break time must be a valid number.';

  @override
  String get clockOutMustBeAfterClockIn =>
      'Clock-out time must be after clock-in.';

  @override
  String get breakMustBeShorterThanShift =>
      'Break must be shorter than shift duration.';

  @override
  String get manualClockingSavedSingle => 'Clocking saved successfully.';

  @override
  String manualClockingSavedMultiple(int count) {
    return '$count clockings saved successfully.';
  }

  @override
  String get manualClockingSaveError =>
      'We couldn\'t save the manual clocking.';

  @override
  String get manualClockingBackToTodayTooltip => 'Back to today';

  @override
  String get manualClockingBackToTodayTitle => 'Back to today?';

  @override
  String get manualClockingBackToTodayMessage =>
      'You are about to leave manual clocking mode.\n\nIf you want to edit a clocking from a past day, you will need to submit a new manual clocking request for that day.';

  @override
  String get manualClockingBackToTodayConfirm => 'Back to today';

  @override
  String get manualClockingOverlapTitle => 'Overlap detected';

  @override
  String manualClockingOverlapMessage(
    String newRange,
    String existingRange,
    String newEndTime,
  ) {
    return 'The new clocking ($newRange) overlaps with an existing clocking ($existingRange).\n\nDo you want to shorten the existing clocking so it ends at $newEndTime?';
  }

  @override
  String get manualClockingOverlapConfirmAdjust => 'Yes, shorten it';

  @override
  String get noTeamSelected => 'No team selected';

  @override
  String get changeOrSearchTeam => 'Open to change team or search for one';

  @override
  String get teamAvailableForClocking => 'Team available for clocking';

  @override
  String get searchTeam => 'Search team...';

  @override
  String get noTeamFound => 'No team found';

  @override
  String get selectTeamFirst => 'Select a team first.';

  @override
  String get selectTeamBeforeVacation =>
      'Select a team before marking vacation.';

  @override
  String markSelectedDateAsVacation(String date) {
    return 'Mark $date as vacation';
  }

  @override
  String get markSelectedDayAsVacationDescription =>
      'This action will mark the selected day as vacation.';

  @override
  String markPermissionForDate(String date) {
    return 'Mark permission for $date';
  }

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String get permissionInvalidRange =>
      'End time must be after start time for permission.';

  @override
  String get noAssignableMembersForTeam =>
      'No assignable members found for this team.';

  @override
  String get assignVacationToMember => 'Mark vacation for a member';

  @override
  String get userLabel => 'User';

  @override
  String optionalNoteFor(String name) {
    return 'Optional note for $name';
  }

  @override
  String get optionalRequestNoteHint => 'Optional note for the request';

  @override
  String get clockingApprovalRequestHint =>
      'You can request clocking, decommit, vacation, or permission for the selected team and date.';

  @override
  String requestClockingForSelectedDate(String date) {
    return 'Request clocking for $date';
  }

  @override
  String requestDecommitForSelectedDate(String date) {
    return 'Request decommit for $date';
  }

  @override
  String get noMembersAvailableForClockingRequest =>
      'No members available for the clocking request.';

  @override
  String get sendRequest => 'Send request';

  @override
  String get clockingRequestSentSuccess =>
      'Clocking request sent successfully.';

  @override
  String get clockingRequestSentError =>
      'We couldn\'t send the clocking request to the team member.';

  @override
  String get decommitRequestSentSuccess =>
      'Decommit request sent successfully.';

  @override
  String get decommitRequestSentError =>
      'We couldn\'t send the decommit request.';

  @override
  String get vacationRequestSentSuccess =>
      'Vacation request sent successfully.';

  @override
  String get vacationRequestSentError =>
      'We couldn\'t send the vacation request.';

  @override
  String get permissionRequestSentSuccess =>
      'Permission request sent successfully.';

  @override
  String get permissionRequestSentError =>
      'We couldn\'t send the permission request.';

  @override
  String get approveRequest => 'Approve';

  @override
  String get rejectRequest => 'Reject';

  @override
  String get clockInDateTimeLabel => 'Clock-in (YYYY-MM-DD HH:MM)';

  @override
  String get clockOutDateTimeLabel => 'Clock-out (YYYY-MM-DD HH:MM)';

  @override
  String get chatTitle => 'Chat';

  @override
  String get chatLive => 'Live';

  @override
  String get chatTeamTitle => 'Team chat';

  @override
  String get chatRefresh => 'Refresh';

  @override
  String get chatChooseConversation => 'Choose a conversation';

  @override
  String get chatListDescriptionWeb =>
      'Pick a team channel or reopen one of your direct chats.';

  @override
  String get chatListDescriptionMobile =>
      'Open a team channel or jump back into one of your direct chats.';

  @override
  String get chatTeamChannels => 'Team channels';

  @override
  String get chatDirectChats => 'Direct chats';

  @override
  String get chatNoDirectContacts =>
      'Your direct chat history will appear here.';

  @override
  String get chatNoTeamsAvailable => 'No teams available for chat right now.';

  @override
  String get chatChooseTeamHeader => 'Choose a team to start chatting.';

  @override
  String chatHeaderDirectDescription(String name) {
    return 'Direct chat with $name';
  }

  @override
  String chatHeaderTeamDescription(String name) {
    return 'Team chat for $name';
  }

  @override
  String get chatRefreshed => 'Chat refreshed.';

  @override
  String get chatLoadTeamsError => 'We couldn\'t load your chat teams.';

  @override
  String get chatLoadConversationError =>
      'We couldn\'t load this conversation.';

  @override
  String get chatSendMessageError => 'We couldn\'t send the message.';

  @override
  String get chatReactionUpdateError => 'We couldn\'t update the reaction.';

  @override
  String get chatDeleteError => 'We couldn\'t delete the message.';

  @override
  String get chatReactTitle => 'React to message';

  @override
  String get chatReactHint => 'Choose an emoji reaction.';

  @override
  String get chatDeleteTitle => 'Delete message';

  @override
  String get chatDeleteMessage => 'Do you want to delete this message?';

  @override
  String get chatYouLabel => 'You';

  @override
  String get chatTimelineBeginning => 'The conversation starts here';

  @override
  String chatTimelineActive(String name) {
    return '$name is active';
  }

  @override
  String chatTimelineResumed(String duration) {
    return 'Conversation resumed after $duration';
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
      other: '$hours hrs',
      one: '1 hr',
    );
    return '$_temp0';
  }

  @override
  String chatDurationDaysShort(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get chatReplyAction => 'Reply';

  @override
  String get chatLoadingOlderMessages => 'Loading older messages...';

  @override
  String get chatNoMessagesYet => 'No messages yet';

  @override
  String get chatEmptyDescription =>
      'Write the first message to start this conversation.';

  @override
  String get chatSeen => 'Seen';

  @override
  String get chatDeletedMessage => 'Message deleted';

  @override
  String get chatAttachmentFallback => 'Attachment';

  @override
  String get chatOpenDocument => 'Open document';

  @override
  String get chatOpenSharedConversation => 'Open the shared team conversation.';

  @override
  String get chatOpenConversation => 'Open conversation';

  @override
  String chatDirectConversationInTeam(String teamName) {
    return 'Direct conversation in $teamName';
  }

  @override
  String get chatDirectActionDescription =>
      'Open a private chat with this team member.';

  @override
  String get chatOpenDirectAction => 'Open direct chat';

  @override
  String get chatReturnToChatList => 'Back to chat list';

  @override
  String get chatReturnToTeamList => 'Back to team list';

  @override
  String get chatComposerHint => 'Write a message';

  @override
  String get chatPickImage => 'Add image';

  @override
  String get chatPickDocument => 'Add document';

  @override
  String get chatAddEmoji => 'Add emoji';

  @override
  String chatReplyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String get chatCancelReply => 'Cancel reply';

  @override
  String get chatImageReadyToSend => 'Image ready to send';

  @override
  String get chatDocumentReadyToSend => 'Document ready to send';

  @override
  String get chatRemoveAttachment => 'Remove attachment';

  @override
  String get chatJustNow => 'just now';

  @override
  String chatMinutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min ago',
      one: '1 min ago',
    );
    return '$_temp0';
  }

  @override
  String chatHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hrs ago',
      one: '1 hr ago',
    );
    return '$_temp0';
  }

  @override
  String get chatYesterday => 'yesterday';

  @override
  String chatDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }
}
