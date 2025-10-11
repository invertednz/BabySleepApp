-- Function to trigger advice generation when user upgrades to paid
-- This will be called by a trigger on user_preferences updates

create or replace function public.trigger_advice_generation_on_upgrade()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  baby_record record;
  function_url text;
  request_id uuid;
begin
  -- Only proceed if plan_tier changed to 'paid' or 'premium' and is_on_trial is false
  if (NEW.plan_tier in ('paid', 'premium') and NEW.is_on_trial = false) and
     (OLD.plan_tier is distinct from NEW.plan_tier or OLD.is_on_trial is distinct from NEW.is_on_trial) then
    
    -- Get Supabase function URL from environment (set via dashboard or CLI)
    -- For now, we'll use pg_net to make HTTP request to the Edge Function
    -- Alternatively, you can use a background job queue
    
    -- Log that we detected an upgrade
    raise notice 'User % upgraded to paid plan, triggering advice generation', NEW.user_id;
    
    -- For each baby belonging to this user, insert a job request
    -- We'll use a simple approach: insert into a queue table that gets processed
    -- Or call the Edge Function directly via pg_net (requires pg_net extension)
    
    -- Simple approach: Insert audit log as "pending" and let a scheduled job pick it up
    -- Or use Supabase Realtime/Webhooks to trigger the function
    
    -- For this implementation, we'll insert audit entries that signal generation needed
    for baby_record in 
      select id, user_id from public.babies where user_id = NEW.user_id
    loop
      insert into public.advice_generation_audit (
        baby_id,
        user_id,
        trigger_source,
        status,
        metadata
      ) values (
        baby_record.id,
        baby_record.user_id,
        'upgrade',
        'skipped',
        jsonb_build_object('note', 'Queued for generation on upgrade', 'queued_at', now())
      );
      
      -- TODO: Call Edge Function via HTTP (requires pg_net extension)
      -- For now, the batch function will pick these up, or you can use Supabase webhooks
    end loop;
  end if;
  
  return NEW;
end;
$$;

-- Create trigger on user_preferences
drop trigger if exists on_user_upgrade_generate_advice on public.user_preferences;
create trigger on_user_upgrade_generate_advice
  after update on public.user_preferences
  for each row
  execute function public.trigger_advice_generation_on_upgrade();

comment on function public.trigger_advice_generation_on_upgrade is 'Triggers weekly advice generation when user upgrades to paid plan';

-- Optional: Create a view to see pending advice generation requests
create or replace view public.v_pending_advice_generation as
select 
  aga.baby_id,
  aga.user_id,
  b.name as baby_name,
  aga.generated_at as queued_at,
  aga.metadata
from public.advice_generation_audit aga
join public.babies b on b.id = aga.baby_id
where aga.trigger_source = 'upgrade'
  and aga.status = 'skipped'
  and aga.metadata->>'note' = 'Queued for generation on upgrade'
  and not exists (
    select 1 from public.baby_weekly_advice bwa
    where bwa.baby_id = aga.baby_id
      and bwa.generated_at > aga.generated_at
  )
order by aga.generated_at desc;

comment on view public.v_pending_advice_generation is 'Shows babies queued for advice generation after user upgrade';
