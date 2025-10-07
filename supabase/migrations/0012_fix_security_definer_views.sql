-- Fix security definer views to use security invoker instead
-- This ensures views respect the querying user's RLS policies

-- Update v_baby_domain_scores to use SECURITY INVOKER
ALTER VIEW public.v_baby_domain_scores SET (security_invoker = true);

-- Update v_baby_milestone_assessment to use SECURITY INVOKER
ALTER VIEW public.v_baby_milestone_assessment SET (security_invoker = true);

-- Update v_baby_overall_score to use SECURITY INVOKER
ALTER VIEW public.v_baby_overall_score SET (security_invoker = true);
