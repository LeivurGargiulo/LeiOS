-- RLS isolation test. Run against a DEV project (it creates then rolls back two users):
--   psql "$DEV_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/rls_isolation.sql
-- Everything runs in one transaction that is rolled back at the end.
begin;

insert into auth.users (id, instance_id, aud, role, email)
values
  ('00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'a@test.local'),
  ('00000000-0000-0000-0000-0000000000b2', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'b@test.local');

-- user A inserts a task
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}', true);
insert into tasks (id, title, created_at, updated_at)
values ('11111111-1111-1111-1111-111111111111', 'A secret', now(), now());

-- user B cannot see it
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000b2","role":"authenticated"}', true);
do $$
declare n int;
begin
  select count(*) into n from tasks;
  if n <> 0 then raise exception 'RLS FAIL: user B can read % task(s) of user A', n; end if;

  update tasks set title = 'hacked' where id = '11111111-1111-1111-1111-111111111111';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'RLS FAIL: user B updated user A row'; end if;

  delete from tasks where id = '11111111-1111-1111-1111-111111111111';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'RLS FAIL: user B deleted user A row'; end if;

  begin
    insert into tasks (id, user_id, title, created_at, updated_at)
    values ('22222222-2222-2222-2222-222222222222', '00000000-0000-0000-0000-0000000000a1', 'spoof', now(), now());
    raise exception 'RLS FAIL: user B inserted a row owned by user A';
  exception when insufficient_privilege then
    null; -- expected: 42501 from the WITH CHECK policy
  end;
end
$$;

-- user A still sees exactly their row
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}', true);
do $$
declare n int;
begin
  select count(*) into n from tasks;
  if n <> 1 then raise exception 'RLS FAIL: user A should see 1 task, saw %', n; end if;
end
$$;

rollback;
\echo 'RLS isolation test passed'
