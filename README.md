# School Management System

A modern high school management system built with **Flutter** and **Supabase**, supporting admin, teacher, student, parent, staff, and accountant portals.

## Tech Stack

- Flutter (multi-platform)
- Supabase (PostgreSQL, Auth, Realtime, Storage)
- Riverpod (state management)
- GoRouter (navigation)

## Public website & releases

- **Public portal:** Next.js app in [`website/`](website/) → deploy to Vercel (Node 24, root `website`)
- **Web app:** Flutter web at `app.yourschool.com` (CI deploys via GitHub Actions)
- **Downloads:** Automated on git tag `v*` — see [`.github/SETUP.md`](.github/SETUP.md)

## Getting Started

### 1. Supabase setup

1. Create a [Supabase](https://supabase.com) project.
2. Run the migration in `supabase/migrations/20260606000000_init_schema.sql` via the SQL editor or Supabase CLI.
3. Copy your project URL and anon key.

### 2. Configure the app

Pass credentials via `--dart-define` when running:

```bash
flutter run -d windows \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Or update defaults in `lib/core/config/app_config.dart` for local development.

### 3. Create the first admin user

Register via the app with role **Admin**, or create a user in Supabase Auth with metadata:

```json
{
  "first_name": "Admin",
  "last_name": "User",
  "role": "admin"
}
```

The database trigger automatically creates the matching `profiles` row.

### 4. Run the app

```bash
flutter pub get
flutter run -d windows
```

## Phase 1 (Current)

- [x] Flutter + Supabase project setup
- [x] Auth (login, register, role-based routing)
- [x] Admin portal: dashboard, school setup, user management, **academic setup**
- [x] Teacher portal: **attendance marking, gradebook**
- [x] Student portal: **schedule, grades, attendance views**
- [x] Database schema with RLS policies

## Project Structure

```
lib/
├── core/           # Config, router, theme
├── features/       # Role-based feature modules
│   ├── admin/
│   ├── auth/
│   ├── teacher/
│   └── student/
└── shared/         # Models and reusable widgets
```

## Phase 2

- [x] Parent portal: child overview, grades, attendance, fees
- [x] Accountant portal: fee structures, invoices, payments
- [x] Student fee view
- [x] Admin parent–student linking
- [x] Fees database schema with RLS + auto-balance trigger

## Phase 3

- [x] Assignments & submissions (teacher create, student submit, teacher grade)
- [x] In-app notification center (assignment posted, grade posted)
- [x] PDF report card download from student grades
- [x] Database schema for assignments, submissions, notifications

## Phase 4

- [x] Realtime notification updates (Supabase Realtime stream)
- [x] File upload for assignment submissions (Supabase Storage)
- [x] Parent assignment status view
- [x] Admin analytics dashboard (charts for roles, fees, attendance, enrollment)

## Phase 5 (Current)

- [x] Localization (English + Swahili) with persisted language preference
- [x] Theme toggle (light / dark / system) with persistence
- [x] School announcements (admin post, all portals view)
- [x] Offline cache for student dashboard data
- [x] Multi-school foundation (`profiles.school_id`)

Apply migrations in order:
1. `supabase/migrations/20260608000000_fees_and_payments.sql`
2. `supabase/migrations/20260609000000_assignments_notifications.sql`
3. `supabase/migrations/20260610000000_storage_realtime.sql`
4. `supabase/migrations/20260611000000_announcements_multischool.sql`
