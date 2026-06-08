-- Fix infinite recursion in profiles RLS policies.
-- Helper functions that read profiles must bypass RLS (SECURITY DEFINER + row_security off).

CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS public.user_role
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
SET row_security = off
STABLE
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
SET row_security = off
STABLE
AS $$
  SELECT public.current_user_role() = 'admin'::public.user_role;
$$;

CREATE OR REPLACE FUNCTION public.is_accountant()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
SET row_security = off
STABLE
AS $$
  SELECT public.current_user_role() = 'accountant'::public.user_role;
$$;

CREATE OR REPLACE FUNCTION public.is_teacher()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
SET row_security = off
STABLE
AS $$
  SELECT public.current_user_role() = 'teacher'::public.user_role;
$$;

CREATE OR REPLACE FUNCTION public.is_staff_role()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
SET row_security = off
STABLE
AS $$
  SELECT public.current_user_role() IN (
    'admin'::public.user_role,
    'teacher'::public.user_role,
    'staff'::public.user_role,
    'accountant'::public.user_role
  );
$$;

-- Profiles: replace inline subqueries that caused recursion
DROP POLICY IF EXISTS "Allow teachers to view student profiles" ON public.profiles;
CREATE POLICY "Allow teachers to view student profiles"
  ON public.profiles
  FOR SELECT
  USING (public.is_teacher());

DROP POLICY IF EXISTS "Allow users to update own profile" ON public.profiles;
CREATE POLICY "Allow users to update own profile"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Student profiles
DROP POLICY IF EXISTS "Allow teachers to view student details" ON public.student_profiles;
CREATE POLICY "Allow teachers to view student details"
  ON public.student_profiles
  FOR SELECT
  USING (public.is_teacher());

-- Attendance
DROP POLICY IF EXISTS "Allow teachers/admins to view all attendance" ON public.attendance;
CREATE POLICY "Allow teachers/admins to view all attendance"
  ON public.attendance
  FOR SELECT
  USING (public.is_staff_role());

-- Grades
DROP POLICY IF EXISTS "Allow teachers to view all grades" ON public.grades;
CREATE POLICY "Allow teachers to view all grades"
  ON public.grades
  FOR SELECT
  USING (public.is_teacher());

-- Notifications
DROP POLICY IF EXISTS "Allow system roles to insert notifications" ON public.notifications;
CREATE POLICY "Allow system roles to insert notifications"
  ON public.notifications
  FOR INSERT
  WITH CHECK (public.is_staff_role());

-- Announcements
DROP POLICY IF EXISTS "Allow teachers to create announcements" ON public.announcements;
CREATE POLICY "Allow teachers to create announcements"
  ON public.announcements
  FOR INSERT
  WITH CHECK (public.is_admin() OR public.is_teacher());

-- Storage
DROP POLICY IF EXISTS "Users read assignment files" ON storage.objects;
CREATE POLICY "Users read assignment files"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'assignments'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR public.is_staff_role()
      OR EXISTS (
        SELECT 1 FROM public.student_parents sp
        WHERE sp.parent_id = auth.uid()
          AND sp.student_id::text = (storage.foldername(name))[1]
      )
    )
  );
