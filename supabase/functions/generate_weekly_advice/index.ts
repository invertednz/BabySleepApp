// deno-lint-ignore-file no-explicit-any
// Supabase Edge Function: generate_weekly_advice
// - Gathers baby context (likes/hates last 60d, short-term focus, age-based missing milestones)
// - Calls Gemini 2.5 Pro securely using env secret
// - Upserts a single weekly plan per baby into public.baby_weekly_advice (one row per baby)
// - Returns the plan JSON

import { createClient } from 'npm:@supabase/supabase-js@2';
import { GoogleGenerativeAI } from 'npm:google-generative-ai@0.18.0';

interface RequestBody {
  baby_id: string;
  force_refresh?: boolean;
}

function jsonResponse(status: number, body: any) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

function daysFromNow(n: number) {
  const d = new Date();
  d.setDate(d.getDate() + n);
  return d;
}

function isoDate(d: Date) {
  return d.toISOString().split('T')[0];
}

function withinLastDays(ts: string | null | undefined, days: number) {
  if (!ts) return false;
  const t = new Date(ts);
  if (isNaN(t.getTime())) return false;
  const cutoff = daysFromNow(-days);
  return t >= cutoff;
}

async function logAudit(supabase: any, log: {
  baby_id: string;
  user_id: string;
  trigger_source: string;
  status: string;
  model_version?: string;
  error_message?: string;
  execution_time_ms?: number;
  metadata?: any;
}) {
  try {
    await supabase.from('advice_generation_audit').insert(log);
  } catch (e) {
    console.error('Failed to log audit entry', e);
  }
}

Deno.serve(async (req) => {
  const startTime = Date.now();
  let babyId = '';
  let userId = '';
  
  try {
    if (req.method !== 'POST') {
      return jsonResponse(405, { error: 'Method not allowed' });
    }

    const body = (await req.json()) as RequestBody;
    babyId = body.baby_id?.trim();
    const forceRefresh = !!body.force_refresh;
    if (!babyId) {
      return jsonResponse(400, { error: 'baby_id is required' });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');
    if (!supabaseUrl || !supabaseAnonKey) {
      return jsonResponse(500, { error: 'Supabase env not configured' });
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
    });

    // Validate auth
    const { data: userData, error: userErr } = await supabase.auth.getUser();
    if (userErr || !userData?.user) {
      return jsonResponse(401, { error: 'Unauthorized' });
    }
    userId = userData.user.id;

    // If an advice exists and still valid for this week, return unless force_refresh
    const today = isoDate(new Date());
    const { data: existing, error: existingErr } = await supabase
      .from('baby_weekly_advice')
      .select('plan, valid_from, valid_to, model_version, generated_at')
      .eq('baby_id', babyId)
      .maybeSingle();

    if (existingErr) {
      // do not fail yet; proceed to regenerate
      console.warn('Read existing weekly advice error', existingErr);
    }

    if (!forceRefresh && existing && existing.valid_to && existing.valid_to >= today) {
      await logAudit(supabase, {
        baby_id: babyId,
        user_id: userId,
        trigger_source: 'api',
        status: 'skipped',
        model_version: existing.model_version,
        execution_time_ms: Date.now() - startTime,
        metadata: { reason: 'cached_plan_still_valid', valid_to: existing.valid_to },
      });
      return jsonResponse(200, { source: 'cache', ...existing });
    }

    // Fetch context
    // 1) Baby profile
    const { data: baby, error: babyErr } = await supabase
      .from('babies')
      .select('id, user_id, name, birthdate, gender')
      .eq('id', babyId)
      .maybeSingle();
    if (babyErr || !baby) {
      return jsonResponse(404, { error: 'Baby not found' });
    }

    // 2) Short-term focus
    const { data: focusRow } = await supabase
      .from('baby_short_term_focus')
      .select('focus, timeframe_start, timeframe_end, updated_at')
      .eq('baby_id', babyId)
      .eq('user_id', userId)
      .maybeSingle();
    const focus: string[] = Array.isArray(focusRow?.focus) ? focusRow!.focus : [];

    // 3) Activity preferences (loves/hates) last 60 days
    const { data: actRow } = await supabase
      .from('baby_activities')
      .select('loves, hates, neutral, skipped, updated_at')
      .eq('baby_id', babyId)
      .eq('user_id', userId)
      .maybeSingle();

    function filterMap(m: Record<string, string> | null | undefined, days = 60) {
      const out: string[] = [];
      if (m && typeof m === 'object') {
        for (const [k, v] of Object.entries(m)) {
          if (withinLastDays(v as string, days)) out.push(k);
        }
      }
      return out;
    }
    const loves = filterMap(actRow?.loves as any, 60);
    const hates = filterMap(actRow?.hates as any, 60);

    // 4) Missing/age-relevant milestones from assessment view
    const { data: ms } = await supabase
      .from('v_baby_milestone_assessment')
      .select('milestone_id, category, title, status, window_start_weeks, window_end_weeks')
      .eq('baby_id', babyId);
    const relevantStatuses = new Set(['upcoming', 'in_window', 'overdue']);
    const missing = (ms ?? []).filter((r: any) => relevantStatuses.has((r.status || '').toLowerCase()));

    // Age in months (approx)
    const birth = new Date(baby.birthdate);
    const ageMonths = Math.max(0, Math.floor((Date.now() - birth.getTime()) / (1000 * 60 * 60 * 24 * 30.437)));

    // Nurture priorities (optional)
    const { data: np } = await supabase
      .from('baby_nurture_priorities')
      .select('priorities')
      .eq('baby_id', babyId)
      .eq('user_id', userId)
      .maybeSingle();
    const priorities: string[] = Array.isArray(np?.priorities) ? np!.priorities : [];

    // Build prompt
    const prompt = `You are a pediatric developmental assistant helping a parent plan one week of activities for their baby. 
Strictly tailor suggestions to the baby's likes/dislikes and the parent's focus areas. Support upcoming or overdue milestones for the baby's current age. Be realistic, safe, and evidence-informed. 

CONTEXT JSON:
```
{
  "baby": {
    "name": ${JSON.stringify(baby.name)},
    "gender": ${JSON.stringify(baby.gender)},
    "birthdate": ${JSON.stringify(baby.birthdate)},
    "age_months": ${JSON.stringify(ageMonths)}
  },
  "short_term_focus": ${JSON.stringify(focus)},
  "nurture_priorities": ${JSON.stringify(priorities)},
  "likes_last_60d": ${JSON.stringify(loves)},
  "dislikes_last_60d": ${JSON.stringify(hates)},
  "missing_milestones": ${JSON.stringify(missing)}
}
```

INSTRUCTIONS:
- Produce a single JSON object only. No prose outside JSON.
- Personalize activities to leverage likes and avoid dislikes. If a disliked item is important, provide a gentle, alternative approach.
- Align weekly plan to short_term_focus and support relevant missing milestones (upcoming, in_window, overdue).
- Keep each activity practical (5–20 min), with simple materials and indoor/outdoor variants if helpful.
- Provide brief rationale per activity referencing likes/focus/milestones.
- Include safety considerations when relevant.
- Provide a short recommendations section for parent interaction, what is coming up, and potential issues to watch in the near term.

OUTPUT JSON SCHEMA:
{
  "week_start": "YYYY-MM-DD",
  "week_end": "YYYY-MM-DD",
  "activities": [
    {
      "date": "YYYY-MM-DD",
      "items": [
        {
          "title": "string",
          "description": "1–2 sentences",
          "category": "e.g., Motor | Sensory | Social | Cognitive | Communication",
          "duration_minutes": 5,
          "materials": ["string"],
          "indoor_outdoor": "indoor|outdoor|either",
          "personalization_reason": "why this fits likes/focus/milestones",
          "milestone_support": [{ "milestone_id": "uuid?", "title": "string", "category": "string" }],
          "fallback_if_disliked": "gentle alternative if baby resists"
        }
      ]
    }
  ],
  "recommendations": {
    "interaction_tips": [{ "title": "string", "tip": "string", "why": "string" }],
    "upcoming": [{ "title": "string", "what_to_expect": "string", "when": "string" }],
    "potential_issues": [{ "title": "string", "what_to_watch": "string", "what_to_do": "string" }]
  }
}
`;

    // Model call
    const modelId = Deno.env.get('GEMINI_MODEL_ID') || 'gemini-2.5-pro';
    const geminiKey = Deno.env.get('GEMINI_API_KEY');
    if (!geminiKey) {
      return jsonResponse(500, { error: 'GEMINI_API_KEY not configured' });
    }

    const genAI = new GoogleGenerativeAI(geminiKey);
    const model = genAI.getGenerativeModel({ model: modelId });

    const weekStart = isoDate(new Date());
    const weekEnd = isoDate(daysFromNow(6));

    const generationConfig: any = { temperature: 0.8, maxOutputTokens: 4096, responseMimeType: 'application/json' };
    const fullPrompt = `${prompt}\n\nConstraints: Plan for ${weekStart} to ${weekEnd}.`;

    let jsonText = '';
    try {
      const result = await model.generateContent({ contents: [{ role: 'user', parts: [{ text: fullPrompt }] }], generationConfig });
      jsonText = result.response.text();
    } catch (err: any) {
      console.error('Gemini call failed', err);
      const executionTime = Date.now() - startTime;
      await logAudit(supabase, {
        baby_id: babyId,
        user_id: userId,
        trigger_source: 'api',
        status: 'error',
        error_message: `Gemini API error: ${err.message || String(err)}`,
        execution_time_ms: executionTime,
      });
      return jsonResponse(502, { error: 'Gemini call failed' });
    }

    let plan: any;
    try {
      plan = JSON.parse(jsonText);
    } catch (_) {
      // Try to extract JSON block if model wrapped it in prose
      const match = jsonText.match(/\{[\s\S]*\}$/);
      if (match) {
        plan = JSON.parse(match[0]);
      } else {
        const executionTime = Date.now() - startTime;
        await logAudit(supabase, {
          baby_id: babyId,
          user_id: userId,
          trigger_source: 'api',
          status: 'error',
          error_message: 'Gemini did not return valid JSON',
          execution_time_ms: executionTime,
          metadata: { response_preview: jsonText.substring(0, 500) },
        });
        return jsonResponse(502, { error: 'Gemini did not return valid JSON' });
      }
    }

    // Upsert weekly advice
    const upsert = {
      baby_id: babyId,
      user_id: userId,
      plan,
      model_version: modelId,
      generated_at: new Date().toISOString(),
      valid_from: weekStart,
      valid_to: weekEnd,
      prompt,
      response_raw: plan,
    };

    const { error: upsertErr } = await supabase
      .from('baby_weekly_advice')
      .upsert(upsert, { onConflict: 'baby_id' });
    if (upsertErr) {
      console.error('Upsert advice error', upsertErr);
      const executionTime = Date.now() - startTime;
      await logAudit(supabase, {
        baby_id: babyId,
        user_id: userId,
        trigger_source: 'api',
        status: 'error',
        error_message: `Database upsert error: ${upsertErr.message}`,
        execution_time_ms: executionTime,
      });
      return jsonResponse(500, { error: 'Failed to save weekly advice' });
    }

    const executionTime = Date.now() - startTime;
    await logAudit(supabase, {
      baby_id: babyId,
      user_id: userId,
      trigger_source: 'api',
      status: 'success',
      model_version: modelId,
      execution_time_ms: executionTime,
    });

    return jsonResponse(200, { source: 'generated', plan, valid_from: weekStart, valid_to: weekEnd, model_version: modelId });
  } catch (e) {
    console.error('Unhandled error', e);
    return jsonResponse(500, { error: 'Unhandled error' });
  }
});
