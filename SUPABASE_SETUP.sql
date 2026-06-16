-- ============================================================================
--  汉字学习 — Supabase setup
-- ============================================================================
--  Run this once in your Supabase project:
--    Supabase Dashboard → SQL Editor → New query → paste → Run
--
--  It creates the `progress` table that stores each user's learning state and
--  locks it down with Row-Level Security so users can only read/write their own
--  row. This is what makes it safe to ship the public anon key in the browser.
-- ============================================================================

-- 1. Table: one row of progress per user, linked to the auth user.
create table if not exists public.progress (
  user_id    uuid        primary key references auth.users (id) on delete cascade,
  data       jsonb       not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- 2. Keep updated_at fresh on every write.
create or replace function public.touch_progress()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists progress_touch on public.progress;
create trigger progress_touch
  before update on public.progress
  for each row execute function public.touch_progress();

-- 3. Row-Level Security: each user sees and edits ONLY their own row.
alter table public.progress enable row level security;

drop policy if exists "own progress: select" on public.progress;
create policy "own progress: select"
  on public.progress for select
  using (auth.uid() = user_id);

drop policy if exists "own progress: insert" on public.progress;
create policy "own progress: insert"
  on public.progress for insert
  with check (auth.uid() = user_id);

drop policy if exists "own progress: update" on public.progress;
create policy "own progress: update"
  on public.progress for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ============================================================================
--  Done. Then in index.html set:
--    const SUPABASE_URL      = 'https://YOUR-PROJECT.supabase.co';
--    const SUPABASE_ANON_KEY = 'YOUR-PUBLIC-ANON-KEY';
--  (Dashboard → Project Settings → API)
-- ============================================================================
