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
