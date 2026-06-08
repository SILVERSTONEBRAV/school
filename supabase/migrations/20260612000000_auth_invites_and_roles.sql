-- Staff invites for admin-provisioned accounts (teacher, staff, accountant, admin)
CREATE TABLE IF NOT EXISTS public.staff_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  role public.user_role NOT NULL,
  school_id UUID REFERENCES public.schools(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE DEFAULT encode(gen_random_bytes(24), 'hex'),
  invited_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
  accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  CONSTRAINT staff_invites_role_check CHECK (
    role IN ('admin', 'teacher', 'staff', 'accountant')
  )
);

CREATE INDEX IF NOT EXISTS idx_staff_invites_token ON public.staff_invites(token);
CREATE INDEX IF NOT EXISTS idx_staff_invites_email ON public.staff_invites(email);

ALTER TABLE public.staff_invites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins manage staff invites"
  ON public.staff_invites
  FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Anyone can validate an invite token during signup (read-only, by token)
CREATE POLICY "Public can read invite by token"
  ON public.staff_invites
  FOR SELECT
  USING (accepted_at IS NULL AND expires_at > NOW());

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

    IF role_val NOT IN ('student', 'parent') THEN
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
    id, email, role, first_name, last_name, phone_number, avatar_url, school_id
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
    profile_school_id
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
  END IF;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
