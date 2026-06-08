-- ---------------------------------------------------------
-- ASSIGNMENTS & SUBMISSIONS
-- ---------------------------------------------------------

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'submission_status') THEN
    CREATE TYPE submission_status AS ENUM ('submitted', 'graded', 'late');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_subject_id UUID NOT NULL REFERENCES public.class_subjects(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  due_date TIMESTAMPTZ NOT NULL,
  max_score NUMERIC DEFAULT 100 NOT NULL CHECK (max_score > 0),
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assignment_id UUID NOT NULL REFERENCES public.assignments(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES public.student_profiles(profile_id) ON DELETE CASCADE,
  content TEXT,
  file_url TEXT,
  score NUMERIC CHECK (score IS NULL OR score >= 0),
  feedback TEXT,
  status submission_status DEFAULT 'submitted' NOT NULL,
  submitted_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  graded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  UNIQUE (assignment_id, student_id)
);

-- ---------------------------------------------------------
-- NOTIFICATIONS
-- ---------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT,
  type TEXT NOT NULL DEFAULT 'general',
  reference_id UUID,
  is_read BOOLEAN DEFAULT false NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
  ON public.notifications (user_id, is_read, created_at DESC);

-- ---------------------------------------------------------
-- RLS
-- ---------------------------------------------------------

ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anyone authenticated to view assignments"
  ON public.assignments FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Allow teachers to manage own subject assignments"
  ON public.assignments FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.class_subjects cs
      WHERE cs.id = class_subject_id AND cs.teacher_id = auth.uid()
    ) OR public.is_admin()
  );

CREATE POLICY "Allow students to view own submissions"
  ON public.submissions FOR SELECT
  USING (auth.uid() = student_id OR public.is_admin());

CREATE POLICY "Allow parents to view children submissions"
  ON public.submissions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.student_parents sp
      WHERE sp.parent_id = auth.uid() AND sp.student_id = student_id
    )
  );

CREATE POLICY "Allow teachers to view submissions for their assignments"
  ON public.submissions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.assignments a
      JOIN public.class_subjects cs ON cs.id = a.class_subject_id
      WHERE a.id = assignment_id AND cs.teacher_id = auth.uid()
    )
  );

CREATE POLICY "Allow students to submit assignments"
  ON public.submissions FOR INSERT
  WITH CHECK (auth.uid() = student_id);

CREATE POLICY "Allow students to update own unsubmitted or resubmit"
  ON public.submissions FOR UPDATE
  USING (auth.uid() = student_id);

CREATE POLICY "Allow teachers to grade submissions"
  ON public.submissions FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.assignments a
      JOIN public.class_subjects cs ON cs.id = a.class_subject_id
      WHERE a.id = assignment_id AND cs.teacher_id = auth.uid()
    ) OR public.is_admin()
  );

CREATE POLICY "Allow users to view own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Allow users to update own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Allow system roles to insert notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (
    public.is_admin()
    OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
  );
