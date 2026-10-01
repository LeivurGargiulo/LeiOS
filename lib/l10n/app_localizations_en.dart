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
}
