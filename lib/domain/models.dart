import 'dates.dart';

enum TaskStatus { todo, doing, done }

enum GoalStatus { pending, active, completed }

enum GoalPrecision { day, month, quarter, year }

enum ListKind { dream, media, wishlist, learning }

enum TxType { income, expense, savingsContribution }

String txTypeToDb(TxType t) => switch (t) {
      TxType.income => 'income',
      TxType.expense => 'expense',
      TxType.savingsContribution => 'savings_contribution',
    };

TxType txTypeFromDb(String s) => switch (s) {
      'income' => TxType.income,
      'savings_contribution' => TxType.savingsContribution,
      _ => TxType.expense,
    };

TaskStatus taskStatusFromDb(Object? s) =>
    TaskStatus.values.firstWhere((e) => e.name == s, orElse: () => TaskStatus.todo);

GoalStatus goalStatusFromDb(Object? s) =>
    GoalStatus.values.firstWhere((e) => e.name == s, orElse: () => GoalStatus.pending);

GoalPrecision? goalPrecisionFromDb(Object? s) {
  for (final p in GoalPrecision.values) {
    if (p.name == s) return p;
  }
  return null;
}

ListKind listKindFromDb(Object? s) =>
    ListKind.values.firstWhere((e) => e.name == s, orElse: () => ListKind.media);

bool _b(Object? v) => v == 1 || v == true;
String _s(Object? v) => (v as String?) ?? '';

class Task {
  const Task({
    required this.id,
    required this.title,
    this.notes = '',
    this.urgent = false,
    this.important = false,
    this.status = TaskStatus.todo,
    this.dueDate,
    this.longTerm = false,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  final String id;
  final String title;
  final String notes;
  final bool urgent;
  final bool important;
  final TaskStatus status;
  final DateTime? dueDate;
  final bool longTerm;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  factory Task.fromRow(Map<String, Object?> r) => Task(
        id: r['id']! as String,
        title: _s(r['title']),
        notes: _s(r['notes']),
        urgent: _b(r['urgent']),
        important: _b(r['important']),
        status: taskStatusFromDb(r['status']),
        dueDate: tryParseIsoDate(r['due_date']),
        longTerm: _b(r['long_term']),
        createdAt: parseInstant(r['created_at']! as String),
        updatedAt: parseInstant(r['updated_at']! as String),
        completedAt: r['completed_at'] == null ? null : parseInstant(r['completed_at']! as String),
      );
}

class Habit {
  const Habit({required this.id, required this.name, this.targetFrequency = 7});
  final String id;
  final String name;
  final int targetFrequency;

  factory Habit.fromRow(Map<String, Object?> r) => Habit(
        id: r['id']! as String,
        name: _s(r['name']),
        targetFrequency: (r['target_frequency'] as int?) ?? 7,
      );
}

class HabitCompletion {
  const HabitCompletion({required this.habitId, required this.date});
  final String habitId;
  final DateTime date;

  factory HabitCompletion.fromRow(Map<String, Object?> r) =>
      HabitCompletion(habitId: r['habit_id']! as String, date: parseIsoDate(r['date']! as String));
}

class Feeling {
  const Feeling({
    required this.id,
    required this.date,
    required this.rating,
    this.notes = '',
    this.tags = '',
  });
  final String id;
  final DateTime date;
  final int rating;
  final String notes;
  final String tags;

  factory Feeling.fromRow(Map<String, Object?> r) => Feeling(
        id: r['id']! as String,
        date: parseIsoDate(r['date']! as String),
        rating: r['rating']! as int,
        notes: _s(r['notes']),
        tags: _s(r['tags']),
      );
}

class Goal {
  const Goal({
    required this.id,
    required this.title,
    this.description = '',
    this.targetDate,
    this.precision,
    this.status = GoalStatus.pending,
    required this.createdAt,
  });
  final String id;
  final String title;
  final String description;
  final DateTime? targetDate;
  final GoalPrecision? precision;
  final GoalStatus status;
  final DateTime createdAt;

  factory Goal.fromRow(Map<String, Object?> r) => Goal(
        id: r['id']! as String,
        title: _s(r['title']),
        description: _s(r['description']),
        targetDate: tryParseIsoDate(r['target_date']),
        precision: goalPrecisionFromDb(r['target_precision']),
        status: goalStatusFromDb(r['status']),
        createdAt: parseInstant(r['created_at']! as String),
      );
}

class GoalStep {
  const GoalStep({
    required this.id,
    required this.goalId,
    required this.title,
    this.done = false,
    required this.sortOrder,
  });
  final String id;
  final String goalId;
  final String title;
  final bool done;
  final int sortOrder;

  factory GoalStep.fromRow(Map<String, Object?> r) => GoalStep(
        id: r['id']! as String,
        goalId: r['goal_id']! as String,
        title: _s(r['title']),
        done: _b(r['done']),
        sortOrder: (r['sort_order'] as int?) ?? 0,
      );
}

class Event {
  const Event({
    required this.id,
    required this.title,
    this.description = '',
    required this.date,
    this.endDate,
    this.startMinutes,
    this.endMinutes,
    this.weekdays,
    this.until,
  });
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final DateTime? endDate;
  final int? startMinutes;
  final int? endMinutes;
  final int? weekdays;
  final DateTime? until;

  bool get allDay => startMinutes == null;
  bool get recurring => weekdays != null;

  factory Event.fromRow(Map<String, Object?> r) => Event(
        id: r['id']! as String,
        title: _s(r['title']),
        description: _s(r['description']),
        date: parseIsoDate(r['date']! as String),
        endDate: tryParseIsoDate(r['end_date']),
        startMinutes: r['start_minutes'] as int?,
        endMinutes: r['end_minutes'] as int?,
        weekdays: r['weekdays'] as int?,
        until: tryParseIsoDate(r['until']),
      );
}

class Note {
  const Note({
    required this.id,
    required this.title,
    this.content = '',
    this.tags = '',
    required this.createdAt,
    required this.updatedAt,
  });
  final String id;
  final String title;
  final String content;
  final String tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Note.fromRow(Map<String, Object?> r) => Note(
        id: r['id']! as String,
        title: _s(r['title']),
        content: _s(r['content']),
        tags: _s(r['tags']),
        createdAt: parseInstant(r['created_at']! as String),
        updatedAt: parseInstant(r['updated_at']! as String),
      );
}

class ListItem {
  const ListItem({
    required this.id,
    required this.list,
    required this.title,
    this.category = '',
    this.notes = '',
    this.url = '',
    this.price,
    this.done = false,
    required this.sortOrder,
  });
  final String id;
  final ListKind list;
  final String title;
  final String category;
  final String notes;
  final String url;
  final int? price;
  final bool done;
  final int sortOrder;

  factory ListItem.fromRow(Map<String, Object?> r) => ListItem(
        id: r['id']! as String,
        list: listKindFromDb(r['list']),
        title: _s(r['title']),
        category: _s(r['category']),
        notes: _s(r['notes']),
        url: _s(r['url']),
        price: r['price'] as int?,
        done: _b(r['done']),
        sortOrder: (r['sort_order'] as int?) ?? 0,
      );
}

class SavingsFund {
  const SavingsFund({required this.id, required this.name, required this.targetAmount});
  final String id;
  final String name;
  final int targetAmount;

  factory SavingsFund.fromRow(Map<String, Object?> r) => SavingsFund(
        id: r['id']! as String,
        name: _s(r['name']),
        targetAmount: r['target_amount']! as int,
      );
}

class Tx {
  const Tx({
    required this.id,
    required this.amount,
    required this.type,
    this.category = '',
    this.note = '',
    required this.date,
    this.savingsFundId,
  });
  final String id;
  final int amount;
  final TxType type;
  final String category;
  final String note;
  final DateTime date;
  final String? savingsFundId;

  factory Tx.fromRow(Map<String, Object?> r) => Tx(
        id: r['id']! as String,
        amount: r['amount']! as int,
        type: txTypeFromDb(_s(r['type'])),
        category: _s(r['category']),
        note: _s(r['note']),
        date: parseIsoDate(r['date']! as String),
        savingsFundId: r['savings_fund_id'] as String?,
      );
}

class AppSettings {
  const AppSettings({this.dateFormat = 'yyyy-MM-dd', this.displayName = ''});
  final String dateFormat;
  final String displayName;

  factory AppSettings.fromRow(Map<String, Object?> r) =>
      AppSettings(dateFormat: _s(r['date_format']), displayName: _s(r['display_name']));
}
