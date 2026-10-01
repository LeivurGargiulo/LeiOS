import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
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
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'LeiOS'**
  String get appName;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get navGoals;

  /// No description provided for @navNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get navNotes;

  /// No description provided for @navLists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get navLists;

  /// No description provided for @navFinances.
  ///
  /// In en, this message translates to:
  /// **'Finances'**
  String get navFinances;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

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

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesBody.
  ///
  /// In en, this message translates to:
  /// **'Your edits will be lost.'**
  String get discardChangesBody;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @newItem.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newItem;

  /// No description provided for @moreDetails.
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get moreDetails;

  /// No description provided for @entityAdded.
  ///
  /// In en, this message translates to:
  /// **'{entity} added'**
  String entityAdded(String entity);

  /// No description provided for @entityDeleted.
  ///
  /// In en, this message translates to:
  /// **'{entity} deleted'**
  String entityDeleted(String entity);

  /// No description provided for @quickAddTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get quickAddTask;

  /// No description provided for @quickAddNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get quickAddNote;

  /// No description provided for @quickAddTransaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get quickAddTransaction;

  /// No description provided for @quickAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick add'**
  String get quickAddTitle;

  /// No description provided for @syncSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncSynced;

  /// No description provided for @syncSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get syncSyncing;

  /// No description provided for @syncOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get syncOffline;

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get syncError;

  /// No description provided for @emptyHabitsTitle.
  ///
  /// In en, this message translates to:
  /// **'No habits yet'**
  String get emptyHabitsTitle;

  /// No description provided for @emptyHabitsMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a habit to start building streaks.'**
  String get emptyHabitsMessage;

  /// No description provided for @emptyHabitsAction.
  ///
  /// In en, this message translates to:
  /// **'Add habit'**
  String get emptyHabitsAction;

  /// No description provided for @emptyCaughtUpTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get emptyCaughtUpTitle;

  /// No description provided for @emptyCaughtUpMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing due in the next 7 days.'**
  String get emptyCaughtUpMessage;

  /// No description provided for @emptyTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to do'**
  String get emptyTasksTitle;

  /// No description provided for @emptyTasksMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a task to get started.'**
  String get emptyTasksMessage;

  /// No description provided for @emptyTasksAction.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get emptyTasksAction;

  /// No description provided for @emptyTasksFilteredTitle.
  ///
  /// In en, this message translates to:
  /// **'No tasks here'**
  String get emptyTasksFilteredTitle;

  /// No description provided for @emptyTasksFilteredMessage.
  ///
  /// In en, this message translates to:
  /// **'Try another view or scope.'**
  String get emptyTasksFilteredMessage;

  /// No description provided for @emptyDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned'**
  String get emptyDayTitle;

  /// No description provided for @emptyDayMessage.
  ///
  /// In en, this message translates to:
  /// **'Enjoy the free day, or add an event.'**
  String get emptyDayMessage;

  /// No description provided for @emptyDayAction.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get emptyDayAction;

  /// No description provided for @emptyGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'No goals yet'**
  String get emptyGoalsTitle;

  /// No description provided for @emptyGoalsMessage.
  ///
  /// In en, this message translates to:
  /// **'Set a goal and break it into steps.'**
  String get emptyGoalsMessage;

  /// No description provided for @emptyGoalsAction.
  ///
  /// In en, this message translates to:
  /// **'Add goal'**
  String get emptyGoalsAction;

  /// No description provided for @emptyNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get emptyNotesTitle;

  /// No description provided for @emptyNotesMessage.
  ///
  /// In en, this message translates to:
  /// **'Capture a thought.'**
  String get emptyNotesMessage;

  /// No description provided for @emptyNotesAction.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get emptyNotesAction;

  /// No description provided for @emptySearchTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get emptySearchTitle;

  /// No description provided for @emptySearchMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or tag.'**
  String get emptySearchMessage;

  /// No description provided for @emptyMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to watch or read'**
  String get emptyMediaTitle;

  /// No description provided for @emptyMediaMessage.
  ///
  /// In en, this message translates to:
  /// **'Add movies, series, books or games.'**
  String get emptyMediaMessage;

  /// No description provided for @emptyWishlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Your wishlist is empty'**
  String get emptyWishlistTitle;

  /// No description provided for @emptyWishlistMessage.
  ///
  /// In en, this message translates to:
  /// **'Add things you want to buy.'**
  String get emptyWishlistMessage;

  /// No description provided for @emptyDreamsTitle.
  ///
  /// In en, this message translates to:
  /// **'No dreams yet'**
  String get emptyDreamsTitle;

  /// No description provided for @emptyDreamsMessage.
  ///
  /// In en, this message translates to:
  /// **'Add something you\'d love to do someday.'**
  String get emptyDreamsMessage;

  /// No description provided for @emptyDreamsAction.
  ///
  /// In en, this message translates to:
  /// **'Add dream'**
  String get emptyDreamsAction;

  /// No description provided for @emptyLearningTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to learn yet'**
  String get emptyLearningTitle;

  /// No description provided for @emptyLearningMessage.
  ///
  /// In en, this message translates to:
  /// **'Add skills or courses you want to learn.'**
  String get emptyLearningMessage;

  /// No description provided for @emptyListAction.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get emptyListAction;

  /// No description provided for @emptyTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions this month'**
  String get emptyTransactionsTitle;

  /// No description provided for @emptyTransactionsMessage.
  ///
  /// In en, this message translates to:
  /// **'Add income or an expense.'**
  String get emptyTransactionsMessage;

  /// No description provided for @emptyTransactionsAction.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get emptyTransactionsAction;

  /// No description provided for @emptyFundsTitle.
  ///
  /// In en, this message translates to:
  /// **'No savings funds'**
  String get emptyFundsTitle;

  /// No description provided for @emptyFundsMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a fund to track a savings goal.'**
  String get emptyFundsMessage;

  /// No description provided for @emptyFundsAction.
  ///
  /// In en, this message translates to:
  /// **'Add fund'**
  String get emptyFundsAction;

  /// No description provided for @emptyMoodTitle.
  ///
  /// In en, this message translates to:
  /// **'No mood entries yet'**
  String get emptyMoodTitle;

  /// No description provided for @emptyMoodMessage.
  ///
  /// In en, this message translates to:
  /// **'Pick how you feel today.'**
  String get emptyMoodMessage;

  /// No description provided for @emptySelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Select an item'**
  String get emptySelectionTitle;

  /// No description provided for @emptySelectionMessage.
  ///
  /// In en, this message translates to:
  /// **'Pick something from the list to see or edit it.'**
  String get emptySelectionMessage;

  /// No description provided for @emptySyncTitle.
  ///
  /// In en, this message translates to:
  /// **'All changes synced'**
  String get emptySyncTitle;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @previousYear.
  ///
  /// In en, this message translates to:
  /// **'Previous year'**
  String get previousYear;

  /// No description provided for @nextYear.
  ///
  /// In en, this message translates to:
  /// **'Next year'**
  String get nextYear;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @precisionDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get precisionDay;

  /// No description provided for @precisionMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get precisionMonth;

  /// No description provided for @precisionQuarter.
  ///
  /// In en, this message translates to:
  /// **'Quarter'**
  String get precisionQuarter;

  /// No description provided for @precisionYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get precisionYear;

  /// No description provided for @quarterShort.
  ///
  /// In en, this message translates to:
  /// **'Q{n}'**
  String quarterShort(int n);

  /// No description provided for @targetPeriod.
  ///
  /// In en, this message translates to:
  /// **'Target: {period}'**
  String targetPeriod(String period);

  /// No description provided for @fabSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'{label}. Long-press for quick add.'**
  String fabSemanticLabel(String label);

  /// No description provided for @fieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authResetPassword;

  /// No description provided for @authAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created. Check your inbox to confirm your email, then sign in.'**
  String get authAccountCreated;

  /// No description provided for @authResetSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists, a reset link is on its way.'**
  String get authResetSent;

  /// No description provided for @authEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email.'**
  String get authEnterValidEmail;

  /// No description provided for @authPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters.'**
  String get authPasswordMin;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authCreateAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get authCreateAnAccount;

  /// No description provided for @authBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get authBackToSignIn;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePassword;

  /// No description provided for @settingsNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get settingsNewPassword;

  /// No description provided for @settingsPasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated.'**
  String get settingsPasswordUpdated;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @settingsSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get settingsSignOutTitle;

  /// No description provided for @settingsSignOutPending.
  ///
  /// In en, this message translates to:
  /// **'You have {count} {count, plural, =1{change} other{changes}} that haven\'t synced yet. Signing out will discard them and clear local data.'**
  String settingsSignOutPending(int count);

  /// No description provided for @settingsSignOutClean.
  ///
  /// In en, this message translates to:
  /// **'Local data on this device will be cleared. Everything is safe in the cloud.'**
  String get settingsSignOutClean;

  /// No description provided for @settingsExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export data?'**
  String get settingsExportTitle;

  /// No description provided for @settingsExportBody.
  ///
  /// In en, this message translates to:
  /// **'The JSON file is plain text and NOT encrypted. Keep it somewhere safe.'**
  String get settingsExportBody;

  /// No description provided for @settingsExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get settingsExport;

  /// No description provided for @settingsExportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save LeiOS export'**
  String get settingsExportDialogTitle;

  /// No description provided for @settingsExportCancelled.
  ///
  /// In en, this message translates to:
  /// **'Export cancelled.'**
  String get settingsExportCancelled;

  /// No description provided for @settingsExportSaved.
  ///
  /// In en, this message translates to:
  /// **'Export saved.'**
  String get settingsExportSaved;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get settingsDisplayName;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsSync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get settingsSync;

  /// No description provided for @settingsConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get settingsConnected;

  /// No description provided for @settingsNotSyncedYet.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get settingsNotSyncedYet;

  /// No description provided for @settingsLastSync.
  ///
  /// In en, this message translates to:
  /// **'Last sync {time}'**
  String settingsLastSync(String time);

  /// No description provided for @settingsPendingChanges.
  ///
  /// In en, this message translates to:
  /// **'Pending changes'**
  String get settingsPendingChanges;

  /// No description provided for @settingsSyncErrors.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{change} other{changes}} could not be synced'**
  String settingsSyncErrors(int count);

  /// No description provided for @settingsDismissAll.
  ///
  /// In en, this message translates to:
  /// **'Dismiss all'**
  String get settingsDismissAll;

  /// No description provided for @settingsReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get settingsReconnect;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// No description provided for @settingsExportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get settingsExportData;

  /// No description provided for @settingsExportHint.
  ///
  /// In en, this message translates to:
  /// **'Plain, unencrypted JSON of all your data'**
  String get settingsExportHint;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @commaSeparated.
  ///
  /// In en, this message translates to:
  /// **'Comma separated'**
  String get commaSeparated;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @entityEntry.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get entityEntry;

  /// No description provided for @entityFund.
  ///
  /// In en, this message translates to:
  /// **'Fund'**
  String get entityFund;

  /// No description provided for @entityGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get entityGoal;

  /// No description provided for @entityEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get entityEvent;

  /// No description provided for @entityItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get entityItem;

  /// No description provided for @statusTodo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get statusTodo;

  /// No description provided for @statusDoing.
  ///
  /// In en, this message translates to:
  /// **'Doing'**
  String get statusDoing;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @sectionCount.
  ///
  /// In en, this message translates to:
  /// **'{title} ({count})'**
  String sectionCount(String title, int count);

  /// No description provided for @tabCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get tabCheckIn;

  /// No description provided for @tabReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get tabReview;

  /// No description provided for @todayDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get todayDueSoon;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @next7Days.
  ///
  /// In en, this message translates to:
  /// **'Next 7 days'**
  String get next7Days;

  /// No description provided for @moodHowAreYou.
  ///
  /// In en, this message translates to:
  /// **'How are you today?'**
  String get moodHowAreYou;

  /// No description provided for @moodAddNoteOrTags.
  ///
  /// In en, this message translates to:
  /// **'Add note or tags'**
  String get moodAddNoteOrTags;

  /// No description provided for @moodEditNote.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get moodEditNote;

  /// No description provided for @moodTitle.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get moodTitle;

  /// No description provided for @moodRatingOf.
  ///
  /// In en, this message translates to:
  /// **'Mood {rating} of 5'**
  String moodRatingOf(int rating);

  /// No description provided for @moodRatingOfSelected.
  ///
  /// In en, this message translates to:
  /// **'Mood {rating} of 5, selected'**
  String moodRatingOfSelected(int rating);

  /// No description provided for @habitsManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get habitsManage;

  /// No description provided for @habitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get habitsTitle;

  /// No description provided for @habitTarget.
  ///
  /// In en, this message translates to:
  /// **'Target {count} / week'**
  String habitTarget(int count);

  /// No description provided for @habitDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String habitDeleteTooltip(String name);

  /// No description provided for @habitDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete habit?'**
  String get habitDeleteTitle;

  /// No description provided for @habitDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This also deletes all completions of \"{name}\".'**
  String habitDeleteBody(String name);

  /// No description provided for @habitNew.
  ///
  /// In en, this message translates to:
  /// **'New habit'**
  String get habitNew;

  /// No description provided for @habitEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit habit'**
  String get habitEdit;

  /// No description provided for @habitTargetPerWeek.
  ///
  /// In en, this message translates to:
  /// **'Target per week: {count}'**
  String habitTargetPerWeek(int count);

  /// No description provided for @habitStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak'**
  String habitStreak(int count);

  /// No description provided for @habitCompletedToday.
  ///
  /// In en, this message translates to:
  /// **'{name}, completed today'**
  String habitCompletedToday(String name);

  /// No description provided for @habitNotCompletedToday.
  ///
  /// In en, this message translates to:
  /// **'{name}, not completed today'**
  String habitNotCompletedToday(String name);

  /// No description provided for @habitDayCompleted.
  ///
  /// In en, this message translates to:
  /// **'{day}, {name}, completed'**
  String habitDayCompleted(String day, String name);

  /// No description provided for @habitDayNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'{day}, {name}, not completed'**
  String habitDayNotCompleted(String day, String name);

  /// No description provided for @weekTitle.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get weekTitle;

  /// No description provided for @weekPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get weekPrevious;

  /// No description provided for @weekNext.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get weekNext;

  /// No description provided for @weekThis.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get weekThis;

  /// No description provided for @weekEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add a habit to see your week.'**
  String get weekEmpty;

  /// No description provided for @statAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get statAverage;

  /// No description provided for @statCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get statCurrentStreak;

  /// No description provided for @statTotalEntries.
  ///
  /// In en, this message translates to:
  /// **'Total entries'**
  String get statTotalEntries;

  /// No description provided for @statBestWeekday.
  ///
  /// In en, this message translates to:
  /// **'Best weekday'**
  String get statBestWeekday;

  /// No description provided for @statWorstWeekday.
  ///
  /// In en, this message translates to:
  /// **'Worst weekday'**
  String get statWorstWeekday;

  /// No description provided for @moodInsights.
  ///
  /// In en, this message translates to:
  /// **'Mood insights'**
  String get moodInsights;

  /// No description provided for @topTags.
  ///
  /// In en, this message translates to:
  /// **'Top tags'**
  String get topTags;

  /// No description provided for @moodTrend.
  ///
  /// In en, this message translates to:
  /// **'Mood trend (30 days)'**
  String get moodTrend;

  /// No description provided for @showChart.
  ///
  /// In en, this message translates to:
  /// **'Show chart'**
  String get showChart;

  /// No description provided for @showTable.
  ///
  /// In en, this message translates to:
  /// **'Show as table'**
  String get showTable;

  /// No description provided for @moodTrendSemantics.
  ///
  /// In en, this message translates to:
  /// **'Mood over the last 30 days. Use \"Show as table\" for the data.'**
  String get moodTrendSemantics;

  /// No description provided for @moodHistory.
  ///
  /// In en, this message translates to:
  /// **'Mood history'**
  String get moodHistory;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @listTabMedia.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get listTabMedia;

  /// No description provided for @listTabWishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get listTabWishlist;

  /// No description provided for @listTabDreams.
  ///
  /// In en, this message translates to:
  /// **'Dreams'**
  String get listTabDreams;

  /// No description provided for @listTabLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get listTabLearning;

  /// No description provided for @listDonePurchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get listDonePurchased;

  /// No description provided for @listDoneLearned.
  ///
  /// In en, this message translates to:
  /// **'Learned'**
  String get listDoneLearned;

  /// No description provided for @listCategoryKind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get listCategoryKind;

  /// No description provided for @listCategoryCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get listCategoryCategory;

  /// No description provided for @listCategoryArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get listCategoryArea;

  /// No description provided for @listReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get listReorder;

  /// No description provided for @listDoneReordering.
  ///
  /// In en, this message translates to:
  /// **'Done reordering'**
  String get listDoneReordering;

  /// No description provided for @listAddItemTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add {kind} item'**
  String listAddItemTooltip(String kind);

  /// No description provided for @listNewItem.
  ///
  /// In en, this message translates to:
  /// **'New {kind} item'**
  String listNewItem(String kind);

  /// No description provided for @listEditItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get listEditItem;

  /// No description provided for @fieldUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get fieldUrl;

  /// No description provided for @fieldPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get fieldPrice;

  /// No description provided for @listFilterBy.
  ///
  /// In en, this message translates to:
  /// **'Filter by {category}'**
  String listFilterBy(String category);

  /// No description provided for @listPendingTotal.
  ///
  /// In en, this message translates to:
  /// **'Pending total'**
  String get listPendingTotal;

  /// No description provided for @listMarkPending.
  ///
  /// In en, this message translates to:
  /// **'Mark pending'**
  String get listMarkPending;

  /// No description provided for @listMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Mark {status}'**
  String listMarkDone(String status);

  /// No description provided for @listStatusYes.
  ///
  /// In en, this message translates to:
  /// **'{status}: yes'**
  String listStatusYes(String status);

  /// No description provided for @listStatusNo.
  ///
  /// In en, this message translates to:
  /// **'{status}: no'**
  String listStatusNo(String status);

  /// No description provided for @listOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get listOpenLink;

  /// No description provided for @longTerm.
  ///
  /// In en, this message translates to:
  /// **'Long-term'**
  String get longTerm;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @important.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get important;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @noDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get noDate;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @viewByStatus.
  ///
  /// In en, this message translates to:
  /// **'By status'**
  String get viewByStatus;

  /// No description provided for @viewByDate.
  ///
  /// In en, this message translates to:
  /// **'By date'**
  String get viewByDate;

  /// No description provided for @viewMatrix.
  ///
  /// In en, this message translates to:
  /// **'Matrix'**
  String get viewMatrix;

  /// No description provided for @scopeRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get scopeRegular;

  /// No description provided for @tasksChangeView.
  ///
  /// In en, this message translates to:
  /// **'Change view'**
  String get tasksChangeView;

  /// No description provided for @tasksCollapseDone.
  ///
  /// In en, this message translates to:
  /// **'Collapse done tasks'**
  String get tasksCollapseDone;

  /// No description provided for @tasksExpandDone.
  ///
  /// In en, this message translates to:
  /// **'Expand done tasks'**
  String get tasksExpandDone;

  /// No description provided for @matrixUrgentImportant.
  ///
  /// In en, this message translates to:
  /// **'Urgent & important'**
  String get matrixUrgentImportant;

  /// No description provided for @matrixImportantNotUrgent.
  ///
  /// In en, this message translates to:
  /// **'Important, not urgent'**
  String get matrixImportantNotUrgent;

  /// No description provided for @matrixUrgentNotImportant.
  ///
  /// In en, this message translates to:
  /// **'Urgent, not important'**
  String get matrixUrgentNotImportant;

  /// No description provided for @matrixNeither.
  ///
  /// In en, this message translates to:
  /// **'Neither'**
  String get matrixNeither;

  /// No description provided for @taskNew.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get taskNew;

  /// No description provided for @taskEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get taskEdit;

  /// No description provided for @taskPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get taskPickDate;

  /// No description provided for @taskTapToAdvance.
  ///
  /// In en, this message translates to:
  /// **'{status}. Tap to advance.'**
  String taskTapToAdvance(String status);

  /// No description provided for @taskMarkTodo.
  ///
  /// In en, this message translates to:
  /// **'Mark to do'**
  String get taskMarkTodo;

  /// No description provided for @taskAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance status'**
  String get taskAdvance;

  /// No description provided for @calendarMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get calendarMonth;

  /// No description provided for @calendarAgenda.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get calendarAgenda;

  /// No description provided for @eventNew.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get eventNew;

  /// No description provided for @eventEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get eventEdit;

  /// No description provided for @calendarTasksDue.
  ///
  /// In en, this message translates to:
  /// **'Tasks due'**
  String get calendarTasksDue;

  /// No description provided for @calendarTasksDueShort.
  ///
  /// In en, this message translates to:
  /// **'tasks due'**
  String get calendarTasksDueShort;

  /// No description provided for @calendarEventsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{event} other{events}}'**
  String calendarEventsCount(int count);

  /// No description provided for @allDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get allDay;

  /// No description provided for @eventRepeatsWeekly.
  ///
  /// In en, this message translates to:
  /// **'Repeats weekly'**
  String get eventRepeatsWeekly;

  /// No description provided for @calendarTodayHeader.
  ///
  /// In en, this message translates to:
  /// **'Today · {label}'**
  String calendarTodayHeader(String label);

  /// No description provided for @eventDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete event?'**
  String get eventDeleteTitle;

  /// No description provided for @eventDeleteSeries.
  ///
  /// In en, this message translates to:
  /// **'This deletes the whole repeating series, not just one occurrence.'**
  String get eventDeleteSeries;

  /// No description provided for @eventDeleteSingle.
  ///
  /// In en, this message translates to:
  /// **'This event will be deleted.'**
  String get eventDeleteSingle;

  /// No description provided for @eventWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get eventWhen;

  /// No description provided for @eventStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get eventStartTime;

  /// No description provided for @eventEndTime.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get eventEndTime;

  /// No description provided for @eventClearEnd.
  ///
  /// In en, this message translates to:
  /// **'Clear end'**
  String get eventClearEnd;

  /// No description provided for @eventRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get eventRepeat;

  /// No description provided for @eventRepeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Repeat weekly'**
  String get eventRepeatWeekly;

  /// No description provided for @eventUntilOptional.
  ///
  /// In en, this message translates to:
  /// **'Until (optional)'**
  String get eventUntilOptional;

  /// No description provided for @eventUntil.
  ///
  /// In en, this message translates to:
  /// **'Until {date}'**
  String eventUntil(String date);

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @eventEndDateMultiDay.
  ///
  /// In en, this message translates to:
  /// **'End date (multi-day)'**
  String get eventEndDateMultiDay;

  /// No description provided for @eventEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends {date}'**
  String eventEnds(String date);

  /// No description provided for @eventDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get eventDetails;

  /// No description provided for @goalDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete goal?'**
  String get goalDeleteTitle;

  /// No description provided for @goalDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This also deletes the goal\'s checklist steps.'**
  String get goalDeleteBody;

  /// No description provided for @goalNew.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get goalNew;

  /// No description provided for @goalEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get goalEdit;

  /// No description provided for @goalTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get goalTarget;

  /// No description provided for @goalStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get goalStatus;

  /// No description provided for @goalProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get goalProgress;

  /// No description provided for @goalSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get goalSteps;

  /// No description provided for @goalProgressSemantics.
  ///
  /// In en, this message translates to:
  /// **'Goal progress'**
  String get goalProgressSemantics;

  /// No description provided for @goalProgressOf.
  ///
  /// In en, this message translates to:
  /// **'{title} progress'**
  String goalProgressOf(String title);

  /// No description provided for @goalRemoveStep.
  ///
  /// In en, this message translates to:
  /// **'Remove step'**
  String get goalRemoveStep;

  /// No description provided for @goalAddStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Add a step'**
  String get goalAddStepLabel;

  /// No description provided for @goalAddStepTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add step'**
  String get goalAddStepTooltip;

  /// No description provided for @goalCreated.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String goalCreated(String date);

  /// No description provided for @goalViewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get goalViewList;

  /// No description provided for @goalViewByPeriod.
  ///
  /// In en, this message translates to:
  /// **'By period'**
  String get goalViewByPeriod;

  /// No description provided for @goalYearSummary.
  ///
  /// In en, this message translates to:
  /// **'Year {year} — completed {completed}/{total} ({percent}%)'**
  String goalYearSummary(int year, int completed, int total, int percent);

  /// No description provided for @goalWholeYear.
  ///
  /// In en, this message translates to:
  /// **'Whole year'**
  String get goalWholeYear;

  /// No description provided for @goalNoTargetDate.
  ///
  /// In en, this message translates to:
  /// **'No target date'**
  String get goalNoTargetDate;

  /// No description provided for @noteNew.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get noteNew;

  /// No description provided for @noteEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get noteEdit;

  /// No description provided for @noteSearch.
  ///
  /// In en, this message translates to:
  /// **'Search notes'**
  String get noteSearch;

  /// No description provided for @noteContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get noteContent;

  /// No description provided for @notePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get notePreview;

  /// No description provided for @noteNothingToPreview.
  ///
  /// In en, this message translates to:
  /// **'*Nothing to preview*'**
  String get noteNothingToPreview;

  /// No description provided for @noteMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Markdown'**
  String get noteMarkdown;

  /// No description provided for @txIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get txIncome;

  /// No description provided for @txExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get txExpense;

  /// No description provided for @txSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get txSaved;

  /// No description provided for @txNew.
  ///
  /// In en, this message translates to:
  /// **'New transaction'**
  String get txNew;

  /// No description provided for @txEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get txEdit;

  /// No description provided for @fieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get fieldAmount;

  /// No description provided for @fieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get fieldCategory;

  /// No description provided for @fieldNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get fieldNote;

  /// No description provided for @fieldSavingsFund.
  ///
  /// In en, this message translates to:
  /// **'Savings fund'**
  String get fieldSavingsFund;

  /// No description provided for @fundDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete fund?'**
  String get fundDeleteTitle;

  /// No description provided for @fundDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Transactions linked to \"{name}\" are kept but no longer belong to a fund.'**
  String fundDeleteBody(String name);

  /// No description provided for @fundNew.
  ///
  /// In en, this message translates to:
  /// **'New savings fund'**
  String get fundNew;

  /// No description provided for @fundEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit savings fund'**
  String get fundEdit;

  /// No description provided for @fieldTargetAmount.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get fieldTargetAmount;

  /// No description provided for @financeTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get financeTransactions;

  /// No description provided for @financeSavingsFunds.
  ///
  /// In en, this message translates to:
  /// **'Savings Funds'**
  String get financeSavingsFunds;

  /// No description provided for @fundProgressOf.
  ///
  /// In en, this message translates to:
  /// **'{name} progress'**
  String fundProgressOf(String name);

  /// No description provided for @financeBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get financeBalance;

  /// No description provided for @financeBalanceSemantics.
  ///
  /// In en, this message translates to:
  /// **'Balance {value}'**
  String financeBalanceSemantics(int value);

  /// No description provided for @financeExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get financeExpenses;

  /// No description provided for @financeSpendingByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by category'**
  String get financeSpendingByCategory;

  /// No description provided for @txUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get txUncategorized;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return L10nEn();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
