# School public website (Next.js)

Marketing and public portal for the school. Deploy to **Vercel** at your main domain (e.g. `yourschool.com`).

The Flutter app lives separately at `NEXT_PUBLIC_APP_URL` (e.g. `app.yourschool.com`).

## Setup

```bash
cd website
cp .env.local.example .env.local
# Edit .env.local with Supabase URL, anon key, and app URL
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Deploy to Vercel

1. Import this repo in Vercel.
2. Set **Root Directory** to `website`.
3. Add environment variables:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - `NEXT_PUBLIC_APP_URL` → your Flutter web URL
4. Deploy.

Apply migration `20260616000000_public_website.sql` in Supabase before going live.

## Admin

- Edit mission, vision, about in the Flutter app → **Admin → Portal CMS**.
- Set app download URLs in **Portal CMS → App downloads**.
- Manage FAQs, downloads, contacts, etc. via Supabase (admin CMS UI coming next).
