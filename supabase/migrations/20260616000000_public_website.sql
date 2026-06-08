-- Public website (Next.js on Vercel): app download links + anonymous portal access

CREATE TABLE IF NOT EXISTS public.portal_app_releases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  platform TEXT NOT NULL CHECK (platform IN ('web', 'windows', 'android', 'ios')),
  download_url TEXT,
  version TEXT,
  release_notes TEXT,
  is_enabled BOOLEAN DEFAULT true NOT NULL,
  sort_order INT DEFAULT 0 NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  UNIQUE (school_id, platform)
);

ALTER TABLE public.portal_app_releases ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone reads enabled app releases"
  ON public.portal_app_releases FOR SELECT
  USING (is_enabled OR public.is_admin());

CREATE POLICY "Admins manage app releases"
  ON public.portal_app_releases FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Seed default app release rows per school
INSERT INTO public.portal_app_releases (school_id, platform, download_url, version, release_notes, sort_order)
SELECT s.id, p.platform, p.download_url, '1.0.0', p.notes, p.sort_order
FROM public.schools s
CROSS JOIN (VALUES
  ('web'::text, NULL::text, 'Open in browser — no install needed', 1),
  ('windows'::text, NULL::text, 'Download Windows desktop app', 2),
  ('android'::text, NULL::text, 'Google Play or APK', 3),
  ('ios'::text, NULL::text, 'Apple App Store', 4)
) AS p(platform, download_url, notes, sort_order)
ON CONFLICT (school_id, platform) DO NOTHING;

-- Allow anonymous visitors to submit reviews (pending admin approval)
DROP POLICY IF EXISTS "Anyone insert reviews" ON public.portal_reviews;
CREATE POLICY "Public submit reviews for moderation"
  ON public.portal_reviews FOR INSERT
  TO anon, authenticated
  WITH CHECK (is_published = false);

-- Explicit public read for published portal content (anon website)
DROP POLICY IF EXISTS "Read published portal faqs" ON public.portal_faqs;
CREATE POLICY "Read published portal faqs"
  ON public.portal_faqs FOR SELECT
  TO anon, authenticated
  USING (is_published OR public.is_admin());

DROP POLICY IF EXISTS "Read published downloads" ON public.portal_downloads;
CREATE POLICY "Read published downloads"
  ON public.portal_downloads FOR SELECT
  TO anon, authenticated
  USING (is_published OR public.is_admin());

DROP POLICY IF EXISTS "Read published contacts" ON public.portal_contacts;
CREATE POLICY "Read published contacts"
  ON public.portal_contacts FOR SELECT
  TO anon, authenticated
  USING (is_published OR public.is_admin());

DROP POLICY IF EXISTS "Read published stories" ON public.portal_success_stories;
CREATE POLICY "Read published stories"
  ON public.portal_success_stories FOR SELECT
  TO anon, authenticated
  USING (is_published OR public.is_admin());

DROP POLICY IF EXISTS "Read published reviews" ON public.portal_reviews;
CREATE POLICY "Read published reviews"
  ON public.portal_reviews FOR SELECT
  TO anon, authenticated
  USING (is_published OR public.is_admin());

DROP POLICY IF EXISTS "Read published help" ON public.portal_help_articles;
CREATE POLICY "Read published help"
  ON public.portal_help_articles FOR SELECT
  TO anon, authenticated
  USING (is_published OR public.is_admin());

DROP POLICY IF EXISTS "Read published gallery" ON public.gallery_posts;
CREATE POLICY "Read published gallery"
  ON public.gallery_posts FOR SELECT
  TO anon, authenticated
  USING (is_published OR public.is_admin());
