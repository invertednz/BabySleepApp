begin;

create table if not exists public.baby_vocabulary (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  baby_id uuid not null references public.babies(id) on delete cascade,
  word text not null,
  recorded_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists idx_baby_vocabulary_user_baby on public.baby_vocabulary(user_id, baby_id, recorded_at desc);

alter table public.baby_vocabulary enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'baby_vocabulary'
      and policyname = 'Allow users to manage their own baby vocabulary'
  ) then
    create policy "Allow users to manage their own baby vocabulary"
      on public.baby_vocabulary for all
      using (auth.uid() = user_id);
  end if;
end $$;

commit;
