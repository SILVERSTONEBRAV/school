# GitHub Actions & hosting setup

Complete this once to enable automated builds, releases, and portal download links.

## 1. Supabase migration

Run in SQL editor:

- `supabase/migrations/20260617000000_app_releases_storage.sql`

## 2. GitHub repository secrets

**Settings → Secrets and variables → Actions → Secrets**

| Secret | Value |
|--------|--------|
| `SUPABASE_URL` | `https://xxxx.supabase.co` |
| `SUPABASE_ANON_KEY` | anon key (used at build time) |
| `SUPABASE_SERVICE_ROLE_KEY` | service role key (updates download links — keep private) |
| `VERCEL_TOKEN` | [Vercel account token](https://vercel.com/account/tokens) |

## 3. GitHub repository variables

**Settings → Secrets and variables → Actions → Variables**

| Variable | Example |
|----------|---------|
| `APP_BASE_URL` | `https://app.yourschool.com` |
| `PUBLIC_WEBSITE_URL` | `https://yourschool.com` |
| `SCHOOL_ID` | optional UUID if you have multiple schools |
| `VERCEL_FLUTTER_PROJECT_ID` | Vercel project id for Flutter web (see below) |

Also add `VERCEL_ORG_ID` as a **secret** (from Vercel team settings).

## 4. Vercel — public website (Next.js)

| Setting | Value |
|---------|--------|
| Root Directory | `website` |
| Node.js | 24.x |

Env vars: `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `NEXT_PUBLIC_APP_URL`

Domain: `yourschool.com`

## 5. Vercel — Flutter web app

1. Create a **second** Vercel project linked to this repo.
2. Name it e.g. `school-app-web`.
3. **Disable** automatic Git builds (Build Command: `echo skip` or use Ignored Build Step) — CI deploys `build/web` instead.
4. Copy **Project ID** → GitHub variable `VERCEL_FLUTTER_PROJECT_ID`.
5. Domain: `app.yourschool.com`
6. Supabase Auth → Redirect URLs: `https://app.yourschool.com/**`

## 6. Ship a release

Bump version in `pubspec.yaml`, commit, then:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Or: **Actions → Release apps → Run workflow** and enter a version.

The workflow will:

1. Build Windows zip + Android APK + Flutter web
2. Create a [GitHub Release](https://github.com/SILVERSTONEBRAV/school/releases) with install files
3. Update `portal_app_releases` in Supabase (download URLs + version on `yourschool.com/get-app`)
4. Deploy Flutter web to Vercel (if `VERCEL_FLUTTER_PROJECT_ID` is set)

## 7. iOS

iOS builds require macOS + Apple certificates. Set the App Store URL manually in **Admin → Portal CMS → iOS**.

## 8. Local build (optional)

```powershell
.\scripts\build-release.ps1 -Version 1.0.0
```
