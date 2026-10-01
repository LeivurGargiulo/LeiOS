// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'LeiOS';

  @override
  String get navToday => 'Today';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navGoals => 'Goals';

  @override
  String get navNotes => 'Notes';

  @override
  String get navLists => 'Lists';

  @override
  String get navFinances => 'Finances';

  @override
  String get navSettings => 'Settings';

  @override
  String get navMore => 'More';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get delete => 'Delete';

  @override
  String get discard => 'Discard';

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String get discardChangesBody => 'Your edits will be lost.';

  @override
  String get undo => 'Undo';

  @override
  String get newItem => 'New';

  @override
  String get moreDetails => 'More details';

  @override
  String entityAdded(String entity) {
    return '$entity added';
  }

  @override
  String entityDeleted(String entity) {
    return '$entity deleted';
  }

  @override
  String get quickAddTask => 'Task';

  @override
  String get quickAddNote => 'Note';

  @override
  String get quickAddTransaction => 'Transaction';

  @override
  String get quickAddTitle => 'Quick add';

  @override
  String get syncSynced => 'Synced';

  @override
  String get syncSyncing => 'Syncing';

  @override
  String get syncOffline => 'Offline';

  @override
  String get syncError => 'Error';

  @override
  String get emptyHabitsTitle => 'No habits yet';

  @override
  String get emptyHabitsMessage => 'Add a habit to start building streaks.';

  @override
  String get emptyHabitsAction => 'Add habit';

  @override
  String get emptyCaughtUpTitle => 'You\'re all caught up';

  @override
  String get emptyCaughtUpMessage => 'Nothing due in the next 7 days.';

  @override
  String get emptyTasksTitle => 'Nothing to do';

  @override
  String get emptyTasksMessage => 'Add a task to get started.';

  @override
  String get emptyTasksAction => 'Add task';

  @override
  String get emptyTasksFilteredTitle => 'No tasks here';

  @override
  String get emptyTasksFilteredMessage => 'Try another view or scope.';

  @override
  String get emptyDayTitle => 'Nothing planned';

  @override
  String get emptyDayMessage => 'Enjoy the free day, or add an event.';

  @override
  String get emptyDayAction => 'Add event';

  @override
  String get emptyGoalsTitle => 'No goals yet';

  @override
  String get emptyGoalsMessage => 'Set a goal and break it into steps.';

  @override
  String get emptyGoalsAction => 'Add goal';

  @override
  String get emptyNotesTitle => 'No notes yet';

  @override
  String get emptyNotesMessage => 'Capture a thought.';

  @override
  String get emptyNotesAction => 'New note';

  @override
  String get emptySearchTitle => 'No matches';

  @override
  String get emptySearchMessage => 'Try a different search or tag.';

  @override
  String get emptyMediaTitle => 'Nothing to watch or read';

  @override
  String get emptyMediaMessage => 'Add movies, series, books or games.';

  @override
  String get emptyWishlistTitle => 'Your wishlist is empty';

  @override
  String get emptyWishlistMessage => 'Add things you want to buy.';

  @override
  String get emptyDreamsTitle => 'No dreams yet';

  @override
  String get emptyDreamsMessage => 'Add something you\'d love to do someday.';

  @override
  String get emptyDreamsAction => 'Add dream';

  @override
  String get emptyLearningTitle => 'Nothing to learn yet';

  @override
  String get emptyLearningMessage => 'Add skills or courses you want to learn.';

  @override
  String get emptyListAction => 'Add item';

  @override
  String get emptyTransactionsTitle => 'No transactions this month';

  @override
  String get emptyTransactionsMessage => 'Add income or an expense.';

  @override
  String get emptyTransactionsAction => 'Add transaction';

  @override
  String get emptyFundsTitle => 'No savings funds';

  @override
  String get emptyFundsMessage => 'Create a fund to track a savings goal.';

  @override
  String get emptyFundsAction => 'Add fund';

  @override
  String get emptyMoodTitle => 'No mood entries yet';

  @override
  String get emptyMoodMessage => 'Pick how you feel today.';

  @override
  String get emptySelectionTitle => 'Select an item';

  @override
  String get emptySelectionMessage =>
      'Pick something from the list to see or edit it.';

  @override
  String get emptySyncTitle => 'All changes synced';

  @override
  String get moreActions => 'More actions';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get previousYear => 'Previous year';

  @override
  String get nextYear => 'Next year';

  @override
  String get none => 'None';

  @override
  String get precisionDay => 'Day';

  @override
  String get precisionMonth => 'Month';

  @override
  String get precisionQuarter => 'Quarter';

  @override
  String get precisionYear => 'Year';

  @override
  String quarterShort(int n) {
    return 'Q$n';
  }

  @override
  String targetPeriod(String period) {
    return 'Target: $period';
  }

  @override
  String fabSemanticLabel(String label) {
    return '$label. Long-press for quick add.';
  }

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authResetPassword => 'Reset password';

  @override
  String get authAccountCreated =>
      'Account created. Check your inbox to confirm your email, then sign in.';

  @override
  String get authResetSent =>
      'If an account exists, a reset link is on its way.';

  @override
  String get authEnterValidEmail => 'Enter a valid email.';

  @override
  String get authPasswordMin => 'Use at least 6 characters.';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authCreateAnAccount => 'Create an account';

  @override
  String get authBackToSignIn => 'Back to sign in';

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsNewPassword => 'New password';

  @override
  String get settingsPasswordUpdated => 'Password updated.';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsSignOutTitle => 'Sign out?';

  @override
  String settingsSignOutPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'changes',
      one: 'change',
    );
    return 'You have $count $_temp0 that haven\'t synced yet. Signing out will discard them and clear local data.';
  }

  @override
  String get settingsSignOutClean =>
      'Local data on this device will be cleared. Everything is safe in the cloud.';

  @override
  String get settingsExportTitle => 'Export data?';

  @override
  String get settingsExportBody =>
      'The JSON file is plain text and NOT encrypted. Keep it somewhere safe.';

  @override
  String get settingsExport => 'Export';

  @override
  String get settingsExportDialogTitle => 'Save LeiOS export';

  @override
  String get settingsExportCancelled => 'Export cancelled.';

  @override
  String get settingsExportSaved => 'Export saved.';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsDisplayName => 'Display name';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsSync => 'Sync';

  @override
  String get settingsConnected => 'Connected';

  @override
  String get settingsNotSyncedYet => 'Not synced yet';

  @override
  String settingsLastSync(String time) {
    return 'Last sync $time';
  }

  @override
  String get settingsPendingChanges => 'Pending changes';

  @override
  String settingsSyncErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'changes',
      one: 'change',
    );
    return '$count $_temp0 could not be synced';
  }

  @override
  String get settingsDismissAll => 'Dismiss all';

  @override
  String get settingsReconnect => 'Reconnect';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsExportData => 'Export data';

  @override
  String get settingsExportHint => 'Plain, unencrypted JSON of all your data';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get edit => 'Edit';

  @override
  String get title => 'Title';

  @override
  String get notes => 'Notes';

  @override
  String get description => 'Description';

  @override
  String get name => 'Name';

  @override
  String get tags => 'Tags';

  @override
  String get commaSeparated => 'Comma separated';

  @override
  String get all => 'All';

  @override
  String get today => 'Today';

  @override
  String get entityEntry => 'Entry';

  @override
  String get entityFund => 'Fund';

  @override
  String get entityGoal => 'Goal';

  @override
  String get entityEvent => 'Event';

  @override
  String get entityItem => 'Item';

  @override
  String get statusTodo => 'To do';

  @override
  String get statusDoing => 'Doing';

  @override
  String get statusDone => 'Done';

  @override
  String sectionCount(String title, int count) {
    return '$title ($count)';
  }

  @override
  String get tabCheckIn => 'Check-in';

  @override
  String get tabReview => 'Review';

  @override
  String get todayDueSoon => 'Due soon';

  @override
  String get overdue => 'Overdue';

  @override
  String get next7Days => 'Next 7 days';

  @override
  String get moodHowAreYou => 'How are you today?';

  @override
  String get moodAddNoteOrTags => 'Add note or tags';

  @override
  String get moodEditNote => 'Edit note';

  @override
  String get moodTitle => 'Mood';

  @override
  String moodRatingOf(int rating) {
    return 'Mood $rating of 5';
  }

  @override
  String moodRatingOfSelected(int rating) {
    return 'Mood $rating of 5, selected';
  }

  @override
  String get habitsManage => 'Manage';

  @override
  String get habitsTitle => 'Habits';

  @override
  String habitTarget(int count) {
    return 'Target $count / week';
  }

  @override
  String habitDeleteTooltip(String name) {
    return 'Delete $name';
  }

  @override
  String get habitDeleteTitle => 'Delete habit?';

  @override
  String habitDeleteBody(String name) {
    return 'This also deletes all completions of \"$name\".';
  }

  @override
  String get habitNew => 'New habit';

  @override
  String get habitEdit => 'Edit habit';

  @override
  String habitTargetPerWeek(int count) {
    return 'Target per week: $count';
  }

  @override
  String habitStreak(int count) {
    return '$count day streak';
  }

  @override
  String habitCompletedToday(String name) {
    return '$name, completed today';
  }

  @override
  String habitNotCompletedToday(String name) {
    return '$name, not completed today';
  }

  @override
  String habitDayCompleted(String day, String name) {
    return '$day, $name, completed';
  }

  @override
  String habitDayNotCompleted(String day, String name) {
    return '$day, $name, not completed';
  }

  @override
  String get weekTitle => 'Week';

  @override
  String get weekPrevious => 'Previous week';

  @override
  String get weekNext => 'Next week';

  @override
  String get weekThis => 'This week';

  @override
  String get weekEmpty => 'Add a habit to see your week.';

  @override
  String get statAverage => 'Average';

  @override
  String get statCurrentStreak => 'Current streak';

  @override
  String get statTotalEntries => 'Total entries';

  @override
  String get statBestWeekday => 'Best weekday';

  @override
  String get statWorstWeekday => 'Worst weekday';

  @override
  String get moodInsights => 'Mood insights';

  @override
  String get topTags => 'Top tags';

  @override
  String get moodTrend => 'Mood trend (30 days)';

  @override
  String get showChart => 'Show chart';

  @override
  String get showTable => 'Show as table';

  @override
  String get moodTrendSemantics =>
      'Mood over the last 30 days. Use \"Show as table\" for the data.';

  @override
  String get moodHistory => 'Mood history';

  @override
  String get pending => 'Pending';

  @override
  String get active => 'Active';

  @override
  String get completed => 'Completed';

  @override
  String get listTabMedia => 'Media';

  @override
  String get listTabWishlist => 'Wishlist';

  @override
  String get listTabDreams => 'Dreams';

  @override
  String get listTabLearning => 'Learning';

  @override
  String get listDonePurchased => 'Purchased';

  @override
  String get listDoneLearned => 'Learned';

  @override
  String get listCategoryKind => 'Kind';

  @override
  String get listCategoryCategory => 'Category';

  @override
  String get listCategoryArea => 'Area';

  @override
  String get listReorder => 'Reorder';

  @override
  String get listDoneReordering => 'Done reordering';

  @override
  String listAddItemTooltip(String kind) {
    return 'Add $kind item';
  }

  @override
  String listNewItem(String kind) {
    return 'New $kind item';
  }

  @override
  String get listEditItem => 'Edit item';

  @override
  String get fieldUrl => 'URL';

  @override
  String get fieldPrice => 'Price';

  @override
  String listFilterBy(String category) {
    return 'Filter by $category';
  }

  @override
  String get listPendingTotal => 'Pending total';

  @override
  String get listMarkPending => 'Mark pending';

  @override
  String listMarkDone(String status) {
    return 'Mark $status';
  }

  @override
  String listStatusYes(String status) {
    return '$status: yes';
  }

  @override
  String listStatusNo(String status) {
    return '$status: no';
  }

  @override
  String get listOpenLink => 'Open link';

  @override
  String get longTerm => 'Long-term';

  @override
  String get urgent => 'Urgent';

  @override
  String get important => 'Important';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get noDate => 'No date';

  @override
  String get later => 'Later';

  @override
  String get viewByStatus => 'By status';

  @override
  String get viewByDate => 'By date';

  @override
  String get viewMatrix => 'Matrix';

  @override
  String get scopeRegular => 'Regular';

  @override
  String get tasksChangeView => 'Change view';

  @override
  String get tasksCollapseDone => 'Collapse done tasks';

  @override
  String get tasksExpandDone => 'Expand done tasks';

  @override
  String get matrixUrgentImportant => 'Urgent & important';

  @override
  String get matrixImportantNotUrgent => 'Important, not urgent';

  @override
  String get matrixUrgentNotImportant => 'Urgent, not important';

  @override
  String get matrixNeither => 'Neither';

  @override
  String get taskNew => 'New task';

  @override
  String get taskEdit => 'Edit task';

  @override
  String get taskPickDate => 'Pick date';

  @override
  String taskTapToAdvance(String status) {
    return '$status. Tap to advance.';
  }

  @override
  String get taskMarkTodo => 'Mark to do';

  @override
  String get taskAdvance => 'Advance status';

  @override
  String get calendarMonth => 'Month';

  @override
  String get calendarAgenda => 'Agenda';

  @override
  String get eventNew => 'New event';

  @override
  String get eventEdit => 'Edit event';

  @override
  String get calendarTasksDue => 'Tasks due';

  @override
  String get calendarTasksDueShort => 'tasks due';

  @override
  String calendarEventsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'events',
      one: 'event',
    );
    return '$count $_temp0';
  }

  @override
  String get allDay => 'All day';

  @override
  String get eventRepeatsWeekly => 'Repeats weekly';

  @override
  String calendarTodayHeader(String label) {
    return 'Today · $label';
  }

  @override
  String get eventDeleteTitle => 'Delete event?';

  @override
  String get eventDeleteSeries =>
      'This deletes the whole repeating series, not just one occurrence.';

  @override
  String get eventDeleteSingle => 'This event will be deleted.';

  @override
  String get eventWhen => 'When';

  @override
  String get eventStartTime => 'Start time';

  @override
  String get eventEndTime => 'End time';

  @override
  String get eventClearEnd => 'Clear end';

  @override
  String get eventRepeat => 'Repeat';

  @override
  String get eventRepeatWeekly => 'Repeat weekly';

  @override
  String get eventUntilOptional => 'Until (optional)';

  @override
  String eventUntil(String date) {
    return 'Until $date';
  }

  @override
  String get clear => 'Clear';

  @override
  String get eventEndDateMultiDay => 'End date (multi-day)';

  @override
  String eventEnds(String date) {
    return 'Ends $date';
  }

  @override
  String get eventDetails => 'Details';

  @override
  String get goalDeleteTitle => 'Delete goal?';

  @override
  String get goalDeleteBody => 'This also deletes the goal\'s checklist steps.';

  @override
  String get goalNew => 'New goal';

  @override
  String get goalEdit => 'Edit goal';

  @override
  String get goalTarget => 'Target';

  @override
  String get goalStatus => 'Status';

  @override
  String get goalProgress => 'Progress';

  @override
  String get goalSteps => 'Steps';

  @override
  String get goalProgressSemantics => 'Goal progress';

  @override
  String goalProgressOf(String title) {
    return '$title progress';
  }

  @override
  String get goalRemoveStep => 'Remove step';

  @override
  String get goalAddStepLabel => 'Add a step';

  @override
  String get goalAddStepTooltip => 'Add step';

  @override
  String goalCreated(String date) {
    return 'Created $date';
  }

  @override
  String get goalViewList => 'List';

  @override
  String get goalViewByPeriod => 'By period';

  @override
  String goalYearSummary(int year, int completed, int total, int percent) {
    return 'Year $year — completed $completed/$total ($percent%)';
  }

  @override
  String get goalWholeYear => 'Whole year';

  @override
  String get goalNoTargetDate => 'No target date';

  @override
  String get noteNew => 'New note';

  @override
  String get noteEdit => 'Edit note';

  @override
  String get noteSearch => 'Search notes';

  @override
  String get noteContent => 'Content';

  @override
  String get notePreview => 'Preview';

  @override
  String get noteNothingToPreview => '*Nothing to preview*';

  @override
  String get noteMarkdown => 'Markdown';

  @override
  String get txIncome => 'Income';

  @override
  String get txExpense => 'Expense';

  @override
  String get txSaved => 'Saved';

  @override
  String get txNew => 'New transaction';

  @override
  String get txEdit => 'Edit transaction';

  @override
  String get fieldAmount => 'Amount';

  @override
  String get fieldCategory => 'Category';

  @override
  String get fieldNote => 'Note';

  @override
  String get fieldSavingsFund => 'Savings fund';

  @override
  String get fundDeleteTitle => 'Delete fund?';

  @override
  String fundDeleteBody(String name) {
    return 'Transactions linked to \"$name\" are kept but no longer belong to a fund.';
  }

  @override
  String get fundNew => 'New savings fund';

  @override
  String get fundEdit => 'Edit savings fund';

  @override
  String get fieldTargetAmount => 'Target amount';

  @override
  String get financeTransactions => 'Transactions';

  @override
  String get financeSavingsFunds => 'Savings Funds';

  @override
  String fundProgressOf(String name) {
    return '$name progress';
  }

  @override
  String get financeBalance => 'Balance';

  @override
  String financeBalanceSemantics(int value) {
    return 'Balance $value';
  }

  @override
  String get financeExpenses => 'Expenses';

  @override
  String get financeSpendingByCategory => 'Spending by category';

  @override
  String get txUncategorized => 'Uncategorized';
}
