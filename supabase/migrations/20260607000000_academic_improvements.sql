-- Allow class teachers to mark attendance for their class
CREATE POLICY "Allow class teachers to log attendance"
  ON public.attendance FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.classes c
      WHERE c.id = class_id AND c.class_teacher_id = auth.uid()
    )
  );

CREATE POLICY "Allow class teachers to update attendance"
  ON public.attendance FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.classes c
      WHERE c.id = class_id AND c.class_teacher_id = auth.uid()
    )
  );

-- Prevent duplicate grade entries per term
ALTER TABLE public.grades
  DROP CONSTRAINT IF EXISTS grades_student_subject_term_unique;

ALTER TABLE public.grades
  ADD CONSTRAINT grades_student_subject_term_unique
  UNIQUE (student_id, class_subject_id, term_id);
