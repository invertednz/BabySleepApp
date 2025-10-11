# Weekly Advice Generation - Required Deployment Steps

## ⚠️ Prerequisites
- Supabase CLI installed and configured
- Gemini API key from Google AI Studio
- Access to your Supabase project

---

## 📋 Step-by-Step Deployment

### Step 1: Apply Database Migrations
```bash
cd "c:\Trae Apps\BabySleepApp"

# Apply all pending migrations
supabase db push
```

**What this does:**
- Creates `baby_weekly_advice` table (stores 1 plan per baby)
- Creates `advice_generation_audit` table (telemetry logging)
- Creates trigger `on_user_upgrade_generate_advice` (auto-generation on paid upgrade)
- Creates view `v_pending_advice_generation` (shows queued generations)

**Verify:**
```sql
-- Check tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('baby_weekly_advice', 'advice_generation_audit');

-- Check trigger exists
SELECT tgname FROM pg_trigger WHERE tgname = 'on_user_upgrade_generate_advice';
```

---

### Step 2: Set Environment Secrets
```bash
# Set your Gemini API key (REQUIRED)
supabase secrets set GEMINI_API_KEY=your_gemini_api_key_here

# Optional: Set custom model (defaults to gemini-2.5-pro)
supabase secrets set GEMINI_MODEL_ID=gemini-2.5-pro

# Verify secrets are set
supabase secrets list
```

**Get Gemini API Key:**
1. Go to https://aistudio.google.com/app/apikey
2. Create new API key
3. Copy and use in command above

---

### Step 3: Deploy Edge Functions
```bash
# Deploy the main generation function
supabase functions deploy generate_weekly_advice

# Deploy the batch processing function
supabase functions deploy generate_weekly_advice_batch

# Verify deployment
supabase functions list
```

**Expected output:**
```
generate_weekly_advice (deployed)
generate_weekly_advice_batch (deployed)
```

---

### Step 4: Test Single Baby Generation
```bash
# Get a test baby_id from your database
# Get user JWT token from your app (or use Supabase dashboard)

curl -X POST https://YOUR_PROJECT_REF.supabase.co/functions/v1/generate_weekly_advice \
  -H "Authorization: Bearer YOUR_USER_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"baby_id": "YOUR_BABY_UUID", "force_refresh": false}'
```

**Expected response:**
```json
{
  "source": "generated",
  "plan": { ... },
  "valid_from": "2025-10-11",
  "valid_to": "2025-10-17",
  "model_version": "gemini-2.5-pro"
}
```

**Check audit log:**
```sql
SELECT * FROM advice_generation_audit 
ORDER BY generated_at DESC 
LIMIT 5;
```

---

### Step 5: Test Batch Function (Service Role)
```bash
# Get your service role key from Supabase dashboard
# Settings > API > service_role key (secret)

curl -X POST https://YOUR_PROJECT_REF.supabase.co/functions/v1/generate_weekly_advice_batch \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"trigger_source": "manual"}'
```

**Expected response:**
```json
{
  "total": 5,
  "success": 3,
  "error": 0,
  "skipped": 2,
  "results": [...]
}
```

---

### Step 6: Schedule Weekly Batch Run

#### Option A: Supabase Dashboard (Recommended)
1. Go to Supabase Dashboard
2. Navigate to **Database** > **Cron Jobs** (or **Extensions** > **pg_cron**)
3. Click **Create a new cron job**
4. Configure:
   - **Name**: `weekly_advice_generation`
   - **Schedule**: `0 2 * * 1` (Every Monday at 2 AM UTC)
   - **Command**: 
     ```sql
     SELECT net.http_post(
       url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/generate_weekly_advice_batch',
       headers := jsonb_build_object(
         'Content-Type', 'application/json',
         'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY'
       ),
       body := jsonb_build_object('trigger_source', 'scheduled')
     );
     ```

#### Option B: SQL Command
```sql
-- Enable pg_cron extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule the job
SELECT cron.schedule(
  'weekly-advice-generation',
  '0 2 * * 1',  -- Every Monday at 2 AM UTC
  $$
  SELECT net.http_post(
    url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/generate_weekly_advice_batch',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY'
    ),
    body := jsonb_build_object('trigger_source', 'scheduled')
  );
  $$
);

-- Verify the job is scheduled
SELECT * FROM cron.job WHERE jobname = 'weekly-advice-generation';
```

**⚠️ Important:** Replace `YOUR_PROJECT_REF` and `YOUR_SERVICE_ROLE_KEY` with actual values

---

### Step 7: Test Auto-Generation on Upgrade

```sql
-- Simulate a user upgrading to paid
UPDATE user_preferences 
SET 
  plan_tier = 'paid',
  is_on_trial = false,
  updated_at = NOW()
WHERE user_id = 'YOUR_TEST_USER_ID';

-- Check that audit logs were created
SELECT * FROM advice_generation_audit
WHERE trigger_source = 'upgrade'
ORDER BY generated_at DESC;

-- Check pending generations view
SELECT * FROM v_pending_advice_generation;
```

---

## ✅ Verification Checklist

After deployment, verify:

- [ ] Migrations applied successfully
- [ ] `baby_weekly_advice` table exists
- [ ] `advice_generation_audit` table exists
- [ ] Trigger `on_user_upgrade_generate_advice` exists
- [ ] Gemini API key secret is set
- [ ] Both Edge Functions deployed
- [ ] Single generation test works
- [ ] Batch generation test works
- [ ] Audit logs are being created
- [ ] Weekly cron job is scheduled
- [ ] Upgrade trigger creates audit logs

---

## 📊 Monitoring After Deployment

### Check Recent Activity
```sql
SELECT 
  baby_id,
  trigger_source,
  status,
  execution_time_ms,
  generated_at
FROM advice_generation_audit
ORDER BY generated_at DESC
LIMIT 20;
```

### Check Success Rate
```sql
SELECT 
  trigger_source,
  status,
  COUNT(*) as count,
  ROUND(AVG(execution_time_ms)) as avg_ms
FROM advice_generation_audit
WHERE generated_at > NOW() - INTERVAL '7 days'
GROUP BY trigger_source, status
ORDER BY trigger_source, status;
```

### Check for Errors
```sql
SELECT 
  error_message,
  COUNT(*) as occurrences,
  MAX(generated_at) as last_occurrence
FROM advice_generation_audit
WHERE status = 'error'
  AND generated_at > NOW() - INTERVAL '7 days'
GROUP BY error_message
ORDER BY occurrences DESC;
```

### Check Paid Users Count
```sql
SELECT COUNT(DISTINCT b.id) as paid_babies_count
FROM babies b
INNER JOIN user_preferences up ON up.user_id = b.user_id
WHERE up.plan_tier IN ('paid', 'premium')
  AND up.is_on_trial = false;
```

---

## 🔧 Troubleshooting

### Issue: "GEMINI_API_KEY not configured"
**Solution:**
```bash
supabase secrets set GEMINI_API_KEY=your_key
supabase functions deploy generate_weekly_advice
supabase functions deploy generate_weekly_advice_batch
```

### Issue: No paid users found in batch
**Solution:**
```sql
-- Check user_preferences values
SELECT user_id, plan_tier, is_on_trial 
FROM user_preferences 
LIMIT 10;

-- Ensure paid users exist
UPDATE user_preferences 
SET plan_tier = 'paid', is_on_trial = false 
WHERE user_id = 'test_user_id';
```

### Issue: Trigger not firing
**Solution:**
```sql
-- Check trigger exists
SELECT * FROM pg_trigger WHERE tgname = 'on_user_upgrade_generate_advice';

-- Manually fire trigger by updating a user
UPDATE user_preferences 
SET plan_tier = 'paid', is_on_trial = false 
WHERE user_id = 'test_user_id';

-- Check audit logs
SELECT * FROM advice_generation_audit 
WHERE trigger_source = 'upgrade';
```

### Issue: Cron job not running
**Solution:**
```sql
-- Check job is scheduled
SELECT * FROM cron.job;

-- Check job run history
SELECT * FROM cron.job_run_details 
ORDER BY start_time DESC 
LIMIT 10;

-- Manually trigger the job
SELECT cron.schedule('test-run', '* * * * *', 'SELECT 1');
SELECT cron.unschedule('test-run');
```

---

## 🎯 Next Steps After Deployment

1. **Monitor first scheduled run** (next Monday 2 AM UTC)
2. **Check audit logs** for any errors
3. **Verify costs** in Gemini API dashboard
4. **Test user upgrade flow** in production
5. **Set up alerts** for high error rates (optional)

---

## 📞 Support Resources

- **Full Documentation**: `WEEKLY_ADVICE_DEPLOYMENT.md`
- **Implementation Details**: `WEEKLY_ADVICE_SUMMARY.md`
- **Quick Reference**: `QUICK_DEPLOY.md`

---

## 🔒 Security Reminders

- ✅ Never commit service role key to git
- ✅ Gemini API key stored as Supabase secret only
- ✅ RLS enabled on all tables
- ✅ User JWT validated for all API calls
- ✅ Batch function requires service role authorization

---

**Last Updated**: 2025-10-11
**Status**: Ready for deployment
