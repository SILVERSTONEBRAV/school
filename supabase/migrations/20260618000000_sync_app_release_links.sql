-- Sync app download links for v1.0.3 (GitHub Release + Flutter web app)
-- Safe to re-run: only updates known platform rows per school.

UPDATE public.portal_app_releases AS r
SET
  download_url = v.url,
  version = '1.0.3',
  release_notes = v.notes,
  is_enabled = true,
  updated_at = NOW()
FROM public.schools AS s
CROSS JOIN (
  VALUES
    (
      'web'::text,
      'https://schoolwebkenya.vercel.app/login'::text,
      'Continue in browser — no install needed'::text
    ),
    (
      'windows'::text,
      'https://github.com/SILVERSTONEBRAV/school/releases/download/v1.0.3/school-management-1.0.3-windows.zip'::text,
      'Windows desktop build v1.0.3'::text
    ),
    (
      'android'::text,
      'https://github.com/SILVERSTONEBRAV/school/releases/download/v1.0.3/school-management-1.0.3-android.apk'::text,
      'Android APK v1.0.3'::text
    )
) AS v(platform, url, notes)
WHERE r.school_id = s.id
  AND r.platform = v.platform;
