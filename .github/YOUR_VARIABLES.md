# Your GitHub Actions values (SILVER SCHOOL)

Copy these into **GitHub → Settings → Secrets and variables → Actions**.

## Variables tab

| Name | Value |
|------|--------|
| `APP_BASE_URL` | `https://schoolwebkenya.vercel.app` |
| `PUBLIC_WEBSITE_URL` | `https://webhighschool.vercel.app` |
| `VERCEL_FLUTTER_PROJECT_ID` | From Vercel → **schoolwebkenya** project → Settings → General → **Project ID** |

No trailing slashes.

## Secrets tab

| Name | Where |
|------|--------|
| `SUPABASE_URL` | Supabase → Settings → API |
| `SUPABASE_ANON_KEY` | Supabase → Settings → API |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase → Settings → API (service_role) |
| `VERCEL_TOKEN` | vercel.com → Account → Tokens |
| `VERCEL_ORG_ID` | Vercel → Account/Team Settings → General |

## Vercel — public website (webhighschool)

Project env vars:

| Name | Value |
|------|--------|
| `NEXT_PUBLIC_SUPABASE_URL` | your Supabase URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | your anon key |
| `NEXT_PUBLIC_APP_URL` | `https://schoolwebkenya.vercel.app` |

## Supabase Auth redirect URLs

```
https://schoolwebkenya.vercel.app/**
https://webhighschool.vercel.app/**
```

## Re-run release

After saving secrets/variables:

1. **Actions → Release apps → Run workflow** → version `1.0.1`

Or push a tag:

```bash
git tag v1.0.1
git push origin v1.0.1
```
