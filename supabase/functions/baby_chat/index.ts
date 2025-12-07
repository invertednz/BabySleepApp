// deno-lint-ignore-file no-explicit-any
// Supabase Edge Function: baby_chat
// Context-aware AI chatbot for BabySteps app using Google Gemini
// - Gathers relevant baby context based on question classification
// - Supports text and image inputs
// - Stores chat history for continuity

import { createClient } from 'npm:@supabase/supabase-js@2';
import { GoogleGenerativeAI } from 'npm:@google/generative-ai@0.21.0';

interface RequestBody {
  baby_id: string;
  message: string;
  image_base64?: string;
  image_mime_type?: string;
}

function jsonResponse(status: number, body: any) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

// Classify question to determine what context to fetch
function classifyQuestion(message: string): string[] {
  const categories: string[] = ['profile']; // Always include basic profile
  const lowerMsg = message.toLowerCase();

  // Milestone-related keywords
  if (/milestone|develop|crawl|walk|talk|sit|stand|roll|grab|point|wave|clap|first/.test(lowerMsg)) {
    categories.push('milestones');
  }

  // Sleep-related keywords
  if (/sleep|nap|bedtime|wake|night|tired|rest|drowsy|schedule/.test(lowerMsg)) {
    categories.push('sleep');
  }

  // Activity-related keywords
  if (/play|activity|game|toy|like|hate|love|fun|bored|engage|stimulat/.test(lowerMsg)) {
    categories.push('activities');
  }

  // Feeding-related keywords
  if (/eat|feed|food|bottle|breast|formula|solid|wean|hungry|milk|nursing/.test(lowerMsg)) {
    categories.push('feeding');
  }

  // Health-related keywords
  if (/sick|health|doctor|concern|worry|fever|rash|pain|cry|teething|diaper|poop/.test(lowerMsg)) {
    categories.push('health');
  }

  // Development advice keywords
  if (/advice|plan|focus|recommend|should|week|help|tips|suggest|best|normal/.test(lowerMsg)) {
    categories.push('development');
  }

  // Image analysis - always include milestones context for comparison
  if (message.includes('[IMAGE]') || lowerMsg.includes('picture') || lowerMsg.includes('photo') || lowerMsg.includes('image')) {
    if (!categories.includes('milestones')) {
      categories.push('milestones');
    }
  }

  // If no specific category matched, include broader context
  if (categories.length === 1) {
    categories.push('milestones', 'activities', 'development');
  }

  return categories;
}

// Calculate age in months and weeks
function calculateAge(birthdate: string): { months: number; weeks: number; ageString: string } {
  const birth = new Date(birthdate);
  const now = new Date();
  const diffMs = now.getTime() - birth.getTime();
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
  const weeks = Math.floor(diffDays / 7);
  const months = Math.floor(diffDays / 30.437);
  
  let ageString: string;
  if (months < 1) {
    ageString = `${weeks} week${weeks !== 1 ? 's' : ''} old`;
  } else if (months < 24) {
    ageString = `${months} month${months !== 1 ? 's' : ''} old`;
  } else {
    const years = Math.floor(months / 12);
    const remainingMonths = months % 12;
    ageString = `${years} year${years !== 1 ? 's' : ''}${remainingMonths > 0 ? ` and ${remainingMonths} month${remainingMonths !== 1 ? 's' : ''}` : ''} old`;
  }
  
  return { months, weeks, ageString };
}

Deno.serve(async (req) => {
  try {
    if (req.method !== 'POST') {
      return jsonResponse(405, { error: 'Method not allowed' });
    }

    const body = (await req.json()) as RequestBody;
    const babyId = body.baby_id?.trim();
    const userMessage = body.message?.trim();

    if (!babyId || !userMessage) {
      return jsonResponse(400, { error: 'baby_id and message are required' });
    }

    // Setup Supabase client
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
    const userId = userData.user.id;

    // Check premium status
    const { data: userPrefs } = await supabase
      .from('user_preferences')
      .select('plan_tier, is_on_trial')
      .eq('user_id', userId)
      .maybeSingle();

    const planTier = (userPrefs?.plan_tier as string)?.toLowerCase() ?? 'free';
    const isOnTrial = userPrefs?.is_on_trial === true;
    const isPaid = planTier !== 'free' || isOnTrial;

    if (!isPaid) {
      return jsonResponse(403, { error: 'Premium subscription required for AI chat' });
    }

    // Fetch baby profile (always needed)
    const { data: baby, error: babyErr } = await supabase
      .from('babies')
      .select('id, user_id, name, birthdate, gender, weight_kg, height_cm')
      .eq('id', babyId)
      .eq('user_id', userId)
      .maybeSingle();

    if (babyErr || !baby) {
      return jsonResponse(404, { error: 'Baby not found' });
    }

    const age = calculateAge(baby.birthdate);

    // Classify question to determine context
    const categories = classifyQuestion(userMessage);
    const contextParts: Record<string, any> = {};

    // Always include baby profile
    contextParts.baby = {
      name: baby.name,
      gender: baby.gender,
      birthdate: baby.birthdate,
      age: age.ageString,
      age_months: age.months,
      age_weeks: age.weeks,
      weight_kg: baby.weight_kg,
      height_cm: baby.height_cm,
    };

    // Fetch milestone context
    if (categories.includes('milestones')) {
      const { data: assessments } = await supabase
        .from('v_baby_milestone_assessment')
        .select('milestone_id, category, title, status, window_start_weeks, window_end_weeks')
        .eq('baby_id', babyId);

      if (assessments && assessments.length > 0) {
        const completed = assessments.filter((m: any) => m.status === 'achieved');
        const upcoming = assessments.filter((m: any) => m.status === 'upcoming');
        const inWindow = assessments.filter((m: any) => m.status === 'in_window');
        const overdue = assessments.filter((m: any) => m.status === 'overdue');

        contextParts.milestones = {
          recently_completed: completed.slice(0, 10).map((m: any) => ({ title: m.title, category: m.category })),
          upcoming_soon: upcoming.slice(0, 10).map((m: any) => ({ title: m.title, category: m.category })),
          currently_in_window: inWindow.slice(0, 10).map((m: any) => ({ title: m.title, category: m.category })),
          overdue: overdue.slice(0, 5).map((m: any) => ({ title: m.title, category: m.category })),
        };
      }
    }

    // Fetch sleep context
    if (categories.includes('sleep')) {
      const { data: sleepData } = await supabase
        .from('sleep_schedules')
        .select('bedtime, wake_time, naps, date')
        .eq('baby_id', babyId)
        .order('date', { ascending: false })
        .limit(7);

      if (sleepData && sleepData.length > 0) {
        const latest = sleepData[0];
        contextParts.sleep = {
          current_schedule: {
            bedtime: latest.bedtime,
            wake_time: latest.wake_time,
            naps: latest.naps,
          },
          history_days: sleepData.length,
        };
      }
    }

    // Fetch activities context
    if (categories.includes('activities')) {
      const { data: actRow } = await supabase
        .from('baby_activities')
        .select('loves, hates, neutral, skipped')
        .eq('baby_id', babyId)
        .eq('user_id', userId)
        .maybeSingle();

      if (actRow) {
        const getKeys = (obj: any) => obj && typeof obj === 'object' ? Object.keys(obj).slice(0, 10) : [];
        contextParts.activities = {
          loves: getKeys(actRow.loves),
          hates: getKeys(actRow.hates),
          neutral: getKeys(actRow.neutral),
        };
      }
    }

    // Fetch health/concerns context
    if (categories.includes('health')) {
      const { data: concerns } = await supabase
        .from('concerns')
        .select('text, is_resolved, created_at')
        .eq('baby_id', babyId)
        .order('created_at', { ascending: false })
        .limit(5);

      if (concerns && concerns.length > 0) {
        contextParts.health = {
          recent_concerns: concerns.map((c: any) => ({
            concern: c.text,
            resolved: c.is_resolved,
          })),
        };
      }
    }

    // Fetch development/advice context
    if (categories.includes('development')) {
      // Short-term focus
      const { data: focusRow } = await supabase
        .from('baby_short_term_focus')
        .select('focus')
        .eq('baby_id', babyId)
        .eq('user_id', userId)
        .maybeSingle();

      // Nurture priorities
      const { data: prioritiesRow } = await supabase
        .from('baby_nurture_priorities')
        .select('priorities')
        .eq('baby_id', babyId)
        .eq('user_id', userId)
        .maybeSingle();

      // Weekly advice summary (if exists)
      const { data: adviceRow } = await supabase
        .from('baby_weekly_advice')
        .select('plan, valid_from, valid_to')
        .eq('baby_id', babyId)
        .maybeSingle();

      contextParts.development = {
        short_term_focus: focusRow?.focus ?? [],
        nurture_priorities: prioritiesRow?.priorities ?? [],
        has_weekly_plan: !!adviceRow?.plan,
        weekly_plan_valid_to: adviceRow?.valid_to,
      };
    }

    // Fetch recent chat history (last 10 messages)
    const { data: chatHistory } = await supabase
      .from('baby_chat_messages')
      .select('role, content, created_at')
      .eq('baby_id', babyId)
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(10);

    const recentHistory = (chatHistory ?? []).reverse();

    // Build the prompt
    const systemPrompt = `You are a friendly, knowledgeable parenting assistant for the BabySteps app. You help parents with questions about their baby's development, sleep, activities, and general parenting.

IMPORTANT GUIDELINES:
- Be warm, supportive, and reassuring - parenting is hard!
- Give evidence-based advice when possible
- ALWAYS recommend consulting a pediatrician for medical concerns or if the parent is worried
- Personalize responses using the baby's name (${baby.name}) and the context provided
- Keep responses concise but helpful (2-4 paragraphs max)
- If you don't have enough information, ask clarifying questions
- When analyzing images, describe what you see and relate it to the baby's development
- Never diagnose medical conditions - always defer to healthcare professionals
- Be encouraging about the baby's progress and reassure the parent

BABY CONTEXT:
${JSON.stringify(contextParts, null, 2)}

${recentHistory.length > 0 ? `RECENT CONVERSATION:
${recentHistory.map((m: any) => `${m.role === 'user' ? 'Parent' : 'Assistant'}: ${m.content}`).join('\n')}` : ''}`;

    // Setup Gemini
    const geminiKey = Deno.env.get('GEMINI_API_KEY');
    if (!geminiKey) {
      return jsonResponse(500, { error: 'GEMINI_API_KEY not configured' });
    }

    const modelId = Deno.env.get('GEMINI_MODEL_ID') || 'gemini-2.0-flash';
    const genAI = new GoogleGenerativeAI(geminiKey);
    const model = genAI.getGenerativeModel({ model: modelId });

    // Build message parts
    const messageParts: any[] = [{ text: userMessage }];

    // Add image if provided
    if (body.image_base64 && body.image_mime_type) {
      messageParts.push({
        inlineData: {
          data: body.image_base64,
          mimeType: body.image_mime_type,
        },
      });
    }

    // Generate response
    let responseText = '';
    try {
      const result = await model.generateContent({
        contents: [
          { role: 'user', parts: [{ text: systemPrompt }] },
          { role: 'model', parts: [{ text: 'I understand. I\'m ready to help as a friendly parenting assistant for BabySteps. I\'ll be warm, supportive, and personalize my responses for ' + baby.name + '. How can I help?' }] },
          { role: 'user', parts: messageParts },
        ],
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: 1024,
        },
      });
      responseText = result.response.text();
    } catch (err: any) {
      console.error('Gemini call failed', err);
      return jsonResponse(502, { error: 'AI service temporarily unavailable' });
    }

    // Save user message to history
    const { data: userMsgData } = await supabase
      .from('baby_chat_messages')
      .insert({
        baby_id: babyId,
        user_id: userId,
        role: 'user',
        content: userMessage,
        image_url: body.image_base64 ? 'image_attached' : null,
      })
      .select('id')
      .single();

    // Save assistant response to history
    const { data: assistantMsgData } = await supabase
      .from('baby_chat_messages')
      .insert({
        baby_id: babyId,
        user_id: userId,
        role: 'assistant',
        content: responseText,
        context_summary: categories.join(', '),
      })
      .select('id')
      .single();

    return jsonResponse(200, {
      response: responseText,
      context_used: categories,
      message_id: assistantMsgData?.id,
    });

  } catch (e) {
    console.error('Unhandled error', e);
    return jsonResponse(500, { error: 'An unexpected error occurred' });
  }
});
