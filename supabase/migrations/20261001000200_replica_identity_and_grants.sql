-- PowerSync needs full old rows on DELETE; new Supabase projects (May 2026+) no longer auto-grant
-- the Data API roles, and uploadData writes through PostgREST as `authenticated`. Idempotent.
do $$
declare
  t text;
begin
  foreach t in array array[
    'tasks', 'habits', 'habit_completions', 'feelings', 'goals', 'goal_steps',
    'events', 'notes', 'list_items', 'savings_funds', 'transactions', 'settings'
  ]
  loop
    execute format('alter table %I replica identity full', t);
    execute format('grant select, insert, update, delete on %I to authenticated', t);
  end loop;
end
$$;
