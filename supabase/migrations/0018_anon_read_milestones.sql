do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'milestones'
      and policyname = 'Allow all users read milestones'
  ) then
    create policy "Allow all users read milestones"
    on public.milestones
    as permissive
    for select
    to anon, authenticated
    using (true);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'milestone_activities'
      and policyname = 'Allow all users read milestone_activities'
  ) then
    create policy "Allow all users read milestone_activities"
    on public.milestone_activities
    as permissive
    for select
    to anon, authenticated
    using (true);
  end if;
end
$$;
