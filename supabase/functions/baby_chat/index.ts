// deno-lint-ignore-file no-explicit-any
// Supabase Edge Function: baby_chat
// Context-aware AI chatbot for BabySteps app using Google Gemini 3 Flash
// Uses focused, recent data for personalization

import { createClient } from "npm:@supabase/supabase-js@2";
import { GoogleGenerativeAI } from "npm:@google/generative-ai@0.21.0";

interface RequestBody {
  baby_id: string;
  message: string;
  image_base64?: string;
  image_mime_type?: string;
}

function jsonResponse(status: number, body: any) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function daysAgo(n: number): string {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d.toISOString();
}

// Get recent items from a JSONB map (activity -> timestamp)
function getRecentFromMap(obj: any, daysLimit: number): string[] {
  if (!obj || typeof obj !== "object") return [];
  const cutoff = new Date(daysAgo(daysLimit));
  return Object.entries(obj)
    .filter(([_, ts]) => ts && new Date(ts as string) >= cutoff)
    .map(([key, _]) => key);
}

// Classify question to determine what context to fetch
function classifyQuestion(message: string): string[] {
  const categories: string[] = ["profile", "priorities"]; // Always include these
  const lowerMsg = message.toLowerCase();

  if (
    /milestone|develop|crawl|walk|talk|sit|stand|roll|grab|point|wave|clap|first|learn|skill/.test(
      lowerMsg,
    )
  ) {
    categories.push("milestones");
  }
  if (
    /sleep|nap|bedtime|wake|night|tired|rest|drowsy|schedule|routine/.test(
      lowerMsg,
    )
  ) {
    categories.push("sleep");
  }
  if (
    /play|activity|game|toy|like|hate|love|fun|bored|engage|stimulat|entertain/.test(
      lowerMsg,
    )
  ) {
    categories.push("activities");
  }
  if (
    /eat|feed|food|bottle|breast|formula|solid|wean|hungry|milk|nursing|meal|snack/.test(
      lowerMsg,
    )
  ) {
    categories.push("feeding");
  }
  if (
    /sick|health|doctor|concern|worry|fever|rash|pain|cry|teething|diaper|poop|pee|wet/.test(
      lowerMsg,
    )
  ) {
    categories.push("health");
  }
  if (/word|say|speak|language|vocab|babbl|sound|communicate/.test(lowerMsg)) {
    categories.push("vocabulary");
  }
  if (
    /advice|plan|focus|recommend|should|week|help|tips|suggest|best|normal|priority|goal/.test(
      lowerMsg,
    )
  ) {
    categories.push("development");
  }

  return [...new Set(categories)];
}

// Calculate age
function calculateAge(birthdate: string): {
  months: number;
  weeks: number;
  ageString: string;
} {
  const birth = new Date(birthdate);
  const now = new Date();
  const days = Math.floor(
    (now.getTime() - birth.getTime()) / (1000 * 60 * 60 * 24),
  );
  const weeks = Math.floor(days / 7);
  const months = Math.floor(days / 30.437);

  let ageString: string;
  if (months < 1) {
    ageString = `${weeks} week${weeks !== 1 ? "s" : ""} old`;
  } else if (months < 24) {
    ageString = `${months} month${months !== 1 ? "s" : ""} old`;
  } else {
    const years = Math.floor(months / 12);
    const remainingMonths = months % 12;
    ageString = `${years} year${years !== 1 ? "s" : ""}${remainingMonths > 0 ? ` and ${remainingMonths} month${remainingMonths !== 1 ? "s" : ""}` : ""} old`;
  }

  return { months, weeks, ageString };
}

Deno.serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return jsonResponse(405, { error: "Method not allowed" });
    }

    const body = (await req.json()) as RequestBody;
    const babyId = body.baby_id?.trim();
    const userMessage = body.message?.trim();

    if (!babyId || !userMessage) {
      return jsonResponse(400, { error: "baby_id and message are required" });
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
    const userId = userData.user.id;

    // Check premium
    const { data: userPrefs } = await supabase
      .from("user_preferences")
      .select(
        "plan_tier, is_on_trial, parenting_styles, nurture_priorities, goals",
      )
      .eq("user_id", userId)
      .maybeSingle();

    const planTier = (userPrefs?.plan_tier as string)?.toLowerCase() ?? "free";
    const isOnTrial = userPrefs?.is_on_trial === true;
    if (planTier === "free" && !isOnTrial) {
      return jsonResponse(403, {
        error: "Premium subscription required for AI chat",
      });
    }

    // Baby profile
    const { data: baby, error: babyErr } = await supabase
      .from("babies")
      .select("id, name, birthdate, gender, weight_kg, height_cm")
      .eq("id", babyId)
      .eq("user_id", userId)
      .maybeSingle();

    if (babyErr || !baby) {
      return jsonResponse(404, { error: "Baby not found" });
    }

    const age = calculateAge(baby.birthdate);
    const categories = classifyQuestion(userMessage);

    // ============================================
    // BUILD FOCUSED CONTEXT (recent data only)
    // ============================================
    const contextParts: string[] = [];

    // 1. BABY PROFILE (always)
    let profile = `${baby.name} is ${age.ageString} (${baby.gender})`;
    if (baby.weight_kg) profile += `, ${baby.weight_kg}kg`;
    if (baby.height_cm) profile += `, ${baby.height_cm}cm`;
    contextParts.push(`Baby: ${profile}`);

    // 2. PARENT'S CURRENT PRIORITIES (always - this is what they care about!)
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

    const focus = focusRow?.focus ?? [];
    const priorities = nurturePrioritiesRow?.priorities ?? [];
    const parentGoals = userPrefs?.goals ?? [];
    const parentingStyles = userPrefs?.parenting_styles ?? [];

    if (focus.length > 0 || priorities.length > 0 || parentGoals.length > 0) {
      let priorityText = "Parent's focus:";
      if (focus.length > 0) priorityText += ` Working on: ${focus.join(", ")}.`;
      if (priorities.length > 0)
        priorityText += ` Priorities: ${priorities.join(", ")}.`;
      if (parentGoals.length > 0)
        priorityText += ` Goals: ${parentGoals.join(", ")}.`;
      if (parentingStyles.length > 0)
        priorityText += ` Style: ${parentingStyles.join(", ")}.`;
      contextParts.push(priorityText);
    }

    // 3. MILESTONES (always include current status)
    const { data: milestones } = await supabase
      .from("v_baby_milestone_assessment")
      .select("title, category, status")
      .eq("baby_id", babyId);

    if (milestones && milestones.length > 0) {
      const inWindow = milestones.filter((m: any) => m.status === "in_window");
      const overdue = milestones.filter((m: any) => m.status === "overdue");
      const achieved = milestones.filter((m: any) => m.status === "achieved");

      let msText = "Milestones:";
      if (inWindow.length > 0)
        msText += ` Currently working on: ${inWindow
          .slice(0, 5)
          .map((m: any) => m.title)
          .join(", ")}.`;
      if (overdue.length > 0)
        msText += ` May need attention: ${overdue.map((m: any) => m.title).join(", ")}.`;
      if (achieved.length > 0)
        msText += ` Achieved ${achieved.length} milestones.`;
      contextParts.push(msText);
    }

    // 4. ACTIVITY PREFERENCES (always include, last 30 days)
    const { data: actRow } = await supabase
      .from("baby_activities")
      .select("loves, hates")
      .eq("baby_id", babyId)
      .eq("user_id", userId)
      .maybeSingle();

    if (actRow) {
      const loves = getRecentFromMap(actRow.loves, 30);
      const hates = getRecentFromMap(actRow.hates, 30);

      if (loves.length > 0 || hates.length > 0) {
        let actText = "Activities:";
        if (loves.length > 0) actText += ` Loves: ${loves.join(", ")}.`;
        if (hates.length > 0) actText += ` Dislikes: ${hates.join(", ")}.`;
        contextParts.push(actText);
      }
    }

    // 5. SLEEP (last 3 days)
    if (categories.includes("sleep")) {
      const { data: sleepData } = await supabase
        .from("sleep_schedules")
        .select("bedtime, wake_time, naps")
        .eq("baby_id", babyId)
        .gte("date", daysAgo(3))
        .order("date", { ascending: false })
        .limit(1);

      if (sleepData && sleepData.length > 0) {
        const s = sleepData[0];
        let sleepText = "Sleep:";
        if (s.bedtime) sleepText += ` Bedtime ${s.bedtime}.`;
        if (s.wake_time) sleepText += ` Wakes ${s.wake_time}.`;
        if (s.naps && Array.isArray(s.naps))
          sleepText += ` ${s.naps.length} naps.`;
        contextParts.push(sleepText);
      }
    }

    // 6. FEEDING (current)
    if (categories.includes("feeding")) {
      const { data: feedingData } = await supabase
        .from("feeding_preferences")
        .select("feeding_method, feedings_per_day")
        .eq("baby_id", babyId)
        .order("date", { ascending: false })
        .limit(1);

      if (feedingData && feedingData.length > 0) {
        const f = feedingData[0];
        let feedText = "Feeding:";
        if (f.feeding_method) feedText += ` ${f.feeding_method}.`;
        if (f.feedings_per_day) feedText += ` ${f.feedings_per_day}x/day.`;
        contextParts.push(feedText);
      }
    }

    // 7. ACTIVE CONCERNS ONLY
    if (categories.includes("health")) {
      const { data: concerns } = await supabase
        .from("concerns")
        .select("text")
        .eq("baby_id", babyId)
        .eq("is_resolved", false)
        .limit(3);

      if (concerns && concerns.length > 0) {
        contextParts.push(
          `Active concerns: ${concerns.map((c: any) => c.text).join("; ")}`,
        );
      }
    }

    // 8. VOCABULARY (recent words only)
    if (categories.includes("vocabulary")) {
      const { data: vocabData } = await supabase
        .from("baby_vocabulary")
        .select("word")
        .eq("baby_id", babyId)
        .order("recorded_at", { ascending: false })
        .limit(15);

      if (vocabData && vocabData.length > 0) {
        contextParts.push(
          `Vocabulary (${vocabData.length} recent words): ${vocabData.map((v: any) => v.word).join(", ")}`,
        );
      }
    }

    // 9. CURRENT WEEKLY PLAN (if valid)
    if (
      categories.includes("development") ||
      categories.includes("activities")
    ) {
      const today = new Date().toISOString().split("T")[0];
      const { data: weeklyAdvice } = await supabase
        .from("baby_weekly_advice")
        .select("plan")
        .eq("baby_id", babyId)
        .gte("valid_to", today)
        .maybeSingle();

      if (weeklyAdvice?.plan?.weekly_summary?.theme) {
        contextParts.push(
          `This week's focus: ${weeklyAdvice.plan.weekly_summary.theme}`,
        );
      }
    }

    // 10. RECENT CHAT HISTORY (last 6 messages for continuity)
    const { data: chatHistory } = await supabase
      .from("baby_chat_messages")
      .select("role, content")
      .eq("baby_id", babyId)
      .eq("user_id", userId)
      .order("created_at", { ascending: false })
      .limit(6);

    const recentHistory = (chatHistory ?? []).reverse();

    // ============================================
    // BUILD PROMPT
    // ============================================
    const systemPrompt = `You are a helpful parenting assistant for ${baby.name} (${age.ageString}).

Context:
${contextParts.join("\n")}

Instructions:
- Use ${baby.name}'s name naturally
- Reference the parent's priorities and focus areas when relevant
- Suggest activities ${baby.name} loves, avoid ones they dislike
- Keep responses concise (2-3 paragraphs)
- Be warm and encouraging
- For medical concerns, recommend consulting a pediatrician
- Don't diagnose conditions`;

    // ============================================
    // GENERATE RESPONSE
    // ============================================
    const geminiKey = Deno.env.get("GEMINI_API_KEY");
    if (!geminiKey) {
      return jsonResponse(500, { error: "GEMINI_API_KEY not configured" });
    }

    const modelId = Deno.env.get("GEMINI_MODEL_ID") || "gemini-3-flash-preview";
    const genAI = new GoogleGenerativeAI(geminiKey);
    const model = genAI.getGenerativeModel({
      model: modelId,
      generationConfig: { temperature: 1.0, maxOutputTokens: 1024 },
    });

    // Build conversation
    const contents: any[] = [
      { role: "user", parts: [{ text: systemPrompt }] },
      {
        role: "model",
        parts: [
          {
            text: `I'm here to help with ${baby.name}. What would you like to know?`,
          },
        ],
      },
    ];

    // Add recent history
    for (const msg of recentHistory) {
      contents.push({
        role: msg.role === "user" ? "user" : "model",
        parts: [{ text: msg.content }],
      });
    }

    // Add current message
    const currentParts: any[] = [{ text: userMessage }];
    if (body.image_base64 && body.image_mime_type) {
      currentParts.push({
        inlineData: { data: body.image_base64, mimeType: body.image_mime_type },
      });
    }
    contents.push({ role: "user", parts: currentParts });

    let responseText = "";
    try {
      const result = await model.generateContent({ contents });
      responseText = result.response.text();
    } catch (err: any) {
      console.error("Gemini call failed", err);
      return jsonResponse(502, { error: "AI service temporarily unavailable" });
    }

    // Save messages
    await supabase.from("baby_chat_messages").insert({
      baby_id: babyId,
      user_id: userId,
      role: "user",
      content: userMessage,
      image_url: body.image_base64 ? "image_attached" : null,
      context_summary: categories.join(", "),
    });

    const { data: assistantMsgData } = await supabase
      .from("baby_chat_messages")
      .insert({
        baby_id: babyId,
        user_id: userId,
        role: "assistant",
        content: responseText,
        context_summary: categories.join(", "),
      })
      .select("id")
      .single();

    return jsonResponse(200, {
      response: responseText,
      context_used: categories,
      message_id: assistantMsgData?.id,
    });
  } catch (e) {
    console.error("Unhandled error", e);
    return jsonResponse(500, { error: "An unexpected error occurred" });
  }
});
