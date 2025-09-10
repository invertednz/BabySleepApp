-- Create the milestones table
CREATE TABLE public.milestones (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    category text NOT NULL,
    title text NOT NULL,
    first_noticed_weeks integer NOT NULL,
    worry_after_weeks integer NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT milestones_pkey PRIMARY KEY (id)
);

-- Add RLS to the milestones table
ALTER TABLE public.milestones ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read all milestones
CREATE POLICY "Allow authenticated user to read milestones" ON public.milestones
AS PERMISSIVE FOR SELECT
TO authenticated
USING (true);

-- Create the milestone_activities table
CREATE TABLE public.milestone_activities (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    milestone_id uuid NOT NULL,
    description text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT milestone_activities_pkey PRIMARY KEY (id),
    CONSTRAINT milestone_activities_milestone_id_fkey FOREIGN KEY (milestone_id) REFERENCES public.milestones(id) ON DELETE CASCADE
);

-- Add RLS to the milestone_activities table
ALTER TABLE public.milestone_activities ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read all milestone activities
CREATE POLICY "Allow authenticated user to read milestone_activities" ON public.milestone_activities
AS PERMISSIVE FOR SELECT
TO authenticated
USING (true);
