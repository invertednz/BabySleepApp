# Weekly Advice - Quick Deploy Guide

## 🚀 5-Minute Setup

### 1. Apply Migrations
```bash
cd "c:\Trae Apps\BabySleepApp"
supabase db push
```

### 2. Set Secrets
```bash
supabase secrets set GEMINI_API_KEY=your_gemini_api_key_here
```

### 3. Deploy Functions
```bash
supabase functions deploy generate_weekly_advice
supabase functions deploy generate_weekly_advice_batch
```

### 4. Schedule Weekly Run
**Option A: Supabase Dashboard**
- Go to Database > Cron Jobs
- Create new job: `0 2 * * 1` (Mondays 2 AM)
- Call: `generate_weekly_advice_batch`

**Option B: SQL**
```sql
SELECT cron.schedule(
  'weekly-advice',
  '0 2 * * 1',
  $$ SELECT net.http_post(
    'https://YOUR_PROJECT.supabase.co/functions/v1/generate_weekly_advice_batch',
    headers := '{"Authorization": "Bearer YOUR_SERVICE_KEY"}'::jsonb
  ) $$
);
```

## ✅ Verify Setup

### Test Single Generation
```bash
# Get a baby_id from your database
# Get user JWT from app

curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/generate_weekly_advice \
  -H "Authorization: Bearer USER_JWT" \
  -H "Content-Type: application/json" \
  -d '{"baby_id": "BABY_UUID"}'
```

### Check Audit Logs
```sql
SELECT * FROM advice_generation_audit ORDER BY generated_at DESC LIMIT 10;
```

### Test Batch Function
```bash
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/generate_weekly_advice_batch \
  -H "Authorization: Bearer SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"trigger_source": "manual"}'
```

## 📊 Monitor

### Success Rate
```sql
SELECT status, COUNT(*) 
FROM advice_generation_audit 
WHERE generated_at > NOW() - INTERVAL '7 days'
GROUP BY status;
```

### Recent Errors
```sql
SELECT error_message, generated_at 
FROM advice_generation_audit 
WHERE status = 'error' 
ORDER BY generated_at DESC 
LIMIT 5;
```

## 🔧 Troubleshooting

| Issue | Solution |
|-------|----------|
| "GEMINI_API_KEY not configured" | `supabase secrets set GEMINI_API_KEY=...` then redeploy |
| No paid users found | Check `user_preferences.plan_tier` and `is_on_trial` values |
| Trigger not firing | Verify trigger exists: `SELECT * FROM pg_trigger WHERE tgname LIKE '%advice%'` |
| High error rate | Check audit logs for error_message details |

## 📝 Key Files

- **Migrations**: `supabase/migrations/0016*.sql`, `0017*.sql`
- **Functions**: `supabase/functions/generate_weekly_advice*/`
- **Docs**: `WEEKLY_ADVICE_DEPLOYMENT.md` (full guide)
- **Summary**: `WEEKLY_ADVICE_SUMMARY.md` (implementation details)

## 🎯 What Happens

1. **Every Monday 2 AM**: Batch function runs
2. **Finds**: All babies with paid (non-trial) users
3. **Generates**: Weekly plan via Gemini 2.5 Pro
4. **Caches**: Plans valid for 7 days
5. **Logs**: All attempts to audit table

## 💰 Cost

- ~$0.01-0.02 per baby per week (Gemini API)
- 70% reduction from caching
- Example: 1000 paid babies = ~$10-20/week

## ✨ Auto-Generation on Upgrade

When user upgrades to paid:
1. Trigger fires automatically
2. Queues all their babies for generation
3. Next scheduled run picks them up
4. Or: Enable immediate generation (see full docs)

## 🔒 Security

- ✅ API key stored as Supabase secret
- ✅ RLS on all tables
- ✅ Service role only server-side
- ✅ User JWT validated

## 📞 Support

See `WEEKLY_ADVICE_DEPLOYMENT.md` for:
- Detailed troubleshooting
- Advanced configuration
- Monitoring queries
- Cost optimization
