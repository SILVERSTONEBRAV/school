-- Multi-school: link profiles to a school
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS school_id UUID REFERENCES public.schools(id) ON DELETE SET NULL;

-- School announcements / circulars
CREATE TABLE IF NOT EXISTS public.announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  author_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  is_pinned BOOLEAN DEFAULT false NOT NULL,
  published_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_announcements_school
  ON public.announcements (school_id, published_at DESC);

ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated users to view announcements"
  ON public.announcements FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Allow admins to manage announcements"
  ON public.announcements FOR ALL
  USING (public.is_admin());

CREATE POLICY "Allow teachers to create announcements"
  ON public.announcements FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('admin', 'teacher')
    )
  );
