// deno-lint-ignore-file no-explicit-any
// Supabase Edge Function: generate_weekly_advice
// Weekly activity plan generator using focused, recent data
// Uses Gemini 3 Flash with structured output

import { createClient } from "npm:@supabase/supabase-js@2";
import {
  GoogleGenerativeAI,
  SchemaType,
} from "npm:@google/generative-ai@0.21.0";

interface RequestBody {
  baby_id: string;
  force_refresh?: boolean;
}

function jsonResponse(status: number, body: any) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function daysFromNow(n: number) {
  const d = new Date();
  d.setDate(d.getDate() + n);
  return d;
}

function isoDate(d: Date) {
  return d.toISOString().split("T")[0];
}

function daysAgo(n: number): Date {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d;
}

// Get recent items from a JSONB map (activity -> timestamp)
function getRecentFromMap(obj: any, daysLimit: number): string[] {
  if (!obj || typeof obj !== "object") return [];
  const cutoff = daysAgo(daysLimit);
  return Object.entries(obj)
    .filter(([_, ts]) => ts && new Date(ts as string) >= cutoff)
    .map(([key, _]) => key);
}

async function logAudit(
  supabase: any,
  log: {
    baby_id: string;
    user_id: string;
    trigger_source: string;
    status: string;
    model_version?: string;
    error_message?: string;
    execution_time_ms?: number;
    metadata?: any;
  },
) {
  try {
    await supabase.from("advice_generation_audit").insert(log);
  } catch (e) {
    console.error("Failed to log audit entry", e);
  }
}

// JSON Schema for structured output
const weeklyPlanSchema = {
  type: SchemaType.OBJECT,
  description: "A personalized weekly activity plan",
  properties: {
    week_start: {
      type: SchemaType.STRING,
      description: "Start date YYYY-MM-DD",
    },
    week_end: { type: SchemaType.STRING, description: "End date YYYY-MM-DD" },
    weekly_summary: {
      type: SchemaType.OBJECT,
      properties: {
        theme: {
          type: SchemaType.STRING,
          description: "Week's theme based on parent's focus",
        },
        main_goals: {
          type: SchemaType.ARRAY,
          items: { type: SchemaType.STRING },
          description: "3-4 goals",
        },
        parent_tip: {
          type: SchemaType.STRING,
          description: "Encouragement for the parent",
        },
      },
      required: ["theme", "main_goals"],
    },
    activities: {
      type: SchemaType.ARRAY,
      items: {
        type: SchemaType.OBJECT,
        properties: {
          date: { type: SchemaType.STRING },
          items: {
            type: SchemaType.ARRAY,
            items: {
              type: SchemaType.OBJECT,
              properties: {
                title: { type: SchemaType.STRING },
                description: { type: SchemaType.STRING },
                category: {
                  type: SchemaType.STRING,
                  description: "Motor|Sensory|Social|Cognitive|Communication",
                },
                duration_minutes: { type: SchemaType.INTEGER },
                materials: {
                  type: SchemaType.ARRAY,
                  items: { type: SchemaType.STRING },
                },
                why_chosen: {
                  type: SchemaType.STRING,
                  description:
                    "Why this fits baby's preferences or parent's focus",
                },
                milestone_support: {
                  type: SchemaType.STRING,
                  description: "Which milestone this helps",
                },
                if_baby_resists: {
                  type: SchemaType.STRING,
                  description: "Alternative approach",
                },
              },
              required: [
                "title",
                "description",
                "category",
                "duration_minutes",
                "why_chosen",
              ],
            },
          },
        },
        required: ["date", "items"],
      },
    },
    focus_areas: {
      type: SchemaType.ARRAY,
      description: "Progress on parent's focus areas",
      items: {
        type: SchemaType.OBJECT,
        properties: {
          area: { type: SchemaType.STRING },
          this_week: { type: SchemaType.STRING },
          look_for: { type: SchemaType.STRING },
        },
        required: ["area", "this_week"],
      },
    },
    milestones_to_watch: {
      type: SchemaType.ARRAY,
      items: {
        type: SchemaType.OBJECT,
        properties: {
          title: { type: SchemaType.STRING },
          status: {
            type: SchemaType.STRING,
            description: "in_window|overdue|upcoming",
          },
          how_to_support: { type: SchemaType.STRING },
        },
        required: ["title", "how_to_support"],
      },
    },
  },
  required: ["week_start", "week_end", "weekly_summary", "activities"],
};

Deno.serve(async (req) => {
  const startTime = Date.now();
  let babyId = "";
  let userId = "";

  try {
    if (req.method !== "POST") {
      return jsonResponse(405, { error: "Method not allowed" });
    }

    const body = (await req.json()) as RequestBody;
    babyId = body.baby_id?.trim();
    const forceRefresh = !!body.force_refresh;
    if (!babyId) {
      return jsonResponse(400, { error: "baby_id is required" });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    if (!supabaseUrl || !supabaseAnonKey) {
      return jsonResponse(500, { error: "Supabase env not configured" });
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: { Authorization: req.headers.get("Authorization") ?? "" },
      },
    });

    const { data: userData, error: userErr } = await supabase.auth.getUser();
    if (userErr || !userData?.user) {
      return jsonResponse(401, { error: "Unauthorized" });
    }
    userId = userData.user.id;

    // Check cache
    const today = isoDate(new Date());
    const { data: existing } = await supabase
      .from("baby_weekly_advice")
      .select("plan, valid_from, valid_to, model_version")
      .eq("baby_id", babyId)
      .maybeSingle();

    if (!forceRefresh && existing?.valid_to && existing.valid_to >= today) {
      await logAudit(supabase, {
        baby_id: babyId,
        user_id: userId,
        trigger_source: "api",
        status: "skipped",
        model_version: existing.model_version,
        execution_time_ms: Date.now() - startTime,
        metadata: { reason: "cached" },
      });
      return jsonResponse(200, { source: "cache", ...existing });
    }

    // ============================================
    // GATHER FOCUSED CONTEXT
    // ============================================

    // 1. Baby profile
    const { data: baby, error: babyErr } = await supabase
      .from("babies")
      .select("name, birthdate, gender, weight_kg, height_cm")
      .eq("id", babyId)
      .maybeSingle();
    if (babyErr || !baby) {
      return jsonResponse(404, { error: "Baby not found" });
    }

    const birth = new Date(baby.birthdate);
    const ageDays = Math.floor(
      (Date.now() - birth.getTime()) / (1000 * 60 * 60 * 24),
    );
    const ageWeeks = Math.floor(ageDays / 7);
    const ageMonths = Math.floor(ageDays / 30.437);

    // 2. User preferences
    const { data: userPrefs } = await supabase
      .from("user_preferences")
      .select("parenting_styles, nurture_priorities, goals")
      .eq("user_id", userId)
      .maybeSingle();

    // 3. Baby-specific focus (IMPORTANT - what parent wants to work on)
    const { data: focusRow } = await supabase
      .from("baby_short_term_focus")
      .select("focus")
      .eq("baby_id", babyId)
      .eq("user_id", userId)
      .maybeSingle();

    const { data: nurturePrioritiesRow } = await supabase
      .from("baby_nurture_priorities")
      .select("priorities")
      .eq("baby_id", babyId)
      .eq("user_id", userId)
      .maybeSingle();

    // 4. Activity preferences (last 30 days - recent preferences only)
    const { data: actRow } = await supabase
      .from("baby_activities")
      .select("loves, hates")
      .eq("baby_id", babyId)
      .eq("user_id", userId)
      .maybeSingle();

    const loves = actRow ? getRecentFromMap(actRow.loves, 30) : [];
    const hates = actRow ? getRecentFromMap(actRow.hates, 30) : [];

    // 5. Current milestone status (not history)
    const { data: milestones } = await supabase
      .from("v_baby_milestone_assessment")
      .select("title, category, status")
      .eq("baby_id", babyId);

    const inWindow = (milestones ?? []).filter(
      (m: any) => m.status === "in_window",
    );
    const overdue = (milestones ?? []).filter(
      (m: any) => m.status === "overdue",
    );
    const upcoming = (milestones ?? [])
      .filter((m: any) => m.status === "upcoming")
      .slice(0, 5);
    const achievedCount = (milestones ?? []).filter(
      (m: any) => m.status === "achieved",
    ).length;

    // 6. Vocabulary count (just the number, not full list)
    const { count: vocabCount } = await supabase
      .from("baby_vocabulary")
      .select("*", { count: "exact", head: true })
      .eq("baby_id", babyId);

    // 7. Current sleep schedule (most recent only)
    const { data: sleepData } = await supabase
      .from("sleep_schedules")
      .select("bedtime, wake_time, naps")
      .eq("baby_id", babyId)
      .order("date", { ascending: false })
      .limit(1);

    // 8. Active concerns only
    const { data: concerns } = await supabase
      .from("concerns")
      .select("text")
      .eq("baby_id", babyId)
      .eq("is_resolved", false)
      .limit(3);

    // ============================================
    // BUILD PROMPT
    // ============================================
    const weekStart = isoDate(new Date());
    const weekEnd = isoDate(daysFromNow(6));

    const focus = focusRow?.focus ?? [];
    const priorities = nurturePrioritiesRow?.priorities ?? [];
    const parentGoals = userPrefs?.goals ?? [];
    const parentingStyles = userPrefs?.parenting_styles ?? [];

    const prompt = `Create a weekly activity plan for ${baby.name}.

BABY:
- ${baby.name}, ${baby.gender}, ${ageMonths} months old (${ageWeeks} weeks)
${baby.weight_kg ? `- Weight: ${baby.weight_kg}kg` : ""}

PARENT'S PRIORITIES (design the week around these!):
${focus.length > 0 ? `- Developmental focus: ${focus.join(", ")}` : "- No specific focus set"}
${priorities.length > 0 ? `- Nurture priorities: ${priorities.join(", ")}` : ""}
${parentGoals.length > 0 ? `- Goals: ${parentGoals.join(", ")}` : ""}
${parentingStyles.length > 0 ? `- Parenting style: ${parentingStyles.join(", ")}` : ""}

WHAT ${baby.name.toUpperCase()} ENJOYS (use these!):
${loves.length > 0 ? loves.join(", ") : "No preferences recorded yet"}

WHAT TO AVOID/ADAPT:
${hates.length > 0 ? hates.join(", ") : "None recorded"}

MILESTONES:
- Achieved: ${achievedCount} milestones completed
- Currently working on: ${inWindow.length > 0 ? inWindow.map((m: any) => m.title).join(", ") : "None in window"}
- NEEDS ATTENTION: ${overdue.length > 0 ? overdue.map((m: any) => m.title).join(", ") : "All on track"}
- Coming soon: ${upcoming.map((m: any) => m.title).join(", ") || "None"}

LANGUAGE: ${vocabCount ?? 0} words recorded

ROUTINE:
${sleepData?.[0] ? `Bedtime: ${sleepData[0].bedtime || "varies"}, Wake: ${sleepData[0].wake_time || "varies"}, Naps: ${Array.isArray(sleepData[0].naps) ? sleepData[0].naps.length : "?"}/day` : "Not recorded"}

${concerns && concerns.length > 0 ? `CONCERNS: ${concerns.map((c: any) => c.text).join("; ")}` : ""}

PLAN FOR: ${weekStart} to ${weekEnd}
- 2-3 activities per day, 5-20 minutes each
- Use simple household materials
- Build activities around parent's focus areas
- Use what ${baby.name} loves
- Support overdue milestones with gentle activities
- Provide alternatives for activities baby might resist`;

    // ============================================
    // GENERATE
    // ============================================
    const modelId = Deno.env.get("GEMINI_MODEL_ID") || "gemini-3-flash-preview";
    const geminiKey = Deno.env.get("GEMINI_API_KEY");
    if (!geminiKey) {
      return jsonResponse(500, { error: "GEMINI_API_KEY not configured" });
    }

    const genAI = new GoogleGenerativeAI(geminiKey);
    const model = genAI.getGenerativeModel({
      model: modelId,
      generationConfig: {
        temperature: 1.0,
        maxOutputTokens: 8192,
        responseMimeType: "application/json",
        responseSchema: weeklyPlanSchema,
      },
    });

    let plan: any;
    try {
      const result = await model.generateContent(prompt);
      plan = JSON.parse(result.response.text());
    } catch (err: any) {
      console.error("Gemini call failed", err);
      await logAudit(supabase, {
        baby_id: babyId,
        user_id: userId,
        trigger_source: "api",
        status: "error",
        error_message: err.message || String(err),
        execution_time_ms: Date.now() - startTime,
      });
      return jsonResponse(502, { error: "Gemini call failed" });
    }

    // Save
    const { error: upsertErr } = await supabase
      .from("baby_weekly_advice")
      .upsert(
        {
          baby_id: babyId,
          user_id: userId,
          plan,
          model_version: modelId,
          generated_at: new Date().toISOString(),
          valid_from: weekStart,
          valid_to: weekEnd,
          prompt,
          response_raw: plan,
        },
        { onConflict: "baby_id" },
      );

    if (upsertErr) {
      console.error("Upsert error", upsertErr);
      await logAudit(supabase, {
        baby_id: babyId,
        user_id: userId,
        trigger_source: "api",
        status: "error",
        error_message: upsertErr.message,
        execution_time_ms: Date.now() - startTime,
      });
      return jsonResponse(500, { error: "Failed to save" });
    }

    await logAudit(supabase, {
      baby_id: babyId,
      user_id: userId,
      trigger_source: "api",
      status: "success",
      model_version: modelId,
      execution_time_ms: Date.now() - startTime,
    });

    return jsonResponse(200, {
      source: "generated",
      plan,
      valid_from: weekStart,
      valid_to: weekEnd,
      model_version: modelId,
    });
  } catch (e) {
    console.error("Unhandled error", e);
    return jsonResponse(500, { error: "Unhandled error" });
  }
});
