# Deployment & app download guide

## Architecture

```
yourschool.com          → Next.js public website (this folder, Vercel, Node 24)
app.yourschool.com      → Flutter web app (separate Vercel project, build/web)
```

Visitors use the **public website** for info and downloads. Signed-in users use the **Flutter web app** (or native apps).

---

## 1. Node.js 24 on Vercel

This project pins Node 24 via `package.json` → `"engines": { "node": "24.x" }` and `.nvmrc`.

In Vercel: **Project → Settings → General → Node.js Version** → set to **24.x** (or leave as default if it reads `engines` from `package.json`).

---

## 2. Public website (Vercel)

| Setting | Value |
|---------|--------|
| Root Directory | `website` |
| Framework | Next.js |
| Node | 24.x |

**Environment variables:**

| Variable | Example |
|----------|---------|
| `NEXT_PUBLIC_SUPABASE_URL` | `https://xxxx.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | your anon key |
| `NEXT_PUBLIC_APP_URL` | `https://app.yourschool.com` |

`NEXT_PUBLIC_APP_URL` is the fallback when the **Web** row in admin has no URL. Header/footer “Sign in” and “Continue on web” use this too.

---

## 3. Flutter web app (second Vercel project)

1. Create another Vercel project from the same repo.
2. Root Directory: **repository root** (not `website`).
3. Build command:

```bash
flutter pub get && flutter build web --release \
  --dart-define=SUPABASE_URL=YOUR_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_KEY \
  --dart-define=APP_BASE_URL=https://app.yourschool.com \
  --dart-define=PUBLIC_WEBSITE_URL=https://yourschool.com
```

4. Output directory: `build/web`
5. Assign domain: `app.yourschool.com`
6. Add Supabase Auth redirect URLs for `https://app.yourschool.com/**`

For Flutter on Vercel you may need a custom `vercel.json` at repo root or use GitHub Actions to build and deploy `build/web`. Simplest path: build locally/CI, deploy `build/web` as static site.

---

## 4. Download links (admin)

All platforms are stored in Supabase table **`portal_app_releases`**:

| platform | Purpose |
|----------|---------|
| `web` | Link to Flutter web login |
| `windows` | `.exe` / `.msix` / zip download URL |
| `android` | Play Store or direct APK URL |
| `ios` | App Store URL |

### In the Flutter admin app

**Admin → Portal CMS → App downloads (Get the App page)**

For each platform, set:

- **Download / Web URL** — full `https://...` link
- **Version** — e.g. `1.2.0` (shown on public site)
- **Notes** — short release note
- **Enabled** — show/hide on website

Changes appear on `yourschool.com/get-app` immediately (no redeploy).

### In Supabase (alternative)

Table Editor → `portal_app_releases` → edit `download_url`, `version`, `release_notes`, `is_enabled`.

---

## 5. Where to host install files

### Windows (.exe / zip)

**Option A — GitHub Releases (recommended, free)**

1. `flutter build windows --release`
2. Zip `build/windows/x64/runner/Release/` (or ship the installer you create).
3. GitHub → repo → **Releases** → New release → tag `v1.0.0` → upload zip.
4. Copy the asset URL, e.g.  
   `https://github.com/SILVERSTONEBRAV/school/releases/download/v1.0.0/school-windows-1.0.0.zip`
5. Paste into **Portal CMS → Windows → Download URL**.

**Option B — Supabase Storage**

1. Create public bucket `app-releases` (Dashboard → Storage).
2. Upload `school-1.0.0-windows.zip`.
3. Copy public URL into admin CMS.

### Android

- **Play Store:** use listing URL  
  `https://play.google.com/store/apps/details?id=com.schoolmgmt.app`
- **Direct APK:** upload APK to GitHub Releases or Supabase Storage, paste URL in **Android** row.

### iOS

- App Store only for most schools:  
  `https://apps.apple.com/app/idXXXXXXXX`
- Paste into **iOS** row in Portal CMS.

### Web

Set **Web** download URL to:

```
https://app.yourschool.com/login
```

Or leave empty — the site uses `NEXT_PUBLIC_APP_URL` + `/login`.

---

## 6. Updating versions

When you ship a new build:

1. Bump version in `pubspec.yaml`:

```yaml
version: 1.1.0+2   # 1.1.0 = user-facing, +2 = build number
```

2. Build the platform artifact (windows / apk / web).
3. Upload to GitHub Releases (or Storage) with a new tag, e.g. `v1.1.0`.
4. In **Admin → Portal CMS**, update that platform:
   - **Version:** `1.1.0`
   - **Download URL:** new release asset URL
   - **Notes:** e.g. “Fee payments fix, gallery updates”
5. Save — public **Get the App** page updates automatically.

You do **not** need to redeploy the Next.js site for link/version changes.

---

## 7. Portal document downloads (PDFs, forms)

Separate from app installs — table **`portal_downloads`**.

Upload files to Supabase Storage bucket `portal-downloads`, insert rows in `portal_downloads` (or extend admin CMS later). They show on `yourschool.com/downloads`.

---

## Quick checklist

- [ ] Migration `20260616000000_public_website.sql` applied
- [ ] Vercel website project: root `website`, Node 24, env vars set
- [ ] Flutter web hosted at `app.yourschool.com`
- [ ] Portal CMS: Web URL → `https://app.yourschool.com/login`
- [ ] Windows/Android/iOS URLs → store or GitHub Release links
- [ ] Supabase Auth redirects include app domain
