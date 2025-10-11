-- Audit table for weekly advice generation telemetry
create table if not exists public.advice_generation_audit (
  id uuid primary key default gen_random_uuid(),
  baby_id uuid not null references public.babies(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  trigger_source text not null check (trigger_source in ('scheduled', 'manual', 'upgrade', 'api')),
  status text not null check (status in ('success', 'error', 'skipped')),
  model_version text,
  error_message text,
  execution_time_ms integer,
  generated_at timestamptz not null default now(),
  metadata jsonb
);

-- Indexes for querying audit logs
create index if not exists idx_advice_audit_baby on public.advice_generation_audit(baby_id, generated_at desc);
create index if not exists idx_advice_audit_user on public.advice_generation_audit(user_id, generated_at desc);
create index if not exists idx_advice_audit_status on public.advice_generation_audit(status, generated_at desc);
create index if not exists idx_advice_audit_trigger on public.advice_generation_audit(trigger_source, generated_at desc);

-- RLS
alter table public.advice_generation_audit enable row level security;

-- Policies
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'advice_generation_audit'
      AND policyname = 'Allow users to view their own audit logs'
  ) THEN
    CREATE POLICY "Allow users to view their own audit logs"
      ON public.advice_generation_audit FOR SELECT USING (auth.uid() = user_id);
  END IF;
END $$;

-- Service role can insert audit logs (for scheduled jobs)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'advice_generation_audit'
      AND policyname = 'Service role can insert audit logs'
  ) THEN
    CREATE POLICY "Service role can insert audit logs"
      ON public.advice_generation_audit FOR INSERT
      WITH CHECK (true);
  END IF;
END $$;

COMMENT ON TABLE public.advice_generation_audit IS 'Audit log for weekly advice generation attempts, outcomes, and errors';
