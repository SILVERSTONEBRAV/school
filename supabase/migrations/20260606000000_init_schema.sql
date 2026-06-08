-- Enable UUID generator extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ---------------------------------------------------------
-- ENUMS
-- ---------------------------------------------------------
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM ('admin', 'teacher', 'student', 'parent', 'staff', 'accountant');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'attendance_status') THEN
        CREATE TYPE attendance_status AS ENUM ('present', 'absent', 'late', 'excused');
    END IF;
END $$;

-- ---------------------------------------------------------
-- CORE TABLES
-- ---------------------------------------------------------

-- Schools
CREATE TABLE IF NOT EXISTS public.schools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    logo_url TEXT,
    motto TEXT,
    address TEXT,
    phone TEXT,
    email TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Profiles (extends auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    role user_role NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    phone_number TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Academic Years
CREATE TABLE IF NOT EXISTS public.academic_years (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
    name TEXT NOT NULL, -- e.g. "2025-2026"
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Terms/Semesters
CREATE TABLE IF NOT EXISTS public.terms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    academic_year_id UUID NOT NULL REFERENCES public.academic_years(id) ON DELETE CASCADE,
    name TEXT NOT NULL, -- e.g. "Term 1"
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Departments
CREATE TABLE IF NOT EXISTS public.departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    head_teacher_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Classes
CREATE TABLE IF NOT EXISTS public.classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
    academic_year_id UUID NOT NULL REFERENCES public.academic_years(id) ON DELETE CASCADE,
    name TEXT NOT NULL, -- e.g. "Grade 10A"
    class_teacher_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Subjects
CREATE TABLE IF NOT EXISTS public.subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    code TEXT NOT NULL,
    department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Class Subjects mapping (which classes are taught which subjects, and by which teacher)
CREATE TABLE IF NOT EXISTS public.class_subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id UUID NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
    subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
    teacher_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    credit_hours NUMERIC DEFAULT 1.0 NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE(class_id, subject_id)
);

-- ---------------------------------------------------------
-- ROLE-SPECIFIC PROFILES
-- ---------------------------------------------------------

-- Students
CREATE TABLE IF NOT EXISTS public.student_profiles (
    profile_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    roll_number TEXT,
    date_of_birth DATE,
    admission_date DATE DEFAULT CURRENT_DATE NOT NULL
);

-- Parents
CREATE TABLE IF NOT EXISTS public.parent_profiles (
    profile_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    address TEXT,
    occupation TEXT
);

-- Parents-Students Junction
CREATE TABLE IF NOT EXISTS public.student_parents (
    student_id UUID NOT NULL REFERENCES public.student_profiles(profile_id) ON DELETE CASCADE,
    parent_id UUID NOT NULL REFERENCES public.parent_profiles(profile_id) ON DELETE CASCADE,
    relationship TEXT, -- e.g. Mother, Father, Guardian
    PRIMARY KEY (student_id, parent_id)
);

-- Enrollments (Student-Class mapping per academic year)
CREATE TABLE IF NOT EXISTS public.enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES public.student_profiles(profile_id) ON DELETE CASCADE,
    class_id UUID NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
    academic_year_id UUID NOT NULL REFERENCES public.academic_years(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'active' NOT NULL CHECK (status IN ('active', 'completed', 'dropped')),
    enrolled_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE(student_id, class_id)
);

-- Attendance Records
CREATE TABLE IF NOT EXISTS public.attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES public.student_profiles(profile_id) ON DELETE CASCADE,
    class_id UUID NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
    date DATE DEFAULT CURRENT_DATE NOT NULL,
    status attendance_status NOT NULL,
    remarks TEXT,
    marked_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE(student_id, date)
);

-- Grades/Marks Record
CREATE TABLE IF NOT EXISTS public.grades (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES public.student_profiles(profile_id) ON DELETE CASCADE,
    class_subject_id UUID NOT NULL REFERENCES public.class_subjects(id) ON DELETE CASCADE,
    term_id UUID NOT NULL REFERENCES public.terms(id) ON DELETE CASCADE,
    grade_letter TEXT, -- e.g. 'A', 'B+'
    score NUMERIC NOT NULL CHECK (score >= 0),
    weight NUMERIC DEFAULT 1.0 NOT NULL,
    comments TEXT,
    graded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- ---------------------------------------------------------
-- TRIGGER FOR USER SIGN UP
-- ---------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  role_val public.user_role;
BEGIN
  -- Parse and cast the role from metadata, default to 'student'
  role_val := COALESCE((new.raw_user_meta_data->>'role')::public.user_role, 'student'::public.user_role);

  -- Insert profile
  INSERT INTO public.profiles (id, email, role, first_name, last_name, phone_number, avatar_url)
  VALUES (
    new.id,
    new.email,
    role_val,
    COALESCE(new.raw_user_meta_data->>'first_name', ''),
    COALESCE(new.raw_user_meta_data->>'last_name', ''),
    new.raw_user_meta_data->>'phone_number',
    new.raw_user_meta_data->>'avatar_url'
  );

  -- Insert secondary profile based on role
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

-- Bind trigger to auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ---------------------------------------------------------
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ---------------------------------------------------------

-- Helper function to check if the current user is an admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS on all tables
ALTER TABLE public.schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.academic_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.terms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parent_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_parents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.grades ENABLE ROW LEVEL SECURITY;

-- 1. Schools RLS Policies
CREATE POLICY "Allow anyone to view schools" ON public.schools FOR SELECT USING (true);
CREATE POLICY "Allow admins to manage schools" ON public.schools FOR ALL USING (public.is_admin());

-- 2. Profiles RLS Policies
CREATE POLICY "Allow users to view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Allow admins to manage profiles" ON public.profiles FOR ALL USING (public.is_admin());
CREATE POLICY "Allow teachers to view student profiles" ON public.profiles FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'teacher')
);
CREATE POLICY "Allow parents to view children profiles" ON public.profiles FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.student_parents sp
    WHERE sp.parent_id = auth.uid() AND sp.student_id = public.profiles.id
  )
);

-- 3. Academic Years & Terms Policies
CREATE POLICY "Allow anyone to view academic years" ON public.academic_years FOR SELECT USING (true);
CREATE POLICY "Allow admins to manage academic years" ON public.academic_years FOR ALL USING (public.is_admin());
CREATE POLICY "Allow anyone to view terms" ON public.terms FOR SELECT USING (true);
CREATE POLICY "Allow admins to manage terms" ON public.terms FOR ALL USING (public.is_admin());

-- 4. Classes, Subjects & Departments Policies
CREATE POLICY "Allow anyone to view departments" ON public.departments FOR SELECT USING (true);
CREATE POLICY "Allow admins to manage departments" ON public.departments FOR ALL USING (public.is_admin());
CREATE POLICY "Allow anyone to view classes" ON public.classes FOR SELECT USING (true);
CREATE POLICY "Allow admins to manage classes" ON public.classes FOR ALL USING (public.is_admin());
CREATE POLICY "Allow anyone to view subjects" ON public.subjects FOR SELECT USING (true);
CREATE POLICY "Allow admins to manage subjects" ON public.subjects FOR ALL USING (public.is_admin());
CREATE POLICY "Allow anyone to view class subjects" ON public.class_subjects FOR SELECT USING (true);
CREATE POLICY "Allow admins to manage class subjects" ON public.class_subjects FOR ALL USING (public.is_admin());

-- 5. Student & Parent Profiles RLS
CREATE POLICY "Allow users to view own role profiles" ON public.student_profiles FOR SELECT USING (auth.uid() = profile_id OR public.is_admin());
CREATE POLICY "Allow teachers to view student details" ON public.student_profiles FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'teacher')
);
CREATE POLICY "Allow parents to view student details" ON public.student_profiles FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.student_parents sp WHERE sp.parent_id = auth.uid() AND sp.student_id = profile_id)
);
CREATE POLICY "Allow admins to manage student profiles" ON public.student_profiles FOR ALL USING (public.is_admin());

CREATE POLICY "Allow users to view own parent details" ON public.parent_profiles FOR SELECT USING (auth.uid() = profile_id OR public.is_admin());
CREATE POLICY "Allow admins to manage parent profiles" ON public.parent_profiles FOR ALL USING (public.is_admin());

CREATE POLICY "Allow parents/students to view relationship mapping" ON public.student_parents FOR SELECT USING (
  auth.uid() = student_id OR auth.uid() = parent_id OR public.is_admin()
);
CREATE POLICY "Allow admins to manage relationship mapping" ON public.student_parents FOR ALL USING (public.is_admin());

-- 6. Enrollments Policies
CREATE POLICY "Allow anyone to view enrollments" ON public.enrollments FOR SELECT USING (true);
CREATE POLICY "Allow admins to manage enrollments" ON public.enrollments FOR ALL USING (public.is_admin());

-- 7. Attendance Policies
CREATE POLICY "Allow students/parents to view attendance" ON public.attendance FOR SELECT USING (
  auth.uid() = student_id OR 
  EXISTS (SELECT 1 FROM public.student_parents sp WHERE sp.parent_id = auth.uid() AND sp.student_id = student_id) OR
  public.is_admin()
);
CREATE POLICY "Allow teachers/admins to view all attendance" ON public.attendance FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'teacher'))
);
CREATE POLICY "Allow teachers to log attendance" ON public.attendance FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.class_subjects cs
    WHERE cs.teacher_id = auth.uid() AND cs.class_id = class_id
  )
);
CREATE POLICY "Allow teachers to update attendance" ON public.attendance FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM public.class_subjects cs
    WHERE cs.teacher_id = auth.uid() AND cs.class_id = class_id
  )
);
CREATE POLICY "Allow admins to manage all attendance" ON public.attendance FOR ALL USING (public.is_admin());

-- 8. Grades Policies
CREATE POLICY "Allow students to view own grades" ON public.grades FOR SELECT USING (
  auth.uid() = student_id OR public.is_admin()
);
CREATE POLICY "Allow parents to view children grades" ON public.grades FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.student_parents sp WHERE sp.parent_id = auth.uid() AND sp.student_id = student_id)
);
CREATE POLICY "Allow teachers to view all grades" ON public.grades FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'teacher')
);
CREATE POLICY "Allow teachers to manage grades for their subjects" ON public.grades FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.class_subjects cs
    WHERE cs.teacher_id = auth.uid() AND cs.id = class_subject_id
  )
);
CREATE POLICY "Allow admins to manage all grades" ON public.grades FOR ALL USING (public.is_admin());
