import 'package:powersync/powersync.dart';

/// Mirrors supabase/migrations (spec §5.1). `id` is implicit.
/// uuid/date/timestamptz/text → text · int/boolean → integer.
const schema = Schema([
  Table('tasks', [
    Column.text('user_id'),
    Column.text('title'),
    Column.text('notes'),
    Column.integer('urgent'),
    Column.integer('important'),
    Column.text('status'),
    Column.text('due_date'),
    Column.integer('long_term'),
    Column.text('created_at'),
    Column.text('updated_at'),
    Column.text('completed_at'),
  ], indexes: [
    Index('by_status', [IndexedColumn('status')]),
    Index('by_due', [IndexedColumn('due_date')]),
  ]),
  Table('habits', [
    Column.text('user_id'),
    Column.text('name'),
    Column.integer('target_frequency'),
    Column.text('created_at'),
  ]),
  Table('habit_completions', [
    Column.text('user_id'),
    Column.text('habit_id'),
    Column.text('date'),
  ], indexes: [
    Index('by_habit_date', [IndexedColumn('habit_id'), IndexedColumn('date')]),
  ]),
  Table('feelings', [
    Column.text('user_id'),
    Column.text('date'),
    Column.integer('rating'),
    Column.text('notes'),
    Column.text('tags'),
  ], indexes: [
    Index('by_date', [IndexedColumn('date')]),
  ]),
  Table('goals', [
    Column.text('user_id'),
    Column.text('title'),
    Column.text('description'),
    Column.text('target_date'),
    Column.text('target_precision'),
    Column.text('status'),
    Column.text('created_at'),
  ]),
  Table('goal_steps', [
    Column.text('user_id'),
    Column.text('goal_id'),
    Column.text('title'),
    Column.integer('done'),
    Column.integer('sort_order'),
    Column.text('created_at'),
  ], indexes: [
    Index('by_goal', [IndexedColumn('goal_id')]),
  ]),
  Table('events', [
    Column.text('user_id'),
    Column.text('title'),
    Column.text('description'),
    Column.text('date'),
    Column.text('end_date'),
    Column.integer('start_minutes'),
    Column.integer('end_minutes'),
    Column.integer('weekdays'),
    Column.text('until'),
    Column.text('created_at'),
  ], indexes: [
    Index('by_date', [IndexedColumn('date')]),
  ]),
  Table('notes', [
    Column.text('user_id'),
    Column.text('title'),
    Column.text('content'),
    Column.text('tags'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),
  Table('list_items', [
    Column.text('user_id'),
    Column.text('list'),
    Column.text('title'),
    Column.text('category'),
    Column.text('notes'),
    Column.text('url'),
    Column.integer('price'),
    Column.integer('done'),
    Column.integer('sort_order'),
    Column.text('created_at'),
  ], indexes: [
    Index('by_list', [IndexedColumn('list'), IndexedColumn('sort_order')]),
  ]),
  Table('savings_funds', [
    Column.text('user_id'),
    Column.text('name'),
    Column.integer('target_amount'),
    Column.text('created_at'),
  ]),
  Table('transactions', [
    Column.text('user_id'),
    Column.integer('amount'),
    Column.text('type'),
    Column.text('category'),
    Column.text('note'),
    Column.text('date'),
    Column.text('savings_fund_id'),
    Column.text('created_at'),
  ], indexes: [
    Index('by_date', [IndexedColumn('date')]),
  ]),
  Table('settings', [
    Column.text('user_id'),
    Column.text('date_format'),
    Column.text('display_name'),
  ]),
  // Local-only record of uploads the server rejected (spec §4.2).
  Table.localOnly('sync_errors', [
    Column.text('table_name'),
    Column.text('row_id'),
    Column.text('op'),
    Column.text('message'),
    Column.text('at'),
  ]),
]);

/// Tables whose rows are synced (everything except local-only tables).
const syncedTables = [
  'tasks', 'habits', 'habit_completions', 'feelings', 'goals', 'goal_steps',
  'events', 'notes', 'list_items', 'savings_funds', 'transactions', 'settings',
];

/// Columns that Postgres stores as `boolean` (PowerSync stores 0/1).
const booleanColumns = {
  'tasks': {'urgent', 'important', 'long_term'},
  'goal_steps': {'done'},
  'list_items': {'done'},
};
