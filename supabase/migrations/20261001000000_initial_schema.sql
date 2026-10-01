-- LeiOS initial schema: 12 tables, all owned by a single user (user_id) and protected by RLS.

create table tasks (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null,
  notes text not null default '',
  urgent boolean not null default false,
  important boolean not null default false,
  status text not null default 'todo' check (status in ('todo', 'doing', 'done')),
  due_date date,
  long_term boolean not null default false,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  completed_at timestamptz
);

create table habits (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  target_frequency int not null default 7 check (target_frequency between 1 and 7),
  created_at timestamptz not null
);

create table habit_completions (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  habit_id uuid not null references habits(id) on delete cascade,
  date date not null,
  unique (habit_id, date)
);

create table feelings (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  date date not null,
  rating int not null check (rating between 1 and 5),
  notes text not null default '',
  tags text not null default '',
  unique (user_id, date)
);

create table goals (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null,
  description text not null default '',
  target_date date,
  target_precision text check (target_precision in ('day', 'month', 'quarter', 'year')),
  status text not null default 'pending' check (status in ('pending', 'active', 'completed')),
  created_at timestamptz not null,
  check ((target_date is null) = (target_precision is null))
);

create table goal_steps (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  goal_id uuid not null references goals(id) on delete cascade,
  title text not null,
  done boolean not null default false,
  sort_order int not null,
  created_at timestamptz not null
);

-- Events use floating local wall-clock time (no timezone).
create table events (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null,
  description text not null default '',
  date date not null,
  end_date date,
  start_minutes int check (start_minutes between 0 and 1439),
  end_minutes int check (end_minutes between 0 and 1439),
  weekdays int check (weekdays between 1 and 127),
  until date,
  created_at timestamptz not null,
  check (end_minutes is null or start_minutes is not null),
  check (end_date is null or end_date >= date),
  check (weekdays is null or end_date is null),
  check (until is null or (weekdays is not null and until >= date))
);

create table notes (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null,
  content text not null default '',
  tags text not null default '',
  created_at timestamptz not null,
  updated_at timestamptz not null
);

create table list_items (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  list text not null check (list in ('dream', 'media', 'wishlist', 'learning')),
  title text not null,
  category text not null default '',
  notes text not null default '',
  url text not null default '',
  price int check (price is null or price >= 0),
  done boolean not null default false,
  sort_order int not null,
  created_at timestamptz not null
);

create table savings_funds (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  target_amount int not null check (target_amount >= 1),
  created_at timestamptz not null
);

create table transactions (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  amount int not null check (amount >= 1),
  type text not null check (type in ('income', 'expense', 'savings_contribution')),
  category text not null default '',
  note text not null default '',
  date date not null,
  savings_fund_id uuid references savings_funds(id) on delete set null,
  created_at timestamptz not null,
  check (savings_fund_id is null or type = 'savings_contribution')
);

create table settings (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  date_format text not null default 'yyyy-MM-dd',
  display_name text not null default ''
);

-- Indexes
create index tasks_user_idx on tasks (user_id);
create index tasks_user_status_idx on tasks (user_id, status);
create index tasks_user_due_idx on tasks (user_id, due_date);
create index habits_user_idx on habits (user_id);
create index habit_completions_user_idx on habit_completions (user_id);
create index habit_completions_habit_date_idx on habit_completions (habit_id, date);
create index feelings_user_idx on feelings (user_id);
create index goals_user_idx on goals (user_id);
create index goal_steps_user_idx on goal_steps (user_id);
create index goal_steps_goal_idx on goal_steps (goal_id);
create index events_user_idx on events (user_id);
create index events_user_date_idx on events (user_id, date);
create index notes_user_idx on notes (user_id);
create index list_items_user_idx on list_items (user_id);
create index list_items_user_list_order_idx on list_items (user_id, list, sort_order);
create index savings_funds_user_idx on savings_funds (user_id);
create index transactions_user_idx on transactions (user_id);
create index transactions_user_date_idx on transactions (user_id, date);
create index transactions_fund_idx on transactions (savings_fund_id);
create index settings_user_idx on settings (user_id);

-- Row level security on every table.
do $$
declare
  t text;
begin
  foreach t in array array[
    'tasks', 'habits', 'habit_completions', 'feelings', 'goals', 'goal_steps',
    'events', 'notes', 'list_items', 'savings_funds', 'transactions', 'settings'
  ]
  loop
    execute format('alter table %I enable row level security', t);
    execute format(
      'create policy "own rows" on %I for all to authenticated
         using (user_id = (select auth.uid()))
         with check (user_id = (select auth.uid()))', t);
  end loop;
end
$$;
