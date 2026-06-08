# School public website (Next.js)

Marketing and public portal for the school. Deploy to **Vercel** at your main domain (e.g. `yourschool.com`).

The Flutter app lives separately at `NEXT_PUBLIC_APP_URL` (e.g. `app.yourschool.com`).

Requires **Node.js 24** (see `.nvmrc` and `package.json` engines).

## Setup

```bash
cd website
nvm use    # or: fnm use / volta pin node@24
cp .env.local.example .env.local
# Edit .env.local with Supabase URL, anon key, and app URL
npm install
npm run dev
```

See **[DEPLOYMENT.md](./DEPLOYMENT.md)** for download links, hosting binaries, and version updates.

Open [http://localhost:3000](http://localhost:3000).

## Deploy to Vercel

1. Import this repo in Vercel.
2. Set **Root Directory** to `website`.
3. **Required** environment variables (Project → Settings → Environment Variables):
   - `NEXT_PUBLIC_SUPABASE_URL` — your Supabase project URL
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY` — anon/public key
   - `NEXT_PUBLIC_APP_URL` — Flutter web app URL (e.g. `https://app.yourschool.com`)
4. Redeploy after adding env vars (build can succeed without them, but pages will be empty until they are set).
5. Deploy.

Apply migration `20260616000000_public_website.sql` in Supabase before going live.

## Admin

- Edit mission, vision, about in the Flutter app → **Admin → Portal CMS**.
- Set app download URLs in **Portal CMS → App downloads**.
- Manage FAQs, downloads, contacts, etc. via Supabase (admin CMS UI coming next).
