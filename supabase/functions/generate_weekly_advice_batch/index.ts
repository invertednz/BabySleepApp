// deno-lint-ignore-file no-explicit-any
// Supabase Edge Function: generate_weekly_advice_batch
// - Service-role function to iterate all babies with paid plans
// - Generates weekly advice for each eligible baby
// - Logs outcomes to advice_generation_audit table
// - Intended for scheduled weekly runs via pg_cron or Supabase Scheduled Triggers

import { createClient } from 'npm:@supabase/supabase-js@2';

interface AuditLog {
  baby_id: string;
  user_id: string;
  trigger_source: 'scheduled' | 'manual' | 'upgrade' | 'api';
  status: 'success' | 'error' | 'skipped';
  model_version?: string;
  error_message?: string;
  execution_time_ms?: number;
  metadata?: any;
}

function jsonResponse(status: number, body: any) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

async function logAudit(supabase: any, log: AuditLog) {
  try {
    await supabase.from('advice_generation_audit').insert({
      baby_id: log.baby_id,
      user_id: log.user_id,
      trigger_source: log.trigger_source,
      status: log.status,
      model_version: log.model_version,
      error_message: log.error_message,
      execution_time_ms: log.execution_time_ms,
      metadata: log.metadata,
    });
  } catch (e) {
    console.error('Failed to log audit entry', e);
  }
}

Deno.serve(async (req) => {
  try {
    if (req.method !== 'POST') {
      return jsonResponse(405, { error: 'Method not allowed' });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    if (!supabaseUrl || !supabaseServiceKey) {
      return jsonResponse(500, { error: 'Supabase env not configured' });
    }

    // Use service role to bypass RLS
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Optional: verify this is an authorized call (e.g., from pg_cron or admin)
    const authHeader = req.headers.get('Authorization');
    const body = await req.json().catch(() => ({}));
    const triggerSource = (body.trigger_source || 'scheduled') as 'scheduled' | 'manual' | 'upgrade' | 'api';

    // Fetch all babies with paid users
    // Join babies with user_preferences where plan_tier in ('paid', 'premium') and is_on_trial = false
    const { data: paidBabies, error: fetchErr } = await supabase
      .from('babies')
      .select(`
        id,
        user_id,
        name,
        birthdate,
        user_preferences!inner(plan_tier, is_on_trial)
      `)
      .in('user_preferences.plan_tier', ['paid', 'premium'])
      .eq('user_preferences.is_on_trial', false);

    if (fetchErr) {
      console.error('Failed to fetch paid babies', fetchErr);
      return jsonResponse(500, { error: 'Failed to fetch paid babies', details: fetchErr });
    }

    const results: any[] = [];
    let successCount = 0;
    let errorCount = 0;
    let skippedCount = 0;

    for (const baby of paidBabies || []) {
      const startTime = Date.now();
      try {
        // Call the generate_weekly_advice function for this baby
        const { data, error } = await supabase.functions.invoke('generate_weekly_advice', {
          body: { baby_id: baby.id, force_refresh: false },
        });

        const executionTime = Date.now() - startTime;

        if (error) {
          errorCount++;
          await logAudit(supabase, {
            baby_id: baby.id,
            user_id: baby.user_id,
            trigger_source: triggerSource,
            status: 'error',
            error_message: error.message || JSON.stringify(error),
            execution_time_ms: executionTime,
          });
          results.push({ baby_id: baby.id, status: 'error', error: error.message });
        } else {
          const source = data?.source || 'unknown';
          if (source === 'cache') {
            skippedCount++;
            await logAudit(supabase, {
              baby_id: baby.id,
              user_id: baby.user_id,
              trigger_source: triggerSource,
              status: 'skipped',
              model_version: data?.model_version,
              execution_time_ms: executionTime,
              metadata: { reason: 'cached_plan_still_valid' },
            });
            results.push({ baby_id: baby.id, status: 'skipped', reason: 'cached' });
          } else {
            successCount++;
            await logAudit(supabase, {
              baby_id: baby.id,
              user_id: baby.user_id,
              trigger_source: triggerSource,
              status: 'success',
              model_version: data?.model_version || 'gemini-2.5-pro',
              execution_time_ms: executionTime,
            });
            results.push({ baby_id: baby.id, status: 'success' });
          }
        }
      } catch (e: any) {
        errorCount++;
        const executionTime = Date.now() - startTime;
        await logAudit(supabase, {
          baby_id: baby.id,
          user_id: baby.user_id,
          trigger_source: triggerSource,
          status: 'error',
          error_message: e.message || String(e),
          execution_time_ms: executionTime,
        });
        results.push({ baby_id: baby.id, status: 'error', error: e.message });
      }
    }

    return jsonResponse(200, {
      total: paidBabies?.length || 0,
      success: successCount,
      error: errorCount,
      skipped: skippedCount,
      results,
    });
  } catch (e: any) {
    console.error('Unhandled error in batch generation', e);
    return jsonResponse(500, { error: 'Unhandled error', details: e.message });
  }
});
