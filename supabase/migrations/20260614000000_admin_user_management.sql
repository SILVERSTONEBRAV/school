-- Admin user management: status, staff profiles, audit log, insights view

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_account_status') THEN
    CREATE TYPE user_account_status AS ENUM ('active', 'inactive', 'suspended');
  END IF;
END $$;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS status user_account_status DEFAULT 'active' NOT NULL;

CREATE TABLE IF NOT EXISTS public.staff_profiles (
  profile_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  employee_id TEXT,
  job_title TEXT,
  department TEXT,
  hire_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.admin_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  target_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  details JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_log_created
  ON public.admin_audit_log (created_at DESC);

ALTER TABLE public.staff_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins manage staff profiles"
  ON public.staff_profiles FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "Staff view own profile details"
  ON public.staff_profiles FOR SELECT
  USING (auth.uid() = profile_id OR public.is_admin());

CREATE POLICY "Admins read audit log"
  ON public.admin_audit_log FOR SELECT
  USING (public.is_admin());

CREATE POLICY "Admins insert audit log"
  ON public.admin_audit_log FOR INSERT
  WITH CHECK (public.is_admin());

CREATE POLICY "Admins update user status on profiles"
  ON public.profiles FOR UPDATE
  USING (public.is_admin() OR auth.uid() = id)
  WITH CHECK (public.is_admin() OR auth.uid() = id);

-- At-risk students: low attendance in last 30 days (< 75% present)
CREATE OR REPLACE VIEW public.at_risk_students AS
SELECT
  sp.profile_id AS student_id,
  p.first_name,
  p.last_name,
  p.email,
  COUNT(a.id) AS total_days,
  COUNT(a.id) FILTER (WHERE a.status IN ('present', 'late')) AS present_days,
  ROUND(
    100.0 * COUNT(a.id) FILTER (WHERE a.status IN ('present', 'late'))
    / NULLIF(COUNT(a.id), 0),
    1
  ) AS attendance_rate
FROM public.student_profiles sp
JOIN public.profiles p ON p.id = sp.profile_id
LEFT JOIN public.attendance a ON a.student_id = sp.profile_id
  AND a.date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY sp.profile_id, p.first_name, p.last_name, p.email
HAVING COUNT(a.id) >= 5
  AND (
    100.0 * COUNT(a.id) FILTER (WHERE a.status IN ('present', 'late'))
    / NULLIF(COUNT(a.id), 0)
  ) < 75;

GRANT SELECT ON public.at_risk_students TO authenticated;

-- Extend handle_new_user for staff/accountant secondary profiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  role_val public.user_role;
  invite_record public.staff_invites%ROWTYPE;
  invite_token TEXT;
  meta_first TEXT;
  meta_last TEXT;
  meta_full TEXT;
  profile_school_id UUID;
BEGIN
  profile_school_id := NULL;
  invite_token := new.raw_user_meta_data->>'invite_token';

  IF invite_token IS NOT NULL AND invite_token <> '' THEN
    SELECT * INTO invite_record
    FROM public.staff_invites
    WHERE token = invite_token
      AND accepted_at IS NULL
      AND expires_at > NOW()
    LIMIT 1;

    IF invite_record.id IS NULL THEN
      RAISE EXCEPTION 'Invalid or expired invite link';
    END IF;

    IF lower(new.email) <> lower(invite_record.email) THEN
      RAISE EXCEPTION 'This invite was sent to a different email address';
    END IF;

    role_val := invite_record.role;
    profile_school_id := invite_record.school_id;

    UPDATE public.staff_invites
    SET accepted_at = NOW()
    WHERE id = invite_record.id;
  ELSE
    role_val := COALESCE(
      (new.raw_user_meta_data->>'role')::public.user_role,
      'student'::public.user_role
    );

    IF invite_token IS NULL
      AND role_val NOT IN ('student', 'parent')
      AND COALESCE((new.raw_user_meta_data->>'created_by_admin')::boolean, false) IS NOT TRUE
    THEN
      role_val := 'student'::public.user_role;
    END IF;
  END IF;

  meta_first := COALESCE(
    new.raw_user_meta_data->>'first_name',
    new.raw_user_meta_data->>'given_name',
    ''
  );
  meta_last := COALESCE(
    new.raw_user_meta_data->>'last_name',
    new.raw_user_meta_data->>'family_name',
    ''
  );
  meta_full := COALESCE(
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'name',
    ''
  );

  IF meta_first = '' AND meta_full <> '' THEN
    meta_first := split_part(meta_full, ' ', 1);
    meta_last := COALESCE(
      NULLIF(trim(substring(meta_full from position(' ' in meta_full))), ''),
      meta_last
    );
  END IF;

  INSERT INTO public.profiles (
    id, email, role, first_name, last_name, phone_number, avatar_url, school_id, status
  )
  VALUES (
    new.id,
    new.email,
    role_val,
    meta_first,
    meta_last,
    new.raw_user_meta_data->>'phone_number',
    COALESCE(
      new.raw_user_meta_data->>'avatar_url',
      new.raw_user_meta_data->>'picture'
    ),
    COALESCE(
      profile_school_id,
      (new.raw_user_meta_data->>'school_id')::uuid
    ),
    COALESCE(
      (new.raw_user_meta_data->>'status')::user_account_status,
      'active'::user_account_status
    )
  );

  IF role_val = 'student' THEN
    INSERT INTO public.student_profiles (profile_id, roll_number, date_of_birth, admission_date)
    VALUES (
      new.id,
      new.raw_user_meta_data->>'roll_number',
      (new.raw_user_meta_data->>'date_of_birth')::DATE,
      COALESCE((new.raw_user_meta_data->>'admission_date')::DATE, CURRENT_DATE)
    );
  ELSIF role_val = 'parent' THEN
    INSERT INTO public.parent_profiles (profile_id, address, occupation)
    VALUES (
      new.id,
      new.raw_user_meta_data->>'address',
      new.raw_user_meta_data->>'occupation'
    );
  ELSIF role_val IN ('teacher', 'staff', 'accountant', 'admin') THEN
    INSERT INTO public.staff_profiles (profile_id, employee_id, job_title, department, hire_date)
    VALUES (
      new.id,
      new.raw_user_meta_data->>'employee_id',
      new.raw_user_meta_data->>'job_title',
      new.raw_user_meta_data->>'department',
      COALESCE((new.raw_user_meta_data->>'hire_date')::DATE, CURRENT_DATE)
    );
  END IF;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
