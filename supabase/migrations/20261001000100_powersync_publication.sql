-- Logical replication publication consumed by PowerSync Cloud.
-- The dedicated replication role/password is created from the Supabase SQL editor
-- (it carries a secret, so it is intentionally NOT kept in the repo). See docs/SETUP.md.
create publication powersync for table
  tasks, habits, habit_completions, feelings, goals, goal_steps,
  events, notes, list_items, savings_funds, transactions, settings;
