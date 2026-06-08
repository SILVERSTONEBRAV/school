-- Enable realtime for notifications
ALTER TABLE public.notifications REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;
END $$;

-- Storage bucket for assignment file uploads
INSERT INTO storage.buckets (id, name, public)
VALUES ('assignments', 'assignments', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Students upload assignment files"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'assignments'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users read assignment files"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'assignments'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR public.is_admin()
      OR EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role IN ('teacher', 'admin')
      )
      OR EXISTS (
        SELECT 1 FROM public.student_parents sp
        WHERE sp.parent_id = auth.uid()
        AND sp.student_id::text = (storage.foldername(name))[1]
      )
    )
  );

CREATE POLICY "Students update own assignment files"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'assignments'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
