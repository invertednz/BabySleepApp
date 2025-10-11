# Weekly Advice Generation - Deployment & Scheduling Guide

## Overview
This system generates personalized weekly activity plans and recommendations for babies using Gemini 2.5 Pro AI, with automatic generation for paid users and comprehensive telemetry logging.

## Architecture

### Components
1. **Database Tables**
   - `baby_weekly_advice` - Stores one weekly plan per baby (overwrites on update)
   - `advice_generation_audit` - Telemetry and error logging for all generation attempts

2. **Edge Functions**
   - `generate_weekly_advice` - Single baby generation (user-triggered or batch-called)
   - `generate_weekly_advice_batch` - Service-role batch processor for all paid babies

3. **Database Triggers**
   - `on_user_upgrade_generate_advice` - Auto-queues generation when user upgrades to paid

## Deployment Steps

### 1. Apply Database Migrations
```bash
# Navigate to your Supabase project
cd "c:\Trae Apps\BabySleepApp"

# Apply migrations in order
supabase db push

# Or apply individually:
# Migration 0015: baby_weekly_advice table
# Migration 0016: advice_generation_audit table
# Migration 0017: triggers for auto-generation on upgrade
```

### 2. Set Environment Secrets
```bash
# Set Gemini API key (required)
supabase secrets set GEMINI_API_KEY=your_gemini_api_key_here

# Set model ID (optional, defaults to gemini-2.5-pro)
supabase secrets set GEMINI_MODEL_ID=gemini-2.5-pro

# Verify secrets
supabase secrets list
```

### 3. Deploy Edge Functions
```bash
# Deploy single-baby generation function
supabase functions deploy generate_weekly_advice

# Deploy batch generation function (for scheduled runs)
supabase functions deploy generate_weekly_advice_batch

# Verify deployment
supabase functions list
```

### 4. Test Functions
```bash
# Test single baby generation (replace with real baby_id and auth token)
curl -X POST https://your-project.supabase.co/functions/v1/generate_weekly_advice \
  -H "Authorization: Bearer YOUR_USER_JWT" \
  -H "Content-Type: application/json" \
  -d '{"baby_id": "uuid-here", "force_refresh": false}'

# Test batch generation (requires service role key)
curl -X POST https://your-project.supabase.co/functions/v1/generate_weekly_advice_batch \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"trigger_source": "manual"}'
```

## Scheduling Weekly Generation

### Option 1: Supabase Scheduled Functions (Recommended)
Supabase supports cron-based scheduling via the dashboard:

1. Go to **Database > Functions** in Supabase Dashboard
2. Create a new scheduled function:
   - **Name**: `weekly_advice_generation`
   - **Schedule**: `0 2 * * 1` (Every Monday at 2 AM UTC)
   - **Function**: Call `generate_weekly_advice_batch`

### Option 2: pg_cron Extension
```sql
-- Enable pg_cron extension
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule weekly batch generation (Mondays at 2 AM UTC)
SELECT cron.schedule(
  'weekly-advice-generation',
  '0 2 * * 1',
  $$
  SELECT net.http_post(
    url := 'https://your-project.supabase.co/functions/v1/generate_weekly_advice_batch',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.service_role_key')
    ),
    body := jsonb_build_object('trigger_source', 'scheduled')
  );
  $$
);

-- View scheduled jobs
SELECT * FROM cron.job;

-- Remove job if needed
SELECT cron.unschedule('weekly-advice-generation');
```

### Option 3: External Scheduler (GitHub Actions, etc.)
Create a GitHub Action workflow:

```yaml
# .github/workflows/weekly-advice.yml
name: Weekly Advice Generation
on:
  schedule:
    - cron: '0 2 * * 1'  # Every Monday at 2 AM UTC
  workflow_dispatch:  # Allow manual trigger

jobs:
  generate:
    runs-on: ubuntu-latest
    steps:
      - name: Call Batch Function
        run: |
          curl -X POST ${{ secrets.SUPABASE_FUNCTION_URL }}/generate_weekly_advice_batch \
            -H "Authorization: Bearer ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}" \
            -H "Content-Type: application/json" \
            -d '{"trigger_source": "scheduled"}'
```

## Auto-Generation on User Upgrade

### How It Works
1. User upgrades to paid plan (via `user_preferences` table update)
2. Database trigger `on_user_upgrade_generate_advice` fires
3. Trigger inserts audit log entries for each baby owned by the user
4. Batch function picks up pending generations on next scheduled run

### Immediate Generation (Optional)
To generate advice immediately on upgrade instead of waiting for scheduled run:

```sql
-- Add pg_net extension for HTTP calls from triggers
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Update trigger function to call Edge Function directly
CREATE OR REPLACE FUNCTION public.trigger_advice_generation_on_upgrade()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  baby_record RECORD;
  response_id bigint;
BEGIN
  IF (NEW.plan_tier IN ('paid', 'premium') AND NEW.is_on_trial = FALSE) AND
     (OLD.plan_tier IS DISTINCT FROM NEW.plan_tier OR OLD.is_on_trial IS DISTINCT FROM NEW.is_on_trial) THEN
    
    FOR baby_record IN 
      SELECT id, user_id FROM public.babies WHERE user_id = NEW.user_id
    LOOP
      -- Call Edge Function via pg_net
      SELECT net.http_post(
        url := 'https://your-project.supabase.co/functions/v1/generate_weekly_advice',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || current_setting('app.service_role_key')
        ),
        body := jsonb_build_object(
          'baby_id', baby_record.id,
          'force_refresh', true
        )
      ) INTO response_id;
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$;
```

## Monitoring & Telemetry

### View Audit Logs
```sql
-- Recent generation attempts
SELECT 
  baby_id,
  user_id,
  trigger_source,
  status,
  model_version,
  execution_time_ms,
  error_message,
  generated_at
FROM advice_generation_audit
ORDER BY generated_at DESC
LIMIT 50;

-- Success rate by trigger source
SELECT 
  trigger_source,
  status,
  COUNT(*) as count,
  AVG(execution_time_ms) as avg_execution_ms
FROM advice_generation_audit
WHERE generated_at > NOW() - INTERVAL '7 days'
GROUP BY trigger_source, status
ORDER BY trigger_source, status;

-- Error summary
SELECT 
  error_message,
  COUNT(*) as occurrences,
  MAX(generated_at) as last_occurrence
FROM advice_generation_audit
WHERE status = 'error'
  AND generated_at > NOW() - INTERVAL '30 days'
GROUP BY error_message
ORDER BY occurrences DESC;

-- Pending generations from upgrades
SELECT * FROM v_pending_advice_generation;
```

### App-Level Monitoring
Add Flutter service method to fetch audit logs:

```dart
// In supabase_service.dart
Future<List<Map<String, dynamic>>> getAdviceAuditLogs({int limit = 50}) async {
  final userId = _client.auth.currentUser?.id;
  if (userId == null) throw Exception('User not authenticated');
  
  final resp = await _client
      .from('advice_generation_audit')
      .select()
      .eq('user_id', userId)
      .order('generated_at', ascending: false)
      .limit(limit);
  
  return (resp as List).map((e) => Map<String, dynamic>.from(e)).toList();
}
```

## Paid User Filtering

The batch function automatically filters for paid users:
```sql
-- Query used in batch function
SELECT b.id, b.user_id, b.name, b.birthdate
FROM babies b
INNER JOIN user_preferences up ON up.user_id = b.user_id
WHERE up.plan_tier IN ('paid', 'premium')
  AND up.is_on_trial = FALSE;
```

## Cost Optimization

### Gemini API Usage
- **Model**: gemini-2.5-pro
- **Avg tokens per request**: ~2000 input + ~1500 output
- **Weekly cost per baby**: ~$0.01-0.02 (check current Gemini pricing)
- **Caching**: Plans valid for 7 days, reduces redundant calls

### Recommendations
1. Monitor `execution_time_ms` in audit logs
2. Set up alerts for high error rates
3. Consider rate limiting if user base grows significantly
4. Use `force_refresh: false` to leverage weekly caching

## Troubleshooting

### Common Issues

**1. "GEMINI_API_KEY not configured"**
- Run: `supabase secrets set GEMINI_API_KEY=your_key`
- Redeploy function after setting secrets

**2. "Unauthorized" errors**
- Verify JWT is being passed correctly
- Check RLS policies on `baby_weekly_advice` table
- Ensure user owns the baby_id being queried

**3. "Gemini did not return valid JSON"**
- Check audit logs for `response_preview` in metadata
- May need to adjust prompt or increase `maxOutputTokens`
- Verify Gemini model version is correct

**4. Batch function not finding paid users**
- Verify `user_preferences.plan_tier` values
- Check that `is_on_trial` is set correctly
- Run test query to confirm paid user count

**5. Trigger not firing on upgrade**
- Check trigger exists: `SELECT * FROM pg_trigger WHERE tgname = 'on_user_upgrade_generate_advice';`
- Verify `user_preferences` table has correct columns
- Check audit logs for 'upgrade' trigger_source entries

## Security Checklist

- ✅ Gemini API key stored as Supabase secret (never in client)
- ✅ RLS enabled on all tables
- ✅ Service role key only used server-side
- ✅ User JWT validated before generation
- ✅ Audit logs track all access attempts

## Support

For issues or questions:
1. Check audit logs for error details
2. Review Supabase function logs in dashboard
3. Verify environment secrets are set
4. Test with manual API calls before debugging scheduled runs
