-- Public bucket for Windows/Android install files (optional; GitHub Releases also works)

INSERT INTO storage.buckets (id, name, public)
VALUES ('app-releases', 'app-releases', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Public read app release files"
  ON storage.objects FOR SELECT
  TO anon, authenticated
  USING (bucket_id = 'app-releases');

CREATE POLICY "Admins manage app release files"
  ON storage.objects FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "Service role full access app releases"
  ON storage.objects FOR ALL
  TO service_role
  USING (bucket_id = 'app-releases')
  WITH CHECK (bucket_id = 'app-releases');
