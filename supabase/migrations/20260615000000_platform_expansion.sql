-- Platform expansion: payments, portal CMS, gallery, materials, feature flags, futuristic modules

-- ============================================================
-- SCHOOL PORTAL PROFILE
-- ============================================================
ALTER TABLE public.schools
  ADD COLUMN IF NOT EXISTS mission TEXT,
  ADD COLUMN IF NOT EXISTS vision TEXT,
  ADD COLUMN IF NOT EXISTS about TEXT,
  ADD COLUMN IF NOT EXISTS website TEXT,
  ADD COLUMN IF NOT EXISTS latitude NUMERIC,
  ADD COLUMN IF NOT EXISTS longitude NUMERIC,
  ADD COLUMN IF NOT EXISTS map_url TEXT,
  ADD COLUMN IF NOT EXISTS established_year INT,
  ADD COLUMN IF NOT EXISTS tagline TEXT;

-- ============================================================
-- FEATURE FLAGS (admin toggle + config placeholders for API keys)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.feature_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  feature_key TEXT NOT NULL,
  is_enabled BOOLEAN DEFAULT false NOT NULL,
  config JSONB DEFAULT '{}'::jsonb NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  UNIQUE (school_id, feature_key)
);

-- ============================================================
-- PAYMENT METHOD CONFIGURATION
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_channel') THEN
    CREATE TYPE payment_channel AS ENUM (
      'manual_till', 'manual_paybill', 'manual_bank',
      'mpesa_online', 'stripe_online', 'bank_online'
    );
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_submission_status') THEN
    CREATE TYPE payment_submission_status AS ENUM ('pending', 'confirmed', 'rejected', 'processing');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.payment_method_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  channel payment_channel NOT NULL,
  is_enabled BOOLEAN DEFAULT false NOT NULL,
  display_name TEXT NOT NULL,
  config JSONB DEFAULT '{}'::jsonb NOT NULL,
  instructions TEXT,
  sort_order INT DEFAULT 0,
  UNIQUE (school_id, channel)
);

-- ============================================================
-- PAYMENT SUBMISSIONS (manual + online pending confirmation)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.payment_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES public.student_profiles(profile_id) ON DELETE CASCADE,
  invoice_id UUID REFERENCES public.invoices(id) ON DELETE SET NULL,
  submitted_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  amount NUMERIC NOT NULL CHECK (amount > 0),
  channel payment_channel NOT NULL,
  reference_code TEXT,
  payer_phone TEXT,
  proof_file_url TEXT,
  status payment_submission_status DEFAULT 'pending' NOT NULL,
  confirmed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  confirmed_at TIMESTAMPTZ,
  rejection_reason TEXT,
  notes TEXT,
  excess_amount NUMERIC DEFAULT 0 NOT NULL CHECK (excess_amount >= 0),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_payment_submissions_status
  ON public.payment_submissions (status, created_at DESC);

-- Fee credits from overpayment — carry to next term/year
CREATE TABLE IF NOT EXISTS public.fee_credits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES public.student_profiles(profile_id) ON DELETE CASCADE,
  amount NUMERIC NOT NULL CHECK (amount > 0),
  remaining_amount NUMERIC NOT NULL CHECK (remaining_amount >= 0),
  source_submission_id UUID REFERENCES public.payment_submissions(id) ON DELETE SET NULL,
  academic_year_id UUID REFERENCES public.academic_years(id) ON DELETE SET NULL,
  term_id UUID REFERENCES public.terms(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- ============================================================
-- PORTAL CMS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.portal_faqs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  category TEXT DEFAULT 'General',
  sort_order INT DEFAULT 0,
  is_published BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.portal_downloads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  file_url TEXT NOT NULL,
  category TEXT DEFAULT 'Documents',
  download_count INT DEFAULT 0 NOT NULL,
  is_published BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.portal_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  department TEXT NOT NULL,
  contact_name TEXT,
  email TEXT,
  phone TEXT,
  sort_order INT DEFAULT 0,
  is_published BOOLEAN DEFAULT true NOT NULL
);

CREATE TABLE IF NOT EXISTS public.portal_success_stories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  image_url TEXT,
  author_name TEXT,
  is_published BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.portal_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  reviewer_name TEXT NOT NULL,
  reviewer_role TEXT,
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  body TEXT NOT NULL,
  is_published BOOLEAN DEFAULT false NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.portal_help_articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  category TEXT DEFAULT 'Help',
  sort_order INT DEFAULT 0,
  is_published BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- ============================================================
-- GALLERY (parents engage: likes + comments)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.gallery_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  author_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  caption TEXT,
  image_url TEXT NOT NULL,
  is_published BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.gallery_likes (
  post_id UUID NOT NULL REFERENCES public.gallery_posts(id) ON DELETE CASCADE,
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  PRIMARY KEY (post_id, profile_id)
);

CREATE TABLE IF NOT EXISTS public.gallery_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES public.gallery_posts(id) ON DELETE CASCADE,
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- ============================================================
-- COURSE MATERIALS (teacher uploads)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.course_materials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_subject_id UUID NOT NULL REFERENCES public.class_subjects(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  file_url TEXT NOT NULL,
  file_name TEXT,
  material_type TEXT DEFAULT 'document',
  uploaded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  is_published BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- ============================================================
-- FUTURISTIC MODULE TABLES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.qr_checkin_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES public.student_profiles(profile_id) ON DELETE CASCADE,
  scanned_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  location_label TEXT DEFAULT 'Main Gate'
);

CREATE TABLE IF NOT EXISTS public.grade_predictions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES public.student_profiles(profile_id) ON DELETE CASCADE,
  class_subject_id UUID REFERENCES public.class_subjects(id) ON DELETE SET NULL,
  predicted_score NUMERIC NOT NULL,
  confidence NUMERIC DEFAULT 0.75,
  insight TEXT,
  generated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.document_vault (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES public.student_profiles(profile_id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  file_url TEXT NOT NULL,
  category TEXT DEFAULT 'certificate',
  uploaded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.digital_credentials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES public.student_profiles(profile_id) ON DELETE CASCADE,
  credential_type TEXT NOT NULL,
  title TEXT NOT NULL,
  credential_hash TEXT NOT NULL,
  issued_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS public.chatbot_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.timetable_slots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id UUID NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
  class_subject_id UUID REFERENCES public.class_subjects(id) ON DELETE SET NULL,
  day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  room TEXT,
  is_auto_generated BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.sms_alert_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_profile_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  phone TEXT,
  message TEXT NOT NULL,
  alert_type TEXT NOT NULL,
  status TEXT DEFAULT 'queued',
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- ============================================================
-- RLS
-- ============================================================
ALTER TABLE public.feature_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_method_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fee_credits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.portal_faqs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.portal_downloads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.portal_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.portal_success_stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.portal_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.portal_help_articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gallery_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gallery_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gallery_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qr_checkin_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.grade_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_vault ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.digital_credentials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chatbot_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timetable_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sms_alert_log ENABLE ROW LEVEL SECURITY;

-- Feature flags & payment configs: admin manage, all read enabled
CREATE POLICY "Anyone reads feature flags" ON public.feature_flags FOR SELECT USING (true);
CREATE POLICY "Admins manage feature flags" ON public.feature_flags FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "Anyone reads payment configs" ON public.payment_method_configs FOR SELECT USING (true);
CREATE POLICY "Admins manage payment configs" ON public.payment_method_configs FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- Payment submissions
CREATE POLICY "Users view own payment submissions" ON public.payment_submissions FOR SELECT USING (
  auth.uid() = submitted_by OR auth.uid() = student_id
  OR public.is_admin() OR public.is_accountant()
  OR EXISTS (SELECT 1 FROM public.student_parents sp WHERE sp.parent_id = auth.uid() AND sp.student_id = payment_submissions.student_id)
);
CREATE POLICY "Students and parents submit payments" ON public.payment_submissions FOR INSERT WITH CHECK (
  auth.uid() = submitted_by AND (
    auth.uid() = student_id
    OR EXISTS (SELECT 1 FROM public.student_parents sp WHERE sp.parent_id = auth.uid() AND sp.student_id = payment_submissions.student_id)
  )
);
CREATE POLICY "Accountants confirm payments" ON public.payment_submissions FOR UPDATE USING (
  public.is_admin() OR public.is_accountant()
);

-- Fee credits
CREATE POLICY "Students parents view credits" ON public.fee_credits FOR SELECT USING (
  auth.uid() = student_id OR public.is_admin() OR public.is_accountant()
  OR EXISTS (SELECT 1 FROM public.student_parents sp WHERE sp.parent_id = auth.uid() AND sp.student_id = fee_credits.student_id)
);
CREATE POLICY "Accountants manage credits" ON public.fee_credits FOR ALL USING (
  public.is_admin() OR public.is_accountant()
);

-- Portal content: published readable by authenticated, admin manages
CREATE POLICY "Read published portal faqs" ON public.portal_faqs FOR SELECT USING (is_published OR public.is_admin());
CREATE POLICY "Admins manage portal faqs" ON public.portal_faqs FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "Read published downloads" ON public.portal_downloads FOR SELECT USING (is_published OR public.is_admin());
CREATE POLICY "Admins manage downloads" ON public.portal_downloads FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "Read published contacts" ON public.portal_contacts FOR SELECT USING (is_published OR public.is_admin());
CREATE POLICY "Admins manage contacts" ON public.portal_contacts FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "Read published stories" ON public.portal_success_stories FOR SELECT USING (is_published OR public.is_admin());
CREATE POLICY "Admins manage stories" ON public.portal_success_stories FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "Read published reviews" ON public.portal_reviews FOR SELECT USING (is_published OR public.is_admin());
CREATE POLICY "Anyone insert reviews" ON public.portal_reviews FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Admins manage reviews" ON public.portal_reviews FOR UPDATE USING (public.is_admin());

CREATE POLICY "Read published help" ON public.portal_help_articles FOR SELECT USING (is_published OR public.is_admin());
CREATE POLICY "Admins manage help" ON public.portal_help_articles FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- Gallery
CREATE POLICY "Read published gallery" ON public.gallery_posts FOR SELECT USING (is_published OR public.is_admin());
CREATE POLICY "Admins manage gallery posts" ON public.gallery_posts FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "Authenticated like gallery" ON public.gallery_likes FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated comment gallery" ON public.gallery_comments FOR ALL USING (auth.role() = 'authenticated');

-- Course materials
CREATE POLICY "Students read published materials" ON public.course_materials FOR SELECT USING (
  is_published OR public.is_admin() OR public.is_teacher()
);
CREATE POLICY "Teachers manage materials" ON public.course_materials FOR ALL USING (
  public.is_admin() OR public.is_teacher()
);

-- Futuristic modules
CREATE POLICY "Students view own qr logs" ON public.qr_checkin_logs FOR SELECT USING (
  auth.uid() = student_id OR public.is_admin() OR public.is_teacher()
);
CREATE POLICY "Students insert qr checkin" ON public.qr_checkin_logs FOR INSERT WITH CHECK (auth.uid() = student_id);

CREATE POLICY "Students view predictions" ON public.grade_predictions FOR SELECT USING (
  auth.uid() = student_id OR public.is_admin() OR public.is_teacher()
  OR EXISTS (SELECT 1 FROM public.student_parents sp WHERE sp.parent_id = auth.uid() AND sp.student_id = grade_predictions.student_id)
);
CREATE POLICY "System admins insert predictions" ON public.grade_predictions FOR INSERT WITH CHECK (public.is_admin());

CREATE POLICY "Students view vault" ON public.document_vault FOR SELECT USING (
  auth.uid() = student_id OR public.is_admin()
);
CREATE POLICY "Admins manage vault" ON public.document_vault FOR ALL USING (public.is_admin());

CREATE POLICY "Students view credentials" ON public.digital_credentials FOR SELECT USING (
  auth.uid() = student_id OR public.is_admin()
);
CREATE POLICY "Admins issue credentials" ON public.digital_credentials FOR ALL USING (public.is_admin());

CREATE POLICY "Users own chatbot messages" ON public.chatbot_messages FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Read timetable" ON public.timetable_slots FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Admins teachers manage timetable" ON public.timetable_slots FOR ALL USING (
  public.is_admin() OR public.is_teacher()
);

CREATE POLICY "Admins view sms log" ON public.sms_alert_log FOR SELECT USING (public.is_admin());

-- ============================================================
-- CONFIRM PAYMENT FUNCTION (accountant)
-- ============================================================
CREATE OR REPLACE FUNCTION public.confirm_payment_submission(
  p_submission_id UUID,
  p_confirmed_by UUID,
  p_apply_credit BOOLEAN DEFAULT true
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  sub public.payment_submissions%ROWTYPE;
  inv public.invoices%ROWTYPE;
  applied NUMERIC;
  excess NUMERIC;
  payment_id UUID;
BEGIN
  SELECT * INTO sub FROM public.payment_submissions WHERE id = p_submission_id FOR UPDATE;
  IF sub.id IS NULL THEN RAISE EXCEPTION 'Submission not found'; END IF;
  IF sub.status NOT IN ('pending', 'processing') THEN RAISE EXCEPTION 'Already processed'; END IF;

  IF sub.invoice_id IS NOT NULL THEN
    SELECT * INTO inv FROM public.invoices WHERE id = sub.invoice_id FOR UPDATE;
    applied := LEAST(sub.amount, inv.amount - inv.amount_paid);
    excess := sub.amount - applied;

    IF applied > 0 THEN
      INSERT INTO public.payments (invoice_id, student_id, amount, payment_method, reference, recorded_by)
      VALUES (sub.invoice_id, sub.student_id, applied, sub.channel::text, sub.reference_code, p_confirmed_by)
      RETURNING id INTO payment_id;
    ELSE
      excess := sub.amount;
    END IF;
  ELSE
    applied := 0;
    excess := sub.amount;
  END IF;

  IF p_apply_credit AND excess > 0 THEN
    INSERT INTO public.fee_credits (student_id, amount, remaining_amount, source_submission_id, notes)
    VALUES (sub.student_id, excess, excess, sub.id, 'Overpayment credit — carry forward');
  END IF;

  UPDATE public.payment_submissions
  SET status = 'confirmed', confirmed_by = p_confirmed_by, confirmed_at = NOW(), excess_amount = excess
  WHERE id = p_submission_id;

  RETURN payment_id;
END;
$$;

-- Storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES
  ('course-materials', 'course-materials', false),
  ('gallery', 'gallery', true),
  ('portal-downloads', 'portal-downloads', false),
  ('payment-proofs', 'payment-proofs', false)
ON CONFLICT (id) DO NOTHING;

-- Seed feature flags for existing schools
INSERT INTO public.feature_flags (school_id, feature_key, is_enabled, config)
SELECT s.id, f.key, false, f.config::jsonb
FROM public.schools s
CROSS JOIN (VALUES
  ('qr_checkin', '{}'),
  ('ai_grade_predictions', '{"model":"placeholder"}'),
  ('sms_push_alerts', '{"provider":"placeholder","api_key":""}'),
  ('timetable_generator', '{}'),
  ('document_vault', '{}'),
  ('multi_school', '{}'),
  ('facial_recognition', '{"api_key":""}'),
  ('ai_chatbot', '{"api_key":""}'),
  ('blockchain_credentials', '{}'),
  ('gallery', '{"enabled_default":true}'),
  ('school_portal', '{"enabled_default":true}'),
  ('course_materials', '{"enabled_default":true}'),
  ('in_app_notifications', '{"enabled_default":true}')
) AS f(key, config)
ON CONFLICT (school_id, feature_key) DO NOTHING;

-- Seed payment method configs
INSERT INTO public.payment_method_configs (school_id, channel, is_enabled, display_name, config, instructions)
SELECT s.id, c.channel::payment_channel, false, c.display_name, c.config::jsonb, c.instructions
FROM public.schools s
CROSS JOIN (VALUES
  ('manual_till'::text, 'M-Pesa Till Number', '{"till_number":""}', 'Pay via M-Pesa Till and enter the confirmation code.'),
  ('manual_paybill'::text, 'M-Pesa Paybill', '{"paybill":"","account_prefix":"ADM"}', 'Use Paybill number and your admission number as account.'),
  ('manual_bank'::text, 'Bank Transfer', '{"bank_name":"","account_number":"","account_name":""}', 'Transfer to school account and upload proof.'),
  ('mpesa_online'::text, 'M-Pesa STK Push', '{"consumer_key":"","consumer_secret":"","passkey":"","shortcode":""}', 'Pay instantly via M-Pesa on your phone.'),
  ('stripe_online'::text, 'Card Payment (Stripe)', '{"publishable_key":"","secret_key":""}', 'Pay securely with Visa/Mastercard.'),
  ('bank_online'::text, 'Online Banking', '{"gateway_url":"","merchant_id":""}', 'Pay via integrated bank gateway.')
) AS c(channel, display_name, config, instructions)
ON CONFLICT (school_id, channel) DO NOTHING;

-- Enable gallery & portal by default for new seeds
UPDATE public.feature_flags SET is_enabled = true
WHERE feature_key IN ('gallery', 'school_portal', 'course_materials', 'in_app_notifications');
