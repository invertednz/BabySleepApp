-- Ensure baby_activities upserts are idempotent by adding a unique constraint
ALTER TABLE public.baby_activities
  ADD CONSTRAINT baby_activities_user_baby_key UNIQUE (user_id, baby_id);

-- Backfill updated_at to now() for any rows missing it
UPDATE public.baby_activities SET updated_at = now() WHERE updated_at IS NULL;
