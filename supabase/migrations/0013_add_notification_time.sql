-- Add notification_time column to user_preferences table
ALTER TABLE public.user_preferences 
ADD COLUMN IF NOT EXISTS notification_time text;

-- Add comment for documentation
COMMENT ON COLUMN public.user_preferences.notification_time IS 'Preferred time for daily notifications: morning, midday, or evening';
